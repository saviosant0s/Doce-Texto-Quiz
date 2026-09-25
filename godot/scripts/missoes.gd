class_name Missoes
## Missões do dia e da semana, e o prêmio por entrar (dias seguidos).
##
## - Todo dia sorteia 3 missões do dia (mesmas para o dia inteiro) e toda
##   semana (de segunda a domingo) 3 missões da semana, de tipos diferentes.
## - O jogo avisa o que acontece com registrar(evento, quantidade): acertos no
##   quiz, partidas, fases do laboratório, clientes da cozinha, partidas do Doce
##   Match, estrelas do quiz, baús abertos.
## - Missão cumprida: o jogador RESGATA moedas + experiência. Cumprindo as 3,
##   ganha um baú (PRATA no dia, OURO na semana).
## - Prêmio por entrar: um por dia; a sequência aumenta se entrar em dias
##   seguidos (e volta ao 1º dia se pular um). O 7º dia dá um baú de ouro.
##
## Estado em Progresso.missoes.

## Tipos de missão: texto (com %d) e quantidade no dia e na semana.
const TIPOS := {
	"acertos": {"texto": "ACERTE %d PERGUNTAS NO QUIZ", "dia": 15, "semana": 70},
	"partidas": {"texto": "JOGUE %d PARTIDAS DO QUIZ", "dia": 2, "semana": 10},
	"estrelas": {"texto": "GANHE %d ESTRELAS NO QUIZ", "dia": 3, "semana": 15},
	"lab_fases": {"texto": "FAÇA %d FASES NO LABORATÓRIO", "dia": 2, "semana": 8},
	"clientes": {"texto": "ATENDA %d CLIENTES NA CONFEITARIA", "dia": 6, "semana": 40},
	"match": {"texto": "JOGUE %d PARTIDAS DO DOCE MATCH", "dia": 1, "semana": 5},
	"baus": {"texto": "ABRA %d BAÚS SURPRESA", "dia": 2, "semana": 8},
}
const QUANTAS := 3
const PREMIO_DIA := {"moedas": 20, "xp": 25}
const PREMIO_SEMANA := {"moedas": 60, "xp": 80}
## Prêmio por entrar, do 1º ao 7º dia seguido.
const ENTRADA := [
	{"moedas": 20}, {"acucar": 30}, {"moedas": 40}, {"bau": "doce"},
	{"moedas": 60}, {"acucar": 60}, {"bau": "ouro"},
]

## Para testes: dia fixo (número de dias desde 01/01/1970); -1 = relógio.
static var dia_fixo := -1


static func padrao() -> Dictionary:
	return {"dia": -1, "diarias": [], "bonus_dia": false, "semana": -1, "semanais": [],
		"bonus_semana": false, "entrada_ultimo": -1, "entrada_sequencia": 0}


# --- Datas ---------------------------------------------------------------------------

## Dia de hoje (dias desde 01/01/1970, pelo calendário do aparelho).
static func dia() -> int:
	if dia_fixo >= 0:
		return dia_fixo
	var d := Time.get_date_dict_from_system()
	return int(Time.get_unix_time_from_datetime_dict({"year": d["year"], "month": d["month"], "day": d["day"]}) / 86400)


static func hoje() -> String:
	return str(dia())


## Semana (começando na segunda). 01/01/1970 foi uma quinta.
static func semana() -> int:
	return floori((dia() + 3) / 7.0)


# --- Sorteio e estado ---------------------------------------------------------------

static func _sortear(semente: int, periodo: String) -> Array:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = semente * (7 if periodo == "semana" else 1) + 12345
	var tipos: Array = TIPOS.keys()
	var escolhidas := []
	while escolhidas.size() < QUANTAS:
		var t: String = tipos[sorteio.randi() % tipos.size()]
		if not escolhidas.any(func(m): return m["tipo"] == t):
			escolhidas.append({"tipo": t, "meta": int(TIPOS[t][periodo]), "progresso": 0, "resgatada": false})
	return escolhidas


## Troca as missões quando muda o dia ou a semana.
static func _atualizar() -> Dictionary:
	var e := Progresso.missoes
	if int(e.get("dia", -1)) != dia():
		e["dia"] = dia()
		e["diarias"] = _sortear(dia(), "dia")
		e["bonus_dia"] = false
	if int(e.get("semana", -1)) != semana():
		e["semana"] = semana()
		e["semanais"] = _sortear(semana(), "semana")
		e["bonus_semana"] = false
	return e


static func diarias() -> Array:
	return _atualizar()["diarias"]


static func semanais() -> Array:
	return _atualizar()["semanais"]


static func texto(m: Dictionary) -> String:
	return TIPOS[m["tipo"]]["texto"] % int(m["meta"])


static func cumprida(m: Dictionary) -> bool:
	return int(m["progresso"]) >= int(m["meta"])


## O jogo avisa que algo aconteceu (conta nas missões do dia e da semana).
static func registrar(evento: String, quantidade := 1) -> void:
	if quantidade <= 0:
		return
	var e := _atualizar()
	for lista in [e["diarias"], e["semanais"]]:
		for m in lista:
			if m["tipo"] == evento:
				m["progresso"] = mini(int(m["progresso"]) + quantidade, int(m["meta"]))


## Resgata o prêmio de uma missão cumprida. `periodo` = "dia" ou "semana".
## Retorna {"moedas", "xp", "bau"} ou {} se não dava.
static func resgatar(periodo: String, indice: int) -> Dictionary:
	var lista: Array = diarias() if periodo == "dia" else semanais()
	if indice < 0 or indice >= lista.size():
		return {}
	var m: Dictionary = lista[indice]
	if not cumprida(m) or m["resgatada"]:
		return {}
	m["resgatada"] = true
	var premio: Dictionary = (PREMIO_DIA if periodo == "dia" else PREMIO_SEMANA).duplicate()
	Progresso.ganhar_moedas(premio["moedas"])
	Experiencia.ganhar(premio["xp"])
	var e := Progresso.missoes
	var chave := "bonus_dia" if periodo == "dia" else "bonus_semana"
	if not e[chave] and lista.all(func(x): return x["resgatada"]):
		e[chave] = true
		premio["bau"] = "prata" if periodo == "dia" else "ouro"
		Baus.ganhar(premio["bau"])
	Progresso.salvar()
	return premio


## Quantos prêmios estão esperando (missões cumpridas + prêmio por entrar).
static func para_resgatar() -> int:
	var n := 0
	for m in diarias() + semanais():
		if cumprida(m) and not m["resgatada"]:
			n += 1
	if entrada_disponivel():
		n += 1
	return n


# --- Prêmio por entrar --------------------------------------------------------------

static func entrada_disponivel() -> bool:
	return int(Progresso.missoes.get("entrada_ultimo", -1)) != dia()


## Em que dia da sequência o jogador está (1 a 7) se resgatar hoje.
static func dia_da_sequencia() -> int:
	var e := Progresso.missoes
	var ultimo := int(e.get("entrada_ultimo", -1))
	var seq := int(e.get("entrada_sequencia", 0))
	if ultimo == dia():
		return (seq - 1) % ENTRADA.size() + 1
	if ultimo != dia() - 1:
		seq = 0
	return seq % ENTRADA.size() + 1


## Resgata o prêmio de hoje. Retorna o prêmio (com "dia") ou {}.
static func resgatar_entrada() -> Dictionary:
	if not entrada_disponivel():
		return {}
	var numero := dia_da_sequencia()
	var e := Progresso.missoes
	var seq := int(e.get("entrada_sequencia", 0))
	e["entrada_sequencia"] = seq + 1 if int(e.get("entrada_ultimo", -1)) == dia() - 1 else 1
	e["entrada_ultimo"] = dia()
	var premio: Dictionary = ENTRADA[numero - 1].duplicate()
	premio["dia"] = numero
	if premio.has("moedas"):
		Progresso.ganhar_moedas(premio["moedas"])
	if premio.has("acucar"):
		Confeitaria.ganhar_acucar(premio["acucar"])
	if premio.has("bau"):
		Baus.ganhar(premio["bau"])
	Progresso.salvar()
	return premio
