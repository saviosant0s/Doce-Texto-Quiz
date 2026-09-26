class_name Terrenos
## Terrenos da Vila dos Doces: o Bairro dos Terrenos (atrás da Escola) tem
## lotes à venda. Comprado o lote, o jogador escolhe o que construir:
##   MOINHO DE AÇÚCAR e COFRE DE MOEDAS produzem com o tempo (até encher);
##   é só passar lá e coletar. Sobem de nível (produzem mais e guardam mais).
##   CASA DE DOCE traz um vizinho novo passeando; JARDIM e FONTE enfeitam.
## EVOLUÇÃO: toda construção sobe até o nível 5 e muda de forma a cada nível.
## Melhorar leva tempo de verdade (a obra, com andaime); só um construtor, uma
## obra por vez; dá para terminar na hora pagando açúcar. Casa, jardim e
## fonte deixam a vila bonita: cada nível deles é +BONUS_BELEZA de produção
## no moinho e no cofre.
## Longe da praça ficam o LAGO DE CHOCOLATE e o MIRANTE DO SORVETE, cada um
## com um presente por dia para quem anda até lá.
##
## Estado em Progresso.vila = {"lotes": {id: {"construcao", "nivel", "desde"
## [, "obra_ate": fim da obra (segundos Unix)]}},
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

## "por_hora" e "maximo" por nível (1 a 5); "melhoria" = moedas para ir ao
## próximo; "niveis" = o que muda na cara da construção a cada nível.
const CONSTRUCOES := {
	"moinho": {"nome": "MOINHO DE AÇÚCAR", "preco": 80, "produz": "acucar",
		"por_hora": [6, 10, 15, 21, 28], "maximo": [30, 50, 80, 120, 170], "melhoria": [150, 300, 550, 900],
		"texto": "Faz açúcar sozinho, até encher.",
		"niveis": ["", "bandeirinhas e base de pedra", "galpão de sacos de açúcar", "torre mais alta com janelas", "telhado de ouro e estrela"]},
	"cofre": {"nome": "COFRE DE MOEDAS", "preco": 150, "produz": "moedas",
		"por_hora": [4, 7, 11, 16, 22], "maximo": [20, 35, 55, 85, 120], "melhoria": [250, 450, 750, 1200],
		"texto": "Junta moedas sozinho, até encher.",
		"niveis": ["", "pilha de moedas", "pedestal de pedra", "coroa e mais moedas", "porquinho de ouro"]},
	"casa": {"nome": "CASA DE DOCE", "preco": 120, "melhoria": [100, 220, 400, 700],
		"texto": "Um vizinho novo passeia pela vila.",
		"niveis": ["", "chaminé, cerquinha e floreiras", "segundo andar", "varanda com colunas", "torrezinha com bandeira"]},
	"jardim": {"nome": "JARDIM DE PIRULITOS", "preco": 60, "melhoria": [60, 150, 300, 500],
		"texto": "Árvores de pirulito e flores.",
		"niveis": ["", "mais árvores", "caminho de pedra e bancos", "coreto no meio", "arco de balas e postes de luz"]},
	"fonte": {"nome": "FONTE DE MORANGO", "preco": 100, "melhoria": [90, 200, 380, 650],
		"texto": "Uma fonte de calda de morango.",
		"niveis": ["", "segundo prato", "canteiro de flores em volta", "ursinhos de goma jogando água", "bacia maior, três pratos e ouro"]},
}
const NIVEL_MAXIMO := 5
## Segundos de obra para chegar a cada nível (índice = nível que vai ficar - 2):
## 3 min, 15 min, 1 h e 4 h. Construir (nível 1) é na hora.
const TEMPO_OBRA := [180, 900, 3600, 14400]
## Cada nível de casa, jardim e fonte: +5% na produção do moinho e do cofre.
const BONUS_BELEZA := 0.05
const DECORACOES := ["casa", "jardim", "fonte"]

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
	_conferir_obra(id)
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


## Produção por hora, já com o bônus de beleza da vila.
static func por_hora(id: String) -> int:
	return int(round(_do_nivel(id, "por_hora") * (1.0 + BONUS_BELEZA * beleza())))


## Soma dos níveis de casas, jardins e fontes (obras prontas).
static func beleza() -> int:
	var soma := 0
	for id in _estado()["lotes"]:
		if construcao(id) in DECORACOES:
			soma += nivel(id)
	return soma


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


## Começa a obra do próximo nível (paga as moedas agora). Falso se já está
## no máximo, se faltam moedas ou se o construtor está em outra obra.
static func melhorar(id: String) -> bool:
	var preco := preco_melhoria(id)
	if preco < 0 or Progresso.moedas < preco or not obra_em_andamento().is_empty():
		return false
	coletar(id)  # o que estava pronto não se perde
	_estado()["lotes"][id]["obra_ate"] = agora() + tempo_obra(nivel(id) + 1)
	Progresso.gastar_moedas(preco)
	return true


## Segundos de obra para chegar ao `nivel_novo` (2 a 5).
static func tempo_obra(nivel_novo: int) -> int:
	return int(TEMPO_OBRA[clampi(nivel_novo - 2, 0, TEMPO_OBRA.size() - 1)])


static func em_obra(id: String) -> bool:
	_conferir_obra(id)
	return _estado()["lotes"].get(id, {}).has("obra_ate")


## Segundos que faltam para a obra acabar (0 = sem obra).
static func falta_obra(id: String) -> int:
	if not em_obra(id):
		return 0
	return maxi(1, ceili(float(_estado()["lotes"][id]["obra_ate"]) - agora()))


## Lote com obra agora ("" = o construtor está livre).
static func obra_em_andamento() -> String:
	for id in _estado()["lotes"]:
		if em_obra(id):
			return id
	return ""


## Açúcar para terminar a obra agora: 1 por minuto que falta.
static func preco_acelerar(id: String) -> int:
	return ceili(falta_obra(id) / 60.0) if em_obra(id) else 0


static func acelerar(id: String) -> bool:
	var preco := preco_acelerar(id)
	if preco <= 0 or not Confeitaria.gastar_acucar(preco):
		return false
	_estado()["lotes"][id]["obra_ate"] = agora()
	_conferir_obra(id)
	Progresso.salvar()
	return true


## Se a obra do lote já acabou: sobe o nível. A produção continua de onde
## estava (nada do que já estava pronto se perde).
static func _conferir_obra(id: String) -> void:
	var dados: Dictionary = _estado()["lotes"].get(id, {})
	if not dados.has("obra_ate") or float(dados["obra_ate"]) > agora():
		return
	dados.erase("obra_ate")
	dados["nivel"] = mini(NIVEL_MAXIMO, int(dados.get("nivel", 1)) + 1)
	Progresso.salvar()


## "m:ss" ou "h:mm:ss" (para o relógio da obra).
static func relogio(segundos: int) -> String:
	var h := segundos / 3600
	var m := (segundos % 3600) / 60
	var s := segundos % 60
	return "%d:%02d:%02d" % [h, m, s] if h > 0 else "%d:%02d" % [m, s]


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
