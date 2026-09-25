class_name Terrenos
## Terrenos da Vila dos Doces: o Bairro dos Terrenos (atrás da Escola) tem
## lotes à venda. Comprado o lote, o jogador escolhe o que construir:
##   MOINHO DE AÇÚCAR e COFRE DE MOEDAS produzem com o tempo (até encher);
##   é só passar lá e coletar. Sobem de nível (produzem mais e guardam mais).
##   CASA DE DOCE traz um vizinho novo passeando; JARDIM e FONTE enfeitam.
## Longe da praça ficam o LAGO DE CHOCOLATE e o MIRANTE DO SORVETE, cada um
## com um presente por dia para quem anda até lá.
##
## Estado em Progresso.vila = {"lotes": {id: {"construcao", "nivel", "desde"}},
## "presentes": {lugar: "AAAA-MM-DD"}}.

## "aberto": lado do lote virado para a rua (a construção olha para lá).
const LOTES := [
	{"id": "lote_1", "posicao": Vector3(-5, 0, -25), "aberto": Vector3(0, 0, 1), "preco": 100},
	{"id": "lote_2", "posicao": Vector3(5, 0, -25), "aberto": Vector3(0, 0, 1), "preco": 200},
	{"id": "lote_3", "posicao": Vector3(-15, 0, -25), "aberto": Vector3(0, 0, 1), "preco": 350},
	{"id": "lote_4", "posicao": Vector3(15, 0, -25), "aberto": Vector3(0, 0, 1), "preco": 500},
	{"id": "lote_5", "posicao": Vector3(-5, 0, -32.5), "aberto": Vector3(1, 0, 0), "preco": 700},
	{"id": "lote_6", "posicao": Vector3(5, 0, -32.5), "aberto": Vector3(-1, 0, 0), "preco": 900},
]
const TAMANHO_LOTE := 6.0

## "por_hora" e "maximo" por nível (1 a 3); "melhoria" = moedas para ir ao próximo.
const CONSTRUCOES := {
	"moinho": {"nome": "MOINHO DE AÇÚCAR", "preco": 80, "produz": "acucar",
		"por_hora": [6, 10, 15], "maximo": [30, 50, 80], "melhoria": [150, 300],
		"texto": "Faz açúcar sozinho, até encher."},
	"cofre": {"nome": "COFRE DE MOEDAS", "preco": 150, "produz": "moedas",
		"por_hora": [4, 7, 11], "maximo": [20, 35, 55], "melhoria": [250, 450],
		"texto": "Junta moedas sozinho, até encher."},
	"casa": {"nome": "CASA DE DOCE", "preco": 120, "texto": "Um vizinho novo passeia pela vila."},
	"jardim": {"nome": "JARDIM DE PIRULITOS", "preco": 60, "texto": "Árvores de pirulito e flores."},
	"fonte": {"nome": "FONTE DE MORANGO", "preco": 100, "texto": "Uma fonte de calda de morango."},
}
const NIVEL_MAXIMO := 3

## Lugares longe da praça, com um presente por dia.
const LUGARES := {
	"lago": {"nome": "LAGO DE CHOCOLATE", "posicao": Vector3(-30, 0, 12)},
	"mirante": {"nome": "MIRANTE DO SORVETE", "posicao": Vector3(30, 0, 12)},
}
const PRESENTE := {"acucar": 20, "moedas": 15}

## Para os testes: hora fixa (segundos Unix) e dia fixo ("" = de verdade).
static var agora_fixo := -1.0
static var dia_fixo := ""


static func padrao() -> Dictionary:
	return {"lotes": {}, "presentes": {}}


static func _estado() -> Dictionary:
	if not Progresso.vila.has("lotes"):
		Progresso.vila["lotes"] = {}
	if not Progresso.vila.has("presentes"):
		Progresso.vila["presentes"] = {}
	return Progresso.vila


static func agora() -> float:
	return agora_fixo if agora_fixo >= 0.0 else Time.get_unix_time_from_system()


static func hoje() -> String:
	return dia_fixo if not dia_fixo.is_empty() else Time.get_date_string_from_system()


static func lote(id: String) -> Dictionary:
	for l in LOTES:
		if l["id"] == id:
			return l
	return {}


static func comprado(id: String) -> bool:
	return _estado()["lotes"].has(id)


static func construcao(id: String) -> String:
	return str(_estado()["lotes"].get(id, {}).get("construcao", ""))


static func nivel(id: String) -> int:
	return int(_estado()["lotes"].get(id, {}).get("nivel", 0))


static func quantos_comprados() -> int:
	return _estado()["lotes"].size()


## Compra o lote (qualquer um, se tiver moedas). Retorna falso se já tem ou
## se faltam moedas.
static func comprar(id: String) -> bool:
	var l := lote(id)
	if l.is_empty() or comprado(id) or Progresso.moedas < int(l["preco"]):
		return false
	_estado()["lotes"][id] = {"construcao": "", "nivel": 0, "desde": agora()}
	Progresso.gastar_moedas(int(l["preco"]))  # também salva
	return true


static func construir(id: String, tipo: String) -> bool:
	if not comprado(id) or construcao(id) != "" or not CONSTRUCOES.has(tipo):
		return false
	var preco := int(CONSTRUCOES[tipo]["preco"])
	if Progresso.moedas < preco:
		return false
	_estado()["lotes"][id] = {"construcao": tipo, "nivel": 1, "desde": agora()}
	Progresso.gastar_moedas(preco)
	return true


static func produz(id: String) -> String:
	return str(CONSTRUCOES.get(construcao(id), {}).get("produz", ""))


static func _do_nivel(id: String, chave: String) -> int:
	var dados: Dictionary = CONSTRUCOES.get(construcao(id), {})
	if not dados.has(chave):
		return 0
	return int(dados[chave][clampi(nivel(id), 1, NIVEL_MAXIMO) - 1])


static func por_hora(id: String) -> int:
	return _do_nivel(id, "por_hora")


static func maximo(id: String) -> int:
	return _do_nivel(id, "maximo")


## Quanto já está pronto para coletar (até o máximo).
static func pronto(id: String) -> int:
	if produz(id).is_empty():
		return 0
	var desde := float(_estado()["lotes"][id].get("desde", agora()))
	var horas := maxf(0.0, agora() - desde) / 3600.0
	return mini(maximo(id), int(horas * por_hora(id)))


## Coleta o que está pronto (açúcar ou moedas). Retorna quanto coletou.
static func coletar(id: String) -> int:
	var quanto := pronto(id)
	if quanto <= 0:
		return 0
	# guarda o "resto" da hora quebrada, a não ser que tenha enchido
	var desde := float(_estado()["lotes"][id]["desde"])
	var usado := quanto * 3600.0 / maxf(1.0, por_hora(id))
	_estado()["lotes"][id]["desde"] = agora() if quanto >= maximo(id) else desde + usado
	if produz(id) == "acucar":
		Confeitaria.ganhar_acucar(quanto)
	else:
		Progresso.ganhar_moedas(quanto)
	Progresso.salvar()
	return quanto


static func preco_melhoria(id: String) -> int:
	var dados: Dictionary = CONSTRUCOES.get(construcao(id), {})
	var n := nivel(id)
	if not dados.has("melhoria") or n < 1 or n >= NIVEL_MAXIMO:
		return -1
	return int(dados["melhoria"][n - 1])


static func melhorar(id: String) -> bool:
	var preco := preco_melhoria(id)
	if preco < 0 or Progresso.moedas < preco:
		return false
	coletar(id)  # o que estava pronto não se perde
	_estado()["lotes"][id]["nivel"] = nivel(id) + 1
	Progresso.gastar_moedas(preco)
	return true


# --- Presentes dos lugares longe -------------------------------------------------

static func presente_disponivel(lugar: String) -> bool:
	return LUGARES.has(lugar) and str(_estado()["presentes"].get(lugar, "")) != hoje()


## Abre o presente do dia do lugar. Retorna {"acucar", "moedas"} ou {}.
static func abrir_presente(lugar: String) -> Dictionary:
	if not presente_disponivel(lugar):
		return {}
	_estado()["presentes"][lugar] = hoje()
	Confeitaria.ganhar_acucar(PRESENTE["acucar"])
	Progresso.ganhar_moedas(PRESENTE["moedas"])  # também salva
	return PRESENTE.duplicate()


## Estágio da Confeitaria por fora (cresce com as máquinas): 1 = só o
## cupcake, 2 = + terraço com mesinhas, 3 = + a segunda torre.
static func estagio_confeitaria() -> int:
	var soma := 0
	for m in Confeitaria.MAQUINAS:
		soma += Confeitaria.nivel(m["id"])
	return 1 if soma <= 2 else (2 if soma <= 5 else 3)
