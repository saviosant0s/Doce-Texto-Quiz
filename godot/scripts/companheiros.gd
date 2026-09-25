class_name Companheiros
## Doces companheiros: raridade, fragmentos, nível e bônus.
##
## - Cada doce da coleção tem uma raridade (COMUM, RARO, ÉPICO, LENDÁRIO) e um
##   bônus. Só o bônus do companheiro escolhido vale (como um herói).
## - Fragmentos vêm dos baús surpresa (ver Baus). Com FRAGMENTOS_PARA_GANHAR,
##   o jogador ganha o doce (sem precisar comprar). Depois, fragmentos do mesmo
##   doce sobem o nível dele (até NIVEL_MAXIMO), e o bônus cresce.
## - Raridade maior = bônus mais forte (MULTIPLICADOR), mas cai menos nos baús.
##
## Estado em Progresso.colecao: "fragmentos" {id: n} e "niveis" {id: n}.

enum Raridade { COMUM, RARO, EPICO, LENDARIO }
const NOMES_RARIDADE := ["COMUM", "RARO", "ÉPICO", "LENDÁRIO"]
const CORES_RARIDADE := [Color("#8FB3C9"), Color("#3E8EF0"), Color("#A45CE6"), Color("#FFB020")]
const MULTIPLICADOR := [1.0, 1.25, 1.5, 2.0]
const FRAGMENTOS_PARA_GANHAR := 10
const NIVEL_MAXIMO := 5
## Para ir do nível n ao n+1: [fragmentos, moedas].
const MELHORIA := [[10, 50], [20, 100], [30, 200], [50, 400]]

## Bônus: "acucar" (% a mais de açúcar no quiz), "moedas_quiz" (% de moedas
## no quiz), "tempo" (segundos a mais por pergunta), "dica_gratis" (tirar 2
## alternativas de graça, por partida), "match" (% de moedas no Doce Match),
## "cozinha" (gorjeta a mais por cliente), "xp" (% de experiência).
const DOCES := {
	"brigadeiro": {"raridade": Raridade.COMUM, "bonus": "acucar"},
	"bala": {"raridade": Raridade.COMUM, "bonus": "tempo"},
	"pirulito": {"raridade": Raridade.COMUM, "bonus": "match"},
	"rosquinha": {"raridade": Raridade.COMUM, "bonus": "cozinha"},
	"maca": {"raridade": Raridade.RARO, "bonus": "moedas_quiz"},
	"macaron": {"raridade": Raridade.RARO, "bonus": "xp"},
	"picole": {"raridade": Raridade.RARO, "bonus": "tempo"},
	"cupcake_morango": {"raridade": Raridade.RARO, "bonus": "acucar"},
	"cupcake": {"raridade": Raridade.EPICO, "bonus": "dica_gratis"},
	"bombom": {"raridade": Raridade.EPICO, "bonus": "moedas_quiz"},
	"pudim": {"raridade": Raridade.EPICO, "bonus": "cozinha"},
	"chocolate": {"raridade": Raridade.LENDARIO, "bonus": "moedas_quiz"},
	"algodao_doce": {"raridade": Raridade.LENDARIO, "bonus": "dica_gratis"},
	"jujuba": {"raridade": Raridade.COMUM, "bonus": "xp"},
	"beijinho": {"raridade": Raridade.COMUM, "bonus": "acucar"},
	"marshmallow": {"raridade": Raridade.COMUM, "bonus": "match"},
	"pacoca": {"raridade": Raridade.COMUM, "bonus": "moedas_quiz"},
	"cocada": {"raridade": Raridade.RARO, "bonus": "cozinha"},
	"pe_de_moleque": {"raridade": Raridade.RARO, "bonus": "match"},
	"sorvete": {"raridade": Raridade.RARO, "bonus": "xp"},
	"pao_de_mel": {"raridade": Raridade.RARO, "bonus": "dica_gratis"},
	"quindim": {"raridade": Raridade.EPICO, "bonus": "acucar"},
	"churros": {"raridade": Raridade.EPICO, "bonus": "tempo"},
	"brownie": {"raridade": Raridade.EPICO, "bonus": "match"},
	"bolo": {"raridade": Raridade.LENDARIO, "bonus": "xp"},
}


static func raridade(id: String) -> int:
	return int(DOCES.get(id, {}).get("raridade", Raridade.COMUM))


static func nome_raridade(id: String) -> String:
	return NOMES_RARIDADE[raridade(id)]


static func cor(id: String) -> Color:
	return CORES_RARIDADE[raridade(id)]


static func de_raridade(r: int) -> Array:
	return DOCES.keys().filter(func(id): return int(DOCES[id]["raridade"]) == r)


static func _colecao() -> Dictionary:
	var c := Progresso.colecao
	if not c.has("fragmentos"):
		c["fragmentos"] = {}
	if not c.has("niveis"):
		c["niveis"] = {}
	return c


static func fragmentos(id: String) -> int:
	return int(_colecao()["fragmentos"].get(id, 0))


## Nível do doce (0 = ainda não tem).
static func nivel(id: String) -> int:
	if not Colecao.tem(id):
		return 0
	return maxi(1, int(_colecao()["niveis"].get(id, 1)))


## Quantos fragmentos faltam para o próximo passo (ganhar ou melhorar); 0 no máximo.
static func fragmentos_precisos(id: String) -> int:
	var n := nivel(id)
	if n == 0:
		return FRAGMENTOS_PARA_GANHAR
	if n >= NIVEL_MAXIMO:
		return 0
	return MELHORIA[n - 1][0]


static func preco_melhoria(id: String) -> int:
	var n := nivel(id)
	return MELHORIA[n - 1][1] if n >= 1 and n < NIVEL_MAXIMO else -1


## Recebe fragmentos. Se ainda não tinha o doce e juntou o bastante, ganha ele
## (gasta os fragmentos). Retorna true se ganhou o doce agora.
static func receber_fragmentos(id: String, quantidade: int) -> bool:
	if not DOCES.has(id) or quantidade <= 0:
		return false
	var c := _colecao()
	c["fragmentos"][id] = fragmentos(id) + quantidade
	if not Colecao.tem(id) and fragmentos(id) >= FRAGMENTOS_PARA_GANHAR:
		c["fragmentos"][id] = fragmentos(id) - FRAGMENTOS_PARA_GANHAR
		if not id in c["doces"]:
			c["doces"].append(id)
		c["niveis"][id] = 1
		return true
	return false


static func pode_melhorar(id: String) -> bool:
	var n := nivel(id)
	return n >= 1 and n < NIVEL_MAXIMO and fragmentos(id) >= MELHORIA[n - 1][0] \
		and Progresso.moedas >= MELHORIA[n - 1][1]


static func melhorar(id: String) -> bool:
	if not pode_melhorar(id):
		return false
	var n := nivel(id)
	var c := _colecao()
	c["fragmentos"][id] = fragmentos(id) - MELHORIA[n - 1][0]
	c["niveis"][id] = n + 1
	Progresso.gastar_moedas(MELHORIA[n - 1][1])  # também salva
	return true


# --- Bônus -----------------------------------------------------------------------

## Valor do bônus de um doce no nível dele (ou num nível dado).
static func valor_bonus(id: String, n := -1) -> float:
	if not DOCES.has(id):
		return 0.0
	if n < 0:
		n = nivel(id)
	if n <= 0:
		return 0.0
	var m: float = MULTIPLICADOR[raridade(id)]
	match DOCES[id]["bonus"]:
		"acucar", "moedas_quiz", "match", "xp":
			return roundf((10.0 + 5.0 * (n - 1)) * m)  # porcentagem
		"tempo":
			return roundf((3.0 + (n - 1)) * m)  # segundos
		"cozinha":
			return roundf(n * m)  # moedas de gorjeta
		"dica_gratis":
			return float(1 + (n - 1) / 2 + (1 if raridade(id) == Raridade.LENDARIO else 0))
	return 0.0


static func descrever_bonus(id: String, n := -1) -> String:
	var v := int(valor_bonus(id, n if n >= 0 else maxi(nivel(id), 1)))
	match DOCES.get(id, {}).get("bonus", ""):
		"acucar":
			return "+%d%% DE AÇÚCAR NO QUIZ" % v
		"moedas_quiz":
			return "+%d%% DE MOEDAS NO QUIZ" % v
		"tempo":
			return "+%d SEGUNDOS POR PERGUNTA" % v
		"dica_gratis":
			return "%d AJUDA%s \"TIRAR 2\" GRÁTIS POR PARTIDA" % [v, "S" if v > 1 else ""]
		"match":
			return "+%d%% DE MOEDAS NO DOCE MATCH" % v
		"cozinha":
			return "+%d DE GORJETA POR CLIENTE" % v
		"xp":
			return "+%d%% DE EXPERIÊNCIA" % v
	return ""


## Bônus ativo (do companheiro escolhido) de um tipo; 0 se o companheiro dá outro.
static func bonus(tipo: String) -> float:
	var id := Colecao.companheiro()
	if id == "" and Colecao.tem("brigadeiro"):
		id = "brigadeiro"
	if not DOCES.has(id) or DOCES[id]["bonus"] != tipo:
		return 0.0
	return valor_bonus(id)


## Aplica um bônus de porcentagem a um valor (arredonda para cima).
static func com_bonus(tipo: String, valor: int) -> int:
	var b := bonus(tipo)
	return valor + ceili(valor * b / 100.0) if b > 0 and valor > 0 else valor
