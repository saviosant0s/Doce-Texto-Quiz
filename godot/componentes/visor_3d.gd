class_name Visor3D
extends Control
## Mostra um modelo 3D que gira com o dedo (ou mouse). Solto, ele continua
## girando um pouco e depois volta para a pose inicial; também flutua de leve.
## Base do mascote da tela inicial (Mascote3D) e dos doces da coleção (Doce3D):
## quem herda monta o modelo em `_montar(pivo)`.
##
## A cena 3D é desenhada na resolução real da tela (e não no tamanho lógico de
## 1280x720 esticado), para não ficar serrilhada em celulares de tela grande.

const SENSIBILIDADE := 0.012  # radianos por pixel arrastado
const ATRITO := 3.0  # quanto o giro "de embalo" freia por segundo
const ESPERA_PARA_VOLTAR := 1.5  # segundos parado até voltar para a pose inicial

## Ângulo (em radianos, no eixo Y) da pose inicial.
@export var angulo_inicial := -0.5
## Distância da câmera: maior = modelo menor na tela.
@export var distancia := 5.6
## Se o dedo pode girar o modelo.
@export var giravel := true

var _viewport: SubViewport
var _imagem: TextureRect
## Nó que gira e flutua; o modelo fica dentro dele.
var _pivo: Node3D
var _girando := false
var _velocidade := 0.0
var _parado_ha := 0.0
var _tempo := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP if giravel else MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)
	_imagem = TextureRect.new()
	_imagem.texture = _viewport.get_texture()
	_imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagem.mouse_filter = MOUSE_FILTER_IGNORE
	_imagem.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_imagem)
	resized.connect(_ajustar_resolucao)
	get_viewport().size_changed.connect(_ajustar_resolucao)
	_ajustar_resolucao.call_deferred()
	_montar_cena()
	_pivo = Node3D.new()
	_pivo.rotation.y = angulo_inicial
	_viewport.add_child(_pivo)
	_montar(_pivo)


## Sobrescreva para colocar o modelo dentro de `pivo`.
func _montar(_pivo_do_modelo: Node3D) -> void:
	pass


## Troca o modelo mostrado (remove o anterior e chama _montar de novo).
func remontar() -> void:
	for filho in _pivo.get_children():
		filho.queue_free()
	_pivo.rotation = Vector3(0, angulo_inicial, 0)
	_velocidade = 0.0
	_montar(_pivo)


## Tamanho em pixels de verdade = tamanho na tela x escala da janela.
func _ajustar_resolucao() -> void:
	var escala := clampf(get_tree().root.get_final_transform().get_scale().x, 1.0, 3.0)
	_viewport.size = Vector2i((size * escala).round()).maxi(1)


func _gui_input(evento: InputEvent) -> void:
	if not giravel:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_girando = evento.pressed
		if evento.pressed:
			_ao_tocar()
		accept_event()
	elif evento is InputEventMouseMotion and _girando:
		var giro: float = evento.relative.x * SENSIBILIDADE
		_pivo.rotation.y += giro
		_velocidade = giro / maxf(get_process_delta_time(), 0.001)
		_parado_ha = 0.0
		accept_event()


## Chamado quando o dedo encosta no modelo (os doces aproveitam para acenar).
func _ao_tocar() -> void:
	pass


func _process(delta: float) -> void:
	_tempo += delta
	if not _girando:
		# embalo: continua girando e vai freando
		_pivo.rotation.y += _velocidade * delta
		_velocidade = move_toward(_velocidade, 0.0, absf(_velocidade) * ATRITO * delta + 0.2 * delta)
		if absf(_velocidade) < 0.05:
			_parado_ha += delta
		if _parado_ha > ESPERA_PARA_VOLTAR:
			# volta devagar para a pose inicial pelo caminho mais curto
			var alvo := angulo_inicial + roundf((_pivo.rotation.y - angulo_inicial) / TAU) * TAU
			_pivo.rotation.y = lerp_angle(_pivo.rotation.y, alvo, 2.5 * delta)
	if Telas.animacoes_continuas:
		_pivo.position.y = sin(_tempo * 2.2) * 0.05  # flutua
		_pivo.rotation.z = sin(_tempo * 1.4) * 0.03  # balança de leve


func _montar_cena() -> void:
	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0, -0.05, distancia)
	_viewport.add_child(camera)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, -30, 0)
	luz.light_energy = 1.1
	_viewport.add_child(luz)
	var luz_de_tras := DirectionalLight3D.new()
	luz_de_tras.rotation_degrees = Vector3(-20, 150, 0)
	luz_de_tras.light_energy = 0.35
	_viewport.add_child(luz_de_tras)

	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_CLEAR_COLOR
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color.WHITE
	ambiente.ambient_light_energy = 0.55
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	_viewport.add_child(mundo)
