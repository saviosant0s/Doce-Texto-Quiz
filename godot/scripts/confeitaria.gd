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
##   rápida, a bandeja maior e o doce mais valioso.
## - Com o jogo fechado, as máquinas continuam, mas só por até LIMITE_FORA
##   segundos (para as moedas não crescerem sem jogar o quiz).
##
## O estado fica em Progresso.confeitaria (ver padrao()).

const ACUCAR_POR_ACERTO := 10
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
const NIVEL_MAXIMO := 3
## Quantos doces o jogador carrega de uma vez, e o preço de cada aumento.
const CARREGAR := [4, 8, 12]
const PRECO_CARREGAR := [120, 300]
## Gorjeta de cada cliente atendido (além do valor dos doces).
const GORJETA := 2


static func padrao() -> Dictionary:
	return {
		"acucar": 0, "acucar_ganho": 0, "maquinas": {}, "carregar_nivel": 0,
		"atualizado": 0.0, "feitos": 0, "atendidos": 0, "presente": false,
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
	return maquina(id)[chave][maxi(nivel(id), 1) - 1]


static func tempo(id: String) -> float:
	return _do_nivel(id, "tempo")


static func valor(id: String) -> int:
	return _do_nivel(id, "valor")


static func capacidade_bandeja(id: String) -> int:
	return _do_nivel(id, "bandeja")


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
	return maquina(id)["melhoria"][n - 1] if n < NIVEL_MAXIMO else -1


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
	if acucar() < maquina(id)["acucar"]:
		return "SEM AÇÚCAR"
	return ""


## Máquina que faz o doce ("" se nenhuma).
static func maquina_do_doce(doce: String) -> String:
	for m in MAQUINAS:
		if m["doce"] == doce:
			return m["id"]
	return ""


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
	return quantos * valor(maquina_do_doce(doce)) + GORJETA


## Vende a bandeja inteira de uma vez (painel simples). Retorna as moedas.
static func vender_bandeja(id: String) -> int:
	var quantos := pegar(id, bandeja(id))
	if quantos == 0:
		return 0
	var ganho := quantos * valor(id)
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
			if bandeja(id) >= capacidade_bandeja(id) or int(e["acucar"]) < m["acucar"]:
				dados["progresso"] = t  # parada, com o próximo doce "quase pronto"
				break
			dados["progresso"] = float(dados["progresso"]) - t
			e["acucar"] = int(e["acucar"]) - m["acucar"]
			dados["bandeja"] = bandeja(id) + 1
			e["feitos"] = int(e["feitos"]) + 1
			prontos += 1
	return prontos
