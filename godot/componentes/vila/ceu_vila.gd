class_name CeuVila
extends Node3D
## O céu da Vila dos Doces ao longo do dia (ver CicloDia): cores do céu, sol
## e lua, estrelas, janelas e luminárias acesas à noite, vaga-lumes, a
## ESTRELA CADENTE para pegar e a CHUVA DE GRANULADO com as gotas pelo chão.
## A vila cria este nó e chama configurar() depois de montar (e juntar) o
## cenário.

signal estrela_pega(premio: Dictionary)
signal gota_pega(acucar: int)

const BRILHO := preload("res://assets/doce_match/brilho.svg")
const ESTRELA := preload("res://assets/itens/estrela.png")
const CORES_GRANULADO := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF", "#FFFFFF", "#FF8A5B"]
const DISTANCIA_PEGAR := 1.3

var _ambiente: Environment
var _ceu: ProceduralSkyMaterial
var _sol: DirectionalLight3D
var _jogador: Node3D
var _camera: Camera3D
var _energia_sol := 1.0
var _energia_ambiente := 0.32
var _emissivos: Array[StandardMaterial3D] = []
var _janelas: Array[StandardMaterial3D] = []
var _luzes: Array[OmniLight3D] = []
var _estrelas: MultiMeshInstance3D
var _mat_estrelas: StandardMaterial3D
var _lua: MeshInstance3D
var _mat_lua: StandardMaterial3D
var _vagalumes: CPUParticles3D
var _chuva: CPUParticles3D
var _estrela_cadente: Node3D
var _gotas := {}  # índice -> Node3D
var _chovia := false
var _tempo := 0.0
var _relogio := 99.0  # segundos desde a última vez que aplicou a hora
## Noite agora (0 a 1), para a vila e os testes.
var noite := 0.0


func configurar(ambiente: Environment, sol: DirectionalLight3D, raiz: Node3D, jogador: Node3D, camera: Camera3D) -> void:
	_ambiente = ambiente
	_ceu = ambiente.sky.sky_material
	_sol = sol
	_jogador = jogador
	_camera = camera
	_energia_sol = sol.light_energy
	_energia_ambiente = ambiente.ambient_light_energy
	_coletar_luzes(raiz)
	_criar_estrelas()
	_criar_lua()
	if Telas.animacoes_continuas and Qualidade.nivel() != Qualidade.BAIXA:
		_vagalumes = _particulas(40, Color("#FFF27A"), 0.12, 4.0)
		_vagalumes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_vagalumes.emission_box_extents = Vector3(12, 1.2, 12)
		_vagalumes.initial_velocity_min = 0.1
		_vagalumes.initial_velocity_max = 0.35
		_vagalumes.spread = 180.0
		_vagalumes.emitting = false
		add_child(_vagalumes)
	atualizar(true)


## Aplica a hora de agora (céu, luzes) e o clima. `ja` = sem esperar o relógio.
func atualizar(ja := false) -> void:
	_relogio = 0.0
	var h := CicloDia.hora()
	noite = CicloDia.noite(h)
	var chuva := CicloDia.chovendo()
	var cinza := 0.45 if chuva else 0.0
	_ceu.sky_top_color = (CicloDia.misturar(CicloDia.CEU_TOPO, h) as Color).lerp(Color("#8E97A8"), cinza * (1.0 - noite))
	_ceu.sky_horizon_color = (CicloDia.misturar(CicloDia.CEU_HORIZONTE, h) as Color).lerp(Color("#C9CCD6"), cinza * (1.0 - noite))
	_ceu.ground_horizon_color = _ceu.sky_horizon_color
	_sol.light_color = CicloDia.misturar(CicloDia.COR_SOL, h)
	_sol.light_energy = _energia_sol * float(CicloDia.misturar(CicloDia.ENERGIA_SOL, h)) * (0.6 if chuva else 1.0)
	_sol.rotation_degrees.x = CicloDia.misturar(CicloDia.ALTURA_SOL, h)
	_ambiente.ambient_light_energy = _energia_ambiente * float(CicloDia.misturar(CicloDia.AMBIENTE, h))
	_ambiente.fog_light_color = CicloDia.misturar(CicloDia.NEVOA, h)
	# de noite, as luzes das portas, janelas e luminárias acendem
	for mat in _emissivos:
		mat.emission_energy_multiplier = float(mat.get_meta("emissao_dia")) * (1.0 + 2.5 * noite)
	for mat in _janelas:
		mat.emission_energy_multiplier = 1.6 * noite
	for luz in _luzes:
		luz.visible = noite > 0.05
		luz.light_energy = 1.4 * noite
	_mat_estrelas.albedo_color.a = smoothstep(0.4, 1.0, noite)
	_estrelas.visible = noite > 0.4
	_mat_lua.albedo_color.a = smoothstep(0.5, 1.0, noite)
	_lua.visible = noite > 0.5
	if _vagalumes:
		_vagalumes.emitting = noite > 0.6
	if chuva != _chovia or ja:
		_chovia = chuva
		_mudar_chuva(chuva)
	_conferir_estrela()


func _process(delta: float) -> void:
	_tempo += delta
	_relogio += delta
	if _relogio > 2.0:
		atualizar()
	if is_instance_valid(_camera):
		# estrelas e lua acompanham a câmera (ficam "no infinito")
		_estrelas.global_position = _camera.global_position
		_lua.global_position = _camera.global_position + _sol.global_transform.basis.z * 85.0
	if not is_instance_valid(_jogador):
		return
	var pe := _jogador.global_position
	if _vagalumes:
		_vagalumes.global_position = pe + Vector3(0, 1.2, 0)
	if _chuva:
		_chuva.global_position = pe + Vector3(0, 14, -3)
	# gotas de granulado: giram, sobem e descem; pega passando por cima
	for indice in _gotas.keys():
		var gota: Node3D = _gotas[indice]
		gota.rotation.y += delta * 2.0
		gota.position.y = 0.55 + sin(_tempo * 3.0 + indice) * 0.12
		if Vector2(gota.global_position.x - pe.x, gota.global_position.z - pe.z).length() < DISTANCIA_PEGAR:
			var ganho := CicloDia.pegar_gota(indice)
			_gotas.erase(indice)
			gota.queue_free()
			if ganho > 0:
				Audio.tocar("moeda", 1.3, -6.0)
				gota_pega.emit(ganho)
	if is_instance_valid(_estrela_cadente):
		_estrela_cadente.rotation.y += delta * 1.5
		var alvo := _estrela_cadente.get_meta("alvo") as Vector3
		if _estrela_cadente.position.y > alvo.y + 0.01:
			# caindo do céu, de lado, até o chão
			_estrela_cadente.position = _estrela_cadente.position.move_toward(alvo, delta * 18.0)
		elif Vector2(alvo.x - pe.x, alvo.z - pe.z).length() < DISTANCIA_PEGAR:
			var premio := CicloDia.pegar_estrela()
			_estrela_cadente.queue_free()
			_estrela_cadente = null
			if not premio.is_empty():
				Audio.tocar("caixa")
				estrela_pega.emit(premio)


# --- Luzes -------------------------------------------------------------------------

## Guarda os materiais que brilham (luminárias, janelas da fábrica...) e
## põe uma luz de verdade em cada porta de prédio.
func _coletar_luzes(raiz: Node3D) -> void:
	var vistos := {}
	for no in raiz.find_children("*", "MeshInstance3D", true, false):
		var mat := (no as MeshInstance3D).material_override as StandardMaterial3D
		if mat == null or vistos.has(mat):
			continue
		vistos[mat] = true
		if mat.has_meta("janela"):
			_janelas.append(mat)
		elif mat.emission_enabled:
			if not mat.has_meta("emissao_dia"):
				mat.set_meta("emissao_dia", mat.emission_energy_multiplier)
			_emissivos.append(mat)
	for fachada in raiz.find_children("Fachada", "Node3D", true, false):
		var luz := OmniLight3D.new()
		luz.name = "LuzDaPorta"
		luz.light_color = Color("#FFC878")
		luz.omni_range = 6.0
		luz.omni_attenuation = 1.4
		luz.shadow_enabled = false
		luz.visible = false
		fachada.add_child(luz)
		luz.position = Vector3(0, 2.2, 1.0)
		_luzes.append(luz)


func _criar_estrelas() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	_mat_estrelas = StandardMaterial3D.new()
	_mat_estrelas.albedo_texture = BRILHO
	_mat_estrelas.albedo_color = Color(1, 1, 1, 0)
	_mat_estrelas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_estrelas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_estrelas.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat_estrelas.disable_fog = true
	_mat_estrelas.vertex_color_use_as_albedo = true
	quad.material = _mat_estrelas
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = quad
	multi.instance_count = 220
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 11
	for i in multi.instance_count:
		var angulo := sorteio.randf() * TAU
		var altura := sorteio.randf_range(0.12, 1.0)
		var direcao := Vector3(cos(angulo) * sqrt(1.0 - altura * altura), altura, sin(angulo) * sqrt(1.0 - altura * altura))
		var escala := sorteio.randf_range(0.6, 2.2)
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * escala), direcao * 90.0))
		var cor := Color.WHITE.lerp(Color("#FFE9A8") if i % 3 == 0 else Color("#BFD8FF"), sorteio.randf() * 0.6)
		multi.set_instance_color(i, cor)
	_estrelas = MultiMeshInstance3D.new()
	_estrelas.name = "Estrelas"
	_estrelas.multimesh = multi
	_estrelas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_estrelas.custom_aabb = AABB(Vector3(-100, -20, -100), Vector3(200, 120, 200))
	add_child(_estrelas)


func _criar_lua() -> void:
	_lua = MeshInstance3D.new()
	_lua.name = "Lua"
	var esfera := SphereMesh.new()
	esfera.radius = 4.0
	esfera.height = 8.0
	_lua.mesh = esfera
	_mat_lua = StandardMaterial3D.new()
	_mat_lua.albedo_color = Color(1, 0.97, 0.88, 0)
	_mat_lua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_lua.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_lua.disable_fog = true
	_lua.material_override = _mat_lua
	_lua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_lua)


# --- Estrela cadente ---------------------------------------------------------------

func _conferir_estrela() -> void:
	var tem := CicloDia.estrela_disponivel()
	if tem and not is_instance_valid(_estrela_cadente):
		_criar_estrela_cadente()
	elif not tem and is_instance_valid(_estrela_cadente):
		_estrela_cadente.queue_free()
		_estrela_cadente = null


func _criar_estrela_cadente() -> void:
	var no := Node3D.new()
	no.name = "EstrelaCadente"
	var alvo := CicloDia.lugar_estrela() + Vector3(0, 1.2, 0)
	no.set_meta("alvo", alvo)
	no.position = alvo + Vector3(-18, 28, -10)  # cai do céu na primeira vez que aparece
	add_child(no)
	_estrela_cadente = no
	var figura := Sprite3D.new()
	figura.texture = ESTRELA
	figura.pixel_size = 0.006
	figura.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	figura.shaded = false
	no.add_child(figura)
	# facho de luz até o céu: dá para achar de longe
	var facho := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.35
	cilindro.bottom_radius = 0.12
	cilindro.height = 14.0
	facho.mesh = cilindro
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.93, 0.55, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	facho.material_override = mat
	facho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	facho.position.y = 7.0
	no.add_child(facho)
	var luz := OmniLight3D.new()
	luz.light_color = Color("#FFE27A")
	luz.light_energy = 2.0
	luz.omni_range = 5.0
	no.add_child(luz)
	var brilhos := _particulas(16, Color("#FFE27A"), 0.25, 1.3)
	brilhos.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	brilhos.emission_sphere_radius = 0.6
	brilhos.local_coords = false
	no.add_child(brilhos)


# --- Chuva de granulado ------------------------------------------------------------

func _mudar_chuva(chuva: bool) -> void:
	for gota in _gotas.values():
		gota.queue_free()
	_gotas.clear()
	if is_instance_valid(_chuva):
		_chuva.emitting = chuva
	if not chuva:
		return
	if not is_instance_valid(_chuva) and Telas.animacoes_continuas:
		_chuva = _criar_chuva()
	var lugares := CicloDia.lugares_gotas()
	for i in lugares.size():
		if not CicloDia.gota_pega(i):
			_gotas[i] = _criar_gota(i, lugares[i])


func _criar_chuva() -> CPUParticles3D:
	var chuva := CPUParticles3D.new()
	chuva.name = "ChuvaDeGranulado"
	chuva.amount = [120, 220, 360][Qualidade.nivel()]
	chuva.lifetime = 1.8
	chuva.local_coords = false
	chuva.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	chuva.emission_box_extents = Vector3(16, 0.5, 16)
	chuva.direction = Vector3.DOWN
	chuva.spread = 4.0
	chuva.initial_velocity_min = 7.0
	chuva.initial_velocity_max = 9.0
	chuva.gravity = Vector3(0, -2, 0)
	chuva.angle_min = -40.0
	chuva.angle_max = 40.0
	var granulado := CapsuleMesh.new()
	granulado.radius = 0.035
	granulado.height = 0.22
	granulado.radial_segments = 6
	granulado.rings = 1
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	granulado.material = mat
	chuva.mesh = granulado
	var cores := Gradient.new()
	cores.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	cores.offsets = PackedFloat32Array()
	cores.colors = PackedColorArray()
	for i in CORES_GRANULADO.size():
		cores.add_point(float(i) / CORES_GRANULADO.size(), Color(CORES_GRANULADO[i]))
	chuva.color_initial_ramp = cores
	add_child(chuva)
	return chuva


## Gota de granulado para pegar: um montinho de granulados coloridos que
## brilha, gira e flutua.
func _criar_gota(indice: int, lugar: Vector3) -> Node3D:
	var no := Node3D.new()
	no.name = "Gota%d" % indice
	no.position = lugar + Vector3(0, 0.55, 0)
	add_child(no)
	# três granulados cruzados (poucos desenhos: são 12 gotas) que brilham
	for k in 3:
		var peca := MeshInstance3D.new()
		var capsula := CapsuleMesh.new()
		capsula.radius = 0.08
		capsula.height = 0.4
		capsula.radial_segments = 8
		capsula.rings = 1
		peca.mesh = capsula
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(CORES_GRANULADO[(k * 2 + indice) % CORES_GRANULADO.size()])
		mat.roughness = 0.25
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.5
		peca.material_override = mat
		peca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		peca.rotation = Vector3(k * 1.05, k * 0.9, PI / 2.0 * (k % 2))
		no.add_child(peca)
	return no


## Partículas de brilho (quadradinhos com a textura de brilho, que somem).
func _particulas(quantas: int, cor: Color, tamanho: float, vida: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = quantas
	p.lifetime = vida
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3.ZERO
	var quad := QuadMesh.new()
	quad.size = Vector2(tamanho, tamanho)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = BRILHO
	mat.albedo_color = cor
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.mesh = quad
	var sumir := Gradient.new()
	sumir.set_color(0, Color(1, 1, 1, 1))
	sumir.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = sumir
	return p
