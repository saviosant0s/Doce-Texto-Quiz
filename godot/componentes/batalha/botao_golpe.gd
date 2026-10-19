class_name BotaoGolpe
extends Control
## Botão REDONDO de golpe da batalha (como os dos jogos de futebol do
## celular): a bola colorida com o nome, a recarga girando por cima (um
## "relógio" escuro que vai sumindo) e, quando `aceso`, um anel pulsando (o
## GOLPE SUPREMO pronto).
##
## Como o Joystick, segue os toques de verdade: dá para apertar com um dedo
## enquanto outro dedo segura o joystick. No computador, funciona com o mouse.

signal apertado

var cor := Color("#4FA3FF")
var texto := ""
## Texto pequeno embaixo do nome (ex.: "2/3" da energia).
var detalhe := ""
## Fração da recarga que falta (1 = acabou de usar, 0 = pronto).
var recarga := 0.0
var disponivel := true
var aceso := false
var _apertado_ate := 0.0
var _tempo := 0.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_NONE


func _process(delta: float) -> void:
	_tempo += delta
	if aceso or _tempo < _apertado_ate + 0.2:
		queue_redraw()


func _input(evento: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if evento is InputEventScreenTouch and evento.pressed and _dentro(evento.position - global_position):
		get_viewport().set_input_as_handled()
		apertar()


func _gui_input(evento: InputEvent) -> void:
	# o mouse "de mentira" que o celular cria a partir do toque fica de fora
	# (o toque já é tratado em _input)
	if evento.device == InputEvent.DEVICE_ID_EMULATION:
		accept_event()
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed \
			and _dentro(evento.position):
		accept_event()
		apertar()


func _has_point(ponto: Vector2) -> bool:
	return _dentro(ponto)


func _dentro(ponto: Vector2) -> bool:
	return ponto.distance_to(size / 2.0) <= minf(size.x, size.y) / 2.0 + 6.0


## Aperta o botão (o toque, o mouse, o teclado ou os testes).
func apertar() -> void:
	_apertado_ate = _tempo + 0.12
	queue_redraw()
	apertado.emit()


func atualizar(novo_recarga: float, novo_disponivel: bool, novo_aceso := false, novo_detalhe := "") -> void:
	if is_equal_approx(novo_recarga, recarga) and novo_disponivel == disponivel and novo_aceso == aceso \
			and novo_detalhe == detalhe:
		return
	recarga = novo_recarga
	disponivel = novo_disponivel
	aceso = novo_aceso
	detalhe = novo_detalhe
	queue_redraw()


func _draw() -> void:
	var centro := size / 2.0
	var raio := minf(size.x, size.y) / 2.0
	var afunda := 0.92 if _tempo < _apertado_ate else 1.0
	raio *= afunda
	var base := cor if disponivel else cor.darkened(0.45)
	if aceso:
		var pulso := 0.5 + 0.5 * sin(_tempo * 7.0)
		draw_circle(centro, raio + 6.0 + 6.0 * pulso, Color(1.0, 0.85, 0.3, 0.35 + 0.3 * pulso))
	# sombra, bola, brilho de cima e borda
	draw_circle(centro + Vector2(0, 5), raio, Color(0, 0, 0, 0.3))
	draw_circle(centro, raio, base.darkened(0.3))
	draw_circle(centro - Vector2(0, 3), raio - 5.0, base)
	draw_circle(centro - Vector2(0, raio * 0.35), raio * 0.5, Color(1, 1, 1, 0.16))
	draw_arc(centro, raio - 2.0, 0, TAU, 64, Color(1, 1, 1, 0.75), 4.0, true)
	# recarga: um "relógio" escuro que some no sentido horário
	if recarga > 0.0:
		var pontos := PackedVector2Array([centro])
		var passos := 40
		for i in passos + 1:
			var angulo := -PI / 2.0 + TAU * (1.0 - recarga) + TAU * recarga * i / passos
			pontos.append(centro + Vector2(cos(angulo), sin(angulo)) * (raio - 4.0))
		draw_colored_polygon(pontos, Color(0.1, 0.05, 0.2, 0.55))
	var fonte := get_theme_default_font()
	var tamanho := int(clampf(raio * 0.36, 14, 30))
	var linhas := texto.split("\n")
	var altura := tamanho * linhas.size() + (tamanho * 0.8 if detalhe != "" else 0.0)
	var y := centro.y - altura / 2.0 + tamanho * 0.8
	for linha in linhas:
		_escrever(fonte, linha, Vector2(centro.x, y), tamanho)
		y += tamanho
	if detalhe != "":
		_escrever(fonte, detalhe, Vector2(centro.x, y - tamanho * 0.15), int(tamanho * 0.75))


func _escrever(fonte: Font, frase: String, onde: Vector2, tamanho: int) -> void:
	var largura := fonte.get_string_size(frase, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	var ponto := onde - Vector2(largura / 2.0, 0)
	draw_string_outline(fonte, ponto, frase, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 7, Color("#2E1D4A"))
	draw_string(fonte, ponto, frase, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, Color.WHITE if disponivel else Color(1, 1, 1, 0.6))
