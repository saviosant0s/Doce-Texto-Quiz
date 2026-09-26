class_name EventoVila
extends Node3D
## O evento da temporada na vila (ver Eventos): decoração em volta da praça
## (varais de bandeirinhas nas cores do evento e enfeites do tema), partículas
## (pétalas, confete, neve...) e os objetos do evento espalhados pela vila
## para pegar (cada um dá fichas; renovam todo dia).

signal item_pego(fichas: int)

const DISTANCIA_PEGAR := 1.3
## Cores dos enfeites de cada evento.
const CORES := {
	"primavera": ["#FF8FB8", "#FFD23F", "#FFFFFF", "#7BE07B"],
	"halloween": ["#FF8A1F", "#3B2A5C", "#7BE07B", "#FFD23F"],
	"natal": ["#E8364F", "#2E7D32", "#FFFFFF", "#FFD23F"],
	"carnaval": ["#B07CFF", "#FFD23F", "#6FD3FF", "#FF6FAE"],
	"pascoa": ["#6FD3FF", "#FFB3D1", "#FFF1A8", "#B8F0C8"],
	"junina": ["#E8364F", "#FFD23F", "#6FD3FF", "#7BE07B"],
}

var id := ""
var _jogador: Node3D
var _itens := {}  # índice -> Node3D
var _tempo := 0.0


func configurar(jogador: Node3D) -> void:
	_jogador = jogador
	id = Eventos.atual()
	if id == "":
		return
	_varais()
	_enfeites()
	if Telas.animacoes_continuas:
		_particulas()
	var lugares := Eventos.lugares_itens()
	for i in lugares.size():
		if not Eventos.item_pego(i):
			_itens[i] = _criar_item(i, lugares[i])


func _process(delta: float) -> void:
	_tempo += delta
	if not is_instance_valid(_jogador):
		return
	var pe := _jogador.global_position
	for indice in _itens.keys():
		var item: Node3D = _itens[indice]
		item.rotation.y += delta * 1.8
		item.position.y = 0.7 + sin(_tempo * 2.5 + indice) * 0.12
		if Vector2(item.position.x - pe.x, item.position.z - pe.z).length() < DISTANCIA_PEGAR:
			var fichas := Eventos.pegar_item(indice)
			_itens.erase(indice)
			item.queue_free()
			if fichas > 0:
				Audio.tocar("moeda", 1.2, -5.0)
				item_pego.emit(fichas)


static func _m(cor: String, aspereza := 0.5, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


static func _luz(cor: String, forca := 1.2) -> StandardMaterial3D:
	var mat := _m(cor, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(cor)
	mat.emission_energy_multiplier = forca
	return mat


## Oito postes em volta da praça com varais de bandeirinhas (ou luzinhas,
## no Natal e no Halloween) entre eles.
func _varais() -> void:
	var cores: Array = CORES[id]
	var raio := 6.6
	var postes := []
	for i in 8:
		var a := i * TAU / 8.0 + TAU / 16.0
		var p := Vector3(cos(a) * raio, 0, sin(a) * raio)
		postes.append(p)
		Pecas3D.cilindro(self, 0.06, 0.08, 3.0, p + Vector3(0, 1.5, 0), _m("#FFFFFF", 0.4))
		Pecas3D.esfera(self, 0.12, p + Vector3(0, 3.05, 0), _m(cores[0], 0.3))
	var luzinhas := id in ["natal", "halloween"]
	for i in 8:
		var de: Vector3 = postes[i] + Vector3(0, 2.85, 0)
		var ate: Vector3 = postes[(i + 1) % 8] + Vector3(0, 2.85, 0)
		for k in 9:
			var t := (k + 0.5) / 9.0
			var p := de.lerp(ate, t) - Vector3(0, sin(t * PI) * 0.45, 0)
			var cor: String = cores[(k + i) % cores.size()]
			if luzinhas:
				Pecas3D.esfera(self, 0.08, p, _luz(cor, 0.8))
			else:
				var bandeira := MeshInstance3D.new()
				var prisma := PrismMesh.new()
				prisma.size = Vector3(0.28, 0.32, 0.02)
				bandeira.mesh = prisma
				bandeira.material_override = _m(cor, 0.6)
				bandeira.position = p - Vector3(0, 0.16, 0)
				bandeira.rotation = Vector3(PI, atan2(ate.x - de.x, ate.z - de.z) + PI / 2.0, 0)
				add_child(bandeira)


## Enfeites do tema em volta da praça e na avenida.
func _enfeites() -> void:
	var lugares := [Vector3(4.8, 0, 4.8), Vector3(-4.8, 0, 4.8), Vector3(4.8, 0, -4.8), Vector3(-4.8, 0, -4.8),
		Vector3(1.8, 0, 11), Vector3(-1.8, 0, 11)]
	for p in lugares:
		match id:
			"primavera":
				Pecas3D.cilindro(self, 0.45, 0.35, 0.6, p + Vector3(0, 0.3, 0), _m("#C8663F", 0.8))
				for i in 9:
					var a := i * 2.1
					Pecas3D.esfera(self, 0.2, p + Vector3(cos(a) * 0.3, 0.8 + (i % 3) * 0.15, sin(a) * 0.3),
						_m(["#FF8FB8", "#FFD23F", "#FFFFFF", "#B07CFF"][i % 4], 0.4))
			"halloween":
				for k in 3:
					var q: Vector3 = p + Vector3((k - 1) * 0.6, 0, (k % 2) * 0.4)
					Pecas3D.esfera(self, 0.35 - k * 0.06, q + Vector3(0, 0.3, 0), _luz("#FF8A1F", 0.25), Vector3(1.2, 0.9, 1.2))
					Pecas3D.cilindro(self, 0.03, 0.04, 0.15, q + Vector3(0, 0.62 - k * 0.06, 0), _m("#3FA34D", 0.6))
			"natal":
				Pecas3D.caixa(self, Vector3(0.6, 0.5, 0.6), p + Vector3(0, 0.25, 0), _m("#E8364F", 0.4))
				Pecas3D.caixa(self, Vector3(0.1, 0.52, 0.62), p + Vector3(0, 0.25, 0), _m("#FFD23F", 0.3))
				Pecas3D.caixa(self, Vector3(0.45, 0.4, 0.45), p + Vector3(0.7, 0.2, 0.2), _m("#2E7D32", 0.4))
			"carnaval":
				Pecas3D.cilindro(self, 0.05, 0.05, 1.6, p + Vector3(0, 0.8, 0), _m("#FFFFFF", 0.4))
				for x in [-0.25, 0.25]:
					Pecas3D.esfera(self, 0.28, p + Vector3(x, 1.75, 0), _m("#B07CFF", 0.2, 0.4), Vector3(1, 0.6, 0.3))
				Pecas3D.esfera(self, 0.35, p + Vector3(0, 2.2, 0), _m("#FFD23F", 0.3), Vector3(1.4, 0.4, 0.3))
			"pascoa":
				for k in 3:
					Pecas3D.esfera(self, 0.3, p + Vector3((k - 1) * 0.55, 0.35, 0), _m(CORES["pascoa"][k], 0.3), Vector3(0.8, 1.15, 0.8))
			"junina":
				for k in 4:
					var a := k * TAU / 4.0
					Pecas3D.cano(self, p + Vector3(cos(a) * 0.4, 0.05, sin(a) * 0.4), p + Vector3(0, 0.7, 0), 0.07, _m("#8A5A2B", 0.8))
				Pecas3D.esfera(self, 0.25, p + Vector3(0, 0.4, 0), _luz("#FF8A1F", 2.0), Vector3(1, 1.5, 1))
	if id == "natal":
		# árvore de Natal grande do lado da praça
		var arvore := Vector3(7.5, 0, 2.5)
		Pecas3D.cilindro(self, 0.25, 0.3, 0.8, arvore + Vector3(0, 0.4, 0), _m("#6B3A1F", 0.6))
		for i in 4:
			Pecas3D.cilindro(self, 0.1, 1.6 - i * 0.35, 1.4, arvore + Vector3(0, 1.3 + i * 0.95, 0), _m("#2E7D32", 0.7))
		for i in 24:
			var a := i * 2.4
			var y := 1.0 + (i % 8) * 0.5
			var r := 1.5 - (i % 8) * 0.17
			Pecas3D.esfera(self, 0.1, arvore + Vector3(cos(a) * r, y, sin(a) * r), _luz(["#E8364F", "#FFD23F", "#6FD3FF"][i % 3], 1.4))
		Pecas3D.esfera(self, 0.28, arvore + Vector3(0, 5.4, 0), _luz("#FFE27A", 2.5))


## Partículas do tema caindo perto do jogador (pétalas, folhas, neve, confete).
func _particulas() -> void:
	var cores: Array = CORES[id]
	var p := CPUParticles3D.new()
	p.name = "ParticulasEvento"
	p.amount = [40, 70, 110][Qualidade.nivel()]
	p.lifetime = 5.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(16, 0.5, 16)
	p.direction = Vector3(0.3, -1, 0.1)
	p.spread = 20.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 1.8
	p.gravity = Vector3(0, -0.4, 0)
	p.angular_velocity_min = -120.0
	p.angular_velocity_max = 120.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.12) if id != "natal" else Vector2(0.1, 0.1)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	p.mesh = quad
	var gradiente := Gradient.new()
	gradiente.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradiente.offsets = PackedFloat32Array()
	gradiente.colors = PackedColorArray()
	var lista: Array = ["#FFFFFF"] if id == "natal" else cores
	for i in lista.size():
		gradiente.add_point(float(i) / lista.size(), Color(lista[i]))
	p.color_initial_ramp = gradiente
	add_child(p)
	set_meta("particulas", p)


func _physics_process(_delta: float) -> void:
	if has_meta("particulas") and is_instance_valid(_jogador):
		(get_meta("particulas") as Node3D).global_position = _jogador.global_position + Vector3(0, 9, -2)


## Objeto do evento para pegar (com um brilho embaixo).
func _criar_item(indice: int, lugar: Vector3) -> Node3D:
	var no := Node3D.new()
	no.name = "ItemEvento%d" % indice
	no.position = lugar + Vector3(0, 0.7, 0)
	add_child(no)
	ficha_3d(no, id)
	var aro := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.45
	disco.bottom_radius = 0.45
	disco.height = 0.02
	aro.mesh = disco
	var mat := _luz(Eventos.EVENTOS[id]["cor"], 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.5
	aro.material_override = mat
	aro.position.y = -0.62
	no.add_child(aro)
	CenarioVila.estilo_desenho(no)
	JuntarMalhas.juntar(no, [])  # cada objeto vira um bloco só (leve)
	return no


## O formato da ficha de cada evento (pétala, abóbora, estrela, confete,
## ovinho, bandeirinha), centrado em (0, 0, 0), ~0,5 m.
static func ficha_3d(no: Node3D, evento: String) -> void:
	match evento:
		"primavera":
			for i in 5:
				var a := i * TAU / 5.0
				Pecas3D.esfera(no, 0.14, Vector3(cos(a) * 0.15, sin(a) * 0.15, 0), _m("#FF8FB8", 0.4), Vector3(1, 1, 0.4))
			Pecas3D.esfera(no, 0.09, Vector3.ZERO, _m("#FFD23F", 0.4))
		"halloween":
			Pecas3D.esfera(no, 0.25, Vector3.ZERO, _luz("#FF8A1F", 0.6), Vector3(1.2, 0.9, 1.2))
			Pecas3D.cilindro(no, 0.03, 0.04, 0.12, Vector3(0, 0.25, 0), _m("#3FA34D", 0.6))
		"natal":
			for i in 5:
				var a := i * TAU / 5.0 + PI / 2.0
				Pecas3D.cilindro(no, 0.0, 0.1, 0.24, Vector3(cos(a) * 0.14, sin(a) * 0.14, 0), _luz("#FFD23F", 1.2),
					Vector3(1, 1, 0.4), Vector3(0, 0, rad_to_deg(a) - 90))
			Pecas3D.esfera(no, 0.12, Vector3.ZERO, _luz("#FFD23F", 1.2), Vector3(1, 1, 0.5))
		"carnaval":
			for i in 3:
				Pecas3D.cilindro(no, 0.16, 0.16, 0.05, Vector3((i - 1) * 0.12, i * 0.08, 0), _m(CORES["carnaval"][i], 0.3),
					Vector3.ONE, Vector3(90, 0, 20 * i))
		"pascoa":
			Pecas3D.esfera(no, 0.2, Vector3.ZERO, _m("#6FD3FF", 0.3), Vector3(0.85, 1.15, 0.85))
			Pecas3D.rosquinha(no, 0.16, 0.19, Vector3.ZERO, _m("#FFB3D1", 0.3), Vector3(1, 0.3, 1))
		_:
			Pecas3D.cano(no, Vector3(-0.3, 0.2, 0), Vector3(0.3, 0.2, 0), 0.015, _m("#FFFFFF", 0.4))
			for i in 3:
				var bandeira := MeshInstance3D.new()
				var prisma := PrismMesh.new()
				prisma.size = Vector3(0.16, 0.2, 0.02)
				bandeira.mesh = prisma
				bandeira.material_override = _m(CORES["junina"][i], 0.5)
				bandeira.position = Vector3(-0.18 + i * 0.18, 0.08, 0)
				bandeira.rotation.x = PI
				no.add_child(bandeira)
