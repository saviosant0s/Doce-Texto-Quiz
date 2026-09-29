class_name Eventos
## EVENTOS DA TEMPORADA: a vila fica decorada com um tema e tem um evento com
## FICHAS próprias (pétalas, abóboras, estrelas...). Os temas trocam SOZINHOS
## a cada DIAS_POR_EVENTO dias do jogo (ver CicloDia: um dia do jogo = 40 min,
## então cada tema fica ~20 horas de verdade), na ordem de ORDEM, em roda.
## - Ganha fichas jogando qualquer coisa (quiz, torre, fábrica, match,
##   confeitaria, laboratório, baús: ver FICHAS_POR_EVENTO) e pegando os
##   objetos do evento espalhados pela vila (ITENS_POR_DIA por dia).
## - A TRILHA de prêmios vai liberando conforme junta fichas: moedas, açúcar,
##   baú, um MÓVEL exclusivo para a Minha Casa e, no fim, um DOCE exclusivo
##   para a coleção (só dá para ter pegando no evento).
## Cada evento volta na próxima volta da roda (as fichas zeram a cada edição).
##
## Estado em Progresso.vila["evento"] = {"edicao": "halloween-24871", "fichas",
## "resgatados": [índices da trilha], "dia": dia do jogo, "pegos": [índices]}.

const ORDEM := ["primavera", "halloween", "natal", "carnaval", "pascoa", "junina"]
const DIAS_POR_EVENTO := 30

const EVENTOS := {
	"primavera": {"nome": "FESTIVAL DAS FLORES", "ficha": "PÉTALAS",
		"cor": "#FF8FB8", "movel": "vaso_primavera", "doce": "flor_de_acucar",
		"texto": "A primavera chegou e a vila está florida!"},
	"halloween": {"nome": "NOITE DAS ABÓBORAS", "ficha": "ABÓBORAS",
		"cor": "#FF8A1F", "movel": "abobora_luminosa", "doce": "abobora_choco",
		"texto": "Abóboras de chocolate apareceram por toda a vila. Gostosuras ou travessuras!"},
	"natal": {"nome": "NATAL DOCE", "ficha": "ESTRELINHAS",
		"cor": "#E8364F", "movel": "arvore_natal", "doce": "biscoito_gengibre",
		"texto": "A vila ganhou luzes, presentes e uma árvore de Natal na praça!"},
	"carnaval": {"nome": "CARNAVAL DE CONFEITOS", "ficha": "CONFETES",
		"cor": "#B07CFF", "movel": "mascara_carnaval", "doce": "confete",
		"texto": "Serpentinas, máscaras e confete colorido por toda parte!"},
	"pascoa": {"nome": "CAÇA AOS OVOS", "ficha": "OVINHOS",
		"cor": "#6FD3FF", "movel": "cesta_pascoa", "doce": "ovo_pascoa",
		"texto": "Ovinhos de chocolate estão escondidos pela vila. Ache todos!"},
	"junina": {"nome": "ARRAIÁ DOCE", "ficha": "BANDEIRINHAS",
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
const ITENS_POR_DIA := 6  # por dia do jogo (40 min)
const FICHAS_ITEM := 3

## Dia do jogo (CicloDia; nos testes, CicloDia.dia_fixo).
static func dia() -> int:
	return CicloDia.dia_jogo()


## Id do evento de agora (sempre tem um: os temas vão trocando em roda).
static func atual() -> String:
	return ORDEM[posmod(floori(dia() / float(DIAS_POR_EVENTO)), ORDEM.size())]


static func ativo() -> bool:
	return atual() != ""


static func dados() -> Dictionary:
	return EVENTOS.get(atual(), {})


## "halloween-24871": o evento e a volta da roda (cada volta é uma edição nova).
static func edicao() -> String:
	return "%s-%d" % [atual(), floori(dia() / float(DIAS_POR_EVENTO))]


## Dias do jogo até o tema trocar (contando hoje).
static func dias_restantes() -> int:
	return DIAS_POR_EVENTO - posmod(dia(), DIAS_POR_EVENTO)


## Horas de verdade (aproximadas) até o tema trocar.
static func horas_restantes() -> int:
	var fim := (floori(dia() / float(DIAS_POR_EVENTO)) + 1) * DIAS_POR_EVENTO
	var falta := (fim * 24.0 - CicloDia.horas_jogo()) / 24.0 * CicloDia.DURACAO_DIA / 3600.0
	return maxi(1, ceili(falta))


static func _estado() -> Dictionary:
	var e: Dictionary = Progresso.vila.get("evento", {})
	if str(e.get("edicao", "")) != edicao():
		var antiga := str(e.get("edicao", ""))
		var partes := antiga.split("-")
		if partes.size() == 2 and partes[0] == atual() and int(partes[1]) >= 2000 and int(partes[1]) < 2100:
			# edição do tempo em que os eventos seguiam o calendário ("primavera-2026"):
			# o mesmo tema continua, então as fichas e prêmios continuam também
			e["edicao"] = edicao()
		else:
			e = {"edicao": edicao(), "fichas": 0, "resgatados": [], "dia": -1, "pegos": []}
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
	sorteio.seed = hash("evento%d" % dia())
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
	if int(e.get("dia", -1)) != dia():
		e["dia"] = dia()
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
