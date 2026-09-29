class_name Eventos
## EVENTOS DA TEMPORADA: a vila fica decorada com um tema e tem um evento com
## FICHAS próprias (pétalas, abóboras, estrelas...).
## Qual evento vale agora, nesta ordem:
## 1. CALENDÁRIO DA INTERNET: eventos novos no arquivo eventos.json do site do
##    jogo (URL_REMOTA), baixado ao abrir o app (Telas). Assim dá para marcar
##    eventos sem atualizar o app: é só editar o arquivo (docs/eventos.md). Um
##    evento de lá pode usar um tema que o app já tem (decoração pronta) ou o
##    tema FESTA (balões e varais na cor do evento) com nome, ficha, texto e
##    cor próprios.
## 2. CALENDÁRIO DO APP (CALENDARIO): datas de verdade, todo ano ("MM-DD") ou
##    num ano só ("AAAA-MM-DD"). Ex.: SEMANA DAS CRIANÇAS de 6 a 19/10.
## 3. A RODA: sem evento de calendário, os temas trocam SOZINHOS a cada
##    DIAS_POR_EVENTO dias do jogo (um dia do jogo = 40 min: ~20 h cada), na
##    ordem de ORDEM.
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
const URL_REMOTA := "https://saviosant0s.github.io/Doce-Texto-Quiz/eventos.json"
const ARQUIVO_REMOTOS := "user://eventos_remotos.json"

## Eventos de data marcada que já vêm no app: "tema" é a decoração (EVENTOS);
## o resto (nome, ficha, cor, texto, movel, doce) é opcional e troca o do tema.
const CALENDARIO := [
	{"id": "criancas", "tema": "criancas", "inicio": "10-06", "fim": "10-19"},
	{"id": "halloween", "tema": "halloween", "inicio": "10-25", "fim": "11-02"},
	{"id": "natal", "tema": "natal", "inicio": "12-10", "fim": "12-31"},
	{"id": "carnaval", "tema": "carnaval", "inicio": "2027-02-05", "fim": "2027-02-10"},
	{"id": "pascoa", "tema": "pascoa", "inicio": "2027-03-22", "fim": "2027-03-29"},
	{"id": "junina", "tema": "junina", "inicio": "06-01", "fim": "06-30"},
]
## Data de hoje nos testes ("2026-10-12"); "" = a data do aparelho.
static var data_fixa := ""
static var _remotos: Array = []
static var _remotos_lidos := false

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
	"criancas": {"nome": "SEMANA DAS CRIANÇAS", "ficha": "BALÕES",
		"cor": "#6FD3FF", "movel": "trem_brinquedo", "doce": "",
		"texto": "É semana das crianças! A vila está cheia de balões e brinquedos."},
	# tema de reserva dos eventos que chegam pela internet com tema novo
	"festa": {"nome": "FESTA NA VILA", "ficha": "BALÕES",
		"cor": "#FF6FAE", "movel": "", "doce": "",
		"texto": "Tem festa na vila! Junte balões para ganhar prêmios."},
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


## Tema do evento de agora (sempre tem um: calendário ou a roda).
static func atual() -> String:
	var c := do_calendario()
	if not c.is_empty():
		return c["tema"] if EVENTOS.has(c["tema"]) else "festa"
	return ORDEM[posmod(floori(dia() / float(DIAS_POR_EVENTO)), ORDEM.size())]


# --- Calendário ----------------------------------------------------------------------

## Hoje ("2026-10-12").
static func hoje() -> String:
	return data_fixa if data_fixa != "" else Time.get_date_string_from_system()


## Data completa de "10-06" (todo ano) ou "2027-02-05" (um ano só) para o ano de `ano`.
static func _data(texto: String, ano: int) -> String:
	return "%d-%s" % [ano, texto] if texto.length() == 5 else texto


## [início, fim] da vez do evento que inclui ou vem depois de hoje ("" se já passou).
static func _periodo(ev: Dictionary) -> Array:
	var h := hoje()
	var ano := int(h.substr(0, 4))
	for a in [ano - 1, ano]:  # (um evento de dezembro a janeiro começa no ano anterior)
		var inicio := _data(ev["inicio"], a)
		var fim := _data(ev["fim"], a if fim_depois(ev) else a + 1)
		if h >= inicio and h <= fim:
			return [inicio, fim]
	return []


## Se o fim fica no mesmo ano do início (senão atravessa o ano novo).
static func fim_depois(ev: Dictionary) -> bool:
	return str(ev["fim"]).right(5) >= str(ev["inicio"]).right(5) or str(ev["fim"]).length() == 10


## Todos os eventos de data marcada: os da internet primeiro (valem mais).
static func calendario() -> Array:
	if not _remotos_lidos:
		_remotos_lidos = true
		if FileAccess.file_exists(ARQUIVO_REMOTOS):
			_remotos = ler_remotos(FileAccess.get_file_as_string(ARQUIVO_REMOTOS))
	return _remotos + CALENDARIO


## O evento de calendário valendo hoje ({} = nenhum: vale a roda).
static func do_calendario() -> Dictionary:
	for ev in calendario():
		var p := _periodo(ev)
		if not p.is_empty():
			var c: Dictionary = ev.duplicate()
			c["periodo"] = p
			return c
	return {}


## Lê o eventos.json (da internet): {"eventos": [...]}. Só entram os eventos
## bem escritos (id, datas, e movel/doce que o app conhece).
static func ler_remotos(texto: String) -> Array:
	var dados = JSON.parse_string(texto)
	if not dados is Dictionary or not dados.get("eventos") is Array:
		return []
	var lista := []
	var data := RegEx.create_from_string("^(\\d{4}-)?\\d{2}-\\d{2}$")
	var nome_id := RegEx.create_from_string("^[a-z0-9_]{2,30}$")
	for ev in dados["eventos"]:
		if not ev is Dictionary:
			continue
		var id := str(ev.get("id", ""))
		var inicio := str(ev.get("inicio", ""))
		var fim := str(ev.get("fim", ""))
		if nome_id.search(id) == null or data.search(inicio) == null or data.search(fim) == null:
			continue
		var limpo := {"id": id, "tema": str(ev.get("tema", "festa")), "inicio": inicio, "fim": fim}
		for chave in ["nome", "ficha", "texto"]:
			if ev.get(chave) is String and not ev[chave].is_empty():
				limpo[chave] = ev[chave].to_upper().left(60) if chave != "texto" else ev[chave].left(140)
		if ev.get("cor") is String and Color.html_is_valid(ev["cor"]):
			limpo["cor"] = ev["cor"]
		if ev.get("movel") is String and Casa.MOVEIS.has(ev["movel"]):
			limpo["movel"] = ev["movel"]
		if ev.get("doce") is String and not Colecao.dados(ev["doce"]).is_empty():
			limpo["doce"] = ev["doce"]
		lista.append(limpo)
	return lista


## Guarda o eventos.json baixado (e passa a valer já). Retorna quantos eventos leu.
static func guardar_remotos(texto: String) -> int:
	var lista := ler_remotos(texto)
	if JSON.parse_string(texto) is Dictionary:
		var arquivo := FileAccess.open(ARQUIVO_REMOTOS, FileAccess.WRITE)
		if arquivo:
			arquivo.store_string(texto)
	_remotos = lista
	_remotos_lidos = true
	return lista.size()


## Texto do fim do evento de calendário ("ATÉ 19/10"; "" na roda).
static func fim_texto() -> String:
	var c := do_calendario()
	if c.is_empty():
		return ""
	var fim: String = c["periodo"][1]
	return "ATÉ %s/%s" % [fim.substr(8, 2), fim.substr(5, 2)]


static func ativo() -> bool:
	return atual() != ""


## Dados do evento de agora: os do tema, trocados pelos do calendário (nome,
## ficha, cor, texto, móvel e doce do prêmio).
static func dados() -> Dictionary:
	var d: Dictionary = EVENTOS.get(atual(), {}).duplicate()
	var c := do_calendario()
	for chave in ["nome", "ficha", "cor", "texto", "movel", "doce"]:
		if c.has(chave):
			d[chave] = c[chave]
	return d


## "halloween-24871": o evento e a volta da roda (cada volta é uma edição nova).
## Evento de calendário: "criancas-2026" (o id e o ano em que começou).
static func edicao() -> String:
	var c := do_calendario()
	if not c.is_empty():
		return "%s-%s" % [c["id"], c["periodo"][0].substr(0, 4)]
	return "%s-%d" % [atual(), floori(dia() / float(DIAS_POR_EVENTO))]


## Dias do jogo até o tema trocar (contando hoje). Evento de calendário: dias
## de verdade até o fim.
static func dias_restantes() -> int:
	var c := do_calendario()
	if not c.is_empty():
		var fim := Time.get_unix_time_from_datetime_string(c["periodo"][1])
		var agora := Time.get_unix_time_from_datetime_string(hoje())
		return int((fim - agora) / 86400) + 1
	return DIAS_POR_EVENTO - posmod(dia(), DIAS_POR_EVENTO)


## Horas de verdade (aproximadas) até o tema trocar.
static func horas_restantes() -> int:
	if not do_calendario().is_empty():
		return dias_restantes() * 24
	var fim := (floori(dia() / float(DIAS_POR_EVENTO)) + 1) * DIAS_POR_EVENTO
	var falta := (fim * 24.0 - CicloDia.horas_jogo()) / 24.0 * CicloDia.DURACAO_DIA / 3600.0
	return maxi(1, ceili(falta))


static func _estado() -> Dictionary:
	var e: Dictionary = Progresso.vila.get("evento", {})
	if str(e.get("edicao", "")) != edicao():
		var antiga := str(e.get("edicao", ""))
		var partes := antiga.split("-")
		var de_ano := func(texto: String) -> bool: return int(texto) >= 2000 and int(texto) < 2100
		if partes.size() == 2 and partes[0] == atual() and (de_ano.call(partes[1]) or not do_calendario().is_empty()):
			# o mesmo tema continua (de uma edição de calendário para a roda ou ao
			# contrário): as fichas e prêmios continuam também
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
	var d := dados()
	# evento sem móvel ou doce próprio (ex.: os da internet): moedas e baú de ouro
	if p.has("movel"):
		p.erase("movel")
		if str(d.get("movel", "")) != "":
			p["movel"] = d["movel"]
		else:
			p["moedas"] = 150
	if p.has("doce"):
		p.erase("doce")
		if str(d.get("doce", "")) != "":
			p["doce"] = d["doce"]
		else:
			p["bau"] = "ouro"
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
