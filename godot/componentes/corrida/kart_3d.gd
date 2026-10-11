class_name Kart3D
extends Node3D
## Carro da Corrida de Doces, com o doce pilotando e fogo no TURBO. A frente é
## o -z. Sem `doce`, fica sem piloto (o kart de enfeite na frente da Pista, na vila).
## - modelo "kart": carrinho de bala com rodas de rosquinha (com cobertura) e aerofólio.
## - modelo "f1": carro de Fórmula 1 de verdade (assets/carros/carro_f1.glb, feito no
##   Blender por ferramentas/gerar_carro_f1.sh), pintado com as cores da `equipe`
##   (EQUIPES_F1) pelo shader tema/pintura_f1.gdshader; o doce vai no cockpit,
##   menor, e as rodas da frente viram nas curvas.

const ESCALA_DOCE := 0.42
const RAIO_RODA := 0.32
const CARRO_F1 := preload("res://assets/carros/carro_f1.glb")
const PINTURA_F1 := preload("res://tema/pintura_f1.gdshader")
const ESCALA_F1 := 1.25  # (o modelo tem 66% de um F1 de verdade; maior, fica do tamanho dos karts)
const ESCALA_DOCE_F1 := 0.2
const RAIO_RODA_F1 := 0.24
## Pinturas do F1: [cor principal, segunda, terceira] (inspiradas nas equipes de
## verdade, sem nome nem marca).
const EQUIPES_F1 := {
	"azul": ["#1B2650", "#D51B2E", "#FFC726"],  # azul-escuro fosco, vermelho e amarelo (como a Red Bull)
}

var doce := ""
var nivel := 0
var cor := Color("#F4E038")
var modelo := "kart"
var equipe := "azul"
var corpo: Node3D
var piloto: Node3D
var rodas: Array[Node3D] = []
var _rodas_frente: Array[Node3D] = []
var _raio_roda := RAIO_RODA
var _fogo: CPUParticles3D

## Materiais do F1 já feitos, por equipe (os carros iguais dividem os materiais).
static var _materiais_f1 := {}
static var _carbono: ImageTexture


func _ready() -> void:
	corpo = Node3D.new()
	corpo.name = "Corpo"
	add_child(corpo)
	if modelo == "f1":
		_montar_f1()
	else:
		_montar_kart()
	if doce != "":
		piloto = Node3D.new()
		piloto.name = "Piloto"
		if modelo == "f1":  # sentado no cockpit, só a parte de cima aparece (como o capacete)
			piloto.scale = Vector3.ONE * ESCALA_DOCE_F1 * ESCALA_F1
			piloto.position = Vector3(0, 0.49, -0.08) * ESCALA_F1
		else:
			piloto.scale = Vector3.ONE * ESCALA_DOCE
			piloto.position = Vector3(0, 0.5 + 1.2 * ESCALA_DOCE, 0.32)
		piloto.rotation.y = PI  # o rosto dos doces fica no +z; o kart anda para o -z
		corpo.add_child(piloto)
		Doces3D.montar(doce, piloto)
		if nivel > 0:
			Doces3D.enfeitar(piloto, doce, nivel)
	if modelo == "f1":
		CenarioVila.sombra_contato(self, Vector3(0, 0.02, 0), 1.0, 0.5).scale = Vector3(0.8, 1, 2.0) * ESCALA_F1
	else:
		CenarioVila.sombra_contato(self, Vector3(0, 0.02, 0), 1.5, 0.5)
	_criar_fogo(Vector3(0, 0.305, 1.72) * ESCALA_F1 if modelo == "f1" else Vector3(0, 0.42, 1.5))


func _montar_kart() -> void:
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


## O F1 do Blender com a pintura da equipe; as rodas são nós separados (giram
## pelo meio) e as da frente viram nas curvas.
func _montar_f1() -> void:
	var carro: Node3D = CARRO_F1.instantiate()
	carro.name = "F1"
	carro.scale = Vector3.ONE * ESCALA_F1
	corpo.add_child(carro)
	var trocas := _materiais_da_equipe(equipe)
	for no in carro.find_children("*", "MeshInstance3D", true, false):
		var peca := no as MeshInstance3D
		for i in peca.mesh.get_surface_count():
			var mat := peca.mesh.surface_get_material(i)
			if mat and trocas.has(mat.resource_name):
				peca.set_surface_override_material(i, trocas[mat.resource_name])
	for nome in ["Roda_FE", "Roda_FD", "Roda_TE", "Roda_TD"]:
		var roda := carro.find_child(nome, true, false) as Node3D
		rodas.append(roda)
		if nome.begins_with("Roda_F"):
			_rodas_frente.append(roda)
	_raio_roda = RAIO_RODA_F1 * ESCALA_F1


## Pintura (com as faixas), segunda e terceira cor e o carbono trançado.
static func _materiais_da_equipe(nome: String) -> Dictionary:
	if _materiais_f1.has(nome):
		return _materiais_f1[nome]
	var cores: Array = EQUIPES_F1.get(nome, EQUIPES_F1["azul"])
	var pintura := ShaderMaterial.new()
	pintura.shader = PINTURA_F1
	pintura.set_shader_parameter("cor_base", Color(cores[0]))
	pintura.set_shader_parameter("cor_destaque", Color(cores[1]))
	pintura.set_shader_parameter("cor_detalhe", Color(cores[2]))
	var destaque := StandardMaterial3D.new()
	destaque.albedo_color = Color(cores[1])
	destaque.metallic = 0.3
	destaque.roughness = 0.4
	var detalhe := StandardMaterial3D.new()
	detalhe.albedo_color = Color(cores[2])
	detalhe.roughness = 0.35
	var carbono := StandardMaterial3D.new()
	carbono.albedo_texture = _trama_carbono()
	carbono.uv1_triplanar = true
	carbono.uv1_scale = Vector3.ONE * 18.0  # (uma trama a cada ~5 cm)
	carbono.roughness = 0.38
	carbono.metallic_specular = 0.3  # (brilhando demais, refletia o chão verde do céu e ficava esverdeado)
	_materiais_f1[nome] = {"Pintura": pintura, "Destaque": destaque, "Detalhe": detalhe, "Carbono": carbono}
	return _materiais_f1[nome]


## Trama de fibra de carbono (fios alternando na diagonal), feita uma vez só.
static func _trama_carbono() -> ImageTexture:
	if _carbono == null:
		var img := Image.create(64, 64, true, Image.FORMAT_RGB8)
		for y in 64:
			for x in 64:
				var deitado := ((x / 8 + y / 8) % 2) == 0
				var ao_longo := float(x % 8 if deitado else y % 8) / 7.0
				var brilho := 0.06 + 0.07 * sin(ao_longo * PI)
				img.set_pixel(x, y, Color(brilho, brilho * 1.04, brilho * 1.12))
		img.generate_mipmaps()
		_carbono = ImageTexture.create_from_image(img)
	return _carbono


func _criar_fogo(posicao: Vector3) -> void:
	_fogo = CPUParticles3D.new()
	_fogo.name = "Fogo"
	_fogo.emitting = false
	_fogo.amount = 36
	_fogo.lifetime = 0.18
	_fogo.local_coords = false
	_fogo.position = posicao
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
		roda.rotation.x -= distancia / _raio_roda


## Vira as rodas da frente (F1) na curva: giro de -1 (esquerda) a 1 (direita).
func virar(giro: float) -> void:
	for roda in _rodas_frente:
		roda.rotation.y = -giro * 0.35
