class_name DoceAndante
extends CharacterBody3D
## Um doce que anda pela Vila dos Doces: o do jogador (controlado pelo joystick
## ou teclado) ou um vizinho passeando sozinho. Vira para onde anda, balança
## pernas e braços (AnimacaoDoce), acelera e freia aos poucos, inclina nas
## curvas, corre soltando poeira de açúcar e pula (amassando ao cair).

const VELOCIDADE := 4.2  # andando
const VELOCIDADE_CORRENDO := 7.0  # joystick empurrado até o fim
const ACELERACAO := 16.0
const FREIO := 12.0
const FORCA_PULO := 7.5
const GRAVIDADE := 22.0
const ESCALA := 0.72  # os modelos têm ~2,4 de altura; na vila ficam com ~1,7
const GIRO := 10.0

## Id do doce (ver Colecao.LISTA).
var id := "brigadeiro"
## Vizinho: anda sozinho, sem controle do jogador.
var passeando := false
## Sombra redonda falsa embaixo (desligada quando a luz já faz sombra de verdade).
var sombra_redonda := true
## Faz barulho de passos, pulo e queda (só o doce do jogador).
var com_som := false
## Sem colisão e sem gravidade (clientes da confeitaria: passam uns pelos
## outros e pelo jogador, sempre no chão).
var sem_colisao := false

var _modelo: Node3D
var _sombra: MeshInstance3D
var _animacao := AnimacaoDoce.new()
var _destino := Vector3.ZERO
var _espera := 0.0
var _area_passeio := Rect2(-6, -6, 12, 12)
var _no_chao := true
var _poeira: CPUParticles3D
var _inclinacao := 0.0


func _ready() -> void:
	# bonecos na camada 2 (a câmera ignora), batendo em paredes (1) e uns nos outros (2)
	collision_layer = 0 if sem_colisao else 2
	collision_mask = 0 if sem_colisao else 3
	var forma := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.48
	capsula.height = 1.7
	forma.shape = capsula
	forma.position.y = 0.85
	add_child(forma)
	_modelo = Node3D.new()
	_modelo.name = "Modelo"
	_modelo.scale = Vector3.ONE * ESCALA
	_modelo.position.y = 2.4 * ESCALA * 0.5 + 0.05  # o modelo é centrado; os pés ficam no chão
	add_child(_modelo)
	Doces3D.montar(id, _modelo)
	add_child(_animacao)
	_animacao.configurar(_modelo)
	_animacao.pisou.connect(func():
		if com_som:
			Audio.tocar("passo", randf_range(0.9, 1.15), -14.0))
	_criar_sombra()
	_criar_poeira()
	if passeando:
		_escolher_destino()


## Só para vizinhos: passeiam dentro deste retângulo (no chão, x e z).
func definir_area_passeio(area: Rect2) -> void:
	_area_passeio = area
	_escolher_destino()


## Anda na direção dada (no chão; comprimento de 0 a 1 = velocidade; perto de
## 1 = correndo). Acelera e freia aos poucos e inclina nas curvas.
func andar(direcao: Vector3, delta: float) -> void:
	var intensidade := clampf(direcao.length(), 0.0, 1.0)
	var maxima := VELOCIDADE_CORRENDO if intensidade > 0.85 else VELOCIDADE
	var alvo := direcao.normalized() * maxima * intensidade if intensidade > 0.05 else Vector3.ZERO
	var horizontal := Vector2(velocity.x, velocity.z)
	var taxa := ACELERACAO if alvo.length() > horizontal.length() else FREIO
	horizontal = horizontal.move_toward(Vector2(alvo.x, alvo.z), taxa * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if sem_colisao:
		velocity.y = 0.0
	else:
		velocity.y -= GRAVIDADE * delta  # ao bater no chão, move_and_slide zera
	move_and_slide()
	var no_chao := is_on_floor() or sem_colisao
	var velocidade := horizontal.length()
	var andando := velocidade > 0.3 and no_chao
	_animacao.andando = andando
	_animacao.ritmo = velocidade / VELOCIDADE
	_animacao.velocidade_chao = velocidade
	var giro := 0.0
	if intensidade > 0.05:
		var angulo := atan2(direcao.x, direcao.z)
		var antes := _modelo.rotation.y
		_modelo.rotation.y = lerp_angle(_modelo.rotation.y, angulo, minf(1.0, GIRO * delta))
		giro = angle_difference(antes, _modelo.rotation.y) / maxf(delta, 0.001)
	# inclina para frente ao correr e para o lado nas curvas
	_inclinacao = lerpf(_inclinacao, clampf(-giro * 0.05, -0.25, 0.25), minf(1.0, 8.0 * delta))
	_modelo.rotation.x = lerpf(_modelo.rotation.x, velocidade / VELOCIDADE_CORRENDO * 0.18, minf(1.0, 8.0 * delta))
	_modelo.rotation.z = _inclinacao
	# poeirinha de açúcar ao correr
	_poeira.emitting = andando and velocidade > VELOCIDADE * 0.9
	# chegou no chão depois de um pulo: amassadinha de desenho animado
	if no_chao and not _no_chao:
		_amassar()
	_no_chao = no_chao


## Pula (só se estiver no chão).
func pular() -> void:
	if not is_on_floor():
		return
	velocity.y = FORCA_PULO
	_no_chao = false
	if com_som:
		Audio.tocar("pulo", randf_range(0.95, 1.05), -4.0)
	var tween := create_tween()
	tween.tween_property(_modelo, "scale", Vector3(0.85, 1.2, 0.85) * ESCALA, 0.1)
	tween.tween_property(_modelo, "scale", Vector3.ONE * ESCALA, 0.2)


func _amassar() -> void:
	if com_som:
		Audio.tocar("passo", 0.8, -6.0)
	var tween := create_tween()
	tween.tween_property(_modelo, "scale", Vector3(1.25, 0.72, 1.25) * ESCALA, 0.07)
	tween.tween_property(_modelo, "scale", Vector3.ONE * ESCALA, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Vira para um ângulo (radianos, no eixo Y) sem andar.
func virar_para_angulo(angulo: float) -> void:
	_modelo.rotation.y = angulo


## Vira de frente para um ponto (ex.: ao sair de um prédio).
func olhar_para(ponto: Vector3) -> void:
	var direcao := ponto - global_position
	_modelo.rotation.y = atan2(direcao.x, direcao.z)


## Deixa o boneco leve: menos faces nas peças pequenas e as peças de cada
## parte (corpo, braços...) juntadas. Chame depois de
## CenarioVila.estilo_desenho().
func otimizar() -> void:
	JuntarMalhas.simplificar(_modelo)
	JuntarMalhas.juntar_boneco(_modelo)


## Liga/desliga as colisões (ex.: para atravessar a porta de um prédio).
func atravessar(sim: bool) -> void:
	sem_colisao = sim
	collision_layer = 0 if sim else 2
	collision_mask = 0 if sim else 3


## Nó à frente do doce, na altura das mãos, onde vai a pilha de coisas que
## ele carrega (doces da confeitaria). Vira junto com o doce; tamanho normal
## (sem a escala do modelo).
func pilha() -> Node3D:
	var no := _modelo.get_node_or_null("Pilha") as Node3D
	if no == null:
		no = Node3D.new()
		no.name = "Pilha"
		no.scale = Vector3.ONE / ESCALA
		no.position = Vector3(0, -0.15, 0.95)
		_modelo.add_child(no)
	return no


## Esconde o doce (câmera em primeira pessoa: a câmera fica "dentro" dele).
## (O que ele carrega nas mãos, a "Pilha", continua aparecendo.)
func mostrar_modelo(visivel: bool) -> void:
	for parte in _modelo.get_children():
		if parte.name != "Pilha" and parte is Node3D:
			parte.visible = visivel
	_sombra.visible = visivel and sombra_redonda


## Para onde o doce está virado (no chão).
func frente() -> Vector3:
	return Vector3(sin(_modelo.rotation.y), 0, cos(_modelo.rotation.y))


func comemorar() -> void:
	_animacao.comemorar()


func _physics_process(delta: float) -> void:
	if not passeando:
		return
	if _espera > 0.0:
		_espera -= delta
		andar(Vector3.ZERO, delta)
		return
	var caminho := _destino - global_position
	caminho.y = 0.0
	if caminho.length() < 0.4 or get_slide_collision_count() > 0 and randf() < 0.02:
		_espera = randf_range(1.0, 3.5)
		_escolher_destino()
		return
	andar(caminho.normalized() * 0.45, delta)  # vizinhos andam devagar


func _escolher_destino() -> void:
	_destino = Vector3(
		randf_range(_area_passeio.position.x, _area_passeio.end.x), 0,
		randf_range(_area_passeio.position.y, _area_passeio.end.y))


## Sombra redonda e suave no chão (leve: sem sombras de verdade).
func _criar_sombra() -> void:
	var sombra := MeshInstance3D.new()
	_sombra = sombra
	var disco := CylinderMesh.new()
	disco.top_radius = 0.6
	disco.bottom_radius = 0.6
	disco.height = 0.01
	sombra.mesh = disco
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.05, 0.2, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sombra.material_override = mat
	sombra.position.y = 0.02
	sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sombra.visible = sombra_redonda
	add_child(sombra)


## Poeira de açúcar saindo dos pés (bolinhas brancas que sobem e somem).
func _criar_poeira() -> void:
	_poeira = CPUParticles3D.new()
	_poeira.emitting = false
	_poeira.amount = 14
	_poeira.lifetime = 0.5
	_poeira.local_coords = false
	var bolinha := SphereMesh.new()
	bolinha.radius = 0.07
	bolinha.height = 0.14
	bolinha.radial_segments = 8
	bolinha.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolinha.material = mat
	_poeira.mesh = bolinha
	_poeira.direction = Vector3(0, 1, 0)
	_poeira.spread = 60.0
	_poeira.initial_velocity_min = 0.6
	_poeira.initial_velocity_max = 1.2
	_poeira.gravity = Vector3(0, -1.5, 0)
	_poeira.scale_amount_min = 0.6
	_poeira.scale_amount_max = 1.3
	var curva := Curve.new()
	curva.add_point(Vector2(0, 1))
	curva.add_point(Vector2(1, 0))
	_poeira.scale_amount_curve = curva
	_poeira.position.y = 0.1
	add_child(_poeira)
