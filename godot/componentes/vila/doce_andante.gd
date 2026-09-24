class_name DoceAndante
extends CharacterBody3D
## Um doce que anda pela Vila dos Doces: o do jogador (controlado pelo joystick
## ou teclado) ou um vizinho passeando sozinho. Vira para onde anda, balança
## pernas e braços (AnimacaoDoce) e tem uma sombrinha redonda embaixo.

const VELOCIDADE := 5.0
const ESCALA := 0.72  # os modelos têm ~2,4 de altura; na vila ficam com ~1,7
const GIRO := 10.0

## Id do doce (ver Colecao.LISTA).
var id := "brigadeiro"
## Vizinho: anda sozinho, sem controle do jogador.
var passeando := false

var _modelo: Node3D
var _animacao := AnimacaoDoce.new()
var _destino := Vector3.ZERO
var _espera := 0.0
var _area_passeio := Rect2(-6, -6, 12, 12)


func _ready() -> void:
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
	_criar_sombra()
	if passeando:
		_escolher_destino()


## Só para vizinhos: passeiam dentro deste retângulo (no chão, x e z).
func definir_area_passeio(area: Rect2) -> void:
	_area_passeio = area
	_escolher_destino()


## Anda na direção dada (no chão; comprimento de 0 a 1 = velocidade).
func andar(direcao: Vector3, delta: float) -> void:
	var intensidade := clampf(direcao.length(), 0.0, 1.0)
	var alvo := direcao.normalized() * VELOCIDADE * intensidade if intensidade > 0.05 else Vector3.ZERO
	velocity.x = alvo.x
	velocity.z = alvo.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	var andando := intensidade > 0.05
	_animacao.andando = andando
	_animacao.ritmo = intensidade
	if andando:
		var angulo := atan2(direcao.x, direcao.z)
		_modelo.rotation.y = lerp_angle(_modelo.rotation.y, angulo, minf(1.0, GIRO * delta))


## Vira de frente para um ponto (ex.: ao sair de um prédio).
func olhar_para(ponto: Vector3) -> void:
	var direcao := ponto - global_position
	_modelo.rotation.y = atan2(direcao.x, direcao.z)


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
	add_child(sombra)
