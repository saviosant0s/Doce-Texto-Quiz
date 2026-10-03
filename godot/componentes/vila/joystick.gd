class_name Joystick
extends Control
## Joystick na tela para andar com o dedo: arraste a bolinha na direção que
## quiser. `vetor` vai de (-1, -1) a (1, 1); (0, 0) quando solto.
##
## No celular, segue um dedo só (`dedo`), pelos toques de verdade: assim
## outro dedo pode girar a visão ou apertar PULAR ao mesmo tempo. No
## computador, funciona com o mouse.

const COR_BASE := Color(1, 1, 1, 0.22)
const COR_BOLINHA := Color("#F4E038")

var vetor := Vector2.ZERO
## Índice do dedo que está no joystick (-1 = nenhum).
var dedo := -1
var _mouse := false


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(190, 190)


func _input(evento: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if evento is InputEventScreenTouch:
		if evento.pressed and dedo == -1 and get_global_rect().has_point(evento.position):
			dedo = evento.index
			_atualizar(evento.position - global_position)
			get_viewport().set_input_as_handled()
		elif not evento.pressed and evento.index == dedo:
			_soltar()
			get_viewport().set_input_as_handled()
	elif evento is InputEventScreenDrag and evento.index == dedo:
		_atualizar(evento.position - global_position)
		get_viewport().set_input_as_handled()


func _gui_input(evento: InputEvent) -> void:
	# o mouse "de mentira" que o celular cria a partir do toque fica de fora
	# (o toque já é tratado em _input)
	if evento.device == InputEvent.DEVICE_ID_EMULATION:
		accept_event()
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_mouse = evento.pressed
		if evento.pressed:
			_atualizar(evento.position)
		else:
			_soltar()
		accept_event()
	elif evento is InputEventMouseMotion and _mouse:
		_atualizar(evento.position)
		accept_event()


func _soltar() -> void:
	dedo = -1
	_mouse = false
	vetor = Vector2.ZERO
	queue_redraw()


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
