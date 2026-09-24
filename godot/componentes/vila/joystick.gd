class_name Joystick
extends Control
## Joystick na tela para andar com o dedo: arraste a bolinha na direção que
## quiser. `vetor` vai de (-1, -1) a (1, 1); (0, 0) quando solto.

const COR_BASE := Color(1, 1, 1, 0.22)
const COR_BOLINHA := Color("#F4E038")

var vetor := Vector2.ZERO
var _arrastando := false


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(190, 190)


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_arrastando = evento.pressed
		if evento.pressed:
			_atualizar(evento.position)
		else:
			vetor = Vector2.ZERO
			queue_redraw()
		accept_event()
	elif evento is InputEventMouseMotion and _arrastando:
		_atualizar(evento.position)
		accept_event()


func _atualizar(posicao: Vector2) -> void:
	var raio := size.x * 0.5
	vetor = ((posicao - size * 0.5) / (raio * 0.7)).limit_length(1.0)
	queue_redraw()


func _draw() -> void:
	var centro := size * 0.5
	var raio := size.x * 0.5
	draw_circle(centro, raio, COR_BASE)
	draw_arc(centro, raio - 3, 0, TAU, 64, Color(1, 1, 1, 0.45), 4.0, true)
	draw_circle(centro + vetor * raio * 0.55, raio * 0.36, COR_BOLINHA)
	draw_arc(centro + vetor * raio * 0.55, raio * 0.36, 0, TAU, 48, Color("#CDB91E"), 4.0, true)
