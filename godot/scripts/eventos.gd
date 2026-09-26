class_name Eventos
## EVENTOS DA TEMPORADA: em algumas épocas do ano a vila fica decorada e tem
## um evento com FICHAS próprias (pétalas, abóboras, estrelas...).
## - Ganha fichas jogando qualquer coisa (quiz, torre, fábrica, match,
##   confeitaria, laboratório, baús: ver FICHAS_POR_EVENTO) e pegando os
##   objetos do evento espalhados pela vila (ITENS_POR_DIA por dia).
## - A TRILHA de prêmios vai liberando conforme junta fichas: moedas, açúcar,
##   baú, um MÓVEL exclusivo para a Minha Casa e, no fim, um DOCE exclusivo
##   para a coleção (só dá para ter pegando no evento).
## Cada evento volta todo ano (as fichas zeram a cada edição).
##
## Estado em Progresso.vila["evento"] = {"edicao": "halloween-2026", "fichas",
## "resgatados": [índices da trilha], "dia": "AAAA-MM-DD", "pegos": [índices]}.

## inicio/fim: [mês, dia] (o Natal passa da virada do ano).
const EVENTOS := {
	"primavera": {"nome": "FESTIVAL DAS FLORES", "inicio": [9, 20], "fim": [10, 14], "ficha": "PÉTALAS",
		"cor": "#FF8FB8", "movel": "vaso_primavera", "doce": "flor_de_acucar",
		"texto": "A primavera chegou e a vila está florida!"},
	"halloween": {"nome": "NOITE DAS ABÓBORAS", "inicio": [10, 15], "fim": [11, 10], "ficha": "ABÓBORAS",
		"cor": "#FF8A1F", "movel": "abobora_luminosa", "doce": "abobora_choco",
		"texto": "Abóboras de chocolate apareceram por toda a vila. Gostosuras ou travessuras!"},
	"natal": {"nome": "NATAL DOCE", "inicio": [12, 1], "fim": [1, 10], "ficha": "ESTRELINHAS",
		"cor": "#E8364F", "movel": "arvore_natal", "doce": "biscoito_gengibre",
		"texto": "A vila ganhou luzes, presentes e uma árvore de Natal na praça!"},
	"carnaval": {"nome": "CARNAVAL DE CONFEITOS", "inicio": [2, 5], "fim": [3, 5], "ficha": "CONFETES",
		"cor": "#B07CFF", "movel": "mascara_carnaval", "doce": "confete",
		"texto": "Serpentinas, máscaras e confete colorido por toda parte!"},
	"pascoa": {"nome": "CAÇA AOS OVOS", "inicio": [3, 20], "fim": [4, 25], "ficha": "OVINHOS",
		"cor": "#6FD3FF", "movel": "cesta_pascoa", "doce": "ovo_pascoa",
		"texto": "Ovinhos de chocolate estão escondidos pela vila. Ache todos!"},
	"junina": {"nome": "ARRAIÁ DOCE", "inicio": [6, 1], "fim": [7, 20], "ficha": "BANDEIRINHAS",
		"cor": "#FFD23F", "movel": "fogueira_junina", "doce": "pipoca_doce",
		"texto": "Tem bandeirinha, fogueira e quentão... de chocolate!"},
}

## Trilha de prêmios: [fichas, prêmio]. "movel" e "doce" são os do evento.
const TRILHA := [
	[20, {"moedas": 30}],
	[50, {"acucar": 40}],
	[90, {"bau": "doce"}],
	[140, {"moedas": 80}],
	[200, {"movel": true}],
	[270, {"acucar": 80}],
	[350, {"doce": true}],
]

## Fichas por evento dos jogos (quantidade vezes o valor; ver Missoes.registrar).
const FICHAS_POR_EVENTO := {"partidas": 5.0, "acertos": 1.0, "estrelas": 2.0, "torre": 0.5, "fabrica": 2.0,
	"match": 4.0, "clientes": 2.0, "lab_fases": 5.0, "baus": 2.0}
const ITENS_POR_DIA := 8
const FICHAS_ITEM := 3

## Para testes e prints: data fixa ("" = de verdade).
static var dia_fixo := ""


static func hoje() -> String:
	return dia_fixo if not dia_fixo.is_empty() else Time.get_date_string_from_system()


## Id do evento de hoje ("" = nenhum).
static func atual() -> String:
	var partes := hoje().split("-")
	var md := int(partes[1]) * 100 + int(partes[2])
	for id in EVENTOS:
		var ini := int(EVENTOS[id]["inicio"][0]) * 100 + int(EVENTOS[id]["inicio"][1])
		var fim := int(EVENTOS[id]["fim"][0]) * 100 + int(EVENTOS[id]["fim"][1])
		if (ini <= fim and md >= ini and md <= fim) or (ini > fim and (md >= ini or md <= fim)):
			return id
	return ""


static func ativo() -> bool:
	return atual() != ""


static func dados() -> Dictionary:
	return EVENTOS.get(atual(), {})


## "halloween-2026" (o Natal de dezembro e o de janeiro são a mesma edição).
static func edicao() -> String:
	var id := atual()
	if id == "":
		return ""
	var partes := hoje().split("-")
	var ano := int(partes[0])
	var ini: Array = EVENTOS[id]["inicio"]
	if int(partes[1]) < int(ini[0]):
		ano -= 1
	return "%s-%d" % [id, ano]


## Dias até o fim do evento (contando hoje).
static func dias_restantes() -> int:
	var id := atual()
	if id == "":
		return 0
	var partes := hoje().split("-")
	var ano := int(partes[0])
	var fim: Array = EVENTOS[id]["fim"]
	if int(fim[0]) < int(partes[1]):
		ano += 1  # termina no ano que vem (Natal)
	var hoje_unix := Time.get_unix_time_from_datetime_string(hoje() + "T12:00:00")
	var fim_unix := Time.get_unix_time_from_datetime_string("%d-%02d-%02dT12:00:00" % [ano, fim[0], fim[1]])
	return int((fim_unix - hoje_unix) / 86400) + 1


static func _estado() -> Dictionary:
	var e: Dictionary = Progresso.vila.get("evento", {})
	if str(e.get("edicao", "")) != edicao():
		e = {"edicao": edicao(), "fichas": 0, "resgatados": [], "dia": "", "pegos": []}
		Progresso.vila["evento"] = e
	return e


static func fichas() -> int:
	return int(_estado()["fichas"]) if ativo() else 0


static func ganhar_fichas(quantidade: int) -> void:
	if not ativo() or quantidade <= 0:
		return
	_estado()["fichas"] = fichas() + quantidade
	Progresso.salvar()


## Eventos dos jogos (chamado por Missoes.registrar).
static func registrar(evento: String, quantidade: int) -> void:
	if ativo() and FICHAS_POR_EVENTO.has(evento):
		ganhar_fichas(ceili(quantidade * float(FICHAS_POR_EVENTO[evento])))


# --- Trilha de prêmios ---------------------------------------------------------------

## Prêmio da faixa `indice` já com o móvel/doce do evento.
static func premio(indice: int) -> Dictionary:
	var p: Dictionary = (TRILHA[indice][1] as Dictionary).duplicate()
	if p.has("movel"):
		p["movel"] = dados()["movel"]
	if p.has("doce"):
		p["doce"] = dados()["doce"]
	return p


static func pode_resgatar(indice: int) -> bool:
	return ativo() and fichas() >= int(TRILHA[indice][0]) and not (indice in _estado()["resgatados"].map(func(i): return int(i)))


static func resgatado(indice: int) -> bool:
	return ativo() and indice in _estado()["resgatados"].map(func(i): return int(i))


## Resgata o prêmio da faixa. Retorna o prêmio ou {}.
static func resgatar(indice: int) -> Dictionary:
	if not pode_resgatar(indice):
		return {}
	var p := premio(indice)
	_estado()["resgatados"].append(indice)
	if p.has("acucar"):
		Confeitaria.ganhar_acucar(int(p["acucar"]))
	if p.has("bau"):
		Baus.ganhar(p["bau"])
	if p.has("movel"):
		Casa.ganhar_movel(p["movel"])
	if p.has("doce") and not p["doce"] in Progresso.colecao["doces"]:
		Progresso.colecao["doces"].append(p["doce"])
	Progresso.ganhar_moedas(int(p.get("moedas", 0)))  # também salva
	return p


## Quantos prêmios já dá para resgatar (para o "!" do botão).
static func prontos() -> int:
	var n := 0
	for i in TRILHA.size():
		if pode_resgatar(i):
			n += 1
	return n


# --- Objetos do evento pela vila -----------------------------------------------------

## Onde ficam os objetos de hoje (sorteio fixo pela data).
static func lugares_itens() -> Array:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = hash("evento" + hoje())
	var lista := []
	while lista.size() < ITENS_POR_DIA:
		var angulo := sorteio.randf() * TAU
		var raio := sorteio.randf_range(6.0, 24.0)
		var p := Vector3(cos(angulo) * raio, 0, sin(angulo) * raio * 0.8)
		if CicloDia.lugar_livre(p):  # nada dentro de prédio, terreno ou lago
			lista.append(p)
	return lista


static func _pegos_hoje() -> Array:
	var e := _estado()
	if str(e["dia"]) != hoje():
		e["dia"] = hoje()
		e["pegos"] = []
	return e["pegos"]


static func item_pego(indice: int) -> bool:
	return int(indice) in _pegos_hoje().map(func(i): return int(i))


static func pegar_item(indice: int) -> int:
	if not ativo() or indice < 0 or indice >= ITENS_POR_DIA or item_pego(indice):
		return 0
	_pegos_hoje().append(indice)
	ganhar_fichas(FICHAS_ITEM)
	return FICHAS_ITEM
