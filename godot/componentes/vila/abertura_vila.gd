class_name AberturaVila
extends CanvasLayer
## ABERTURA: na primeira vez na vila (e pelo VER ABERTURA das configurações),
## a câmera voa pela vila mostrando o que dá para fazer, com legendas
## grandes e faixas de cinema; no fim, gira em volta do seu doce com o nome
## do jogo e TOQUE PARA JOGAR. Tocar em qualquer lugar pula para o fim. A
## interface da vila fica escondida enquanto passa (ver Vila.ver_abertura).

signal terminou

const LOGO := preload("res://assets/abertura.png")
## Tomadas: [posição inicial, olhar inicial, posição final, olhar final,
## segundos, legenda, linha de baixo].
const TOMADAS := [
	[Vector3(0, 42, 62), Vector3(0, 0, 0), Vector3(0, 20, 30), Vector3(0, 0, -4), 5.0,
		"BEM-VINDO À VILA DOS DOCES", "UM JOGO PARA APRENDER WORD, EXCEL E POWERPOINT BRINCANDO"],
	[Vector3(-9, 3.6, -2.5), Vector3(0, 3.0, -14), Vector3(9, 3.6, -2.5), Vector3(0, 3.0, -14), 4.2,
		"JOGUE O QUIZ NA ESCOLA", "ACERTE PERGUNTAS E GANHE MOEDAS, AÇÚCAR E TÍTULOS"],
	[Vector3(4, 3.2, -5), Vector3(10, 2.6, -13), Vector3(-4, 3.2, -5), Vector3(-10, 2.6, -13), 4.2,
		"LABORATÓRIO E MINIJOGOS", "FASES DE EXCEL E WORD DE VERDADE, DOCE MATCH, TORRE E FÁBRICA"],
	[Vector3(-4, 3.2, 10), Vector3(-12, 2.0, 19), Vector3(4, 3.2, 10), Vector3(12, 2.0, 19), 4.2,
		"CORRIDAS, BATALHAS E CHEFÕES", "CADA PORTAL, GOLPE E DESAFIO É UMA PERGUNTA DO QUIZ"],
	[Vector3(-4.5, 2.6, 4.5), Vector3(-13, 2.0, -2), Vector3(-5.5, 4.2, -6.5), Vector3(-13, 2.0, -2), 3.8,
		"MONTE SUA CONFEITARIA", "COLECIONE DOCES 3D, DECORE A SUA CASA E CONSTRUA NOS TERRENOS"],
	[Vector3(6, 24, 30), Vector3(-30, 0, 12), Vector3(-6, 24, 30), Vector3(32, 0, 10), 4.6,
		"EXPLORE NOVAS REGIÕES", "A ILHA, O BOSQUE E A MONTANHA ABREM CONFORME VOCÊ APRENDE"],
]
const GIRO_FINAL := 9.0  # segundos para uma volta em volta do doce

var _vila: Node
var _camera: Camera3D
var _faixas: Array[ColorRect] = []
var _legenda: Label
var _linha: Label
var _logo: TextureRect
var _toque: Label
var _pular: Button
var _tween: Tween
var _pulou := false
var _no_final := false
var _saindo := false
var _relogio := 0.0
## Tomada em andamento (para os testes; -1 = no final).
var tomada := 0


func _init(vila: Node) -> void:
	_vila = vila
	layer = 6
	name = "Abertura"


func _ready() -> void:
	_camera = _vila._camera
	_montar()
	_rodar()


func _process(delta: float) -> void:
	_relogio += delta
	if not _no_final:
		return
	# volta lenta em volta do doce, de frente para ele
	var doce: Vector3 = _vila.jogador.global_position
	var angulo := _relogio * TAU / GIRO_FINAL
	var lugar := doce + Vector3(sin(angulo) * 3.6, 1.3, cos(angulo) * 3.6)
	_camera.global_position = _camera.global_position.lerp(lugar, 1.0 - exp(-delta * 3.0))
	_olhar_ao_lado(doce)
	_toque.modulate.a = 0.55 + 0.45 * absf(sin(_relogio * 2.6))


func _input(evento: InputEvent) -> void:
	var tocou: bool = (evento is InputEventScreenTouch and evento.pressed) \
		or (evento is InputEventMouseButton and evento.pressed and evento.device != InputEvent.DEVICE_ID_EMULATION) \
		or (evento is InputEventKey and evento.pressed and not evento.echo)
	if not tocou:
		return
	get_viewport().set_input_as_handled()
	if _no_final:
		fechar()
	else:
		pular()


func _montar() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	# faixas pretas de cinema, que entram deslizando
	for i in 2:
		var faixa := ColorRect.new()
		faixa.color = Color(0.06, 0.03, 0.12, 0.92)
		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faixa.anchor_right = 1.0
		faixa.anchor_top = 0.0 if i == 0 else 1.0
		faixa.anchor_bottom = faixa.anchor_top
		raiz.add_child(faixa)
		faixa.create_tween().tween_property(faixa, "offset_bottom" if i == 0 else "offset_top", 72.0 if i == 0 else -72.0, 0.6) \
			.set_trans(Tween.TRANS_SINE)
		_faixas.append(faixa)
	_legenda = _rotulo(raiz, 64, Color("#FFD23F"), 16)
	_legenda.anchor_top = 0.66
	_legenda.anchor_bottom = 0.66
	_linha = _rotulo(raiz, 28, Color.WHITE, 10)
	_linha.anchor_top = 0.66
	_linha.anchor_bottom = 0.66
	_linha.offset_top = 78
	_linha.offset_bottom = 120
	_logo = TextureRect.new()
	_logo.name = "Logo"
	_logo.texture = LOGO
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.anchor_left = 0.3
	_logo.anchor_right = 0.3
	_logo.anchor_top = 0.17
	_logo.anchor_bottom = 0.17
	_logo.offset_left = -160
	_logo.offset_right = 160
	_logo.offset_bottom = 262
	_logo.visible = false
	raiz.add_child(_logo)
	_toque = _rotulo(raiz, 46, Color.WHITE, 14)
	_toque.name = "TocarParaJogar"
	_toque.text = "TOQUE PARA JOGAR"
	_toque.anchor_top = 0.64
	_toque.anchor_bottom = 0.64
	_toque.anchor_right = 0.6
	_toque.visible = false
	_pular = Button.new()
	_pular.name = "Pular"
	_pular.text = "PULAR"
	_pular.theme_type_variation = &"BotaoSecundario"
	_pular.custom_minimum_size = Vector2(150, 54)
	_pular.focus_mode = Control.FOCUS_NONE
	_pular.anchor_left = 1.0
	_pular.anchor_right = 1.0
	_pular.offset_left = -170
	_pular.offset_right = -20
	_pular.offset_top = 92
	_pular.offset_bottom = 146
	_pular.pressed.connect(pular)
	raiz.add_child(_pular)


func _rotulo(pai: Control, tamanho: int, cor: Color, contorno: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_constant_override("outline_size", contorno)
	rotulo.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.anchor_right = 1.0
	rotulo.offset_left = 40
	rotulo.offset_right = -40
	pai.add_child(rotulo)
	return rotulo


func _rodar() -> void:
	Audio.tocar("especial", 0.8)
	for i in TOMADAS.size():
		if _pulou or not is_inside_tree():
			return
		tomada = i
		await _tomada(TOMADAS[i])
	if not _pulou and is_inside_tree():
		_final()


## Uma tomada: a câmera vai de um lugar a outro, com a legenda entrando e saindo.
func _tomada(t: Array) -> void:
	var de := Transform3D(Basis.looking_at(t[1] - t[0]), t[0])
	var ate := Transform3D(Basis.looking_at(t[3] - t[2]), t[2])
	var duracao: float = t[4]
	_legenda.text = t[5]
	_linha.text = t[6]
	for rotulo in [_legenda, _linha]:
		rotulo.modulate.a = 0.0
		var aparece: Tween = rotulo.create_tween()
		aparece.tween_interval(0.25 if rotulo == _legenda else 0.55)
		aparece.tween_property(rotulo, "modulate:a", 1.0, 0.4)
		aparece.tween_interval(duracao - 1.4)
		aparece.tween_property(rotulo, "modulate:a", 0.0, 0.35)
	_legenda.pivot_offset = Vector2(_legenda.size.x / 2.0, 40)
	_legenda.scale = Vector2.ONE * 0.85
	_legenda.create_tween().tween_property(_legenda, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween = create_tween()
	_tween.tween_method(func(p: float): _camera.global_transform = de.interpolate_with(ate, p), 0.0, 1.0, duracao) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished


## Pula as tomadas e vai direto para o final.
func pular() -> void:
	if _pulou or _no_final:
		return
	_pulou = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_final()


## O final: a câmera gira em volta do seu doce (que comemora), o nome do
## jogo aparece e TOQUE PARA JOGAR fica piscando.
func _final() -> void:
	_no_final = true
	tomada = -1
	_pular.visible = false
	_legenda.visible = false
	_linha.visible = false
	_relogio = 0.0
	var doce: Vector3 = _vila.jogador.global_position
	_camera.global_position = doce + Vector3(0, 1.3, 3.6)
	_olhar_ao_lado(doce)
	_vila.jogador.olhar_para(_camera.global_position)
	_vila.jogador.comemorar()
	Audio.tocar("vitoria", 1.0, -3.0)
	_logo.visible = true
	_logo.pivot_offset = Vector2(160, 131)
	_logo.scale = Vector2.ONE * 0.3
	_logo.create_tween().tween_property(_logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_toque.visible = true


## Olha um pouco à esquerda do doce: ele fica na metade direita da tela e
## o nome do jogo na esquerda.
func _olhar_ao_lado(doce: Vector3) -> void:
	var direcao := doce + Vector3(0, 1.0, 0) - _camera.global_position
	var tela := get_viewport().get_visible_rect().size
	var desvio := 19.0 if tela.x > tela.y * 1.2 else 0.0  # tela em pé (vídeo vertical): o doce no meio
	_camera.look_at(_camera.global_position + direcao.rotated(Vector3.UP, deg_to_rad(desvio)))


## TOQUE PARA JOGAR: tira as faixas e devolve a vila ao jogador.
func fechar() -> void:
	if _saindo:
		return
	_saindo = true
	Audio.tocar("pulo", 1.1)
	var tween := create_tween().set_parallel()
	for no in [_logo, _toque]:
		tween.tween_property(no, "modulate:a", 0.0, 0.3)
	for i in _faixas.size():
		tween.tween_property(_faixas[i], "offset_bottom" if i == 0 else "offset_top", 0.0, 0.35)
	await tween.finished
	terminou.emit()
	queue_free()
