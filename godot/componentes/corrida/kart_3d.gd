class_name Kart3D
extends Node3D
## Kart da Corrida de Doces: carrinho de bala com rodas de rosquinha (com
## cobertura), aerofólio, escapamentos que soltam fogo no TURBO e o doce
## pilotando. A frente do kart é o -z. Sem `doce`, fica sem piloto (o kart
## de enfeite na frente da Pista, na vila).

const ESCALA_DOCE := 0.42
const RAIO_RODA := 0.32

var doce := ""
var nivel := 0
var cor := Color("#F4E038")
var corpo: Node3D
var piloto: Node3D
var rodas: Array[Node3D] = []
var _fogo: CPUParticles3D


func _ready() -> void:
	corpo = Node3D.new()
	corpo.name = "Corpo"
	add_child(corpo)
	var tinta := Pecas3D.material(cor, 0.22)
	var escuro := Pecas3D.material(Color("#3A2A4A"), 0.5)
	var branco := Pecas3D.material(Color("#FFF6EE"), 0.35)
	# chassi arredondado, para-choque e encosto
	Pecas3D.caixa(corpo, Vector3(1.4, 0.32, 2.1), Vector3(0, 0.42, 0.1), tinta)
	Pecas3D.esfera(corpo, 0.7, Vector3(0, 0.44, -0.95), tinta, Vector3(1.0, 0.42, 0.75))
	Pecas3D.caixa(corpo, Vector3(1.5, 0.14, 0.32), Vector3(0, 0.3, -1.38), escuro)
	Pecas3D.caixa(corpo, Vector3(1.2, 0.5, 0.22), Vector3(0, 0.8, 0.88), tinta)
	Pecas3D.caixa(corpo, Vector3(0.28, 0.03, 1.3), Vector3(0, 0.6, -0.3), branco)  # listra no capô
	# aerofólio com plaquinhas dos lados
	Pecas3D.caixa(corpo, Vector3(1.6, 0.08, 0.42), Vector3(0, 1.14, 1.2), escuro)
	for lado in [-1, 1]:
		Pecas3D.caixa(corpo, Vector3(0.08, 0.45, 0.1), Vector3(lado * 0.5, 0.88, 1.18), escuro)
		Pecas3D.caixa(corpo, Vector3(0.06, 0.32, 0.5), Vector3(lado * 0.8, 1.14, 1.2), tinta)
		Pecas3D.cilindro(corpo, 0.08, 0.1, 0.34, Vector3(lado * 0.34, 0.42, 1.28), escuro, Vector3.ONE, Vector3(90, 0, 0))
	Pecas3D.rosquinha(corpo, 0.1, 0.17, Vector3(0, 0.86, -0.36), escuro, Vector3.ONE, Vector3(-60, 0, 0))
	# rodas de rosquinha (as de trás maiores), com cobertura rosa por fora
	var massa := Pecas3D.material(Color("#D9955A"), 0.7)
	var cobertura := Pecas3D.material(Color("#FF8FB8"), 0.25)
	for p in [Vector3(-0.82, 0.3, -0.72), Vector3(0.82, 0.3, -0.72), Vector3(-0.86, 0.34, 0.78), Vector3(0.86, 0.34, 0.78)]:
		var roda := Node3D.new()
		roda.name = "Roda"
		roda.position = p
		corpo.add_child(roda)
		var raio: float = p.y
		Pecas3D.rosquinha(roda, raio * 0.35, raio, Vector3.ZERO, massa, Vector3.ONE, Vector3(0, 0, 90))
		Pecas3D.rosquinha(roda, raio * 0.42, raio * 0.9, Vector3(signf(p.x) * 0.07, 0, 0), cobertura,
			Vector3(1, 0.45, 1), Vector3(0, 0, 90))
		rodas.append(roda)
	if doce != "":
		piloto = Node3D.new()
		piloto.name = "Piloto"
		piloto.scale = Vector3.ONE * ESCALA_DOCE
		piloto.position = Vector3(0, 0.5 + 1.2 * ESCALA_DOCE, 0.32)
		piloto.rotation.y = PI  # o rosto dos doces fica no +z; o kart anda para o -z
		corpo.add_child(piloto)
		Doces3D.montar(doce, piloto)
		if nivel > 0:
			Doces3D.enfeitar(piloto, doce, nivel)
	CenarioVila.sombra_contato(self, Vector3(0, 0.02, 0), 1.5, 0.5)
	_fogo = CPUParticles3D.new()
	_fogo.name = "Fogo"
	_fogo.emitting = false
	_fogo.amount = 36
	_fogo.lifetime = 0.18
	_fogo.local_coords = false
	_fogo.position = Vector3(0, 0.42, 1.5)
	_fogo.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_fogo.emission_sphere_radius = 0.1
	_fogo.direction = Vector3(0, 0.15, 1)
	_fogo.spread = 10.0
	_fogo.initial_velocity_min = 3.0
	_fogo.initial_velocity_max = 5.0
	_fogo.gravity = Vector3.ZERO
	_fogo.scale_amount_min = 0.7
	_fogo.scale_amount_max = 1.2
	var encolher := Curve.new()
	encolher.add_point(Vector2(0, 1))
	encolher.add_point(Vector2(1, 0.2))
	_fogo.scale_amount_curve = encolher
	var tons := Gradient.new()
	tons.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	tons.colors = PackedColorArray([Color("#FFD23F"), Color("#FF7A1A"), Color(0.9, 0.15, 0.05, 0.0)])
	_fogo.color_ramp = tons
	var bolinha := SphereMesh.new()
	bolinha.radius = 0.11
	bolinha.height = 0.22
	bolinha.radial_segments = 8
	bolinha.rings = 4
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bolinha.material = mat
	_fogo.mesh = bolinha
	add_child(_fogo)


## Leve para o celular: as peças de cada parte (corpo, rodas, piloto) juntadas.
func otimizar() -> void:
	CenarioVila.estilo_desenho(self)
	JuntarMalhas.simplificar(self)
	JuntarMalhas.juntar_boneco(self)


func turbo(ligado: bool) -> void:
	if _fogo.emitting != ligado:
		_fogo.emitting = ligado


## Gira as rodas pela distância andada (metros).
func rodar(distancia: float) -> void:
	for roda in rodas:
		roda.rotation.x -= distancia / RAIO_RODA
