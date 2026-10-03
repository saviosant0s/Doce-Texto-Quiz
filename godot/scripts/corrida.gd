class_name Corrida
extends RefCounted
## Regras da CORRIDA DE DOCES (minigame da Pista, na vila).
##
## Quatro karts de doce dão VOLTAS voltas numa pista fechada que passa pela
## vila, pela ponte do Lago de Morango, pelo Bosque de Pirulitos e pela
## Montanha de Sorvete. Os karts andam sozinhos pela pista; o jogador só vira
## para os lados (◀ ▶, joystick ou teclado).
## - PORTAIS DO QUIZ: um pouco antes de cada portal tudo fica em câmera lenta
##   e aparece uma pergunta; cada alternativa é uma faixa colorida do portal
##   (A, B, C, D). Passou pela faixa certa: TURBO; pela errada: fica lento.
##   Tocar na resposta leva o kart sozinho até a faixa dela.
## - Setas no chão dão um turbo curtinho; poças de calda deixam lento; blocos
##   de gelatina dão uma trombada (perde velocidade).
## - Cubos de açúcar: cada um vale 1 açúcar no fim (e deixa o kart 1% mais
##   rápido, até 10%).
## Jogar é de graça; o prêmio depende do lugar (PREMIOS) e dos cubos.
##
## Coordenadas: `s` = metros andados desde a largada (todas as voltas
## juntas; negativo = atrás da linha) e `x` = de lado, do meio da pista
## (positivo = direita de quem corre).
##
## Estado em Progresso.estatisticas: corrida_partidas, corrida_vitorias e
## corrida_recorde (segundos; 0 = nenhuma ainda).

const VOLTAS := 2
const MEIA_LARGURA := 6.0
const FAIXAS := [-4.5, -1.5, 1.5, 4.5]  # das alternativas A, B, C, D (nos portais)
const VELOCIDADE := 25.0  # metros por segundo
const LATERAL := 10.0  # virando para o lado
const CONTAGEM := 3.0  # 3, 2, 1, JÁ!
const TURBO := 1.55
const TEMPO_TURBO := 3.0  # acertou no portal
const TEMPO_TURBO_SETA := 1.4
const LENTO := 0.55
const TEMPO_LENTO := 2.0  # errou no portal
const TEMPO_POCA := 1.1
const BATIDA := 0.35  # sobra da velocidade numa trombada
const BONUS_CUBO := 0.01
const CUBOS_BONUS_MAXIMO := 10
const BONUS_NIVEL := 0.015  # o seu doce: +1,5% de velocidade por nível acima do 1
## Metros antes do portal em que a pergunta aparece e a corrida fica lenta.
const AVISO_PORTAL := 55.0
const RITMO_PERGUNTA := 0.12  # velocidade do tempo enquanto a pergunta não é respondida
## Prêmio pelo lugar (1º ao 4º); os cubos somam açúcar.
const PREMIOS := [{"moedas": 40, "acucar": 30}, {"moedas": 25, "acucar": 20},
	{"moedas": 15, "acucar": 15}, {"moedas": 5, "acucar": 10}]
const CORES_FAIXAS := ["#E8364F", "#2E9BE8", "#F2C230", "#4CC36B"]

## O desenho da pista (os pontos por onde ela passa; y = altura). Fecha no
## primeiro. Ver ZONAS.
const PONTOS := [
	Vector3(0, 0, 0), Vector3(0, 0, -45), Vector3(8, 0, -75), Vector3(32, 0, -90),
	Vector3(60, 1.6, -92), Vector3(95, 1.6, -92), Vector3(122, 0, -84), Vector3(134, 0, -62),
	Vector3(126, 0, -38), Vector3(136, 0, -14), Vector3(126, 0, 10), Vector3(108, 3, 30),
	Vector3(82, 7, 42), Vector3(56, 7, 42), Vector3(32, 3, 38), Vector3(10, 0, 26), Vector3(1, 0, 12),
]
## Trechos da pista: começam no ponto `de` (índice em PONTOS).
const ZONAS := [
	{"id": "vila", "nome": "VILA DOS DOCES", "de": 0},
	{"id": "lago", "nome": "LAGO DE MORANGO", "de": 3},
	{"id": "bosque", "nome": "BOSQUE DE PIRULITOS", "de": 6},
	{"id": "montanha", "nome": "MONTANHA DE SORVETE", "de": 10},
	{"id": "vila", "nome": "VILA DOS DOCES", "de": 14},
]
## Portais do quiz (em cada volta): no fim da ponte e no alto da montanha.
const PORTAIS_EM := [Vector3(95, 1.6, -92), Vector3(66, 7, 42)]
## Coisas na pista: [fração da volta, x].
const SETAS := [[0.07, 0.0], [0.19, -3.0], [0.45, 3.0], [0.6, -2.5], [0.92, 2.5]]
const POCAS := [[0.13, 2.5], [0.41, -3.5], [0.52, -1.0], [0.64, 3.5], [0.97, -3.0]]
const BLOCOS := [[0.21, -2.0], [0.48, 0.5], [0.57, 2.0], [0.88, -1.5]]
## Fileiras de 5 cubos: [fração, x do primeiro, x do último].
const CUBOS := [[0.03, 0.0, 0.0], [0.1, -4.0, 4.0], [0.16, 3.5, 3.5], [0.4, 4.0, -4.0],
	[0.5, -4.5, -4.5], [0.62, 0.0, 0.0], [0.85, -3.0, 3.0], [0.94, 4.5, 4.5]]

var curva: Curve3D
var comprimento := 0.0
## Corredores (o 0 é o jogador): {"doce", "nome", "jogador", "s", "x", "v",
## "turbo", "lento", "alvo_x", "habilidade", "fim" (segundos; -1 = correndo),
## "acertos", "proximo_portal", "faixa_portal", "pensar"}.
var corredores: Array = []
var tempo := 0.0
var contagem := CONTAGEM
var ritmo := 1.0
## Para onde o jogador está virando (-1 esquerda, 0 reto, 1 direita).
var direcao := 0.0
var cubos := 0
var acabou := false
## Portais (metros desde a largada, todas as voltas) e a pergunta de cada um.
var portais: Array = []
var perguntas: Array = []
## Pergunta na tela (índice em `portais`; -1 = nenhuma) e a escolha (-1 = não respondeu).
var portal_ativo := -1
var escolha := -1
## Elementos: {"s" (na volta), "x"} (+ "pego": volta em que foi pego, nos cubos).
var setas: Array = []
var pocas: Array = []
var blocos: Array = []
var cubos_pista: Array = []
var _sorteio := RandomNumberGenerator.new()


func _init(semente := -1, rivais: Array = []) -> void:
	if semente >= 0:
		_sorteio.seed = semente
	else:
		_sorteio.randomize()
	curva = montar_curva()
	comprimento = curva.get_baked_length()
	for volta in VOLTAS:
		for p in PORTAIS_EM:
			portais.append(volta * comprimento + curva.get_closest_offset(p))
	_sortear_perguntas()
	_espalhar_coisas()
	var meu := Colecao.companheiro()
	if meu == "" or not Colecao.tem(meu):
		meu = "brigadeiro"
	if rivais.is_empty():
		rivais = sortear_rivais(meu, _sorteio)
	var nivel := Companheiros.nivel(meu)
	_novo_corredor(meu, true, 0.0, 1.0 + BONUS_NIVEL * (nivel - 1))
	var base := 0.35 + 0.1 * mini(vitorias(), 5)
	for i in rivais.size():
		_novo_corredor(rivais[i], false, clampf(base + 0.07 * i, 0.0, 0.95), 0.0)
	# largada em fila dupla atrás da linha (o jogador por último, para ultrapassar)
	var grade := [[-4.0, -2.2], [-4.0, 2.2], [-9.0, -2.2], [-9.5, 2.2]]
	var ordem := range(1, corredores.size()) + [0]
	for k in ordem.size():
		var c: Dictionary = corredores[ordem[k]]
		c["s"] = grade[k][0]
		c["x"] = grade[k][1]
		c["alvo_x"] = grade[k][1]


## A pista como curva suave que passa por PONTOS (fechada).
static func montar_curva() -> Curve3D:
	var c := Curve3D.new()
	c.bake_interval = 0.5
	var n := PONTOS.size()
	for i in n + 1:
		var p: Vector3 = PONTOS[i % n]
		var tangente: Vector3 = (PONTOS[(i + 1) % n] - PONTOS[(i - 1 + n) % n]) / 6.0
		c.add_point(p, -tangente, tangente)
	return c


## Três doces da coleção para correr contra (sem o do jogador).
static func sortear_rivais(meu: String, sorteio: RandomNumberGenerator) -> Array:
	var ids := []
	for d in Colecao.LISTA:
		if d["id"] != meu:
			ids.append(d["id"])
	var escolhidos := []
	for i in 3:
		var k := sorteio.randi() % ids.size()
		escolhidos.append(ids[k])
		ids.remove_at(k)
	return escolhidos


func _novo_corredor(doce: String, jogador: bool, habilidade: float, bonus: float) -> void:
	var dados := Colecao.dados(doce)
	corredores.append({"doce": doce, "nome": "VOCÊ" if jogador else str(dados.get("nome", doce.to_upper())),
		"jogador": jogador, "s": 0.0, "x": 0.0, "v": 0.0, "turbo": 0.0, "lento": 0.0, "alvo_x": 0.0,
		"habilidade": habilidade, "fator": bonus if jogador else 0.9 + 0.08 * habilidade, "fim": -1.0,
		"acertos": 0, "proximo_portal": 0, "faixa_portal": -1, "pensar": 0.0, "auto": false})


## As perguntas dos portais (fácil; médio e difícil entram com os títulos), sem repetir.
func _sortear_perguntas() -> void:
	var niveis := [0]
	if Quiz.tem_titulo("noob"):
		niveis.append(1)
	if Quiz.tem_titulo("pro"):
		niveis.append(2)
	var banco := []
	for n in niveis:
		banco.append_array(Jogo.niveis[n]["perguntas"])
	for i in portais.size():
		var original: Dictionary = banco.pop_at(_sorteio.randi() % banco.size())
		var alternativas: Array = original["alternativas"].duplicate()
		var correta: String = alternativas[int(original["resposta"])]
		for k in range(alternativas.size() - 1, 0, -1):
			var j := _sorteio.randi() % (k + 1)
			var troca = alternativas[k]
			alternativas[k] = alternativas[j]
			alternativas[j] = troca
		perguntas.append({"id": original["id"], "enunciado": original["enunciado"],
			"alternativas": alternativas, "resposta": alternativas.find(correta)})


## Setas, poças, blocos e cubos (fora do corredor de cada portal, que fica limpo).
func _espalhar_coisas() -> void:
	for e in SETAS:
		_colocar(setas, e[0], e[1])
	for e in POCAS:
		_colocar(pocas, e[0], e[1])
	for e in BLOCOS:
		_colocar(blocos, e[0], e[1])
	for fila in CUBOS:
		for k in 5:
			var s: float = fila[0] * comprimento + k * 3.0
			if _livre(s):
				cubos_pista.append({"s": s, "x": lerpf(fila[1], fila[2], k / 4.0), "pego": -1})


func _colocar(lista: Array, fracao: float, x: float) -> void:
	var s := fracao * comprimento
	if _livre(s):
		lista.append({"s": s, "x": x})


func _livre(s: float) -> bool:
	for p in portais.slice(0, PORTAIS_EM.size()):
		if s > p - AVISO_PORTAL - 4.0 and s < p + 10.0:
			return false
	return s > 10.0  # a largada também fica limpa


# --- Pista ------------------------------------------------------------------------------

## Ponto da pista: `s` metros desde a largada, `x` de lado (positivo = direita).
func ponto(s: float, x := 0.0) -> Vector3:
	var o := fposmod(s, comprimento)
	return curva.sample_baked(o, true) + lado(s) * x


## Para onde a pista vai em `s` (vetor de tamanho 1).
func frente(s: float) -> Vector3:
	var a := curva.sample_baked(fposmod(s - 0.5, comprimento), true)
	var b := curva.sample_baked(fposmod(s + 0.5, comprimento), true)
	return (b - a).normalized()


## Direita de quem corre em `s` (sempre na horizontal).
func lado(s: float) -> Vector3:
	var f := frente(s)
	return Vector3(-f.z, 0, f.x).normalized()


## Trecho da pista em `s` (ver ZONAS).
func zona(s: float) -> Dictionary:
	var o := fposmod(s, comprimento)
	var atual: Dictionary = ZONAS[0]
	for z in ZONAS:
		if o >= curva.get_closest_offset(PONTOS[z["de"]]) - 0.01:
			atual = z
	return atual


# --- Andamento --------------------------------------------------------------------------

## Põe o corredor `i` em `s` (metros) e `x`, já de olho no próximo portal
## (para as capturas de tela e os testes).
func colocar(i: int, s: float, x: float) -> void:
	var c: Dictionary = corredores[i]
	c["s"] = s
	c["x"] = x
	c["alvo_x"] = x
	c["proximo_portal"] = portais.size()
	for k in portais.size():
		if portais[k] > s:
			c["proximo_portal"] = k
			break


func jogador() -> Dictionary:
	return corredores[0]


## Volta em que o corredor está (1 a VOLTAS).
func volta(i := 0) -> int:
	return clampi(floori(corredores[i]["s"] / comprimento) + 1, 1, VOLTAS)


## Lugar do corredor agora (1 = primeiro).
func colocacao(i := 0) -> int:
	return ranking().find(i) + 1


## Índices dos corredores do primeiro ao último.
func ranking() -> Array:
	var ordem := range(corredores.size())
	ordem.sort_custom(func(a, b):
		var ca: Dictionary = corredores[a]
		var cb: Dictionary = corredores[b]
		if ca["fim"] >= 0.0 and cb["fim"] >= 0.0:
			return ca["fim"] < cb["fim"]
		if ca["fim"] >= 0.0 or cb["fim"] >= 0.0:
			return ca["fim"] >= 0.0
		return ca["s"] > cb["s"])
	return ordem


## Quanto falta (0 a 1) até o portal da pergunta na tela.
func falta_portal() -> float:
	if portal_ativo < 0:
		return 0.0
	return clampf((portais[portal_ativo] - jogador()["s"]) / AVISO_PORTAL, 0.0, 1.0)


func pergunta() -> Dictionary:
	return perguntas[portal_ativo] if portal_ativo >= 0 else {}


## O jogador tocou numa resposta: o kart vai sozinho para a faixa dela e o
## tempo volta ao normal.
func escolher(k: int) -> void:
	if portal_ativo < 0 or escolha >= 0:
		return
	escolha = k
	var c := jogador()
	c["alvo_x"] = FAIXAS[k]
	c["auto"] = true


## Faixa do portal (0 a 3) mais perto de `x`.
static func faixa_de(x: float) -> int:
	var melhor := 0
	for k in FAIXAS.size():
		if absf(x - FAIXAS[k]) < absf(x - FAIXAS[melhor]):
			melhor = k
	return melhor


## Avança a corrida `delta` segundos (de verdade). Retorna o que aconteceu,
## para a tela animar: [{"tipo": "largada" | "pergunta" | "portal" | "seta" |
## "poca" | "batida" | "cubo" | "volta" | "chegada" | "fim", ...}].
func avancar(delta: float) -> Array:
	var eventos: Array = []
	if acabou:
		return eventos
	if contagem > 0.0:
		contagem -= delta
		if contagem <= 0.0:
			eventos.append({"tipo": "largada"})
		return eventos
	var alvo_ritmo := RITMO_PERGUNTA if portal_ativo >= 0 and escolha < 0 else 1.0
	ritmo = move_toward(ritmo, alvo_ritmo, delta * (5.0 if alvo_ritmo < ritmo else 1.6))
	var dt := delta * ritmo
	tempo += dt
	for i in corredores.size():
		_mover(i, dt, eventos)
	_empurroes()
	return eventos


func _velocidade_alvo(c: Dictionary) -> float:
	var v: float = VELOCIDADE * c["fator"]
	if c["jogador"]:
		v *= 1.0 + BONUS_CUBO * mini(cubos, CUBOS_BONUS_MAXIMO)
	else:
		# os rivais não fogem nem ficam muito para trás (a corrida fica disputada)
		var diferenca: float = c["s"] - jogador()["s"]
		if diferenca > 30.0:
			v *= 0.93
		elif diferenca < -30.0:
			v *= 1.04
	if c["turbo"] > 0.0:
		v *= TURBO
	if c["lento"] > 0.0:
		v *= LENTO
	if c["fim"] >= 0.0:
		v *= 0.6  # depois da chegada, devagar
	return v


func _mover(i: int, dt: float, eventos: Array) -> void:
	var c: Dictionary = corredores[i]
	var alvo := _velocidade_alvo(c)
	c["v"] = lerpf(c["v"], alvo, 1.0 - exp(-dt * (2.2 if alvo > c["v"] else 4.0)))
	c["turbo"] = maxf(0.0, c["turbo"] - dt)
	c["lento"] = maxf(0.0, c["lento"] - dt)
	var antes: float = c["s"]
	c["s"] = antes + c["v"] * dt
	if c["jogador"]:
		if direcao != 0.0:
			c["auto"] = false
			c["x"] = c["x"] + direcao * LATERAL * dt
		elif c["auto"]:
			c["x"] = move_toward(c["x"], c["alvo_x"], LATERAL * dt)
	else:
		_pilotar(c, dt)
		c["x"] = move_toward(c["x"], c["alvo_x"], LATERAL * 0.8 * dt)
	c["x"] = clampf(c["x"], -MEIA_LARGURA + 0.9, MEIA_LARGURA - 0.9)
	_passar_coisas(i, antes, c["s"], eventos)
	_passar_portal(i, eventos)
	# volta completa e chegada
	if c["fim"] < 0.0:
		if floori(c["s"] / comprimento) > floori(antes / comprimento) and antes >= 0.0 and c["s"] < VOLTAS * comprimento:
			eventos.append({"tipo": "volta", "quem": i, "volta": volta(i)})
		if c["s"] >= VOLTAS * comprimento:
			c["fim"] = tempo
			eventos.append({"tipo": "chegada", "quem": i, "lugar": colocacao(i)})
			if c["jogador"]:
				_terminar()
				eventos.append({"tipo": "fim", "lugar": colocacao(0)})


## Rivais: desviam do que tem pela frente, às vezes pegam as setas e, perto
## do portal, escolhem uma faixa (a certa, conforme a habilidade).
func _pilotar(c: Dictionary, dt: float) -> void:
	var p: int = c["proximo_portal"]
	if p < portais.size() and c["s"] > portais[p] - AVISO_PORTAL * 0.8:
		if c["faixa_portal"] < 0:
			var certa: int = perguntas[p]["resposta"]
			if _sorteio.randf() < 0.4 + 0.4 * c["habilidade"]:
				c["faixa_portal"] = certa
			else:
				c["faixa_portal"] = (certa + 1 + _sorteio.randi() % 3) % 4
		c["alvo_x"] = FAIXAS[c["faixa_portal"]]
		return
	c["pensar"] -= dt
	if c["pensar"] <= 0.0:
		c["pensar"] = _sorteio.randf_range(0.8, 2.2)
		c["alvo_x"] = _sorteio.randf_range(-4.0, 4.0)
		for e in setas:
			var falta := _distancia_a_frente(c["s"], e["s"])
			if falta > 0.0 and falta < 35.0 and _sorteio.randf() < c["habilidade"]:
				c["alvo_x"] = e["x"]
	for e in pocas + blocos:
		var falta := _distancia_a_frente(c["s"], e["s"])
		if falta > 0.0 and falta < 22.0 and absf(c["alvo_x"] - e["x"]) < 2.2:
			c["alvo_x"] = e["x"] + (2.8 if e["x"] < 0.0 else -2.8)


## Metros de `s` até a coisa em `s_coisa` (na volta) logo à frente.
func _distancia_a_frente(s: float, s_coisa: float) -> float:
	return fposmod(s_coisa - fposmod(s, comprimento), comprimento)


## Passou por cima de uma seta, poça, bloco ou cubo entre `antes` e `depois`?
func _passar_coisas(i: int, antes: float, depois: float, eventos: Array) -> void:
	if antes < 0.0:
		return
	var c: Dictionary = corredores[i]
	for e in setas:
		if _cruzou(antes, depois, e["s"]) and absf(c["x"] - e["x"]) < 1.6:
			c["turbo"] = maxf(c["turbo"], TEMPO_TURBO_SETA)
			c["lento"] = 0.0
			eventos.append({"tipo": "seta", "quem": i})
	for e in pocas:
		if _cruzou(antes, depois, e["s"]) and absf(c["x"] - e["x"]) < 1.8:
			c["lento"] = maxf(c["lento"], TEMPO_POCA)
			eventos.append({"tipo": "poca", "quem": i})
	for e in blocos:
		if _cruzou(antes, depois, e["s"]) and absf(c["x"] - e["x"]) < 1.5:
			c["v"] = c["v"] * BATIDA
			c["turbo"] = 0.0
			eventos.append({"tipo": "batida", "quem": i})
	if c["jogador"]:
		var v := volta(i)
		for k in cubos_pista.size():
			var e: Dictionary = cubos_pista[k]
			if e["pego"] != v and _cruzou(antes, depois, e["s"]) and absf(c["x"] - e["x"]) < 1.3:
				e["pego"] = v
				cubos += 1
				eventos.append({"tipo": "cubo", "quem": i, "cubo": k})


func _cruzou(antes: float, depois: float, s_coisa: float) -> bool:
	var base := floorf(antes / comprimento) * comprimento
	var alvo := base + s_coisa
	if alvo < antes:
		alvo += comprimento
	return alvo <= depois


func _passar_portal(i: int, eventos: Array) -> void:
	var c: Dictionary = corredores[i]
	var p: int = c["proximo_portal"]
	if p >= portais.size():
		return
	if c["jogador"] and portal_ativo < 0 and c["s"] >= portais[p] - AVISO_PORTAL:
		portal_ativo = p
		escolha = -1
		eventos.append({"tipo": "pergunta", "portal": p})
	if c["s"] < portais[p]:
		return
	var faixa := faixa_de(c["x"])
	var acertou: bool = faixa == int(perguntas[p]["resposta"])
	if acertou:
		c["turbo"] = TEMPO_TURBO
		c["lento"] = 0.0
		c["acertos"] += 1
	else:
		c["lento"] = TEMPO_LENTO
		c["turbo"] = 0.0
	c["proximo_portal"] = p + 1
	c["faixa_portal"] = -1
	c["pensar"] = 0.0
	eventos.append({"tipo": "portal", "quem": i, "portal": p, "faixa": faixa, "acertou": acertou})
	if c["jogador"]:
		portal_ativo = -1
		escolha = -1
		c["auto"] = false


## Karts lado a lado se empurram (e quem vem atrás perde um pouco).
func _empurroes() -> void:
	for a in corredores.size():
		for b in range(a + 1, corredores.size()):
			var ca: Dictionary = corredores[a]
			var cb: Dictionary = corredores[b]
			var ds: float = ca["s"] - cb["s"]
			var dx: float = ca["x"] - cb["x"]
			if absf(ds) < 2.4 and absf(dx) < 1.7:
				var empurra := (1.7 - absf(dx)) * 0.5 * (1.0 if dx >= 0.0 else -1.0)
				ca["x"] = clampf(ca["x"] + empurra, -MEIA_LARGURA + 0.9, MEIA_LARGURA - 0.9)
				cb["x"] = clampf(cb["x"] - empurra, -MEIA_LARGURA + 0.9, MEIA_LARGURA - 0.9)
				var atras: Dictionary = cb if ds > 0.0 else ca
				atras["v"] = atras["v"] * 0.98


## O jogador chegou: os outros terminam com o tempo que fariam no ritmo de agora.
func _terminar() -> void:
	acabou = true
	for c in corredores:
		if c["fim"] < 0.0:
			var falta: float = VOLTAS * comprimento - c["s"]
			c["fim"] = tempo + falta / maxf(VELOCIDADE * 0.8, c["v"])


# --- Fim da corrida ---------------------------------------------------------------------

static func recorde() -> float:
	return float(Progresso.estatisticas.get("corrida_recorde", 0.0))


static func vitorias() -> int:
	return int(Progresso.estatisticas.get("corrida_vitorias", 0))


## Prêmio pelo lugar + 1 açúcar por cubo; ganhar com tempo recorde dá um baú
## de doce. Retorna {"lugar", "tempo", "moedas", "acucar", "bau", "recorde_novo"}.
func concluir() -> Dictionary:
	if not acabou:
		return {}
	var lugar := colocacao(0)
	var meu_tempo: float = jogador()["fim"]
	var premio: Dictionary = PREMIOS[lugar - 1]
	var acucar := Companheiros.com_bonus("acucar", int(premio["acucar"]) + cubos)
	var moedas: int = premio["moedas"]
	var antes := recorde()
	var recorde_novo := antes <= 0.0 or meu_tempo < antes
	if recorde_novo:
		Progresso.estatisticas["corrida_recorde"] = snappedf(meu_tempo, 0.01)
	var bau := ""
	if lugar == 1 and recorde_novo:
		bau = "doce"
		Baus.ganhar(bau)
	if lugar == 1:
		Progresso.estatisticas["corrida_vitorias"] = vitorias() + 1
	Progresso.estatisticas["corrida_partidas"] = int(Progresso.estatisticas.get("corrida_partidas", 0)) + 1
	Confeitaria.ganhar_acucar(acucar)
	Missoes.registrar("corrida", 1)
	Experiencia.ganhar(Experiencia.XP_MATCH)
	Progresso.ganhar_moedas(moedas)  # também salva
	return {"lugar": lugar, "tempo": meu_tempo, "moedas": moedas, "acucar": acucar, "bau": bau,
		"recorde_novo": recorde_novo}


## "1:05.3"
static func texto_tempo(segundos: float) -> String:
	var s := maxf(0.0, segundos)
	return "%d:%04.1f" % [floori(s / 60.0), fmod(s, 60.0)]
