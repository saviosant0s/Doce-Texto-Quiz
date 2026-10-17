class_name ChefaoVila
extends Node3D
## O chefão gigante em cima da fonte da praça (regras em scripts/chefao.gd):
## respira e balança, tem uma aura escura em volta, joga chocolate no doce
## do jogador, treme quando leva um golpe, fica vermelho quando está BRAVO e,
## vencido, explode numa chuva de doces.

const ESCALA := 3.0
const ALTURA := 2.6  # os pés ficam em cima da fonte

var doce := "chocolate"
var _pivo: Node3D
var _animacao := AnimacaoDoce.new()
var _aura: CPUParticles3D
var _luz_brava: OmniLight3D
var _tempo := 0.0


func _ready() -> void:
	name = "Chefao"
	_pivo = Node3D.new()
	_pivo.name = "Gigante"
	_pivo.scale = Vector3.ONE * ESCALA
	_pivo.position.y = ALTURA + 1.2 * ESCALA
	add_child(_pivo)
	var modelo := Node3D.new()
	_pivo.add_child(modelo)
	Doces3D.montar(doce, modelo)
	Doces3D.enfeitar(modelo, doce, Companheiros.NIVEL_MAXIMO)  # com coroa
	_sobrancelhas(modelo)
	# leve: as peças de cada parte (corpo, braços, olhos...) juntadas
	CenarioVila.estilo_desenho(modelo)
	JuntarMalhas.simplificar(modelo)
	JuntarMalhas.juntar_boneco(modelo)
	add_child(_animacao)
	_animacao.configurar(modelo)
	# virado para o sul (de onde o jogador chega pela avenida)
	_pivo.rotation.y = 0.0
	_aura = CPUParticles3D.new()
	_aura.name = "Aura"
	_aura.amount = 40
	_aura.lifetime = 1.6
	_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_aura.emission_sphere_radius = 3.6
	_aura.position = _pivo.position
	_aura.direction = Vector3.UP
	_aura.spread = 30.0
	_aura.initial_velocity_min = 0.6
	_aura.initial_velocity_max = 1.4
	_aura.gravity = Vector3(0, 0.4, 0)
	_aura.scale_amount_min = 0.5
	_aura.scale_amount_max = 1.2
	var bolinha := SphereMesh.new()
	bolinha.radius = 0.18
	bolinha.height = 0.36
	bolinha.radial_segments = 8
	bolinha.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.08, 0.3, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolinha.material = mat
	_aura.mesh = bolinha
	add_child(_aura)
	_luz_brava = OmniLight3D.new()
	_luz_brava.light_color = Color("#FF3030")
	_luz_brava.light_energy = 0.0
	_luz_brava.visible = false  # (apagada mas ligada, a luz pesava em tudo em volta da praça)
	_luz_brava.omni_range = 12.0
	_luz_brava.position = _pivo.position + Vector3(0, 0, 4)
	add_child(_luz_brava)


func _process(delta: float) -> void:
	_tempo += delta
	_pivo.rotation.y = sin(_tempo * 0.6) * 0.25
	_pivo.rotation.z = sin(_tempo * 1.3) * 0.04


## Sobrancelhas bravas em cima dos olhos (o modelo é o mesmo da coleção).
func _sobrancelhas(modelo: Node3D) -> void:
	var olhos := modelo.find_child("Olhos", true, false) as Node3D
	if olhos == null:
		return
	var escuro := Pecas3D.material(Color("#2A1410"), 0.4)
	for lado in [-1, 1]:
		var s := Pecas3D.caixa(olhos.get_parent(), Vector3(0.22, 0.05, 0.05),
			olhos.position + Vector3(lado * 0.17, 0.17, 0.06), escuro)
		s.rotation.z = -lado * 0.45


## Onde o chefão é atingido (o meio do corpo, no mundo).
func alvo() -> Vector3:
	return _pivo.global_position + Vector3(0, -0.4 * ESCALA, 0.6 * ESCALA)


## De onde ele joga as coisas (a mão, mais ou menos).
func mao() -> Vector3:
	return _pivo.global_position + Vector3(1.1 * ESCALA, 0.1 * ESCALA, 0.5 * ESCALA)


## Levou um golpe: encolhe e treme um pouco.
func receber_golpe(forte: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_pivo, "scale", Vector3(1.08, 0.88, 1.08) * ESCALA * _tamanho(), 0.08)
	tween.tween_property(_pivo, "scale", Vector3.ONE * ESCALA * _tamanho(), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var base := _pivo.position
	var tremor := create_tween()
	for i in (6 if forte else 3):
		tremor.tween_property(_pivo, "position", base + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.2, 0.2)), 0.04)
	tremor.tween_property(_pivo, "position", base, 0.05)


## Inclina para a frente (antes de jogar o chocolate).
func preparar_ataque() -> void:
	var tween := create_tween()
	tween.tween_property(_pivo, "rotation:x", 0.3, 0.18)
	tween.tween_property(_pivo, "rotation:x", 0.0, 0.3)


var _bravo := false


## Metade da vida: fica maior e vermelho.
func ficar_bravo() -> void:
	_bravo = true
	create_tween().tween_property(_pivo, "scale", Vector3.ONE * ESCALA * _tamanho(), 0.5).set_trans(Tween.TRANS_ELASTIC)
	_luz_brava.visible = true
	create_tween().tween_property(_luz_brava, "light_energy", 3.0, 0.5)
	(_aura.mesh.material as StandardMaterial3D).albedo_color = Color(0.6, 0.05, 0.05, 0.6)
	_aura.amount = 70


func _tamanho() -> float:
	return 1.12 if _bravo else 1.0


## Vencido: encolhe girando e explode numa chuva de doces coloridos.
func explodir() -> void:
	_aura.emitting = false
	var chuva := chuva_de_doces(160)
	chuva.position = _pivo.position
	add_child(chuva)
	var tween := create_tween().set_parallel()
	tween.tween_property(_pivo, "scale", Vector3.ONE * 0.01, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_pivo, "rotation:y", TAU * 2.0, 0.6)
	tween.tween_property(_luz_brava, "light_energy", 0.0, 0.4)
	await tween.finished
	_luz_brava.visible = false
	chuva.emitting = true


static var _malha_chuva: SphereMesh


## A chuva de doces coloridos de quando ele é vencido (sem tocar ainda).
static func chuva_de_doces(quantos: int) -> CPUParticles3D:
	var chuva := CPUParticles3D.new()
	chuva.name = "ChuvaDeDoces"
	chuva.one_shot = true
	chuva.explosiveness = 0.9
	chuva.amount = quantos
	chuva.lifetime = 2.6
	chuva.direction = Vector3.UP
	chuva.spread = 70.0
	chuva.initial_velocity_min = 6.0
	chuva.initial_velocity_max = 12.0
	chuva.gravity = Vector3(0, -9.0, 0)
	chuva.scale_amount_min = 0.6
	chuva.scale_amount_max = 1.4
	chuva.hue_variation_min = -1.0
	chuva.hue_variation_max = 1.0
	chuva.color = Color("#FF6FAE")
	chuva.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _malha_chuva == null:
		_malha_chuva = SphereMesh.new()
		_malha_chuva.radius = 0.16
		_malha_chuva.height = 0.32
		_malha_chuva.radial_segments = 8
		_malha_chuva.rings = 4
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.2
		_malha_chuva.material = mat
	chuva.mesh = _malha_chuva
	return chuva


## Aquecer a vila: liga a luz vermelha (fraquinha) por um instante, para o
## celular preparar o desenho com ela antes da luta.
func aquecer(ligar: bool) -> void:
	_luz_brava.visible = ligar or _bravo
	if ligar and not _bravo:
		_luz_brava.light_energy = 0.01
	elif not _bravo:
		_luz_brava.light_energy = 0.0
