class_name Confeitaria
## Minha Confeitaria: regras da fábrica de doces, ligada ao quiz. A cozinha 3D
## (cenas/cozinha.*) e o painel simples (cenas/confeitaria.*, para aparelhos
## sem placa de vídeo) usam estas regras.
##
## - Cada acerto no quiz dá ACUCAR_POR_ACERTO de açúcar (o ingrediente).
## - As máquinas transformam açúcar em doces, sozinhas, com o tempo, e põem
##   os doces na bandeja delas (até encher). Cada máquina faz um doce da
##   coleção e é liberada passando no nível que dá esse doce (a panela de
##   brigadeiro já vem liberada).
## - Na cozinha, o jogador pega os doces das bandejas (até CARREGAR por vez),
##   leva ao balcão e os clientes pagam em moedas. No painel simples, vende a
##   bandeja direto.
## - Construir e melhorar custa moedas: cada melhoria deixa a máquina mais
##   rápida, a bandeja maior e o doce mais valioso. Os níveis vão até
##   NIVEL_MAXIMO (depois do 3, por conta: ver _nivel_alto), com o preço subindo.
## - MELHORIAS fixas da loja (cada uma num círculo da cozinha, preço subindo a
##   cada nível): VITRINE DE OURO (mais moedas por doce), LIVRO DE RECEITAS
##   (menos açúcar por doce), LETREIRO (clientes chegam mais rápido) e MESAS
##   (clientes atendidos sentam e deixam gorjeta na mesa).
## - ESTÁGIO da confeitaria (1 SIMPLES a 5 DE LUXO): sobe com os níveis das
##   máquinas e das melhorias, e muda a cara da loja (cozinha e prédio na vila).
## - Com o jogo fechado, as máquinas continuam, mas só por até LIMITE_FORA
##   segundos (para as moedas não crescerem sem jogar o quiz).
##
## O estado fica em Progresso.confeitaria (ver padrao()).

const ACUCAR_POR_ACERTO := 15
const LIMITE_FORA := 2 * 60 * 60.0  # segundos de produção contados de uma vez
## Presente de inauguração: açúcar ao construir a primeira máquina.
const ACUCAR_PRESENTE := 50

## Máquinas, na ordem da cozinha. Listas por nível (1, 2 e 3):
## "tempo" = segundos por doce; "valor" = moedas por doce; "bandeja" = quantos
## doces cabem nela; "melhoria" = preço para ir ao próximo nível.
const MAQUINAS := [
	{"id": "brigadeiro", "nome": "PANELA DE BRIGADEIRO", "doce": "brigadeiro",
		"construir": 0, "acucar": 5, "tempo": [6.0, 4.5, 3.0], "valor": [2, 3, 4],
		"bandeja": [6, 10, 15], "melhoria": [100, 250]},
	{"id": "maca", "nome": "TACHO DE MAÇÃ DO AMOR", "doce": "maca", "nivel_quiz": 0,
		"construir": 150, "acucar": 8, "tempo": [9.0, 7.0, 5.0], "valor": [4, 6, 8],
		"bandeja": [6, 10, 15], "melhoria": [200, 400]},
	{"id": "cupcake", "nome": "FORNO DE CUPCAKE", "doce": "cupcake", "nivel_quiz": 1,
		"construir": 300, "acucar": 12, "tempo": [12.0, 9.0, 6.5], "valor": [7, 10, 13],
		"bandeja": [6, 10, 15], "melhoria": [300, 600]},
]
const NIVEL_MAXIMO := 30
## Depois do nível 3: cada nível multiplica o tempo por FATOR_TEMPO (até
## TEMPO_MINIMO do tempo do nível 3), soma 2 doces na bandeja (até BANDEJA_MAXIMA)
## e ~25% do valor do nível 3; o preço sobe AUMENTO_PRECO a cada nível.
const FATOR_TEMPO := 0.94
const TEMPO_MINIMO := 0.4
const BANDEJA_MAXIMA := 40
const AUMENTO_PRECO := 1.45
## Melhorias fixas da loja: preço do 1º nível (sobe PRECO_MELHORIAS a cada nível) e o máximo.
const MELHORIAS := [
	{"id": "vitrine", "nome": "VITRINE DE OURO", "efeito": "+12% DE MOEDAS POR DOCE", "preco": 200, "maximo": 20},
	{"id": "receita", "nome": "LIVRO DE RECEITAS", "efeito": "-10% DE AÇÚCAR POR DOCE", "preco": 250, "maximo": 7},
	{"id": "letreiro", "nome": "LETREIRO", "efeito": "CLIENTES CHEGAM MAIS RÁPIDO", "preco": 180, "maximo": 10},
	{"id": "mesas", "nome": "MESA COM GORJETA", "efeito": "+1 MESA: O CLIENTE SENTA E DEIXA GORJETA", "preco": 300, "maximo": 4},
]
const PRECO_MELHORIAS := 1.6
const BONUS_VITRINE := 0.12
const ECONOMIA_RECEITA := 0.1
const ACUCAR_MINIMO := 0.3  # o livro de receitas não baixa de 30% do açúcar
const RITMO_LETREIRO := 0.88  # intervalo entre clientes multiplicado a cada nível
const INTERVALO_CLIENTES := Vector2(4.0, 7.0)
## Estágios da confeitaria: pontos = níveis das máquinas + níveis das melhorias
## (os 3 primeiros batem com os de antes das melhorias: quem já tinha tudo no
## nível 3 continua ELEGANTE).
const ESTAGIOS := [
	{"nome": "SIMPLES", "pontos": 0}, {"nome": "CHARMOSA", "pontos": 3}, {"nome": "ELEGANTE", "pontos": 6},
	{"nome": "PREMIUM", "pontos": 15}, {"nome": "DE LUXO", "pontos": 28},
]
## Quantos doces o jogador carrega de uma vez, e o preço de cada aumento.
const CARREGAR := [4, 8, 12]
const PRECO_CARREGAR := [120, 300]
## Gorjeta de cada cliente atendido (além do valor dos doces).
const GORJETA := 2
## Açúcar de presente para quem começa: dá para experimentar os minigames
## antes de jogar o quiz. Quem já jogava ganha
## o mesmo presente uma vez (ver Progresso.carregar).
const ACUCAR_INICIAL := 100


static func padrao() -> Dictionary:
	return {
		"acucar": ACUCAR_INICIAL, "acucar_ganho": 0, "presente_inicial": true, "maquinas": {}, "carregar_nivel": 0,
		"atualizado": 0.0, "feitos": 0, "atendidos": 0, "presente": false, "melhorias": {}, "gorjetas": 0,
	}


static func _estado() -> Dictionary:
	return Progresso.confeitaria


static func maquina(id: String) -> Dictionary:
	for m in MAQUINAS:
		if m["id"] == id:
			return m
	return {}


# --- Consultas ---------------------------------------------------------------

## Se o jogador já pode construir a máquina (passou no nível que dá o doce).
static func liberada(id: String) -> bool:
	var m := maquina(id)
	return not m.has("nivel_quiz") or Progresso.niveis[m["nivel_quiz"]]["aprovado"]


static func construida(id: String) -> bool:
	return _estado()["maquinas"].has(id)


static func alguma_construida() -> bool:
	return not _estado()["maquinas"].is_empty()


## Nível da máquina (0 = não construída).
static func nivel(id: String) -> int:
	return int(_estado()["maquinas"].get(id, {}).get("nivel", 0))


static func _do_nivel(id: String, chave: String) -> Variant:
	return maquina(id)[chave][mini(maxi(nivel(id), 1), 3) - 1]


## Quantos níveis acima do 3 (os da tabela) a máquina está.
static func _nivel_alto(id: String) -> int:
	return maxi(0, nivel(id) - 3)


static func tempo(id: String) -> float:
	return float(_do_nivel(id, "tempo")) * maxf(TEMPO_MINIMO, pow(FATOR_TEMPO, _nivel_alto(id)))


## Moedas por doce (com a vitrine).
static func valor(id: String) -> int:
	var base: int = _do_nivel(id, "valor")
	base += _nivel_alto(id) * maxi(1, roundi(base / 4.0))
	return roundi(base * (1.0 + BONUS_VITRINE * nivel_melhoria("vitrine")))


static func capacidade_bandeja(id: String) -> int:
	return mini(BANDEJA_MAXIMA, int(_do_nivel(id, "bandeja")) + 2 * _nivel_alto(id))


## Açúcar gasto por doce da máquina (com o livro de receitas).
static func acucar_por_doce(id: String) -> int:
	var base: int = maquina(id)["acucar"]
	return maxi(1, roundi(base * maxf(ACUCAR_MINIMO, 1.0 - ECONOMIA_RECEITA * nivel_melhoria("receita"))))


## Doces prontos na bandeja da máquina.
static func bandeja(id: String) -> int:
	return int(_estado()["maquinas"].get(id, {}).get("bandeja", 0))


## Quanto falta para o próximo doce da máquina (0 a 1).
static func andamento(id: String) -> float:
	if not construida(id):
		return 0.0
	return clampf(float(_estado()["maquinas"][id]["progresso"]) / tempo(id), 0.0, 1.0)


## Preço para construir (se não construída) ou melhorar; -1 = já no máximo.
static func preco(id: String) -> int:
	var n := nivel(id)
	if n == 0:
		return maquina(id)["construir"]
	if n >= NIVEL_MAXIMO:
		return -1
	var tabela: Array = maquina(id)["melhoria"]
	if n - 1 < tabela.size():
		return tabela[n - 1]
	return snappedi(roundi(float(tabela[tabela.size() - 1]) * pow(AUMENTO_PRECO, n - tabela.size())), 10)


static func acucar() -> int:
	return int(_estado()["acucar"])


static func carregar() -> int:
	return CARREGAR[int(_estado()["carregar_nivel"])]


static func preco_carregar() -> int:
	var n := int(_estado()["carregar_nivel"])
	return PRECO_CARREGAR[n] if n < PRECO_CARREGAR.size() else -1


## Por que a máquina está parada ("" = funcionando).
static func parada(id: String) -> String:
	if not construida(id):
		return ""
	if bandeja(id) >= capacidade_bandeja(id):
		return "BANDEJA CHEIA"
	if acucar() < acucar_por_doce(id):
		return "SEM AÇÚCAR"
	return ""


## Máquina que faz o doce ("" se nenhuma).
static func maquina_do_doce(doce: String) -> String:
	for m in MAQUINAS:
		if m["doce"] == doce:
			return m["id"]
	return ""


# --- Melhorias fixas e estágio --------------------------------------------------------

static func melhoria(id: String) -> Dictionary:
	for m in MELHORIAS:
		if m["id"] == id:
			return m
	return {}


static func nivel_melhoria(id: String) -> int:
	return int(_estado().get("melhorias", {}).get(id, 0))


## Preço do próximo nível da melhoria (-1 = no máximo).
static func preco_melhoria(id: String) -> int:
	var m := melhoria(id)
	var n := nivel_melhoria(id)
	if m.is_empty() or n >= int(m["maximo"]):
		return -1
	return snappedi(roundi(float(m["preco"]) * pow(PRECO_MELHORIAS, n)), 10)


static func comprar_melhoria(id: String) -> bool:
	var custo := preco_melhoria(id)
	if custo < 0 or Progresso.moedas < custo:
		return false
	atualizar()
	var e := _estado()
	if not e.has("melhorias"):
		e["melhorias"] = {}
	e["melhorias"][id] = nivel_melhoria(id) + 1
	Progresso.gastar_moedas(custo)  # também salva
	return true


## Segundos entre um cliente e outro (com o letreiro).
static func intervalo_clientes() -> Vector2:
	return INTERVALO_CLIENTES * pow(RITMO_LETREIRO, nivel_melhoria("letreiro"))


static func mesas() -> int:
	return nivel_melhoria("mesas")


## Gorjeta que um cliente deixa na mesa (cresce com o estágio e a vitrine).
static func gorjeta_mesa() -> int:
	return roundi((3 + 2 * estagio()) * (1.0 + BONUS_VITRINE * nivel_melhoria("vitrine")))


static func pontos_estagio() -> int:
	var pontos := 0
	for m in MAQUINAS:
		pontos += nivel(m["id"])
	for m in MELHORIAS:
		pontos += nivel_melhoria(m["id"])
	return pontos


## Estágio da confeitaria (1 a ESTAGIOS.size()).
static func estagio() -> int:
	var pontos := pontos_estagio()
	var atual := 1
	for i in ESTAGIOS.size():
		if pontos >= int(ESTAGIOS[i]["pontos"]):
			atual = i + 1
	return atual


static func nome_estagio(n := -1) -> String:
	return ESTAGIOS[clampi(n if n > 0 else estagio(), 1, ESTAGIOS.size()) - 1]["nome"]


## Pontos que faltam para o próximo estágio (0 = já no último).
static func falta_proximo_estagio() -> int:
	var n := estagio()
	if n >= ESTAGIOS.size():
		return 0
	return int(ESTAGIOS[n]["pontos"]) - pontos_estagio()


## Gorjeta deixada numa mesa: vai direto para as moedas quando o jogador pega.
static func receber_gorjeta(moedas: int) -> void:
	if moedas <= 0:
		return
	_estado()["gorjetas"] = int(_estado().get("gorjetas", 0)) + moedas
	Progresso.ganhar_moedas(moedas)


# --- Ações -------------------------------------------------------------------

## Açúcar ganho no quiz (chamado ao terminar uma partida).
static func ganhar_acucar(quantidade: int) -> void:
	if quantidade <= 0:
		return
	var e := _estado()
	atualizar()  # o que já estava sendo feito conta com o açúcar de antes
	e["acucar"] = int(e["acucar"]) + quantidade
	e["acucar_ganho"] = int(e["acucar_ganho"]) + quantidade
	Progresso.salvar()


## Constrói (nível 0 -> 1) ou melhora a máquina, pagando as moedas. Falso se
## não está liberada, já está no máximo ou faltam moedas. A primeira máquina
## vem com um presente de açúcar.
static func construir_ou_melhorar(id: String) -> bool:
	var custo := preco(id)
	if maquina(id).is_empty() or not liberada(id) or custo < 0 or Progresso.moedas < custo:
		return false
	atualizar()
	var e := _estado()
	if construida(id):
		e["maquinas"][id]["nivel"] = nivel(id) + 1
	else:
		e["maquinas"][id] = {"nivel": 1, "progresso": 0.0, "bandeja": 0}
		if not e["presente"]:
			e["presente"] = true
			e["acucar"] = int(e["acucar"]) + ACUCAR_PRESENTE
	if custo > 0:
		Progresso.gastar_moedas(custo)  # também salva
	else:
		Progresso.salvar()
	return true


## Gasta açúcar em outra coisa (ex.: uma partida do Doce Match).
static func gastar_acucar(quantidade: int) -> bool:
	if acucar() < quantidade:
		return false
	atualizar()
	_estado()["acucar"] = acucar() - quantidade
	Progresso.salvar()
	return true


static func aumentar_carregar() -> bool:
	var custo := preco_carregar()
	if custo < 0 or Progresso.moedas < custo:
		return false
	_estado()["carregar_nivel"] = int(_estado()["carregar_nivel"]) + 1
	Progresso.gastar_moedas(custo)
	return true


## Tira até `quantos` doces da bandeja. Retorna quantos tirou.
static func pegar(id: String, quantos := 1) -> int:
	var tirados := mini(quantos, bandeja(id))
	if tirados > 0:
		_estado()["maquinas"][id]["bandeja"] = bandeja(id) - tirados
	return tirados


## Quanto um cliente paga por `quantos` doces (valor da máquina + gorjeta), e
## conta o atendimento. Não dá as moedas: elas ficam no caixa até o jogador
## pegar (ver receber()).
static func cobrar(doce: String, quantos: int) -> int:
	_estado()["atendidos"] = int(_estado()["atendidos"]) + 1
	Missoes.registrar("clientes", 1)
	Experiencia.ganhar(Experiencia.XP_CLIENTE)
	return quantos * valor(maquina_do_doce(doce)) + GORJETA + int(Companheiros.bonus("cozinha"))


## Vende a bandeja inteira de uma vez (painel simples). Retorna as moedas.
static func vender_bandeja(id: String) -> int:
	var quantos := pegar(id, bandeja(id))
	if quantos == 0:
		return 0
	var ganho := quantos * valor(id)
	Missoes.registrar("clientes", 1)
	Progresso.ganhar_moedas(ganho)  # também salva
	return ganho


static func receber(moedas: int) -> void:
	if moedas > 0:
		Progresso.ganhar_moedas(moedas)


## Faz as máquinas trabalharem pelo tempo que passou desde a última vez (no
## máximo LIMITE_FORA). `agora` em segundos (Unix); -1 = relógio do sistema.
## Retorna quantos doces ficaram prontos.
static func atualizar(agora := -1.0) -> int:
	var e := _estado()
	if agora < 0.0:
		agora = Time.get_unix_time_from_system()
	var ultimo := float(e["atualizado"])
	e["atualizado"] = agora
	if ultimo <= 0.0 or e["maquinas"].is_empty():
		return 0
	var passou := clampf(agora - ultimo, 0.0, LIMITE_FORA)
	var prontos := 0
	for m in MAQUINAS:
		var id: String = m["id"]
		if not construida(id):
			continue
		var dados: Dictionary = e["maquinas"][id]
		var t := tempo(id)
		dados["progresso"] = float(dados["progresso"]) + passou
		while float(dados["progresso"]) >= t:
			var gasto := acucar_por_doce(id)
			if bandeja(id) >= capacidade_bandeja(id) or int(e["acucar"]) < gasto:
				dados["progresso"] = t  # parada, com o próximo doce "quase pronto"
				break
			dados["progresso"] = float(dados["progresso"]) - t
			e["acucar"] = int(e["acucar"]) - gasto
			dados["bandeja"] = bandeja(id) + 1
			e["feitos"] = int(e["feitos"]) + 1
			prontos += 1
	return prontos
