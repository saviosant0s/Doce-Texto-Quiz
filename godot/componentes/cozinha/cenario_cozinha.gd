class_name CenarioCozinha
## Peças da cozinha da Minha Confeitaria, montadas por código (como a vila):
## sala, máquinas (panela de brigadeiro, tacho de maçã do amor, forno de
## cupcake), mesas-bandeja, balcão, caixa, círculos de melhoria, doces
## pequenos (para bandejas e pilhas) e moedas.

const FONTE := preload("res://assets/fontes/BebasNeue-Regular.ttf")
## Altura de cada doce pequeno numa pilha.
const ALTURA_DOCE := 0.27


static func _m(cor: String, aspereza := 0.5, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


static func _parede(pai: Node3D, tamanho: Vector3, posicao: Vector3) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = posicao
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	forma.shape = caixa
	corpo.add_child(forma)
	pai.add_child(corpo)


## Texto que sempre olha para a câmera (placas das máquinas, preços...).
static func rotulo(pai: Node3D, texto: String, posicao: Vector3, tamanho := 64, cor := Color.WHITE) -> Label3D:
	var r := Label3D.new()
	r.text = texto
	r.font = FONTE
	r.font_size = tamanho
	r.pixel_size = 0.006
	r.modulate = cor
	r.outline_modulate = Color("#3A2060")
	r.outline_size = 14
	r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	r.no_depth_test = true
	r.visibility_range_begin = 2.2  # some quando a câmera está colada nele
	r.position = posicao
	pai.add_child(r)
	return r


# --- Sala --------------------------------------------------------------------------

## Sala da confeitaria: x de -`meia_largura` a +`meia_largura`, z de
## -`meio_fundo` (parede do fundo) a +`meio_fundo` (aberta para a câmera).
## A parede da direita tem a porta dos clientes (z entre `porta_z` ± 1).
static func sala(pai: Node3D, meia_largura: float, meio_fundo: float, porta_z: float) -> void:
	# piso de mármore (textura real), levemente rosado
	var piso := Texturas.real("piso_cozinha", "#FFE9F1", 0.08)
	var plano := PlaneMesh.new()
	plano.size = Vector2(meia_largura * 2 + 1, meio_fundo * 2 + 1)
	var chao := MeshInstance3D.new()
	chao.name = "Piso"
	chao.mesh = plano
	chao.material_override = piso
	pai.add_child(chao)
	_parede(pai, Vector3(meia_largura * 4, 1, meio_fundo * 4), Vector3(0, -0.5, 0))
	# papel de parede listrado, rodapé e faixa no alto
	var altura := 4.0
	var papel := Texturas.real("reboco", "#CFF0E0", 0.5)
	var rodape := _m("#7E57B1", 0.5)
	Pecas3D.caixa(pai, Vector3(meia_largura * 2 + 0.6, altura, 0.3), Vector3(0, altura / 2, -meio_fundo - 0.15), papel)
	Pecas3D.caixa(pai, Vector3(meia_largura * 2 + 0.6, 0.35, 0.36), Vector3(0, 0.17, -meio_fundo - 0.1), rodape)
	_parede(pai, Vector3(meia_largura * 2 + 1, altura, 0.4), Vector3(0, altura / 2, -meio_fundo - 0.2))
	# paredes dos lados baixinhas, para não taparem a câmera
	altura = 1.3
	for lado in [-1, 1]:
		var x: float = lado * (meia_largura + 0.15)
		if lado > 0:  # parede da direita, com a porta dos clientes
			var tras := porta_z - 1.1 + meio_fundo
			Pecas3D.caixa(pai, Vector3(0.3, altura, tras), Vector3(x, altura / 2, -meio_fundo + tras / 2), papel)
			var frente := meio_fundo - porta_z - 1.1
			Pecas3D.caixa(pai, Vector3(0.3, altura, frente), Vector3(x, altura / 2, meio_fundo - frente / 2), papel)
			# batente da porta
			for z in [porta_z - 1.1, porta_z + 1.1]:
				Pecas3D.caixa(pai, Vector3(0.4, 2.7, 0.2), Vector3(x, 1.35, z), rodape)
			Pecas3D.caixa(pai, Vector3(0.4, 0.2, 2.4), Vector3(x, 2.7, porta_z), rodape)
			_parede(pai, Vector3(0.4, 4, tras), Vector3(x + 0.05, 2, -meio_fundo + tras / 2))
			_parede(pai, Vector3(0.4, 4, frente), Vector3(x + 0.05, 2, meio_fundo - frente / 2))
			_parede(pai, Vector3(2.0, 4, 2.4), Vector3(x + 1.2, 2, porta_z))  # jogador não sai pela porta dos clientes
		else:
			Pecas3D.caixa(pai, Vector3(0.3, altura, meio_fundo * 2), Vector3(x, altura / 2, 0), papel)
			_parede(pai, Vector3(0.4, 4, meio_fundo * 2 + 1), Vector3(x - 0.05, 2, 0))
		Pecas3D.caixa(pai, Vector3(0.36, 0.35, meio_fundo * 2), Vector3(x, 0.17, 0), rodape)
	# frente aberta para a câmera, mas com parede invisível
	_parede(pai, Vector3(meia_largura * 2 + 1, 4, 0.4), Vector3(0, 2, meio_fundo + 0.4))
	# prateleiras com potes coloridos na parede do fundo
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 8
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF", "#FF8A5B"]
	for x in [-6.5, -2.5, 2.5, 6.5]:
		Pecas3D.caixa(pai, Vector3(2.4, 0.12, 0.5), Vector3(x, 2.9, -meio_fundo + 0.25), Texturas.real("madeira", "#FFFFFF", 0.8))
		for i in 4:
			var pote := Vector3(x - 0.85 + i * 0.57, 3.2, -meio_fundo + 0.25)
			var altura_pote := sorteio.randf_range(0.35, 0.55)
			Pecas3D.cilindro(pai, 0.17, 0.17, altura_pote, pote + Vector3(0, altura_pote / 2 - 0.25, 0),
				_m(cores[(i + int(x)) % cores.size()], 0.2))
			Pecas3D.cilindro(pai, 0.19, 0.19, 0.08, pote + Vector3(0, altura_pote - 0.22, 0), _m("#FFFFFF", 0.4))
	# letreiro no alto da parede do fundo
	var placa := Label3D.new()
	placa.text = "MINHA CONFEITARIA"
	placa.font = FONTE
	placa.font_size = 180
	placa.pixel_size = 0.006
	placa.modulate = Color("#7E57B1")
	placa.outline_size = 0
	placa.position = Vector3(0, 3.55, -meio_fundo + 0.02)
	pai.add_child(placa)


## Paredes altas (frente e o alto dos lados), só para as câmeras de perto: na
## câmera de cima elas tapariam a visão, então a cozinha aparece aberta.
static func paredes_altas(pai: Node3D, meia_largura: float, meio_fundo: float, porta_z: float, saida_x: float) -> Node3D:
	var no := Node3D.new()
	no.name = "ParedesAltas"
	pai.add_child(no)
	var papel := Texturas.real("reboco", "#CFF0E0", 0.5)
	var roxo := _m("#7E57B1", 0.5)
	var altura := 4.0
	# frente, com a porta de saída em cima do tapete SAIR
	var z := meio_fundo + 0.3
	var esquerda := saida_x - 1.1 + meia_largura
	Pecas3D.caixa(no, Vector3(esquerda, altura, 0.3), Vector3(-meia_largura + esquerda / 2, altura / 2, z), papel)
	var direita := meia_largura - (saida_x + 1.1)
	Pecas3D.caixa(no, Vector3(direita, altura, 0.3), Vector3(meia_largura - direita / 2, altura / 2, z), papel)
	Pecas3D.caixa(no, Vector3(2.2, altura - 2.6, 0.3), Vector3(saida_x, 2.6 + (altura - 2.6) / 2, z), papel)
	Pecas3D.caixa(no, Vector3(2.4, 0.2, 0.4), Vector3(saida_x, 2.6, z), roxo)
	var rua := _m("#9FD4F7", 0.9)
	rua.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Pecas3D.caixa(no, Vector3(2.2, 2.6, 0.05), Vector3(saida_x, 1.3, z + 0.3), rua)  # o céu lá fora
	Pecas3D.caixa(no, Vector3(meia_largura * 2 + 0.6, 0.35, 0.36), Vector3(0, 0.17, z - 0.05), roxo)
	# alto das paredes dos lados (acima da parte baixa de 1,3)
	for lado in [-1, 1]:
		var x: float = lado * (meia_largura + 0.15)
		Pecas3D.caixa(no, Vector3(0.3, altura - 1.3, meio_fundo * 2), Vector3(x, 1.3 + (altura - 1.3) / 2, 0), papel)
	# teto branquinho
	Pecas3D.caixa(no, Vector3(meia_largura * 2 + 0.6, 0.1, meio_fundo * 2 + 0.6), Vector3(0, altura, 0), _m("#FFF6EC", 0.9))
	return no


## Tapete na frente, onde o jogador sai de volta para a vila.
static func tapete_saida(pai: Node3D, posicao: Vector3) -> void:
	Pecas3D.cilindro(pai, 0.8, 0.8, 0.03, posicao + Vector3(0, 0.015, 0), _m("#7E57B1", 0.8), Vector3(1.2, 1, 0.8))
	rotulo(pai, "SAIR", posicao + Vector3(0, 0.6, 0), 70, Color("#F4E038"))


# --- Máquinas ------------------------------------------------------------------------

## Monta a máquina `id` em `posicao` (de frente para +z). Retorna
## {"no", "vapor": CPUParticles3D, "gira": Node3D que gira enquanto trabalha}.
static func maquina(pai: Node3D, id: String, posicao: Vector3) -> Dictionary:
	var no := Node3D.new()
	no.name = "Maquina_" + id
	no.position = posicao
	pai.add_child(no)
	var gira := Node3D.new()
	var topo := 1.0
	match id:
		"brigadeiro":
			_fogao(no, "#FFF1F5")
			Pecas3D.cilindro(no, 0.6, 0.55, 0.6, Vector3(0, 1.3, 0), _m("#B8B8C8", 0.25, 0.6))
			Pecas3D.cilindro(no, 0.56, 0.56, 0.04, Vector3(0, 1.56, 0), _m("#5A2E17", 0.2))
			for lado in [-1, 1]:
				Pecas3D.rosquinha(no, 0.05, 0.1, Vector3(lado * 0.66, 1.45, 0), _m("#5E3D8E", 0.4), Vector3.ONE, Vector3(0, 0, 90))
			gira.position = Vector3(0, 1.58, 0)
			Pecas3D.cano(gira, Vector3(0.25, -0.1, 0), Vector3(0.45, 0.75, 0.1), 0.05, _m("#C98A4B", 0.7))
			topo = 1.6
		"maca":
			_fogao(no, "#FFE08A")
			Pecas3D.cilindro(no, 0.8, 0.62, 0.35, Vector3(0, 1.17, 0), _m("#D9822B", 0.25, 0.6))
			Pecas3D.cilindro(no, 0.76, 0.76, 0.04, Vector3(0, 1.32, 0), _m("#C0182B", 0.15))
			gira.position = Vector3(0, 1.34, 0)
			for i in 3:
				var angulo := i * TAU / 3.0
				var ponto := Vector3(cos(angulo) * 0.4, 0.1, sin(angulo) * 0.4)
				Pecas3D.esfera(gira, 0.16, ponto, _m("#E8263F", 0.15))
				Pecas3D.cano(gira, ponto, ponto + Vector3(0, 0.45, 0), 0.025, _m("#F2D6A2", 0.6))
			topo = 1.4
		"cupcake":
			var corpo := _m("#FF8FB8", 0.45)
			Pecas3D.caixa(no, Vector3(2.2, 1.9, 1.4), Vector3(0, 0.95, 0), corpo)
			Pecas3D.caixa(no, Vector3(2.3, 0.14, 1.5), Vector3(0, 1.95, 0), _m("#FFFFFF", 0.4))
			var vidro := _m("#FFB347", 0.2)
			vidro.emission_enabled = true
			vidro.emission = Color("#FF9F1C")
			vidro.emission_energy_multiplier = 0.25
			Pecas3D.caixa(no, Vector3(1.5, 0.9, 0.08), Vector3(0, 0.95, 0.72), vidro)
			Pecas3D.caixa(no, Vector3(1.6, 0.08, 0.14), Vector3(0, 1.5, 0.76), _m("#5E3D8E", 0.4))
			for i in 3:
				Pecas3D.cilindro(no, 0.09, 0.09, 0.08, Vector3(-0.6 + i * 0.6, 1.72, 0.72), _m("#F4E038", 0.3), Vector3.ONE, Vector3(90, 0, 0))
			# cupcake de enfeite em cima (gira devagar)
			gira.position = Vector3(0, 2.02, 0)
			mini_doce(gira, "cupcake").scale = Vector3.ONE * 2.2
			topo = 2.6
	no.add_child(gira)
	var vapor := CPUParticles3D.new()
	vapor.amount = 10
	vapor.lifetime = 1.4
	vapor.emitting = false
	var bolha := SphereMesh.new()
	bolha.radius = 0.12
	bolha.height = 0.24
	bolha.radial_segments = 8
	bolha.rings = 4
	var branco := StandardMaterial3D.new()
	branco.albedo_color = Color(1, 1, 1, 0.7)
	branco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	branco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolha.material = branco
	vapor.mesh = bolha
	vapor.direction = Vector3.UP
	vapor.spread = 15.0
	vapor.gravity = Vector3(0, 0.6, 0)
	vapor.initial_velocity_min = 0.3
	vapor.initial_velocity_max = 0.6
	vapor.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	vapor.emission_sphere_radius = 0.3
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.4))
	curva.add_point(Vector2(0.5, 1.0))
	curva.add_point(Vector2(1, 0))
	vapor.scale_amount_curve = curva
	vapor.position = Vector3(0, topo, 0)
	no.add_child(vapor)
	_parede(no, Vector3(2.3, 2.2, 1.5), Vector3(0, 1.1, 0))
	return {"no": no, "vapor": vapor, "gira": gira, "topo": topo}


static func _fogao(no: Node3D, cor: String) -> void:
	Pecas3D.caixa(no, Vector3(2.2, 0.95, 1.4), Vector3(0, 0.475, 0), _m(cor, 0.5))
	Pecas3D.caixa(no, Vector3(2.3, 0.08, 1.5), Vector3(0, 0.99, 0), _m("#3A2A5E", 0.4))
	Pecas3D.caixa(no, Vector3(1.6, 0.5, 0.06), Vector3(0, 0.45, 0.71), _m("#FFFFFF", 0.3))
	for i in 3:
		Pecas3D.cilindro(no, 0.08, 0.08, 0.08, Vector3(-0.6 + i * 0.6, 0.82, 0.72), _m("#E8364F", 0.3), Vector3.ONE, Vector3(90, 0, 0))


## Mesa onde a máquina põe os doces prontos (topo em y = 0.95).
static func mesa_bandeja(pai: Node3D, posicao: Vector3) -> void:
	var madeira := Texturas.real("madeira", "#FFFFFF", 0.8)
	Pecas3D.caixa(pai, Vector3(2.0, 0.1, 0.95), posicao + Vector3(0, 0.9, 0), madeira)
	Pecas3D.caixa(pai, Vector3(1.9, 0.04, 0.85), posicao + Vector3(0, 0.96, 0), _m("#FFFFFF", 0.4))
	for x in [-0.85, 0.85]:
		for z in [-0.35, 0.35]:
			Pecas3D.caixa(pai, Vector3(0.1, 0.9, 0.1), posicao + Vector3(x, 0.45, z), madeira)
	_parede(pai, Vector3(2.0, 1.0, 0.95), posicao + Vector3(0, 0.5, 0))


## Posição (relativa à mesa) do doce número `i` na bandeja: 5 x 3 e depois
## uma segunda camada.
static func lugar_na_bandeja(i: int) -> Vector3:
	var camada := i / 15
	var j := i % 15
	return Vector3(-0.72 + (j % 5) * 0.36, 0.98 + camada * ALTURA_DOCE, -0.26 + (j / 5) * 0.26)


# --- Balcão, caixa e círculos ----------------------------------------------------------

static func balcao(pai: Node3D, posicao: Vector3, largura: float) -> void:
	var roxo := _m("#7E57B1", 0.5)
	Pecas3D.caixa(pai, Vector3(largura, 1.0, 1.0), posicao + Vector3(0, 0.5, 0), roxo)
	Pecas3D.caixa(pai, Vector3(largura + 0.2, 0.12, 1.2), posicao + Vector3(0, 1.06, 0), Texturas.real("madeira", "#FFFFFF", 0.8))
	for i in int(largura / 0.8):
		var x := -largura / 2 + 0.4 + i * 0.8
		Pecas3D.caixa(pai, Vector3(0.35, 0.8, 0.04), posicao + Vector3(x, 0.5, 0.51), _m("#F4E038", 0.4))
	# caixa registradora na ponta esquerda
	var registradora := posicao + Vector3(-largura / 2 + 0.5, 1.12, -0.1)
	Pecas3D.caixa(pai, Vector3(0.7, 0.35, 0.55), registradora + Vector3(0, 0.17, 0), _m("#5E3D8E", 0.4))
	Pecas3D.caixa(pai, Vector3(0.5, 0.25, 0.08), registradora + Vector3(0, 0.5, -0.1), _m("#8FD3F4", 0.2))
	_parede(pai, Vector3(largura + 0.2, 1.2, 1.2), posicao + Vector3(0, 0.6, 0))


## Mesinha redonda onde ficam as moedas pagas pelos clientes (topo em y = 0.9).
static func mesa_caixa(pai: Node3D, posicao: Vector3) -> void:
	Pecas3D.cilindro(pai, 0.1, 0.12, 0.85, posicao + Vector3(0, 0.42, 0), _m("#5E3D8E", 0.5))
	Pecas3D.cilindro(pai, 0.65, 0.65, 0.08, posicao + Vector3(0, 0.88, 0), _m("#F4E038", 0.4))
	Pecas3D.cilindro(pai, 0.4, 0.45, 0.05, posicao + Vector3(0, 0.02, 0), _m("#5E3D8E", 0.5))
	_poste(pai, 0.6, 0.95, posicao)


static func _poste(pai: Node3D, raio: float, altura: float, posicao: Vector3) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = posicao + Vector3(0, altura / 2.0, 0)
	var forma := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = raio
	cilindro.height = altura
	forma.shape = cilindro
	corpo.add_child(forma)
	pai.add_child(corpo)


## Posição (relativa à mesa do caixa) da moeda número `i` na pilha.
static func lugar_da_moeda(i: int) -> Vector3:
	var coluna := i % 6
	var angulo := coluna * TAU / 6.0
	return Vector3(cos(angulo) * 0.3, 0.95 + (i / 6) * 0.05, sin(angulo) * 0.3)


static func moeda(pai: Node3D) -> MeshInstance3D:
	var no := Pecas3D.cilindro(pai, 0.13, 0.13, 0.045, Vector3.ZERO, _m("#F2C230", 0.2, 0.6))
	no.name = "Moeda"
	return no


## Círculo no chão para construir ou melhorar algo: fica em cima e ele
## enche. Retorna {"no", "enchimento", "texto", "anel"}.
static func circulo(pai: Node3D, posicao: Vector3) -> Dictionary:
	var no := Node3D.new()
	no.name = "Circulo"
	no.position = posicao
	pai.add_child(no)
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.62
	toro.outer_radius = 0.8
	anel.mesh = toro
	anel.scale = Vector3(1, 0.25, 1)
	anel.position.y = 0.03
	anel.material_override = _m("#F4E038", 0.4)
	no.add_child(anel)
	var fundo := StandardMaterial3D.new()
	fundo.albedo_color = Color(0.49, 0.34, 0.69, 0.35)
	fundo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fundo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Pecas3D.cilindro(no, 0.64, 0.64, 0.02, Vector3(0, 0.02, 0), fundo)
	var cheio := StandardMaterial3D.new()
	cheio.albedo_color = Color("#F4E038")
	cheio.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var enchimento := Pecas3D.cilindro(no, 0.62, 0.62, 0.025, Vector3(0, 0.035, 0), cheio)
	enchimento.scale = Vector3(0.001, 1, 0.001)
	var texto := rotulo(no, "", Vector3(0, 1.0, 0), 56)
	return {"no": no, "enchimento": enchimento, "texto": texto, "anel": anel}


## Seta amarela que pula em cima do que o jogador deve fazer agora.
static func seta(pai: Node3D) -> Node3D:
	var no := Node3D.new()
	no.name = "Seta"
	pai.add_child(no)
	var mat := _m("#F4E038", 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Pecas3D.cilindro(no, 0.0, 0.32, 0.5, Vector3(0, 0.25, 0), mat, Vector3.ONE, Vector3(180, 0, 0))
	Pecas3D.cilindro(no, 0.12, 0.12, 0.45, Vector3(0, 0.72, 0), mat)
	return no


# --- Doces pequenos ----------------------------------------------------------------------

## Doce pequeno (bandejas, pilhas, cartazes). A base fica em y = 0.
static func mini_doce(pai: Node3D, doce: String) -> Node3D:
	var no := Node3D.new()
	no.name = "Doce"
	pai.add_child(no)
	match doce:
		"brigadeiro":
			Pecas3D.cilindro(no, 0.12, 0.09, 0.1, Vector3(0, 0.05, 0), _m("#FFF1F5", 0.5))
			Pecas3D.esfera(no, 0.12, Vector3(0, 0.15, 0), _m("#5A2E17", 0.35))
			for i in 4:
				var angulo := i * TAU / 4.0 + 0.4
				Pecas3D.esfera(no, 0.022, Vector3(cos(angulo) * 0.07, 0.25, sin(angulo) * 0.07), _m(["#FF6FAE", "#FFD23F", "#6FD3FF", "#FFFFFF"][i], 0.3))
		"maca":
			Pecas3D.esfera(no, 0.13, Vector3(0, 0.13, 0), _m("#E8263F", 0.15))
			Pecas3D.cano(no, Vector3(0, 0.2, 0), Vector3(0, 0.38, 0), 0.02, _m("#F2D6A2", 0.6))
		"cupcake":
			Pecas3D.cilindro(no, 0.12, 0.09, 0.12, Vector3(0, 0.06, 0), _m("#FF8FB8", 0.5))
			Pecas3D.esfera(no, 0.12, Vector3(0, 0.15, 0), _m("#FFF1F5", 0.35), Vector3(1, 0.8, 1))
			Pecas3D.esfera(no, 0.04, Vector3(0, 0.26, 0), _m("#E8263F", 0.2))
	return no
