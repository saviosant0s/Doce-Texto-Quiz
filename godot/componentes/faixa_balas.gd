@tool
class_name FaixaBalas
extends Control
## Faixa decorativa com balas embrulhadas, desenhada por código.
## Use no topo ou (com `invertida`) na base da tela.

## Borda ondulada virada para cima (para usar na base da tela).
@export var invertida := false:
	set(valor):
		invertida = valor
		queue_redraw()
## Pixels por segundo; negativo anda para a esquerda.
@export var velocidade := 18.0

const ESPACO := 86.0  # distância entre balas
const RAIO_ONDA := 14.0
const CONTORNO := Color("#3B2463")
const CORES := [Cores.ROSA, Cores.AZUL, Cores.VERDE, Cores.AMARELO, Color("#FF9F43")]

var _deslocamento := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_deslocamento = fposmod(_deslocamento + velocidade * delta, ESPACO * CORES.size())
	queue_redraw()


func _draw() -> void:
	_desenhar_faixa()
	var centro_y := (size.y - RAIO_ONDA) / 2.0 + (RAIO_ONDA if invertida else 0.0)
	var quantidade := int(size.x / ESPACO) + CORES.size() + 2
	for i in quantidade:
		var x := i * ESPACO + _deslocamento - ESPACO * CORES.size()
		if x < -ESPACO or x > size.x + ESPACO:
			continue
		var cor: Color = CORES[i % CORES.size()]
		var angulo := deg_to_rad(-18.0 if i % 2 == 0 else 14.0)
		var sobe := -4.0 if i % 2 == 0 else 4.0
		_desenhar_bala(Vector2(x, centro_y + sobe), angulo, cor)


## Fundo da faixa em roxo escuro com a borda ondulada virada para o conteúdo.
func _desenhar_faixa() -> void:
	var altura := size.y - RAIO_ONDA
	var topo := RAIO_ONDA if invertida else 0.0
	draw_rect(Rect2(0, topo, size.x, altura), Cores.ROXO_ESCURO)
	var borda_y := topo if invertida else altura
	var x := RAIO_ONDA
	while x < size.x + RAIO_ONDA:
		draw_circle(Vector2(x, borda_y), RAIO_ONDA, Cores.ROXO_ESCURO, true, -1.0, true)
		x += RAIO_ONDA * 2.0


func _desenhar_bala(centro: Vector2, angulo: float, cor: Color) -> void:
	draw_set_transform(centro, angulo, Vector2.ONE * 1.1)
	var escura := cor.darkened(0.25)
	# Pontas do papel (laços), com dobrinhas
	for lado in [-1.0, 1.0]:
		var laco := PackedVector2Array([
			Vector2(lado * 14, -4), Vector2(lado * 30, -13), Vector2(lado * 27, -4),
			Vector2(lado * 32, 0), Vector2(lado * 27, 4), Vector2(lado * 30, 13), Vector2(lado * 14, 4),
		])
		draw_colored_polygon(laco, escura)
		draw_polyline(_fechar(laco), CONTORNO, 2.5, true)
		draw_line(Vector2(lado * 16, 0), Vector2(lado * 26, 0), CONTORNO, 1.5, true)
	# Corpo da bala
	var corpo := _elipse(Vector2.ZERO, Vector2(19, 13), 24)
	draw_colored_polygon(corpo, cor)
	# Listras diagonais (recortadas dentro do corpo)
	for dx in [-8.0, 2.0, 12.0]:
		var listra := PackedVector2Array([
			Vector2(dx - 4, -12), Vector2(dx + 1, -12), Vector2(dx - 5, 12), Vector2(dx - 10, 12),
		])
		var dentro := Geometry2D.intersect_polygons(listra, corpo)
		for parte in dentro:
			draw_colored_polygon(parte, Color(Color.WHITE, 0.35))
	draw_polyline(_fechar(corpo), CONTORNO, 2.5, true)
	# Brilho
	draw_colored_polygon(_elipse(Vector2(-7, -6), Vector2(5, 2.5), 12), Color(Color.WHITE, 0.8))
	draw_set_transform(Vector2.ZERO)


func _elipse(centro: Vector2, raio: Vector2, pontos: int) -> PackedVector2Array:
	var resultado := PackedVector2Array()
	for i in pontos:
		var a := TAU * i / pontos
		resultado.append(centro + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	return resultado


func _fechar(pontos: PackedVector2Array) -> PackedVector2Array:
	var fechado := pontos.duplicate()
	fechado.append(pontos[0])
	return fechado
