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
## lado esquerdo da reta). Pontos: x, altura, z (ver Corrida.montar_curva).
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
		"id": "valenca", "nome": "GP DE VALENÇA (BA)", "cidade": "VALENÇA", "estado": "BA",
		"voltas": 3, "premio": 1.6, "dificuldade": 0.05, "cor": "#2FA36B",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(10, 0, -85), Vector3(40, 0, -100),
			Vector3(75, 1.8, -102), Vector3(115, 1.8, -102), Vector3(148, 0, -96), Vector3(172, 0, -72),
			Vector3(178, 0, -38), Vector3(163, 0, -8), Vector3(172, 0, 24), Vector3(160, 0, 56),
			Vector3(128, 0, 72), Vector3(94, 0, 76), Vector3(60, 0, 70), Vector3(30, 0, 55),
			Vector3(10, 0, 30), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "colonial", "nome": "CENTRO DE VALENÇA", "de": 0},
			{"id": "rio", "nome": "PONTE DO RIO UNA", "de": 3},
			{"id": "praia", "nome": "COQUEIRAL", "de": 6},
			{"id": "serra", "nome": "MATA ATLÂNTICA", "de": 10},
			{"id": "colonial", "nome": "CASARIO DO CENTRO", "de": 13},
		],
		"portais": [Vector3(115, 1.8, -102), Vector3(172, 0, 24), Vector3(60, 0, 70)],
		"aguas": [{"centro": Vector3(95, 0, -100), "raios": Vector2(12, 70), "cor": "#4E9C93", "margem": "#C9B48A", "beira": 2.5}],
		"marcos": [
			{"tipo": "igreja", "lugar": Vector3(-24, 0, -62), "cor": "#FFFFFF", "detalhe": "#2E9BE8"},
			{"tipo": "fabrica", "lugar": Vector3(52, 0, 98)},
		],
		"fundo": "morros",
		"ceu": ["#4FA8EC", "#D8F0FF"], "nevoa": "#E3F2F7",
		"texto": "3 voltas pelo centro histórico, pela ponte do Rio Una, pelo coqueiral e pela Mata Atlântica.",
	},
	{
		"id": "salvador", "nome": "GP DE SALVADOR (BA)", "cidade": "SALVADOR", "estado": "BA",
		"voltas": 3, "premio": 2.2, "dificuldade": 0.1, "cor": "#2E9BE8",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(-5, 0, -90), Vector3(15, 0, -122),
			Vector3(50, 0, -132), Vector3(90, 0, -130), Vector3(130, 0, -134), Vector3(165, 0, -122),
			Vector3(186, 0, -92), Vector3(182, 0, -56), Vector3(160, 0, -30), Vector3(150, 1, 0),
			Vector3(150, 4, 32), Vector3(135, 6, 56), Vector3(105, 8, 66), Vector3(75, 6, 62),
			Vector3(50, 3, 50), Vector3(25, 0, 36), Vector3(8, 0, 22), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "vila", "nome": "LARGADA", "de": 0},
			{"id": "praia", "nome": "ORLA DA BARRA", "de": 3},
			{"id": "predios", "nome": "AVENIDA SETE", "de": 9},
			{"id": "colonial", "nome": "PELOURINHO", "de": 12},
			{"id": "vila", "nome": "LARGADA", "de": 18},
		],
		"portais": [Vector3(130, 0, -134), Vector3(182, 0, -56), Vector3(105, 8, 66)],
		"aguas": [{"centro": Vector3(100, 0, -195), "raios": Vector2(150, 45), "cor": "#2F9FD6", "margem": "#F2DDA4", "beira": 16.0}],
		"marcos": [
			{"tipo": "farol", "lugar": Vector3(176, 0, -146)},
			{"tipo": "elevador", "lugar": Vector3(186, 0, 30)},
			{"tipo": "igreja", "lugar": Vector3(98, 0, 92), "cor": "#3E7FD0", "detalhe": "#FFFFFF"},
		],
		"fundo": "morros",
		"ceu": ["#2F96E8", "#CFEFFF"], "nevoa": "#DDF1FB",
		"texto": "3 voltas pela Orla da Barra (com o farol), pela cidade e pelas ladeiras do Pelourinho.",
	},
	{
		"id": "ouro_preto", "nome": "GP DE OURO PRETO (MG)", "cidade": "OURO PRETO", "estado": "MG",
		"voltas": 3, "premio": 2.8, "dificuldade": 0.15, "cor": "#C9932E",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(8, 2, -86), Vector3(30, 5, -112),
			Vector3(62, 8, -120), Vector3(96, 10, -114), Vector3(122, 12, -96), Vector3(132, 12, -64),
			Vector3(122, 10, -34), Vector3(132, 8, -4), Vector3(122, 6, 26), Vector3(100, 8, 48),
			Vector3(70, 10, 58), Vector3(42, 7, 55), Vector3(22, 3, 40), Vector3(8, 0, 24), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "colonial", "nome": "PRAÇA TIRADENTES", "de": 0},
			{"id": "serra", "nome": "SERRA DO ITACOLOMI", "de": 3},
			{"id": "colonial", "nome": "LADEIRAS DE OURO PRETO", "de": 9},
			{"id": "serra", "nome": "MIRANTE", "de": 12},
			{"id": "colonial", "nome": "PRAÇA TIRADENTES", "de": 15},
		],
		"portais": [Vector3(62, 8, -120), Vector3(132, 12, -64), Vector3(70, 10, 58)],
		"aguas": [],
		"marcos": [
			{"tipo": "igreja", "lugar": Vector3(-26, 0, -40), "cor": "#FFFFFF", "detalhe": "#C9932E"},
			{"tipo": "igreja", "lugar": Vector3(92, 0, 8), "cor": "#FFF6E0", "detalhe": "#7A5230"},
			{"tipo": "pico", "lugar": Vector3(190, 0, -150)},
		],
		"fundo": "morros",
		"ceu": ["#5C9FE0", "#F2E6D8"], "nevoa": "#EEE6DC",
		"texto": "3 voltas subindo e descendo as ladeiras, com as igrejas barrocas e a Serra do Itacolomi.",
	},
	{
		"id": "sao_paulo", "nome": "GP DE SÃO PAULO (SP)", "cidade": "SÃO PAULO", "estado": "SP",
		"voltas": 3, "premio": 3.5, "dificuldade": 0.2, "cor": "#E8364F",
		"pontos": [
			Vector3(0, 0, 0), Vector3(0, 0, -60), Vector3(0, 0, -110), Vector3(15, 0, -142),
			Vector3(50, 0, -152), Vector3(85, 0, -140), Vector3(100, 0, -114), Vector3(130, 0, -104),
			Vector3(165, 0, -116), Vector3(196, 0, -100), Vector3(206, 0, -64), Vector3(190, 0, -34),
			Vector3(160, 0, -24), Vector3(140, 0, 2), Vector3(150, 0, 32), Vector3(130, 0, 56),
			Vector3(95, 0, 64), Vector3(60, 0, 56), Vector3(30, 0, 42), Vector3(10, 0, 26), Vector3(1, 0, 12),
		],
		"zonas": [
			{"id": "vila", "nome": "RETA DOS BOXES", "de": 0},
			{"id": "parque", "nome": "PARQUE DO IBIRAPUERA", "de": 3},
			{"id": "predios", "nome": "AVENIDA PAULISTA", "de": 7},
			{"id": "predios", "nome": "CENTRO", "de": 13},
			{"id": "vila", "nome": "RETA DOS BOXES", "de": 18},
		],
		"portais": [Vector3(130, 0, -104), Vector3(206, 0, -64), Vector3(95, 0, 64)],
		"aguas": [{"centro": Vector3(62, 0, -92), "raios": Vector2(20, 11), "cor": "#5FA6C8", "margem": "#B9D98C", "beira": 3.0}],
		"marcos": [
			{"tipo": "museu", "lugar": Vector3(140, 0, -152)},
			{"tipo": "torre", "lugar": Vector3(230, 0, -20)},
			{"tipo": "torre", "lugar": Vector3(176, 0, 84)},
		],
		"fundo": "predios",
		"ceu": ["#7DA9D6", "#E8E4EA"], "nevoa": "#E6E2E8",
		"texto": "3 voltas pela reta dos boxes, pelo Parque do Ibirapuera e pelos prédios da Avenida Paulista.",
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
