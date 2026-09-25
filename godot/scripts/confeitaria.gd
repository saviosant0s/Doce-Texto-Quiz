class_name Confeitaria
## Minha Confeitaria: minijogo de fábrica de doces, ligado ao quiz.
##
## - Cada acerto no quiz dá AÇÚCAR_POR_ACERTO de açúcar (o ingrediente).
## - As máquinas transformam açúcar em doces, sozinhas, com o tempo. Cada
##   máquina faz um doce da coleção e é liberada passando no nível que dá
##   esse doce (a panela de brigadeiro já vem liberada).
## - Construir e melhorar máquinas custa moedas; cada melhoria deixa a
##   máquina mais rápida e o doce mais valioso.
## - Os doces vão para o estoque (com limite, que dá para ampliar). Dá para
##   vender o estoque por moedas ou entregar encomendas dos moradores da vila,
##   que pagam mais.
## - Com o jogo fechado, as máquinas continuam, mas só por até LIMITE_FORA
##   segundos (para as moedas não crescerem sem jogar o quiz).
##
## O estado fica em Progresso.confeitaria (ver padrao()).

const ACUCAR_POR_ACERTO := 10
const LIMITE_FORA := 2 * 60 * 60.0  # segundos de produção contados de uma vez
const ENCOMENDAS_ABERTAS := 2

## Máquinas, na ordem da tela. Listas por nível (1, 2 e 3):
## "tempo" = segundos por doce; "valor" = moedas ao vender cada doce;
## "melhoria" = preço para ir ao próximo nível.
const MAQUINAS := [
	{"id": "brigadeiro", "nome": "PANELA DE BRIGADEIRO", "doce": "brigadeiro",
		"construir": 0, "acucar": 5, "tempo": [20.0, 14.0, 9.0], "valor": [2, 3, 4],
		"melhoria": [100, 250]},
	{"id": "maca", "nome": "TACHO DE MAÇÃ DO AMOR", "doce": "maca", "nivel_quiz": 0,
		"construir": 150, "acucar": 8, "tempo": [30.0, 21.0, 14.0], "valor": [4, 6, 8],
		"melhoria": [200, 400]},
	{"id": "cupcake", "nome": "FORNO DE CUPCAKE", "doce": "cupcake", "nivel_quiz": 1,
		"construir": 300, "acucar": 12, "tempo": [45.0, 32.0, 22.0], "valor": [7, 10, 13],
		"melhoria": [300, 600]},
]
const NIVEL_MAXIMO := 3
## Quantos doces cabem no estoque em cada tamanho, e o preço para ampliar.
const ESTOQUE := [30, 60, 120]
const PRECO_AMPLIAR := [150, 400]
## Moradores que fazem encomendas (nomes como em Personagens.textura).
const CLIENTES := [
	{"id": "bala_verde", "nome": "BALA VERDE"},
	{"id": "milho_doce", "nome": "MILHO DOCE"},
	{"id": "fantasma", "nome": "FANTASMA"},
]


static func padrao() -> Dictionary:
	return {
		"acucar": 0, "acucar_ganho": 0, "estoque_nivel": 0, "maquinas": {}, "estoque": {},
		"encomendas": [], "atualizado": 0.0, "feitos": 0, "entregues": 0,
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


## Nível da máquina (0 = não construída).
static func nivel(id: String) -> int:
	return int(_estado()["maquinas"].get(id, {}).get("nivel", 0))


static func tempo(id: String) -> float:
	return maquina(id)["tempo"][maxi(nivel(id), 1) - 1]


static func valor(id: String) -> int:
	return maquina(id)["valor"][maxi(nivel(id), 1) - 1]


## Quanto falta para o próximo doce da máquina (0 a 1).
static func andamento(id: String) -> float:
	if not construida(id):
		return 0.0
	return clampf(float(_estado()["maquinas"][id]["progresso"]) / tempo(id), 0.0, 1.0)


static func preco_melhoria(id: String) -> int:
	var n := nivel(id)
	return maquina(id)["melhoria"][n - 1] if n >= 1 and n < NIVEL_MAXIMO else -1


static func acucar() -> int:
	return int(_estado()["acucar"])


static func estoque(doce: String) -> int:
	return int(_estado()["estoque"].get(doce, 0))


static func estoque_total() -> int:
	var total := 0
	for doce in _estado()["estoque"]:
		total += int(_estado()["estoque"][doce])
	return total


static func capacidade() -> int:
	return ESTOQUE[int(_estado()["estoque_nivel"])]


static func preco_ampliar() -> int:
	var n := int(_estado()["estoque_nivel"])
	return PRECO_AMPLIAR[n] if n < PRECO_AMPLIAR.size() else -1


## Por que a máquina está parada ("" = funcionando).
static func parada(id: String) -> String:
	if not construida(id):
		return ""
	if estoque_total() >= capacidade():
		return "ESTOQUE CHEIO"
	if acucar() < maquina(id)["acucar"]:
		return "SEM AÇÚCAR"
	return ""


static func encomendas() -> Array:
	return _estado()["encomendas"]


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


## Constrói a máquina (paga as moedas). Falso se não está liberada, já existe
## ou faltam moedas.
static func construir(id: String) -> bool:
	var m := maquina(id)
	if m.is_empty() or not liberada(id) or construida(id) or Progresso.moedas < m["construir"]:
		return false
	atualizar()
	_estado()["maquinas"][id] = {"nivel": 1, "progresso": 0.0}
	_completar_encomendas()
	if m["construir"] > 0:
		Progresso.gastar_moedas(m["construir"])  # também salva
	else:
		Progresso.salvar()
	return true


static func melhorar(id: String) -> bool:
	var preco := preco_melhoria(id)
	if preco < 0 or Progresso.moedas < preco:
		return false
	atualizar()
	_estado()["maquinas"][id]["nivel"] = nivel(id) + 1
	Progresso.gastar_moedas(preco)
	return true


static func ampliar_estoque() -> bool:
	var preco := preco_ampliar()
	if preco < 0 or Progresso.moedas < preco:
		return false
	atualizar()
	_estado()["estoque_nivel"] = int(_estado()["estoque_nivel"]) + 1
	Progresso.gastar_moedas(preco)
	return true


## Vende todo o estoque de um doce. Retorna as moedas ganhas.
static func vender(doce: String) -> int:
	var quantos := estoque(doce)
	if quantos <= 0:
		return 0
	var id := _maquina_do_doce(doce)
	var ganho := quantos * valor(id)
	_estado()["estoque"][doce] = 0
	Progresso.ganhar_moedas(ganho)  # também salva
	return ganho


## Entrega a encomenda `indice` (se houver doces). Retorna as moedas ganhas
## (0 = não deu) e abre uma encomenda nova no lugar.
static func entregar(indice: int) -> int:
	var lista := encomendas()
	if indice < 0 or indice >= lista.size():
		return 0
	var pedido: Dictionary = lista[indice]
	if estoque(pedido["doce"]) < int(pedido["quantidade"]):
		return 0
	_estado()["estoque"][pedido["doce"]] = estoque(pedido["doce"]) - int(pedido["quantidade"])
	lista.remove_at(indice)
	_estado()["entregues"] = int(_estado()["entregues"]) + 1
	_completar_encomendas()
	Progresso.ganhar_moedas(int(pedido["recompensa"]))
	return int(pedido["recompensa"])


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
			if estoque_total() >= capacidade() or int(e["acucar"]) < m["acucar"]:
				dados["progresso"] = t  # parada, com o próximo doce "quase pronto"
				break
			dados["progresso"] = float(dados["progresso"]) - t
			e["acucar"] = int(e["acucar"]) - m["acucar"]
			e["estoque"][m["doce"]] = estoque(m["doce"]) + 1
			e["feitos"] = int(e["feitos"]) + 1
			prontos += 1
	return prontos


static func _maquina_do_doce(doce: String) -> String:
	for m in MAQUINAS:
		if m["doce"] == doce:
			return m["id"]
	return ""


## Abre encomendas até ENCOMENDAS_ABERTAS, só de doces que alguma máquina
## construída faz. Quantidade e recompensa crescem com as entregas.
static func _completar_encomendas() -> void:
	var e := _estado()
	var feitas := []
	for m in MAQUINAS:
		if construida(m["id"]):
			feitas.append(m)
	if feitas.is_empty():
		return
	var entregues := int(e["entregues"])
	while e["encomendas"].size() < ENCOMENDAS_ABERTAS:
		var numero: int = entregues + e["encomendas"].size()
		# alterna os doces e os clientes, sem sorteio (fica igual em todo aparelho)
		var m: Dictionary = feitas[(numero * 2 + 1) % feitas.size()] if numero > 0 else feitas[0]
		var cliente: Dictionary = CLIENTES[numero % CLIENTES.size()]
		var quantidade: int = 5 + (numero % 4) * 2 + mini(entregues, 10)
		e["encomendas"].append({
			"cliente": cliente["id"], "nome": cliente["nome"], "doce": m["doce"],
			"quantidade": quantidade,
			# paga como vender com a máquina no nível máximo, mais um agrado
			"recompensa": quantidade * m["valor"][NIVEL_MAXIMO - 1] + 10,
		})
