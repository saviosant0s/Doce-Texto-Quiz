class_name Torre
extends RefCounted
## Regras da TORRE DE DOCES (minigame do prédio mais alto da vila).
##
## Um andar de bolo passa de um lado para o outro em cima da torre; o toque
## solta. O pedaço que ficou para fora cai (a torre vai afinando). Soltar
## bem em cima (PERFEITO) não perde nada; 3 perfeitos seguidos alargam o
## andar de novo. Errou tudo (nada em cima da torre): acabou.
## A cada ANDARES_PERGUNTA andares vem uma pergunta rápida do quiz: acertou,
## ganha pontos e o andar volta à largura toda.
## Cada partida custa CUSTO_ACUCAR; o prêmio sai em moedas (e um baú de doce
## ao passar do recorde de 10 em 10 andares).
##
## Coordenadas: x = centro do andar (0 = meio da tela), em "pixels do jogo".

const LARGURA_BASE := 260.0
const LIMITE := 330.0  # até onde o andar vai para cada lado
const VELOCIDADE_INICIAL := 260.0
const ACELERACAO := 9.0  # a cada andar
const VELOCIDADE_MAXIMA := 620.0
const TOLERANCIA_PERFEITO := 7.0
const CRESCE_COM_PERFEITOS := 3
const CRESCIMENTO := 16.0
const ANDARES_PERGUNTA := 10
const PONTOS_ANDAR := 10
const PONTOS_PERFEITO := 15
const PONTOS_PERGUNTA := 100
const CUSTO_ACUCAR := 20
const MOEDAS_POR_ANDAR := 1

## Andares já colocados: [{"x", "largura"}]; o 0 é a base.
var andares: Array = []
## O andar que está passando: {"x", "largura", "direcao"}.
var atual := {}
var pontos := 0
var perfeitos_seguidos := 0
var perfeitos := 0
var acabou := false
var pergunta_pendente := false
var _sorteio := RandomNumberGenerator.new()


func _init(semente := -1) -> void:
	if semente >= 0:
		_sorteio.seed = semente
	else:
		_sorteio.randomize()
	andares = [{"x": 0.0, "largura": LARGURA_BASE}]
	_novo_andar()


func altura() -> int:
	return andares.size() - 1  # a base não conta


func velocidade() -> float:
	return minf(VELOCIDADE_MAXIMA, VELOCIDADE_INICIAL + ACELERACAO * altura())


func topo() -> Dictionary:
	return andares[-1]


func _novo_andar() -> void:
	var lado := -1.0 if _sorteio.randf() < 0.5 else 1.0
	atual = {"x": lado * LIMITE, "largura": topo()["largura"], "direcao": -lado}


## Move o andar que está passando (vai e volta entre -LIMITE e LIMITE).
func avancar(delta: float) -> void:
	if acabou or pergunta_pendente:
		return
	atual["x"] += atual["direcao"] * velocidade() * delta
	if absf(atual["x"]) > LIMITE:
		atual["x"] = clampf(atual["x"], -LIMITE, LIMITE)
		atual["direcao"] = -atual["direcao"]


## Solta o andar. Retorna o que aconteceu (para a tela animar):
## {"ficou": bool, "perfeito": bool, "x", "largura" (o que ficou),
##  "sobra_x", "sobra_largura" (o pedaço que cai; 0 = nada), "cresceu": bool}.
func soltar() -> Dictionary:
	if acabou or pergunta_pendente:
		return {}
	var t := topo()
	var a_esq: float = atual["x"] - atual["largura"] / 2.0
	var a_dir: float = atual["x"] + atual["largura"] / 2.0
	var t_esq: float = t["x"] - t["largura"] / 2.0
	var t_dir: float = t["x"] + t["largura"] / 2.0
	var esq := maxf(a_esq, t_esq)
	var dir := minf(a_dir, t_dir)
	if dir - esq <= 0.5:
		acabou = true
		return {"ficou": false, "perfeito": false, "x": atual["x"], "largura": 0.0,
			"sobra_x": atual["x"], "sobra_largura": atual["largura"], "cresceu": false}
	var resultado := {}
	if absf(atual["x"] - t["x"]) <= TOLERANCIA_PERFEITO:
		perfeitos_seguidos += 1
		perfeitos += 1
		var largura: float = atual["largura"]
		var cresceu := false
		if perfeitos_seguidos % CRESCE_COM_PERFEITOS == 0 and largura < LARGURA_BASE:
			largura = minf(LARGURA_BASE, largura + CRESCIMENTO)
			cresceu = true
		andares.append({"x": t["x"], "largura": largura})
		pontos += PONTOS_ANDAR + PONTOS_PERFEITO
		resultado = {"ficou": true, "perfeito": true, "x": t["x"], "largura": largura,
			"sobra_x": 0.0, "sobra_largura": 0.0, "cresceu": cresceu}
	else:
		perfeitos_seguidos = 0
		var largura := dir - esq
		var centro := (esq + dir) / 2.0
		# o pedaço que ficou para fora (de um lado só)
		var sobra_largura: float = atual["largura"] - largura
		var sobra_x := (a_esq + esq) / 2.0 if a_esq < t_esq else (dir + a_dir) / 2.0
		andares.append({"x": centro, "largura": largura})
		pontos += PONTOS_ANDAR
		resultado = {"ficou": true, "perfeito": false, "x": centro, "largura": largura,
			"sobra_x": sobra_x, "sobra_largura": sobra_largura, "cresceu": false}
	if altura() % ANDARES_PERGUNTA == 0:
		pergunta_pendente = true
	_novo_andar()
	return resultado


## Resposta da pergunta do quiz (a cada 10 andares). Acertou: pontos e o
## andar que vem volta à largura toda.
func responder(acertou: bool) -> void:
	if not pergunta_pendente:
		return
	pergunta_pendente = false
	if acertou:
		pontos += PONTOS_PERGUNTA
		topo()["largura"] = LARGURA_BASE
		atual["largura"] = LARGURA_BASE


## Uma pergunta do quiz dos níveis já liberados (para a pausa dos 10 andares).
static func sortear_pergunta(sorteio: RandomNumberGenerator = null) -> Dictionary:
	var todas := []
	for i in Jogo.niveis.size():
		if i == 0 or Progresso.nivel_liberado(i):
			todas.append_array(Jogo.niveis[i]["perguntas"])
	if todas.is_empty():
		return {}
	var r := sorteio if sorteio else RandomNumberGenerator.new()
	if not sorteio:
		r.randomize()
	return todas[r.randi() % todas.size()]


# --- Progresso -------------------------------------------------------------------

static func recorde() -> int:
	return int(Progresso.estatisticas.get("torre_recorde", 0))


## Fim da partida: moedas (1 por andar + 1 por perfeito), recorde, missão e
## XP. Um baú de doce a cada nova dezena de andares acima do recorde.
## Retorna {"moedas", "bau", "recorde_novo"}.
static func concluir(jogo: Torre) -> Dictionary:
	var antes := recorde()
	var altura := jogo.altura()
	var moedas := altura * MOEDAS_POR_ANDAR + jogo.perfeitos
	var bau := ""
	if altura / 10 > antes / 10 and altura >= 10:
		bau = "doce"
		Baus.ganhar(bau)
	if altura > antes:
		Progresso.estatisticas["torre_recorde"] = altura
	Progresso.estatisticas["torre_partidas"] = int(Progresso.estatisticas.get("torre_partidas", 0)) + 1
	Missoes.registrar("torre", altura)
	Experiencia.ganhar(Experiencia.XP_MATCH)
	if moedas > 0:
		Progresso.ganhar_moedas(moedas)  # também salva
	else:
		Progresso.salvar()
	return {"moedas": moedas, "bau": bau, "recorde_novo": altura > antes}
