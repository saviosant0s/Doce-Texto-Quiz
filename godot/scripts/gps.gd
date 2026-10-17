class_name GPs
extends RefCounted
## Os GPs da CORRIDA DE DOCES: cada um é uma pista numa cidade de verdade (o
## nome leva a cidade e o estado: "GP DE VALENÇA (BA)"), com o desenho da
## pista, os trechos (ZONAS), os portais do quiz, a água (rio, mar, lago), os
## pontos famosos da cidade (marcos) e o céu. O primeiro é o da Vila dos Doces;
## cada GP seguinte é liberado chegando no pódio (1º a 3º) do anterior, tem
## mais voltas e paga mais (`premio` multiplica o prêmio do lugar).
##
## Todas as pistas largam em (0, 0, 0) indo para -z (a arquibancada fica do
## lado esquerdo da reta; "arquibancada": 1 = do lado direito, nas pistas que
## viram para a esquerda). Pontos: x, altura, z (ver Corrida.montar_curva).
## Os desenhos das cidades se inspiram no mapa de verdade (ver o comentário de cada uma).
##
## Tipos de trecho (o que a tela põe em volta, ver cenas/corrida.gd):
## vila, lago e rio (com ponte), bosque, parque (mata), montanha (de sorvete), praia
## (coqueiros e guarda-sóis), colonial (casarões coloridos), serra (morros,
## pedras e mata) e predios (cidade grande). Marcos: igreja, farol, elevador,
## fabrica, torre, museu, pico.
##
## Recordes e melhores lugares em Progresso.vila["gps"]: {id: {"lugar", "recorde"}}
## (o recorde da Vila também fica em estatisticas.corrida_recorde).

const LISTA := [
	{
		"id": "vila", "nome": "GP DA VILA DOS DOCES", "cidade": "VILA DOS DOCES", "estado": "",
		"voltas": 2, "premio": 1.0, "dificuldade": 0.0, "cor": "#FF6FAE",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -45), Vector3(8, 0, -75), Vector3(32, 0, -90),
			Vector3(60, 1.6, -92), Vector3(95, 1.6, -92), Vector3(122, 0, -84), Vector3(134, 0, -62),
			Vector3(126, 0, -38), Vector3(136, 0, -14), Vector3(126, 0, 10), Vector3(108, 3, 30),
			Vector3(82, 7, 42), Vector3(56, 7, 42), Vector3(32, 3, 38), Vector3(10, 0, 26), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "vila", "nome": "VILA DOS DOCES", "de": 0},
			{"id": "lago", "nome": "LAGO DE MORANGO", "de": 3},
			{"id": "bosque", "nome": "BOSQUE DE PIRULITOS", "de": 6},
			{"id": "montanha", "nome": "MONTANHA DE SORVETE", "de": 10},
			{"id": "vila", "nome": "VILA DOS DOCES", "de": 14},
		],
		"portais": [Vector3(95, 1.6, -92), Vector3(66, 7, 42)],
		"aguas": [{"centro": Vector3(78, 0, -93), "raios": Vector2(34, 19), "cor": "#FF86B8", "margem": "#F6D2A2", "beira": 3.0}],
		"marcos": [],
		"fundo": "sorvete",
		"ceu": ["#6FB8F0", "#FFD9EC"], "nevoa": "#FFE1EE",
		"texto": "2 voltas pela vila, pela ponte do Lago de Morango, pelo Bosque de Pirulitos e pela Montanha de Sorvete.",
	},
	{
		# Valença: a cidade cortada pelo Rio Una (largo, de oeste a leste); a pista
		# cruza o rio pela ponte do centro, sobe pela beira-rio e pela mata do
		# morro, volta pela ponte nova e passa pelo casario do centro.
		"id": "valenca", "nome": "GP DE VALENÇA (BA)", "cidade": "VALENÇA", "estado": "BA",
		"voltas": 3, "premio": 1.6, "dificuldade": 0.05, "cor": "#2FA36B",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -45), Vector3(0, 1.8, -75), Vector3(2, 0, -105),
			Vector3(30, 0, -122), Vector3(65, 0, -114), Vector3(100, 0, -120), Vector3(125, 0, -142),
			Vector3(112, 0, -172), Vector3(140, 0, -195), Vector3(178, 0, -178), Vector3(184, 0, -135),
			Vector3(174, 1.8, -75), Vector3(170, 0, -40), Vector3(162, 0, -2), Vector3(138, 0, 28),
			Vector3(100, 0, 40), Vector3(62, 0, 30), Vector3(32, 0, 44), Vector3(10, 0, 30), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "colonial", "nome": "CENTRO DE VALENÇA", "de": 0},
			{"id": "rio", "nome": "PONTE DO RIO UNA", "de": 1},
			{"id": "praia", "nome": "BEIRA-RIO", "de": 3},
			{"id": "serra", "nome": "MATA ATLÂNTICA", "de": 7},
			{"id": "rio", "nome": "PONTE NOVA", "de": 11},
			{"id": "colonial", "nome": "CASARIO DO CENTRO", "de": 14},
		],
		"portais": [Vector3(0, 1.8, -75), Vector3(140, 0, -195), Vector3(100, 0, 40)],
		"aguas": [{"centro": Vector3(90, 0, -75), "raios": Vector2(160, 13), "cor": "#4E9C93", "margem": "#C9B48A", "beira": 2.5}],
		"marcos": [
			{"tipo": "igreja", "lugar": Vector3(-30, 0, -122), "cor": "#FFFFFF", "detalhe": "#2E9BE8"},
			{"tipo": "fabrica", "lugar": Vector3(70, 0, -152)},
			{"tipo": "igreja", "lugar": Vector3(130, 0, 72), "cor": "#FFF6E0", "detalhe": "#E8364F"},
		],
		"fundo": "morros",
		"ceu": ["#4FA8EC", "#D8F0FF"], "nevoa": "#E3F2F7",
		"texto": "3 voltas: atravesse o Rio Una pelas duas pontes, suba pela mata e passe pelo centro histórico.",
	},
	{
		# Salvador: a península entre a Baía de Todos os Santos (à esquerda) e o
		# mar aberto. Desce a Avenida Sete até a ponta do Farol da Barra, segue a
		# orla cheia de enseadas (Ondina, Rio Vermelho) e volta pelas ladeiras do
		# Pelourinho, perto do Elevador Lacerda.
		"id": "salvador", "nome": "GP DE SALVADOR (BA)", "cidade": "SALVADOR", "estado": "BA",
		"voltas": 3, "premio": 2.2, "dificuldade": 0.1, "cor": "#2E9BE8",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(6, 0, -100), Vector3(28, 0, -128),
			Vector3(60, 0, -148), Vector3(92, 0, -166), Vector3(116, 0, -180), Vector3(138, 0, -168),
			Vector3(136, 0, -138), Vector3(152, 0, -112), Vector3(146, 0, -80), Vector3(166, 0, -54),
			Vector3(162, 0, -22), Vector3(178, 0, 8), Vector3(158, 2, 36), Vector3(124, 4, 42),
			Vector3(98, 6, 26), Vector3(72, 6, 46), Vector3(46, 4, 30), Vector3(24, 2, 42), Vector3(8, 0, 24), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "predios", "nome": "AVENIDA SETE", "de": 0},
			{"id": "praia", "nome": "FAROL DA BARRA", "de": 4},
			{"id": "praia", "nome": "ORLA DE ONDINA", "de": 8},
			{"id": "praia", "nome": "RIO VERMELHO", "de": 11},
			{"id": "colonial", "nome": "PELOURINHO", "de": 14},
		],
		"portais": [Vector3(6, 0, -100), Vector3(152, 0, -112), Vector3(72, 6, 46)],
		"aguas": [
			{"centro": Vector3(-70, 0, -90), "raios": Vector2(50, 140), "cor": "#2F8FC6", "margem": "#F2DDA4", "beira": 6.0},
			{"centro": Vector3(215, 0, -110), "raios": Vector2(48, 150), "cor": "#2F9FD6", "margem": "#F2DDA4", "beira": 16.0},
			{"centro": Vector3(60, 0, -245), "raios": Vector2(170, 52), "cor": "#2F9FD6", "margem": "#F2DDA4", "beira": 16.0},
		],
		"marcos": [
			{"tipo": "farol", "lugar": Vector3(124, 0, -205)},
			{"tipo": "elevador", "lugar": Vector3(-28, 0, 42)},
			{"tipo": "igreja", "lugar": Vector3(110, 0, 80), "cor": "#3E7FD0", "detalhe": "#FFFFFF"},
		],
		"fundo": "morros",
		"ceu": ["#2F96E8", "#CFEFFF"], "nevoa": "#DDF1FB",
		"texto": "3 voltas: desça a Avenida Sete até o Farol da Barra, siga a orla e suba as ladeiras do Pelourinho.",
	},
	{
		# Ouro Preto: ruas estreitas em zigue-zague subindo o morro (ladeiras), a
		# Praça Tiradentes lá no alto, a descida pela serra e mais ladeiras até
		# a largada; igrejas barrocas e o Pico do Itacolomi no horizonte.
		"id": "ouro_preto", "nome": "GP DE OURO PRETO (MG)", "cidade": "OURO PRETO", "estado": "MG",
		"voltas": 3, "premio": 2.8, "dificuldade": 0.15, "cor": "#C9932E",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(5, 1, -82), Vector3(30, 2, -100),
			Vector3(80, 3, -100), Vector3(98, 4, -115), Vector3(80, 5, -130), Vector3(32, 6, -130),
			Vector3(14, 7, -147), Vector3(30, 8, -163), Vector3(80, 9, -165), Vector3(125, 9, -162),
			Vector3(148, 8, -140), Vector3(150, 7, -100), Vector3(146, 5, -62), Vector3(118, 4, -42),
			Vector3(68, 4, -40), Vector3(48, 3, -24), Vector3(66, 2, -8), Vector3(112, 2, -8),
			Vector3(130, 1, 10), Vector3(112, 1, 26), Vector3(60, 1, 22), Vector3(28, 0, 26), Vector3(8, 0, 22), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "colonial", "nome": "LADEIRA DO PILAR", "de": 0},
			{"id": "colonial", "nome": "LADEIRAS DE OURO PRETO", "de": 3},
			{"id": "colonial", "nome": "PRAÇA TIRADENTES", "de": 9},
			{"id": "serra", "nome": "SERRA DO ITACOLOMI", "de": 12},
			{"id": "colonial", "nome": "RUA DIREITA", "de": 16},
			{"id": "colonial", "nome": "LADEIRA DE SÃO FRANCISCO", "de": 22},
		],
		"portais": [Vector3(80, 3, -100), Vector3(80, 9, -165), Vector3(112, 2, -8)],
		"aguas": [],
		"marcos": [
			{"tipo": "igreja", "lugar": Vector3(60, 0, -196), "cor": "#FFFFFF", "detalhe": "#C9932E"},
			{"tipo": "igreja", "lugar": Vector3(-26, 0, -122), "cor": "#FFF6E0", "detalhe": "#7A5230"},
			{"tipo": "pico", "lugar": Vector3(240, 0, -120)},
		],
		"fundo": "morros",
		"ceu": ["#5C9FE0", "#F2E6D8"], "nevoa": "#EEE6DC",
		"texto": "3 voltas pelo zigue-zague das ladeiras até a Praça Tiradentes, descendo pela serra.",
	},
	{
		# São Paulo: inspirado no autódromo de Interlagos (sentido anti-horário):
		# reta dos boxes, S do Senna, Curva do Sol, reta oposta, Descida do Lago,
		# o miolo (Ferradura, Pinheirinho, Bico de Pato, Mergulho), Junção e a
		# subida dos boxes; prédios da cidade em volta.
		"id": "sao_paulo", "nome": "GP DE SÃO PAULO (SP)", "cidade": "SÃO PAULO", "estado": "SP",
		"voltas": 3, "premio": 3.5, "dificuldade": 0.2, "cor": "#E8364F", "arquibancada": 1,
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -60), Vector3(-4, 0, -112), Vector3(-20, 0, -140),
			Vector3(-46, 1, -138), Vector3(-74, 2, -152), Vector3(-108, 2, -142), Vector3(-126, 2, -112),
			Vector3(-130, 2, -62), Vector3(-128, 1, -12), Vector3(-122, 0, 22), Vector3(-98, 0, 40),
			Vector3(-72, 0, 32), Vector3(-66, 1, 4), Vector3(-80, 2, -24), Vector3(-68, 3, -52),
			Vector3(-40, 3, -56), Vector3(-30, 2, -28), Vector3(-36, 1, 8), Vector3(-26, 0, 40),
			Vector3(-4, 0, 52), Vector3(14, 0, 36), Vector3(2, 0, 14),
		],
		"zonas": [
			{"id": "vila", "nome": "RETA DOS BOXES", "de": 0},
			{"id": "predios", "nome": "S DO SENNA", "de": 2},
			{"id": "parque", "nome": "RETA OPOSTA", "de": 7},
			{"id": "parque", "nome": "DESCIDA DO LAGO", "de": 10},
			{"id": "parque", "nome": "PINHEIRINHO", "de": 14},
			{"id": "predios", "nome": "JUNÇÃO", "de": 18},
			{"id": "vila", "nome": "SUBIDA DOS BOXES", "de": 20},
		],
		"portais": [Vector3(-4, 0, -112), Vector3(-130, 2, -62), Vector3(-68, 3, -52)],
		"aguas": [{"centro": Vector3(-98, 0, -90), "raios": Vector2(14, 22), "cor": "#5FA6C8", "margem": "#B9D98C", "beira": 3.0}],
		"marcos": [
			{"tipo": "museu", "lugar": Vector3(42, 0, -82)},
			{"tipo": "torre", "lugar": Vector3(-172, 0, -60)},
			{"tipo": "torre", "lugar": Vector3(-62, 0, 92)},
		],
		"fundo": "predios",
		"ceu": ["#7DA9D6", "#E8E4EA"], "nevoa": "#E6E2E8",
		"texto": "3 voltas num traçado como o de Interlagos: S do Senna, reta oposta, Descida do Lago e o miolo.",
	},
]


static func dados(id: String) -> Dictionary:
	for gp in LISTA:
		if gp["id"] == id:
			return gp
	return LISTA[0]


static func indice(id: String) -> int:
	for i in LISTA.size():
		if LISTA[i]["id"] == id:
			return i
	return 0


static func _estado() -> Dictionary:
	if not Progresso.vila.has("gps"):
		Progresso.vila["gps"] = {}
	return Progresso.vila["gps"]


## Melhor lugar no GP (0 = nunca correu).
static func melhor_lugar(id: String) -> int:
	return int(_estado().get(id, {}).get("lugar", 0))


static func recorde(id: String) -> float:
	if id == "vila":
		return float(Progresso.estatisticas.get("corrida_recorde", 0.0))
	return float(_estado().get(id, {}).get("recorde", 0.0))


## O primeiro está sempre liberado; os outros, com pódio (1º a 3º) no anterior.
static func liberado(id: String) -> bool:
	var i := indice(id)
	if i == 0:
		return true
	var anterior := melhor_lugar(LISTA[i - 1]["id"])
	return anterior >= 1 and anterior <= 3


## Guarda o lugar e o tempo; retorna se foi recorde do GP.
static func registrar(id: String, lugar: int, tempo: float) -> bool:
	var antes := recorde(id)
	var novo := antes <= 0.0 or tempo < antes
	var estado: Dictionary = _estado().get(id, {})
	var melhor := melhor_lugar(id)
	estado["lugar"] = lugar if melhor == 0 else mini(melhor, lugar)
	if novo:
		estado["recorde"] = snappedf(tempo, 0.01)
		if id == "vila":
			Progresso.estatisticas["corrida_recorde"] = snappedf(tempo, 0.01)
	_estado()[id] = estado
	return novo


## O GP escolhido para correr (liberado; senão, o da Vila).
static func escolhido() -> String:
	var id := str(Progresso.config.get("gp", "vila"))
	return id if liberado(id) else "vila"


static func escolher(id: String) -> bool:
	if not liberado(id):
		return false
	Progresso.config["gp"] = id
	Progresso.salvar()
	return true
