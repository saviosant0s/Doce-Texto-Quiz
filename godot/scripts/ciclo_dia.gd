class_name CicloDia
## Dia e noite da Vila dos Doces pelo relógio de verdade, e o clima.
##
## - O céu, o sol (de noite, a lua), a luz ambiente e a névoa mudam com a
##   hora do celular: manhã (5h–7h clareia), dia, pôr do sol (17h–19h30) e
##   noite. À noite as janelas e luminárias acendem e aparecem estrelas e
##   vaga-lumes.
## - ESTRELA CADENTE: de noite, uma estrela cai em algum canto da vila; quem
##   chega até ela ganha açúcar e moedas (uma por noite).
## - CHUVA DE GRANULADO: em algumas horas do dia chove granulado colorido e
##   aparecem GOTAS DE GRANULADO pelo chão; cada uma dá açúcar.
## - Configurações > "Dia e noite": RELÓGIO (padrão) ou SEMPRE DIA.
##
## Estado em Progresso.vila: "estrela": noite em que já pegou ("AAAA-MM-DD"),
## "granulado": {"chuva": "AAAA-MM-DD-HH", "pegas": [índices]}.

## Para testes e prints: hora fixa (0 a 24) e dia fixo ("" = de verdade).
static var hora_fixa := -1.0
static var dia_fixo := ""
## Para testes e prints: força chuva (1), sem chuva (0) ou de verdade (-1).
static var chuva_fixa := -1

const PREMIO_ESTRELA := {"acucar": 25, "moedas": 25}
const ACUCAR_GOTA := 3
const GOTAS := 12
## Uma hora em CHANCE_CHUVA tem chuva (sorteio fixo pela data e hora).
const CHANCE_CHUVA := 6
## Onde a estrela cadente pode cair (uma por noite, sorteada pela data).
const LUGARES_ESTRELA := [Vector3(-6, 0, 5), Vector3(7, 0, 9), Vector3(-17, 0, 11), Vector3(20, 0, 3),
	Vector3(-4, 0, -21), Vector3(16, 0, -19)]

## Cores e luzes de cada momento: [dia, pôr do sol, noite].
const CEU_TOPO := [Color("#9FD4F7"), Color("#8A9FE0"), Color("#0B1030")]
const CEU_HORIZONTE := [Color("#FFD6EA"), Color("#FF9E6B"), Color("#2B2A5E")]
const COR_SOL := [Color("#FFF0D6"), Color("#FFB26B"), Color("#8098FF")]
const ENERGIA_SOL := [1.0, 0.7, 0.2]
const ALTURA_SOL := [-55.0, -14.0, -48.0]  # graus (de noite é a lua, alta)
const AMBIENTE := [1.0, 0.85, 0.45]
const NEVOA := [Color("#FFE3F0"), Color("#FFC6A8"), Color("#1C1A44")]


static func sempre_dia() -> bool:
	return bool(Progresso.config.get("sempre_dia", false))


static func escolher_sempre_dia(sim: bool) -> void:
	Progresso.config["sempre_dia"] = sim
	Progresso.salvar()


## Hora agora (0 a 24, com os minutos); meio-dia se "sempre dia".
static func hora() -> float:
	if hora_fixa >= 0.0:
		return hora_fixa
	if sempre_dia():
		return 12.0
	var t := Time.get_time_dict_from_system()
	return t["hour"] + t["minute"] / 60.0


static func hoje() -> String:
	return dia_fixo if not dia_fixo.is_empty() else Time.get_date_string_from_system()


## 0 = dia claro, 1 = noite fechada (vai e volta aos poucos).
static func noite(h := -1.0) -> float:
	if h < 0.0:
		h = hora()
	if h >= 7.0 and h <= 17.0:
		return 0.0
	if h > 17.0 and h < 19.5:
		return smoothstep(17.0, 19.5, h)
	if h > 5.0 and h < 7.0:
		return 1.0 - smoothstep(5.0, 7.0, h)
	return 1.0


## 0 a 1: o quanto é pôr (ou nascer) do sol, o céu alaranjado.
static func por_do_sol(h := -1.0) -> float:
	if h < 0.0:
		h = hora()
	var tarde := 1.0 - clampf(absf(h - 18.3) / 1.3, 0.0, 1.0)
	var manha := 1.0 - clampf(absf(h - 6.0) / 1.0, 0.0, 1.0)
	return maxf(tarde, manha)


static func fase(h := -1.0) -> String:
	if h < 0.0:
		h = hora()
	if noite(h) > 0.6:
		return "NOITE"
	if por_do_sol(h) > 0.4:
		return "PÔR DO SOL" if h > 12.0 else "AMANHECER"
	return "MANHÃ" if h < 12.0 else "TARDE"


## Mistura um valor [dia, pôr do sol, noite] para a hora `h`.
static func misturar(valores: Array, h := -1.0) -> Variant:
	var n := noite(h)
	var p := por_do_sol(h) * (1.0 - n)
	var base: Variant = lerp(valores[0], valores[2], n)
	return lerp(base, valores[1], p)


## A noite "de hoje": depois da meia-noite ainda conta a da véspera.
static func id_noite() -> String:
	var dia := hoje()
	if hora() < 12.0:
		var unix := Time.get_unix_time_from_datetime_string(dia + "T12:00:00") - 86400
		dia = Time.get_date_string_from_unix_time(unix)
	return dia


# --- Estrela cadente --------------------------------------------------------------

static func estrela_disponivel() -> bool:
	return noite() > 0.6 and str(Progresso.vila.get("estrela", "")) != id_noite()


static func lugar_estrela() -> Vector3:
	return LUGARES_ESTRELA[absi(hash(id_noite())) % LUGARES_ESTRELA.size()]


## Pega a estrela da noite. Retorna o prêmio ou {} se não tinha.
static func pegar_estrela() -> Dictionary:
	if not estrela_disponivel():
		return {}
	Progresso.vila["estrela"] = id_noite()
	Confeitaria.ganhar_acucar(PREMIO_ESTRELA["acucar"])
	Progresso.ganhar_moedas(PREMIO_ESTRELA["moedas"])  # também salva
	return PREMIO_ESTRELA.duplicate()


# --- Chuva de granulado -----------------------------------------------------------

## Identificador da hora de agora ("AAAA-MM-DD-HH").
static func id_hora() -> String:
	return "%s-%02d" % [hoje(), int(hora())]


static func chovendo() -> bool:
	if chuva_fixa >= 0:
		return chuva_fixa == 1
	if sempre_dia():
		return false
	return absi(hash("chuva" + id_hora())) % CHANCE_CHUVA == 0


## Onde ficam as gotas desta chuva (espalhadas pela praça e ruas, sorteio
## fixo pela hora: ao voltar para a vila, estão no mesmo lugar).
static func lugares_gotas() -> Array:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = hash("gotas" + id_hora())
	var lista := []
	while lista.size() < GOTAS:
		var angulo := sorteio.randf() * TAU
		var raio := sorteio.randf_range(5.5, 16.0)
		var p := Vector3(cos(angulo) * raio, 0, sin(angulo) * raio + 2.0)
		if lugar_livre(p):
			lista.append(p)
	return lista


## Se dá para chegar no ponto (fora dos prédios, dos terrenos, do lago, do
## mirante e da fonte da praça). Usado para espalhar gotas e objetos.
static func lugar_livre(p: Vector3) -> bool:
	var chao := Vector2(p.x, p.z)
	if chao.length() < 5.0 or absf(p.x) > 34.0 or absf(p.z) > 34.0:
		return false
	for predio in Vila.PREDIOS:
		var pos: Vector3 = predio["posicao"]
		if chao.distance_to(Vector2(pos.x, pos.z)) < 5.0:
			return false
	for lote in Terrenos.LOTES:
		var pos: Vector3 = lote["posicao"]
		if absf(p.x - pos.x) < Terrenos.TAMANHO_LOTE / 2.0 + 1.0 and absf(p.z - pos.z) < Terrenos.TAMANHO_LOTE / 2.0 + 1.0:
			return false
	for lugar in Terrenos.LUGARES:
		var pos: Vector3 = Terrenos.LUGARES[lugar]["posicao"]
		if chao.distance_to(Vector2(pos.x, pos.z)) < 8.0:
			return false
	return true


static func _granulado() -> Dictionary:
	var g: Dictionary = Progresso.vila.get("granulado", {})
	if str(g.get("chuva", "")) != id_hora():
		g = {"chuva": id_hora(), "pegas": []}
		Progresso.vila["granulado"] = g
	return g


static func gota_pega(indice: int) -> bool:
	return int(indice) in _granulado()["pegas"].map(func(i): return int(i))


## Pega a gota `indice` desta chuva. Retorna o açúcar ganho (0 se já pegou).
static func pegar_gota(indice: int) -> int:
	if not chovendo() or indice < 0 or indice >= GOTAS or gota_pega(indice):
		return 0
	_granulado()["pegas"].append(indice)
	Confeitaria.ganhar_acucar(ACUCAR_GOTA)  # também salva
	return ACUCAR_GOTA
