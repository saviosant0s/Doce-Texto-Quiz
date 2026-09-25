class_name DoceMatch
extends RefCounted
## Regras do Doce Match (jogo de combinar 3, no Fliperama da Vila dos Doces).
## As peças são símbolos de informática desenhados por nós (NÃO os logos
## oficiais do Word/Excel): folha (W), planilha (X), gráfico, célula, tecla
## Ctrl e disquete.
##
## - O jogo tem NÍVEIS (dados/doce_match.json), cada um com jogadas e
##   objetivos: fazer pontos, coletar peças de um tipo ou limpar a gelatina
##   (camada rosa debaixo das peças). Cumpriu tudo: venceu (cada jogada que
##   sobrou vale BONUS_JOGADA). Acabaram as jogadas antes: perdeu.
## - Troca duas peças vizinhas; só vale se formar fila de 3+ iguais.
## - Peças especiais (como no Candy Crush):
##     fila de 4        -> LISTRADA (explode a linha, se a fila era deitada,
##                         ou a coluna, se era em pé)
##     fila em L ou T   -> EMBRULHADA (explode as 8 casas em volta)
##     fila de 5        -> BOMBA de cor (trocada com uma peça, some com todas
##                         as peças daquele tipo; não precisa formar fila)
##   Quando uma especial some junto com uma fila, ela explode também (e pode
##   acionar outras: é a reação em cadeia).
## - Cascata: as peças caem, novas entram por cima; filas novas valem combo.
## - Cada tentativa custa CUSTO_ACUCAR (açúcar vem dos acertos no quiz).
##
## A tela (cenas/doce_match.*) só desenha e anima; tudo o que acontece fica
## aqui, para ser testado sem tela.

enum Especial { NENHUM, LINHA, COLUNA, EMBRULHO, BOMBA }

const LARGURA := 8
const ALTURA := 8
const TIPOS := ["folha", "planilha", "grafico", "celula", "tecla", "disquete"]
const NOMES_TIPOS := {"folha": "FOLHAS DO WORD", "planilha": "PLANILHAS", "grafico": "GRÁFICOS",
	"celula": "CÉLULAS", "tecla": "TECLAS CTRL", "disquete": "DISQUETES"}
const CUSTO_ACUCAR := 30
const PONTOS_POR_PECA := 20
const BONUS_FILA_GRANDE := 60  # por peça além da 3ª numa fila
const BONUS_ESPECIAL := 100  # cada especial que explode
const BONUS_JOGADA := 250  # cada jogada que sobrou ao vencer
const BOMBA := -2  # "tipo" da bomba de cor (não forma fila com ninguém)
const CAMINHO_NIVEIS := "res://dados/doce_match.json"
## Partida livre (sem nível): o modo antigo, usado quando não se passa um nível.
const LIVRE := {"numero": 0, "jogadas": 20, "tipos": 6, "objetivos": [{"tipo": "pontos", "meta": 1200}],
	"estrelas": [1200, 2400, 3600]}

## grade[y][x] = índice em TIPOS (-1 = vazio, só durante a queda; BOMBA).
var grade: Array = []
var especial: Array = []  # [y][x] -> Especial
var gelatina: Array = []  # [y][x] -> bool
var pontos := 0
var jogadas := 0
var nivel: Dictionary
var coletados := {}  # tipo (nome) -> quantas peças daquele tipo sumiram
var gelatinas_total := 0
var _ultima_troca: Array = []  # [a, b]: onde nasce a especial da jogada
var _bomba: Array = []  # [posição da bomba, tipo que ela leva] na próxima rodada
var _sorteio := RandomNumberGenerator.new()
static var _niveis: Array = []


static func niveis() -> Array:
	if _niveis.is_empty():
		_niveis = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_NIVEIS))["niveis"]
	return _niveis


static func dados_nivel(numero: int) -> Dictionary:
	return niveis()[numero - 1] if numero >= 1 and numero <= niveis().size() else {}


func _init(dados_do_nivel: Dictionary = {}, semente := -1) -> void:
	nivel = dados_do_nivel if not dados_do_nivel.is_empty() else LIVRE
	jogadas = int(nivel["jogadas"])
	if semente >= 0:
		_sorteio.seed = semente
	else:
		_sorteio.randomize()
	for t in TIPOS:
		coletados[t] = 0
	novo_tabuleiro()


## Cópia independente (para o robô de calibragem e para testes).
func copia() -> DoceMatch:
	var c := DoceMatch.new(nivel, 0)
	c.grade = grade.duplicate(true)
	c.especial = especial.duplicate(true)
	c.gelatina = gelatina.duplicate(true)
	c.gelatinas_total = gelatinas_total
	c.pontos = pontos
	c.jogadas = jogadas
	c.coletados = coletados.duplicate()
	c._sorteio.randomize()  # a cópia não sabe quais peças vão cair
	return c


func quantos_tipos() -> int:
	return clampi(int(nivel.get("tipos", 6)), 4, TIPOS.size())


## Tabuleiro novo, sem filas prontas e com pelo menos uma troca possível. A
## gelatina vem do desenho do nível ("g" = tem gelatina).
func novo_tabuleiro() -> void:
	gelatina.clear()
	gelatinas_total = 0
	var desenho: Array = nivel.get("gelatina", [])
	for y in ALTURA:
		var linha := []
		for x in LARGURA:
			var tem: bool = y < desenho.size() and x < str(desenho[y]).length() and str(desenho[y])[x] == "g"
			linha.append(tem)
			if tem:
				gelatinas_total += 1
		gelatina.append(linha)
	while true:
		grade.clear()
		especial.clear()
		for y in ALTURA:
			var linha := []
			var linha_especial := []
			for x in LARGURA:
				var t := _sorteio.randi() % quantos_tipos()
				# evita começar com 3 iguais
				while (x >= 2 and linha[x - 1] == t and linha[x - 2] == t) \
						or (y >= 2 and grade[y - 1][x] == t and grade[y - 2][x] == t):
					t = _sorteio.randi() % quantos_tipos()
				linha.append(t)
				linha_especial.append(Especial.NENHUM)
			grade.append(linha)
			especial.append(linha_especial)
		if not jogada_possivel().is_empty():
			return


func tipo(p: Vector2i) -> int:
	return grade[p.y][p.x]


func especial_em(p: Vector2i) -> int:
	return especial[p.y][p.x]


func dentro(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < LARGURA and p.y < ALTURA


func vizinhas(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


func _trocar_na_grade(a: Vector2i, b: Vector2i) -> void:
	var t: int = grade[a.y][a.x]
	grade[a.y][a.x] = grade[b.y][b.x]
	grade[b.y][b.x] = t
	var e: int = especial[a.y][a.x]
	especial[a.y][a.x] = especial[b.y][b.x]
	especial[b.y][b.x] = e


## Tenta trocar `a` e `b`. Vale se formar fila ou se uma delas for a BOMBA.
## Se não valer, desfaz e retorna falso. Se valer, gasta uma jogada.
func trocar(a: Vector2i, b: Vector2i) -> bool:
	if acabou() or not dentro(a) or not dentro(b) or not vizinhas(a, b):
		return false
	_trocar_na_grade(a, b)
	_ultima_troca = [a, b]
	# bomba de cor: leva o tipo da peça com que foi trocada
	for par in [[b, a], [a, b]]:
		if grade[par[0].y][par[0].x] == BOMBA:
			var outro: int = grade[par[1].y][par[1].x]
			_bomba = [par[0], outro]
			jogadas -= 1
			return true
	if filas().is_empty():
		_trocar_na_grade(a, b)
		_ultima_troca = []
		return false
	jogadas -= 1
	return true


## Filas de 3+ iguais agora: [{"celulas": [Vector2i], "deitada": bool, "tipo": int}].
func _grupos() -> Array:
	var lista := []
	for y in ALTURA:
		var x := 0
		while x < LARGURA:
			var fim := x
			while fim + 1 < LARGURA and grade[y][fim + 1] == grade[y][x] and grade[y][x] >= 0:
				fim += 1
			if fim - x + 1 >= 3:
				var celulas := []
				for i in range(x, fim + 1):
					celulas.append(Vector2i(i, y))
				lista.append({"celulas": celulas, "deitada": true, "tipo": grade[y][x]})
			x = fim + 1
	for x in LARGURA:
		var y := 0
		while y < ALTURA:
			var fim := y
			while fim + 1 < ALTURA and grade[fim + 1][x] == grade[y][x] and grade[y][x] >= 0:
				fim += 1
			if fim - y + 1 >= 3:
				var celulas := []
				for i in range(y, fim + 1):
					celulas.append(Vector2i(x, i))
				lista.append({"celulas": celulas, "deitada": false, "tipo": grade[y][x]})
			y = fim + 1
	return lista


## Posições que estão em filas de 3+ iguais agora. Retorna {Vector2i: true}.
func filas() -> Dictionary:
	var marcadas := {}
	for g in _grupos():
		for c in g["celulas"]:
			marcadas[c] = true
	return marcadas


## Onde nasce a especial de um grupo: na casa trocada, se ela faz parte; senão
## no meio do grupo.
func _lugar_da_especial(celulas: Array) -> Vector2i:
	for p in _ultima_troca:
		if p in celulas:
			return p
	return celulas[celulas.size() / 2]


## Especiais que nascem desta rodada: {Vector2i: [Especial, tipo]}.
func _especiais_novas(grupos: Array) -> Dictionary:
	var novas := {}
	var usadas := {}
	# fila de 5+ -> bomba
	for g in grupos:
		if g["celulas"].size() >= 5:
			var p := _lugar_da_especial(g["celulas"])
			novas[p] = [Especial.BOMBA, BOMBA]
			for c in g["celulas"]:
				usadas[c] = true
	# L ou T (uma fila deitada e uma em pé do mesmo tipo se cruzando) -> embrulhada
	for g in grupos:
		if not g["deitada"]:
			continue
		for h in grupos:
			if h["deitada"] or h["tipo"] != g["tipo"]:
				continue
			for c in g["celulas"]:
				if c in h["celulas"] and not usadas.has(c):
					novas[c] = [Especial.EMBRULHO, g["tipo"]]
					for d in g["celulas"] + h["celulas"]:
						usadas[d] = true
	# fila de 4 -> listrada
	for g in grupos:
		if g["celulas"].size() == 4 and not g["celulas"].any(func(c): return usadas.has(c)):
			var p := _lugar_da_especial(g["celulas"])
			novas[p] = [Especial.LINHA if g["deitada"] else Especial.COLUNA, g["tipo"]]
	return novas


## Uma rodada da cascata: tira as filas (e o que as especiais explodem), faz
## as peças caírem e completa por cima. Retorna o que aconteceu (para a tela
## animar), ou {} se não havia nada: {"somem": [Vector2i], "caem": [[de,
## para]], "novas": [[Vector2i, tipo]], "ganho", "combo", "efeitos":
## [{"tipo": "linha"/"coluna"/"embrulho"/"bomba", "pos", "alvos"}],
## "criadas": [[Vector2i, Especial, tipo]], "gelatinas": [Vector2i]}.
func passo(combo: int) -> Dictionary:
	var grupos := _grupos()
	var somem := {}
	var efeitos := []
	var fila_ganho := 0
	for g in grupos:
		for c in g["celulas"]:
			somem[c] = true
		fila_ganho += maxi(0, g["celulas"].size() - 3) * BONUS_FILA_GRANDE
	if not _bomba.is_empty():
		var pos: Vector2i = _bomba[0]
		var alvo: int = _bomba[1]
		var alvos := []
		for y in ALTURA:
			for x in LARGURA:
				if (alvo == BOMBA and grade[y][x] != -1) or (alvo >= 0 and grade[y][x] == alvo):
					alvos.append(Vector2i(x, y))
					somem[Vector2i(x, y)] = true
		somem[pos] = true
		efeitos.append({"tipo": "bomba", "pos": pos, "alvos": alvos})
		_bomba = []
	if somem.is_empty():
		return {}
	var criadas := _especiais_novas(grupos)
	for p in criadas:
		somem.erase(p)
	# reação em cadeia: especiais que somem explodem também
	var fila := somem.keys()
	var disparadas := {}
	while not fila.is_empty():
		var c: Vector2i = fila.pop_back()
		var e: int = especial[c.y][c.x]
		if e == Especial.NENHUM or disparadas.has(c) or efeitos.any(func(f): return f["tipo"] == "bomba" and f["pos"] == c):
			continue
		disparadas[c] = true
		var alvos := []
		match e:
			Especial.LINHA:
				for x in LARGURA:
					alvos.append(Vector2i(x, c.y))
			Especial.COLUNA:
				for y in ALTURA:
					alvos.append(Vector2i(c.x, y))
			Especial.EMBRULHO:
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var p := c + Vector2i(dx, dy)
						if dentro(p):
							alvos.append(p)
			Especial.BOMBA:
				# bomba explodida por outra especial: leva o tipo mais comum
				var alvo := _tipo_mais_comum()
				for y in ALTURA:
					for x in LARGURA:
						if grade[y][x] == alvo:
							alvos.append(Vector2i(x, y))
		efeitos.append({"tipo": ["", "linha", "coluna", "embrulho", "bomba"][e], "pos": c, "alvos": alvos})
		for p in alvos:
			if not somem.has(p) and not criadas.has(p):
				somem[p] = true
				fila.append(p)
	var ganho := (somem.size() * PONTOS_POR_PECA + fila_ganho + disparadas.size() * BONUS_ESPECIAL) * combo
	pontos += ganho
	var gelatinas_limpas := []
	for p in somem:
		var t: int = grade[p.y][p.x]
		if t >= 0:
			coletados[TIPOS[t]] = int(coletados[TIPOS[t]]) + 1
		if gelatina[p.y][p.x]:
			gelatina[p.y][p.x] = false
			gelatinas_limpas.append(p)
		grade[p.y][p.x] = -1
		especial[p.y][p.x] = Especial.NENHUM
	var lista_criadas := []
	for p in criadas:
		especial[p.y][p.x] = criadas[p][0]
		grade[p.y][p.x] = criadas[p][1]
		lista_criadas.append([p, criadas[p][0], criadas[p][1]])
	_ultima_troca = []  # nas cascatas, a especial nasce no meio da fila
	# queda
	var caem := []
	var novas := []
	for x in LARGURA:
		var destino := ALTURA - 1
		for y in range(ALTURA - 1, -1, -1):
			if grade[y][x] != -1:
				if y != destino:
					grade[destino][x] = grade[y][x]
					especial[destino][x] = especial[y][x]
					grade[y][x] = -1
					especial[y][x] = Especial.NENHUM
					caem.append([Vector2i(x, y), Vector2i(x, destino)])
				destino -= 1
		for y in range(destino, -1, -1):
			var novo := _sorteio.randi() % quantos_tipos()
			grade[y][x] = novo
			especial[y][x] = Especial.NENHUM
			novas.append([Vector2i(x, y), novo])
	return {"somem": somem.keys(), "caem": caem, "novas": novas, "ganho": ganho, "combo": combo,
		"efeitos": efeitos, "criadas": lista_criadas, "gelatinas": gelatinas_limpas}


func _tipo_mais_comum() -> int:
	var contagem := {}
	for linha in grade:
		for t in linha:
			if t >= 0:
				contagem[t] = contagem.get(t, 0) + 1
	var melhor := 0
	for t in contagem:
		if contagem[t] > contagem.get(melhor, 0):
			melhor = t
	return melhor


## Resolve a cascata inteira de uma vez (sem animação). Retorna os passos.
## Se venceu, soma o bônus das jogadas que sobraram.
func resolver() -> Array:
	var passos := []
	var combo := 1
	while true:
		var p := passo(combo)
		if p.is_empty():
			break
		passos.append(p)
		combo += 1
	if jogada_possivel().is_empty():
		embaralhar()
	return passos


## Uma troca que vale ([a, b]), ou [] se não houver nenhuma.
func jogada_possivel() -> Array:
	for y in ALTURA:
		for x in LARGURA:
			if grade[y][x] == BOMBA:
				var a := Vector2i(x, y)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if dentro(a + d):
						return [a, a + d]
	for y in ALTURA:
		for x in LARGURA:
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var a := Vector2i(x, y)
				var b: Vector2i = a + d
				if not dentro(b):
					continue
				_trocar_na_grade(a, b)
				var forma := not filas().is_empty()
				_trocar_na_grade(a, b)
				if forma:
					return [a, b]
	return []


## Mistura as peças (com as especiais) até ter jogada e nenhuma fila pronta.
func embaralhar() -> void:
	var pecas := []
	for y in ALTURA:
		for x in LARGURA:
			pecas.append([grade[y][x], especial[y][x]])
	for tentativa in 100:
		for i in range(pecas.size() - 1, 0, -1):
			var j := _sorteio.randi_range(0, i)
			var t = pecas[i]
			pecas[i] = pecas[j]
			pecas[j] = t
		for y in ALTURA:
			for x in LARGURA:
				grade[y][x] = pecas[y * LARGURA + x][0]
				especial[y][x] = pecas[y * LARGURA + x][1]
		if filas().is_empty() and not jogada_possivel().is_empty():
			return
	var desenho := gelatina.duplicate(true)
	novo_tabuleiro()
	gelatina = desenho


# --- Objetivos, fim e estrelas --------------------------------------------------------

func gelatinas_restantes() -> int:
	var n := 0
	for linha in gelatina:
		for g in linha:
			if g:
				n += 1
	return n


## [atual, meta] de um objetivo.
func progresso_objetivo(obj: Dictionary) -> Array:
	match obj["tipo"]:
		"pontos":
			return [pontos, int(obj["meta"])]
		"coletar":
			return [mini(int(coletados[obj["peca"]]), int(obj["quantidade"])), int(obj["quantidade"])]
		"gelatina":
			return [gelatinas_total - gelatinas_restantes(), gelatinas_total]
	return [0, 1]


func objetivo_cumprido(obj: Dictionary) -> bool:
	var p := progresso_objetivo(obj)
	return p[0] >= p[1]


func venceu() -> bool:
	return nivel["objetivos"].all(func(o): return objetivo_cumprido(o))


func acabou() -> bool:
	return jogadas <= 0 or (nivel != LIVRE and venceu())


## Ao vencer: cada jogada que sobrou vira pontos. Retorna o bônus.
func bonus_de_jogadas() -> int:
	if not venceu():
		return 0
	var bonus := jogadas * BONUS_JOGADA
	pontos += bonus
	jogadas = 0
	return bonus


## Estrelas pela pontuação (METAS do nível). Vencer vale pelo menos 1; perder, 0.
func estrelas() -> int:
	var metas: Array = nivel["estrelas"]
	var n := 0
	for meta in metas:
		if pontos >= int(meta):
			n += 1
	if nivel == LIVRE:
		return n
	return maxi(n, 1) if venceu() else 0


## Moedas do modo livre (o antigo); nos níveis o prêmio vem de DoceMatch.concluir.
func moedas() -> int:
	return pontos / 100 + estrelas() * 8


static func descrever(obj: Dictionary) -> String:
	match obj["tipo"]:
		"pontos":
			return "FAÇA %s PONTOS" % Jogo.formatar(int(obj["meta"]))
		"coletar":
			return "JUNTE %d %s" % [int(obj["quantidade"]), NOMES_TIPOS[obj["peca"]]]
		"gelatina":
			return "LIMPE TODA A GELATINA"
	return ""


# --- Progresso dos níveis ---------------------------------------------------------------
## Progresso.doce_match = {"estrelas": {"1": 3, ...}}

const MOEDAS_NIVEL := 10
const MOEDAS_POR_ESTRELA := 5


static func estrelas_do_nivel(numero: int) -> int:
	return int(Progresso.doce_match.get("estrelas", {}).get(str(numero), 0))


static func liberado(numero: int) -> bool:
	return numero == 1 or estrelas_do_nivel(numero - 1) > 0


static func proximo_nivel() -> int:
	for i in range(1, niveis().size() + 1):
		if estrelas_do_nivel(i) == 0:
			return i
	return niveis().size()


static func total_estrelas() -> int:
	var n := 0
	for k in Progresso.doce_match.get("estrelas", {}):
		n += int(Progresso.doce_match["estrelas"][k])
	return n


## Baú ao vencer um nível múltiplo de 5 pela primeira vez ("" = nenhum).
static func bau_do_nivel(numero: int) -> String:
	if numero % 5 != 0:
		return ""
	return "ouro" if numero % 15 == 0 else "prata"


## Registra a vitória e dá o prêmio. Retorna {"moedas", "bau", "primeira", "novas"}.
static func concluir(numero: int, n_estrelas: int) -> Dictionary:
	var antes := estrelas_do_nivel(numero)
	var primeira := antes == 0
	var novas := maxi(0, n_estrelas - antes)
	var moedas := novas * MOEDAS_POR_ESTRELA + (MOEDAS_NIVEL if primeira else 0)
	moedas = Companheiros.com_bonus("match", moedas)
	if not Progresso.doce_match.has("estrelas"):
		Progresso.doce_match["estrelas"] = {}
	if n_estrelas > antes:
		Progresso.doce_match["estrelas"][str(numero)] = n_estrelas
	var bau := bau_do_nivel(numero) if primeira else ""
	if bau != "":
		Baus.ganhar(bau)
	if moedas > 0:
		Progresso.ganhar_moedas(moedas)  # também salva
	Progresso.salvar()
	return {"moedas": moedas, "bau": bau, "primeira": primeira, "novas": novas}
