class_name Mascote3D
extends SubViewportContainer
## Mascote 3D (caixa de cereal) montado com formas simples. Arraste com o dedo
## ou o mouse para girar; solto, ele continua girando um pouco e depois volta
## a olhar para a frente.

const SENSIBILIDADE := 0.012  # radianos por pixel arrastado
const ATRITO := 3.0  # quanto o giro "de embalo" freia por segundo
const ESPERA_PARA_VOLTAR := 1.5  # segundos parado até voltar para a pose inicial
const ANGULO_INICIAL := -0.5  # levemente de lado, mostrando a lateral rosa

const CONTORNO := Color("#2B1D3A")
const AMARELO := Color("#F7DC3B")
const ROSA := Color("#F06AA8")
const ROXO := Color("#7E57B1")
const BRANCO := Color("#FFFFFF")

var _modelo: Node3D
var _viewport: SubViewport
var _girando := false
var _velocidade := 0.0
var _parado_ha := 0.0
var _tempo := 0.0


func _ready() -> void:
	stretch = true
	mouse_filter = MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)
	_montar_cena()


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_girando = evento.pressed
		accept_event()
	elif evento is InputEventMouseMotion and _girando:
		var giro: float = evento.relative.x * SENSIBILIDADE
		_modelo.rotation.y += giro
		_velocidade = giro / maxf(get_process_delta_time(), 0.001)
		_parado_ha = 0.0
		accept_event()


func _process(delta: float) -> void:
	_tempo += delta
	if not _girando:
		# embalo: continua girando e vai freando
		_modelo.rotation.y += _velocidade * delta
		_velocidade = move_toward(_velocidade, 0.0, absf(_velocidade) * ATRITO * delta + 0.2 * delta)
		if absf(_velocidade) < 0.05:
			_parado_ha += delta
		if _parado_ha > ESPERA_PARA_VOLTAR:
			# volta devagar para a pose inicial pelo caminho mais curto
			var alvo := ANGULO_INICIAL + roundf((_modelo.rotation.y - ANGULO_INICIAL) / TAU) * TAU
			_modelo.rotation.y = lerp_angle(_modelo.rotation.y, alvo, 2.5 * delta)
	if Jogo.animacoes_continuas:
		_modelo.position.y = sin(_tempo * 2.2) * 0.05  # flutua
		_modelo.rotation.z = sin(_tempo * 1.4) * 0.03  # balança de leve


# --- Montagem do modelo ------------------------------------------------------

func _montar_cena() -> void:
	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0, -0.05, 5.6)
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

	_modelo = Node3D.new()
	_modelo.rotation.y = ANGULO_INICIAL
	_viewport.add_child(_modelo)
	var caixa := Node3D.new()  # a caixa fica um pouco acima do centro
	caixa.position.y = 0.25
	_modelo.add_child(caixa)

	# Caixa: frente amarela, laterais e faixa de baixo rosa
	_bloco(caixa, Vector3(1.1, 1.5, 0.46), Vector3.ZERO, AMARELO)
	for lado in [-1, 1]:
		_bloco(caixa, Vector3(0.03, 1.52, 0.48), Vector3(lado * 0.555, 0, 0), ROSA)
	_bloco(caixa, Vector3(1.14, 0.26, 0.5), Vector3(0, -0.64, 0), ROSA)
	_bloco(caixa, Vector3(1.14, 0.08, 0.5), Vector3(0, 0.74, 0), ROSA)

	# Rosto na frente e nas costas (para aparecer ao girar)
	var rosto := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.95, 0.71)
	rosto.mesh = quad
	var mat_rosto := StandardMaterial3D.new()
	mat_rosto.albedo_texture = load("res://assets/mascote_3d/rosto.svg")
	mat_rosto.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat_rosto.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_rosto.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rosto.material_override = mat_rosto
	rosto.position = Vector3(0, 0.22, 0.236)
	caixa.add_child(rosto)

	# Tigela de cereal na frente
	var tigela := _esfera(caixa, 0.26, Vector3(0.05, -0.33, 0.24), BRANCO, Vector3(1.3, 0.55, 0.45))
	tigela.rotation_degrees.x = 10
	var cores_cereal := [ROSA, ROXO, AMARELO, Color("#8FD3F4"), Color("#FF9F43")]
	for i in 5:
		var anel := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = 0.025
		toro.outer_radius = 0.06
		anel.mesh = toro
		anel.material_override = _material(cores_cereal[i])
		anel.position = Vector3(-0.18 + i * 0.09 + 0.05, -0.22 + (i % 2) * 0.03, 0.3)
		anel.rotation_degrees = Vector3(70, i * 30, 0)
		caixa.add_child(anel)

	# Braços com luvas (acenando)
	for lado in [-1, 1]:
		var ombro := Vector3(lado * 0.56, 0.05, 0)
		var mao := Vector3(lado * 1.02, 0.42 if lado == 1 else 0.3, 0.12)
		_cano(caixa, ombro, mao, 0.045, CONTORNO)
		_esfera(caixa, 0.15, mao, BRANCO)
		_esfera(caixa, 0.065, mao + Vector3(-lado * 0.12, 0.06, 0.05), BRANCO)

	# Pernas e sapatos
	for lado in [-1, 1]:
		var quadril := Vector3(lado * 0.24, -0.76, 0)
		var tornozelo := Vector3(lado * 0.3, -1.28, 0.02)
		_cano(caixa, quadril, tornozelo, 0.05, ROSA)
		_esfera(caixa, 0.2, tornozelo + Vector3(lado * 0.04, -0.06, 0.1), ROXO, Vector3(1.1, 0.6, 1.5))


func _material(cor: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.roughness = 0.35
	mat.metallic_specular = 0.6
	# contorno de desenho animado: cópia um pouco maior, só com o lado de dentro
	var contorno := StandardMaterial3D.new()
	contorno.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	contorno.albedo_color = CONTORNO
	contorno.cull_mode = BaseMaterial3D.CULL_FRONT
	contorno.grow = true
	contorno.grow_amount = 0.018
	mat.next_pass = contorno
	return mat


func _bloco(pai: Node3D, tamanho: Vector3, posicao: Vector3, cor: Color) -> MeshInstance3D:
	var no := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	no.mesh = malha
	no.material_override = _material(cor)
	no.position = posicao
	pai.add_child(no)
	return no


func _esfera(pai: Node3D, raio: float, posicao: Vector3, cor: Color, escala := Vector3.ONE) -> MeshInstance3D:
	var no := MeshInstance3D.new()
	var malha := SphereMesh.new()
	malha.radius = raio
	malha.height = raio * 2.0
	no.mesh = malha
	no.material_override = _material(cor)
	no.position = posicao
	no.scale = escala
	pai.add_child(no)
	return no


## Cilindro ligando dois pontos (braços e pernas).
func _cano(pai: Node3D, de: Vector3, ate: Vector3, raio: float, cor: Color) -> void:
	var no := MeshInstance3D.new()
	var malha := CapsuleMesh.new()
	malha.radius = raio
	malha.height = de.distance_to(ate) + raio * 2.0
	no.mesh = malha
	no.material_override = _material(cor)
	no.position = (de + ate) / 2.0
	var eixo_y := (ate - de).normalized()
	var eixo_x := eixo_y.cross(Vector3.FORWARD).normalized()
	no.basis = Basis(eixo_x, eixo_y, eixo_x.cross(eixo_y))
	pai.add_child(no)
