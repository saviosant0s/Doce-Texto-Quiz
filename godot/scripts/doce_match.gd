class_name DoceMatch
extends RefCounted
## Regras do Doce Match (jogo de combinar 3, no Fliperama da Vila dos Doces).
## As peças são símbolos de informática desenhados por nós (NÃO os logos
## oficiais do Word/Excel): folha (W), planilha (X), gráfico, célula, tecla
## Ctrl e disquete.
##
## - Cada partida custa CUSTO_ACUCAR de açúcar (o mesmo da confeitaria, que
##   vem dos acertos no quiz): o minijogo não vira um jeito de ganhar moedas
##   sem estudar.
## - Tabuleiro LARGURA x ALTURA; troca duas peças vizinhas. A troca só vale se
##   formar uma fila de 3 ou mais iguais (na linha ou na coluna).
## - As filas somem, as peças de cima caem e novas entram por cima; se isso
##   formar novas filas, elas somem também (cascata), valendo mais (combo).
## - Fila de 4 ou mais vale bônus. Cada partida tem JOGADAS trocas; as
##   estrelas vêm da pontuação (METAS). Se não houver troca possível, embaralha.
##
## A tela (cenas/doce_match.*) só desenha e anima; tudo o que acontece fica
## aqui, para ser testado sem tela.

const LARGURA := 8
const ALTURA := 8
const TIPOS := ["folha", "planilha", "grafico", "celula", "tecla", "disquete"]
const JOGADAS := 20
const CUSTO_ACUCAR := 40
const METAS := [1200, 2400, 3600]  # pontos para 1, 2 e 3 estrelas
const PONTOS_POR_PECA := 20
const BONUS_FILA_GRANDE := 60  # por peça além da 3ª numa fila

## grade[y][x] = índice em TIPOS (-1 = vazio, só durante a queda).
var grade: Array = []
var pontos := 0
var jogadas := JOGADAS
var _sorteio := RandomNumberGenerator.new()


func _init(semente := -1) -> void:
	if semente >= 0:
		_sorteio.seed = semente
	else:
		_sorteio.randomize()
	novo_tabuleiro()


## Tabuleiro novo, sem filas prontas e com pelo menos uma troca possível.
func novo_tabuleiro() -> void:
	while true:
		grade.clear()
		for y in ALTURA:
			var linha := []
			for x in LARGURA:
				var tipo := _sorteio.randi() % TIPOS.size()
				# evita começar com 3 iguais
				while (x >= 2 and linha[x - 1] == tipo and linha[x - 2] == tipo) \
						or (y >= 2 and grade[y - 1][x] == tipo and grade[y - 2][x] == tipo):
					tipo = _sorteio.randi() % TIPOS.size()
				linha.append(tipo)
			grade.append(linha)
		if not jogada_possivel().is_empty():
			return


func tipo(p: Vector2i) -> int:
	return grade[p.y][p.x]


func dentro(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < LARGURA and p.y < ALTURA


func vizinhas(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


func _trocar_na_grade(a: Vector2i, b: Vector2i) -> void:
	var t: int = grade[a.y][a.x]
	grade[a.y][a.x] = grade[b.y][b.x]
	grade[b.y][b.x] = t


## Tenta trocar `a` e `b`. Se não formar fila, desfaz e retorna falso. Se
## formar, gasta uma jogada (as filas somem em resolver()).
func trocar(a: Vector2i, b: Vector2i) -> bool:
	if jogadas <= 0 or not dentro(a) or not dentro(b) or not vizinhas(a, b):
		return false
	_trocar_na_grade(a, b)
	if filas().is_empty():
		_trocar_na_grade(a, b)
		return false
	jogadas -= 1
	return true


## Posições que estão em filas de 3+ iguais agora. Retorna {Vector2i: true}.
func filas() -> Dictionary:
	var marcadas := {}
	for y in ALTURA:
		var x := 0
		while x < LARGURA:
			var fim := x
			while fim + 1 < LARGURA and grade[y][fim + 1] == grade[y][x] and grade[y][x] >= 0:
				fim += 1
			if fim - x + 1 >= 3:
				for i in range(x, fim + 1):
					marcadas[Vector2i(i, y)] = true
			x = fim + 1
	for x in LARGURA:
		var y := 0
		while y < ALTURA:
			var fim := y
			while fim + 1 < ALTURA and grade[fim + 1][x] == grade[y][x] and grade[y][x] >= 0:
				fim += 1
			if fim - y + 1 >= 3:
				for i in range(y, fim + 1):
					marcadas[Vector2i(x, i)] = true
			y = fim + 1
	return marcadas


## Uma rodada da cascata: tira as filas, faz as peças caírem e completa por
## cima. Retorna o que aconteceu (para a tela animar), ou {} se não havia
## fila: {"somem": [Vector2i], "caem": [[de, para]], "novas": [[Vector2i, tipo]],
## "ganho": pontos, "combo": n}.
func passo(combo: int) -> Dictionary:
	var marcadas := filas()
	if marcadas.is_empty():
		return {}
	var ganho := marcadas.size() * PONTOS_POR_PECA + maxi(0, marcadas.size() - 3) * BONUS_FILA_GRANDE
	ganho *= combo
	pontos += ganho
	for p in marcadas:
		grade[p.y][p.x] = -1
	var caem := []
	var novas := []
	for x in LARGURA:
		var destino := ALTURA - 1
		for y in range(ALTURA - 1, -1, -1):
			if grade[y][x] >= 0:
				if y != destino:
					grade[destino][x] = grade[y][x]
					grade[y][x] = -1
					caem.append([Vector2i(x, y), Vector2i(x, destino)])
				destino -= 1
		for y in range(destino, -1, -1):
			var novo := _sorteio.randi() % TIPOS.size()
			grade[y][x] = novo
			novas.append([Vector2i(x, y), novo])
	return {"somem": marcadas.keys(), "caem": caem, "novas": novas, "ganho": ganho, "combo": combo}


## Resolve a cascata inteira de uma vez (sem animação). Retorna os passos.
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


## Uma troca que forma fila ([a, b]), ou [] se não houver nenhuma.
func jogada_possivel() -> Array:
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


## Mistura as peças até ter jogada e nenhuma fila pronta.
func embaralhar() -> void:
	var pecas := []
	for linha in grade:
		pecas.append_array(linha)
	for tentativa in 100:
		for i in range(pecas.size() - 1, 0, -1):
			var j := _sorteio.randi_range(0, i)
			var t = pecas[i]
			pecas[i] = pecas[j]
			pecas[j] = t
		for y in ALTURA:
			for x in LARGURA:
				grade[y][x] = pecas[y * LARGURA + x]
		if filas().is_empty() and not jogada_possivel().is_empty():
			return
	novo_tabuleiro()


func estrelas() -> int:
	var n := 0
	for meta in METAS:
		if pontos >= meta:
			n += 1
	return n


func acabou() -> bool:
	return jogadas <= 0


## Moedas ganhas no fim da partida.
func moedas() -> int:
	return pontos / 100 + estrelas() * 8
