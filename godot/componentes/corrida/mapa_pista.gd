class_name MapaPista
extends Control
## Desenho da pista vista de cima: o minimapa da corrida (com os karts, nas
## cores de cada um; o seu é maior e tem borda branca) e o mapinha de cada GP
## nos cartões de escolher o GP (sem karts).

const CORES_KARTS := ["#F4E038", "#FF6FAE", "#6FD3FF", "#7BE07B"]

## A corrida, para desenhar os karts (null = só a pista).
var corrida: Corrida
var cor_pista := Color("#FFF6EE")
var cor_borda := Color("#2E1D4A")
var largura := 5.0
var _linha := PackedVector2Array()  # a pista em coordenadas do mundo (x, z)
var _portais := PackedVector2Array()
var _min := Vector2.ZERO
var _max := Vector2.ONE


## Pista de um GP (GPs.LISTA) ou da corrida em andamento.
func usar_gp(gp: Dictionary) -> void:
	_montar(Corrida.montar_curva(gp["pontos"]), gp["portais"])


func usar_corrida(c: Corrida) -> void:
	corrida = c
	_montar(c.curva, c.portais_em)


func _montar(curva: Curve3D, portais: Array) -> void:
	_linha.clear()
	var comprimento := curva.get_baked_length()
	var passos := 120
	for i in passos + 1:
		var p := curva.sample_baked(comprimento * i / passos)
		_linha.append(Vector2(p.x, p.z))
	_portais.clear()
	for p: Vector3 in portais:
		_portais.append(Vector2(p.x, p.z))
	_min = _linha[0]
	_max = _linha[0]
	for p in _linha:
		_min = _min.min(p)
		_max = _max.max(p)
	queue_redraw()


func _process(_delta: float) -> void:
	if corrida and is_visible_in_tree():
		queue_redraw()


## Do mundo (x, z) para o desenho, cabendo no tamanho do controle (com margem).
func _no_mapa(p: Vector2) -> Vector2:
	var area := size - Vector2.ONE * (largura * 2.0 + 8.0)
	var tamanho := (_max - _min).max(Vector2.ONE)
	var escala := minf(area.x / tamanho.x, area.y / tamanho.y)
	var sobra := area - tamanho * escala
	return Vector2.ONE * (largura + 4.0) + sobra / 2.0 + (p - _min) * escala


func _draw() -> void:
	if _linha.size() < 2:
		return
	var pontos := PackedVector2Array()
	for p in _linha:
		pontos.append(_no_mapa(p))
	draw_polyline(pontos, cor_borda, largura + 4.0, true)
	draw_polyline(pontos, cor_pista, largura, true)
	# largada (quadradinho xadrez) e portais do quiz (bolinhas amarelas)
	draw_circle(pontos[0], largura * 0.9, Color.WHITE)
	draw_circle(pontos[0], largura * 0.55, cor_borda)
	for p in _portais:
		draw_circle(_no_mapa(p), largura * 0.75, Color("#FFD23F"))
	if corrida == null:
		return
	# os karts (o do jogador por cima de todos)
	for i in range(corrida.corredores.size() - 1, -1, -1):
		var c: Dictionary = corrida.corredores[i]
		var p := corrida.ponto(c["s"], c["x"])
		var no_mapa := _no_mapa(Vector2(p.x, p.z))
		var raio := largura * (1.25 if i == 0 else 0.95)
		draw_circle(no_mapa, raio + 2.0, Color.WHITE if i == 0 else cor_borda)
		draw_circle(no_mapa, raio, Color(CORES_KARTS[i % CORES_KARTS.size()]))
