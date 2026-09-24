class_name Mascote3D
extends Control
## Mascote 3D que gira com o dedo. Usa o modelo em MODELO (.glb, por exemplo
## gerado por IA a partir do mascote original); sem ele, monta a caixa de
## cereal com as faces tiradas das imagens do mascote (assets/mascote_3d).
## Arraste com o dedo ou o mouse para girar; solto, ele continua girando um
## pouco e depois volta para a pose inicial.
##
## A cena 3D é desenhada na resolução real da tela (e não no tamanho lógico de
## 1280x720 esticado), para não ficar serrilhada em celulares de tela grande.

const MODELO := "res://assets/mascote_3d/mascote.glb"
## Altura que o modelo ocupa na cena (o .glb é redimensionado para caber).
const ALTURA_MODELO := 2.4
const TEXTURA_FRENTE := "res://assets/mascote_3d/frente.png"


## Há um modelo (.glb) ou as texturas da caixa para montar o mascote 3D?
static func disponivel() -> bool:
	return ResourceLoader.exists(MODELO) or ResourceLoader.exists(TEXTURA_FRENTE)

const SENSIBILIDADE := 0.012  # radianos por pixel arrastado
const ATRITO := 3.0  # quanto o giro "de embalo" freia por segundo
const ESPERA_PARA_VOLTAR := 1.5  # segundos parado até voltar para a pose inicial
const ANGULO_INICIAL := -0.5  # levemente de lado, mostrando a lateral rosa

const ROSA := Color("#D8386A")
const ROXO := Color("#6A3DA6")
const ROXO_ESCURO := Color("#45256F")
const BRANCO := Color("#F7F5F2")

var _modelo: Node3D
var _viewport: SubViewport
var _imagem: TextureRect
var _girando := false
var _velocidade := 0.0
var _parado_ha := 0.0
var _tempo := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
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


## Tamanho em pixels de verdade = tamanho na tela x escala da janela.
func _ajustar_resolucao() -> void:
	var escala := clampf(get_tree().root.get_final_transform().get_scale().x, 1.0, 3.0)
	_viewport.size = Vector2i((size * escala).round()).maxi(1)


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
	if Telas.animacoes_continuas:
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
	if ResourceLoader.exists(MODELO):
		_carregar_modelo()
		return
	_montar_mascote()


## Caixa de cereal com as faces tiradas das imagens do mascote (frente, costas)
## e desenhadas (laterais, topo); braços, luvas, pernas e sapatos em 3D.
func _montar_mascote() -> void:
	var caixa := Node3D.new()
	caixa.position.y = 0.32
	_modelo.add_child(caixa)
	var w := 1.0
	var h := 1.6
	var p := 0.54
	_face(caixa, "frente", Vector2(w, h), Vector3(0, 0, p / 2), Vector3.ZERO)
	_face(caixa, "tras", Vector2(w, h), Vector3(0, 0, -p / 2), Vector3(0, 180, 0))
	_face(caixa, "lado", Vector2(p, h), Vector3(w / 2, 0, 0), Vector3(0, 90, 0))
	_face(caixa, "lado", Vector2(p, h), Vector3(-w / 2, 0, 0), Vector3(0, -90, 0))
	_face(caixa, "topo", Vector2(w, p), Vector3(0, h / 2, 0), Vector3(-90, 0, 0))
	_face(caixa, "baixo", Vector2(w, p), Vector3(0, -h / 2, 0), Vector3(90, 0, 0))

	# Braços abertos com as mãos para cima ("tcharam!")
	for lado in [-1, 1]:
		var ombro := Vector3(lado * 0.5, -0.1, 0.02)
		var cotovelo := Vector3(lado * 0.82, -0.14, 0.08)
		var pulso := Vector3(lado * 1.02, 0.02, 0.14)
		_cano(caixa, ombro, cotovelo, 0.068, ROSA)
		_cano(caixa, cotovelo, pulso, 0.068, ROSA)
		_luva(caixa, pulso, lado)

	# Pernas e sapatos
	for lado in [-1, 1]:
		var quadril := Vector3(lado * 0.24, -0.78, 0.0)
		var tornozelo := Vector3(lado * 0.26, -1.3, 0.04)
		_cano(caixa, quadril, tornozelo, 0.085, ROSA)
		_sapato(caixa, tornozelo + Vector3(lado * 0.02, -0.08, 0.1))


func _face(pai: Node3D, textura: String, tamanho: Vector2, posicao: Vector3, rotacao: Vector3) -> void:
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = tamanho
	face.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/mascote_3d/%s.png" % textura)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 0.45
	face.material_override = mat
	face.position = posicao
	face.rotation_degrees = rotacao
	pai.add_child(face)


## Luva branca: palma, polegar, três dedos e punho.
func _luva(pai: Node3D, pulso: Vector3, lado: int) -> void:
	var mao := Node3D.new()
	mao.position = pulso + Vector3(lado * 0.08, 0.1, 0.02)
	mao.rotation_degrees = Vector3(-15, 0, -lado * 25)
	pai.add_child(mao)
	var punho := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.05
	toro.outer_radius = 0.095
	punho.mesh = toro
	punho.material_override = _material(BRANCO)
	punho.position = Vector3(0, -0.12, 0)
	mao.add_child(punho)
	_esfera(mao, 0.13, Vector3.ZERO, BRANCO, Vector3(1.05, 1.0, 0.6))
	for i in 3:
		var dedo_base := Vector3(-0.07 + i * 0.07, 0.08, 0.0)
		_cano(mao, dedo_base, dedo_base + Vector3((i - 1) * 0.03, 0.13, 0.02), 0.038, BRANCO)
	_cano(mao, Vector3(-lado * 0.1, -0.02, 0.02), Vector3(-lado * 0.2, 0.06, 0.05), 0.04, BRANCO)


func _sapato(pai: Node3D, posicao: Vector3) -> void:
	var sapato := Node3D.new()
	sapato.position = posicao
	sapato.scale = Vector3.ONE * 1.25
	pai.add_child(sapato)
	_esfera(sapato, 0.2, Vector3(0, 0.02, 0.04), ROXO, Vector3(1.05, 0.62, 1.45))
	var sola := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.2
	cilindro.bottom_radius = 0.2
	cilindro.height = 0.06
	sola.mesh = cilindro
	sola.material_override = _material(ROXO_ESCURO)
	sola.position = Vector3(0, -0.09, 0.04)
	sola.scale = Vector3(1.1, 1.0, 1.55)
	sapato.add_child(sola)
	_esfera(sapato, 0.09, Vector3(0, 0.1, -0.08), ROXO, Vector3(1.0, 0.8, 1.0))


## Carrega o .glb, centraliza e ajusta o tamanho para caber na cena.
func _carregar_modelo() -> void:
	var cena: Node3D = load(MODELO).instantiate()
	_modelo.add_child(cena)
	var caixa := AABB()
	var primeira := true
	for malha in cena.find_children("*", "MeshInstance3D", true, false):
		var limites: AABB = malha.global_transform * malha.get_aabb()
		caixa = limites if primeira else caixa.merge(limites)
		primeira = false
	if primeira:
		return
	var escala := ALTURA_MODELO / maxf(caixa.size.y, 0.001)
	cena.scale = Vector3.ONE * escala
	cena.position = -caixa.get_center() * escala


func _material(cor: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.roughness = 0.28  # plástico brilhante, como nas imagens
	mat.metallic_specular = 0.7
	return mat


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
