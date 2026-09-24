class_name Pecas3D
## Peças básicas para montar personagens 3D por código: materiais, formas
## (esfera, cilindro, cápsula, rosquinha), rosto, braços e pernas.
## Os doces da coleção (Doces3D) são montados com estas peças.
##
## Convenções: o personagem olha para +Z (para a câmera) e mede cerca de 2,4
## de altura, centralizado na origem.

const COR_OLHO := Color("#FFFFFF")
const COR_PUPILA := Color("#1E1414")
const COR_BOCA := Color("#5A1A22")
const COR_LINGUA := Color("#F07A8C")
const COR_BOCHECHA := Color("#FF7E9D")
const COR_LUVA := Color("#F7F5F2")
const COR_DENTES := Color("#FFFFFF")


# --- Materiais -----------------------------------------------------------------

## Material de doce. `aspereza` baixa = brilhante (calda, bala); alta = fosco
## (chocolate, massa). `metal` > 0 para papel laminado.
static func material(cor: Color, aspereza := 0.3, metal := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.roughness = aspereza
	mat.metallic = metal
	mat.metallic_specular = 0.6
	return mat


## Material com textura gerada (listras etc.), repetida `repeticao` vezes.
static func material_textura(textura: Texture2D, aspereza := 0.3, repeticao := Vector3.ONE) -> StandardMaterial3D:
	var mat := material(Color.WHITE, aspereza)
	mat.albedo_texture = textura
	mat.uv1_scale = repeticao
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


## Textura de faixas horizontais (o V da malha vai de cima a baixo).
static func faixas(cores: Array, quantidade: int, altura := 256) -> ImageTexture:
	var imagem := Image.create(8, altura, true, Image.FORMAT_RGBA8)
	for y in altura:
		var cor: Color = cores[int(float(y) / altura * quantidade) % cores.size()]
		for x in 8:
			imagem.set_pixel(x, y, cor)
	imagem.generate_mipmaps()
	return ImageTexture.create_from_image(imagem)


## Textura de listras verticais alternando `cores` (o U da malha dá a volta).
static func listras(cores: Array, quantidade: int, largura := 256) -> ImageTexture:
	var imagem := Image.create(largura, 8, true, Image.FORMAT_RGBA8)
	for x in largura:
		var cor: Color = cores[int(float(x) / largura * quantidade) % cores.size()]
		for y in 8:
			imagem.set_pixel(x, y, cor)
	imagem.generate_mipmaps()
	return ImageTexture.create_from_image(imagem)


# --- Formas --------------------------------------------------------------------

static func _no(pai: Node3D, malha: Mesh, mat: Material, posicao: Vector3, escala: Vector3, rotacao: Vector3) -> MeshInstance3D:
	var no := MeshInstance3D.new()
	no.mesh = malha
	no.material_override = mat
	no.position = posicao
	no.rotation_degrees = rotacao
	no.scale = escala
	pai.add_child(no)
	return no


static func esfera(pai: Node3D, raio: float, posicao: Vector3, mat: Material,
		escala := Vector3.ONE, rotacao := Vector3.ZERO) -> MeshInstance3D:
	var malha := SphereMesh.new()
	malha.radius = raio
	malha.height = raio * 2.0
	malha.radial_segments = 40
	malha.rings = 20
	return _no(pai, malha, mat, posicao, escala, rotacao)


static func cilindro(pai: Node3D, raio_topo: float, raio_base: float, altura: float, posicao: Vector3,
		mat: Material, escala := Vector3.ONE, rotacao := Vector3.ZERO) -> MeshInstance3D:
	var malha := CylinderMesh.new()
	malha.top_radius = raio_topo
	malha.bottom_radius = raio_base
	malha.height = altura
	malha.radial_segments = 40
	return _no(pai, malha, mat, posicao, escala, rotacao)


static func rosquinha(pai: Node3D, raio_interno: float, raio_externo: float, posicao: Vector3,
		mat: Material, escala := Vector3.ONE, rotacao := Vector3.ZERO) -> MeshInstance3D:
	var malha := TorusMesh.new()
	malha.inner_radius = raio_interno
	malha.outer_radius = raio_externo
	malha.rings = 48
	malha.ring_segments = 24
	return _no(pai, malha, mat, posicao, escala, rotacao)


static func caixa(pai: Node3D, tamanho: Vector3, posicao: Vector3, mat: Material, rotacao := Vector3.ZERO) -> MeshInstance3D:
	var malha := BoxMesh.new()
	malha.size = tamanho
	return _no(pai, malha, mat, posicao, Vector3.ONE, rotacao)


## Cápsula ligando dois pontos (braços, pernas, palitos, granulado).
static func cano(pai: Node3D, de: Vector3, ate: Vector3, raio: float, mat: Material) -> MeshInstance3D:
	var malha := CapsuleMesh.new()
	malha.radius = raio
	malha.height = de.distance_to(ate) + raio * 2.0
	malha.radial_segments = 16
	malha.rings = 4
	var no := _no(pai, malha, mat, (de + ate) / 2.0, Vector3.ONE, Vector3.ZERO)
	var eixo_y := (ate - de).normalized()
	var auxiliar := Vector3.FORWARD if absf(eixo_y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var eixo_x := eixo_y.cross(auxiliar).normalized()
	no.basis = Basis(eixo_x, eixo_y, eixo_x.cross(eixo_y))
	return no


## Granulado espalhado sobre uma esfera (centro, raio), acima de
## `altura_minima` e fora do rosto (direções com z maior que `rosto_livre`
## ficam sem granulado). Semente fixa para o doce ser sempre igual.
static func granulado(pai: Node3D, centro: Vector3, raio: float, quantidade: int, cores: Array,
		semente: int, altura_minima := 0.0, tamanho := 1.0, rosto_livre := 2.0) -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = semente
	var materiais := cores.map(func(c): return material(c, 0.35))
	var colocados := 0
	while colocados < quantidade:
		var direcao := Vector3(sorteio.randf_range(-1, 1), sorteio.randf_range(-1, 1), sorteio.randf_range(-1, 1))
		if direcao.length() < 0.2 or direcao.length() > 1.0:
			continue
		direcao = direcao.normalized()
		if direcao.y < altura_minima or direcao.z < -0.3 or direcao.z > rosto_livre:
			continue
		var ponto := centro + direcao * raio
		var tangente := direcao.cross(Vector3(sorteio.randf(), sorteio.randf(), sorteio.randf())).normalized()
		var meio := 0.035 * tamanho
		cano(pai, ponto - tangente * meio, ponto + tangente * meio, 0.014 * tamanho, materiais[colocados % materiais.size()])
		colocados += 1


# --- Rosto e membros -------------------------------------------------------------

## Rosto sorridente centrado em `centro` (na superfície da frente do doce).
## `curvatura` = raio da superfície (recua olhos e bochechas nas laterais).
## Os olhos ficam num nó "Olhos", que o Doce3D fecha para piscar.
## Com `triste`, a boca vira para baixo e as sobrancelhas sobem no meio.
static func rosto(pai: Node3D, centro: Vector3, tamanho := 1.0, curvatura := 1.0, nariz := Color.TRANSPARENT,
		triste := false) -> void:
	var recuo := func(x: float) -> float: return (x * x) / (2.0 * maxf(curvatura, 0.2))
	var olhos := Node3D.new()
	olhos.name = "Olhos"
	olhos.position = centro + Vector3(0, 0.06 * tamanho, 0)
	pai.add_child(olhos)
	var branco := material(COR_OLHO, 0.12)
	var pupila := material(COR_PUPILA, 0.08)
	for lado in [-1, 1]:
		var x: float = lado * 0.17 * tamanho
		var z: float = -recuo.call(x)
		# olho simpático: quase todo pupila, com pouco branco em volta (sem ar de susto)
		esfera(olhos, 0.105 * tamanho, Vector3(x, 0, z), branco, Vector3(0.9, 1.08, 0.5))
		esfera(olhos, 0.088 * tamanho, Vector3(x, -0.008 * tamanho, z + 0.03 * tamanho), pupila, Vector3(0.9, 1.08, 0.5))
		esfera(olhos, 0.03 * tamanho, Vector3(x + 0.03 * tamanho, 0.035 * tamanho, z + 0.07 * tamanho), branco)
		esfera(olhos, 0.013 * tamanho, Vector3(x - 0.028 * tamanho, -0.03 * tamanho, z + 0.07 * tamanho), branco)
	var bochecha := material(COR_BOCHECHA, 0.6)
	for lado in [-1, 1]:
		var x: float = lado * 0.34 * tamanho
		esfera(pai, 0.065 * tamanho, centro + Vector3(x, -0.09 * tamanho, -recuo.call(x) - 0.01), bochecha, Vector3(1.4, 0.75, 0.35))
	if nariz.a > 0.0:
		esfera(pai, 0.045 * tamanho, centro + Vector3(0, -0.035 * tamanho, 0.03), material(nariz, 0.15))
	if triste:
		# boca em arco para baixo e sobrancelhas preocupadas
		var escuro := material(COR_BOCA, 0.4)
		var anterior := centro + Vector3(-0.12 * tamanho, -0.21 * tamanho, 0.0)
		for i in range(1, 7):
			var t := i / 6.0
			var ponto := centro + Vector3((-0.12 + 0.24 * t) * tamanho, (-0.21 + sin(t * PI) * 0.06) * tamanho, 0.0)
			cano(pai, anterior, ponto, 0.018 * tamanho, escuro)
			anterior = ponto
		for lado in [-1, 1]:
			var x: float = lado * 0.19 * tamanho
			var z: float = -recuo.call(x) + 0.03
			cano(pai, centro + Vector3(x - lado * 0.09 * tamanho, 0.25 * tamanho, z),
				centro + Vector3(x + lado * 0.07 * tamanho, 0.2 * tamanho, z), 0.018 * tamanho, escuro)
		return
	# sorriso aberto em "D": meia esfera com o lado reto para cima
	var meia := SphereMesh.new()
	meia.radius = 0.11 * tamanho
	meia.height = 0.11 * tamanho
	meia.is_hemisphere = true
	meia.radial_segments = 32
	meia.rings = 12
	var boca := _no(pai, meia, material(COR_BOCA, 0.4), centro + Vector3(0, -0.1 * tamanho, -0.01),
		Vector3(1.25, 0.95, 0.35), Vector3(180, 0, 0))
	boca.name = "Boca"
	esfera(pai, 0.055 * tamanho, centro + Vector3(0, -0.165 * tamanho, 0.018), material(COR_LINGUA, 0.4), Vector3(1.35, 0.6, 0.4))
	# dentinhos de cima
	esfera(pai, 0.075 * tamanho, centro + Vector3(0, -0.108 * tamanho, 0.02), material(COR_DENTES, 0.2), Vector3(1.4, 0.26, 0.3))


## Braço com mãozinha redonda, preso no `ombro`. `lado` = -1 (esquerda da tela)
## ou 1. Se `acenando`, fica levantado e se chama "Aceno" (o Doce3D balança).
static func braco(pai: Node3D, ombro: Vector3, lado: int, mat: Material, tamanho := 1.0, acenando := false) -> Node3D:
	var braco := Node3D.new()
	braco.name = "Aceno" if acenando else "Braco"
	braco.position = ombro
	pai.add_child(braco)
	var cotovelo := Vector3(lado * 0.2, -0.12, 0.05) * tamanho
	var mao := Vector3(lado * 0.36, -0.28, 0.12) * tamanho
	if acenando:
		cotovelo = Vector3(lado * 0.22, 0.02, 0.05) * tamanho
		mao = Vector3(lado * 0.3, 0.26, 0.08) * tamanho
	cano(braco, Vector3.ZERO, cotovelo, 0.055 * tamanho, mat)
	cano(braco, cotovelo, mao, 0.055 * tamanho, mat)
	# luva branca (como a família de personagens do jogo): mão, punho e polegar
	var luva := material(COR_LUVA, 0.45)
	rosquinha(braco, 0.035 * tamanho, 0.075 * tamanho, cotovelo.lerp(mao, 0.72), luva, Vector3.ONE,
		Vector3(0, 0, rad_to_deg((mao - cotovelo).angle_to(Vector3.UP)) * -signf(mao.x - cotovelo.x)))
	esfera(braco, 0.105 * tamanho, mao, luva, Vector3(1.0, 1.05, 0.8))
	esfera(braco, 0.045 * tamanho, mao + Vector3(-lado * 0.08, 0.05, 0.04) * tamanho, luva)
	return braco


## Duas perninhas com sapatinhos, saindo de `quadril` (altura do corpo).
static func pernas(pai: Node3D, quadril: Vector3, abertura: float, comprimento: float, mat: Material,
		mat_sapato: Material, tamanho := 1.0) -> void:
	for lado in [-1, 1]:
		var topo := quadril + Vector3(lado * abertura, 0, 0)
		var pe := topo + Vector3(lado * 0.03, -comprimento, 0.02)
		cano(pai, topo, pe, 0.06 * tamanho, mat)
		esfera(pai, 0.1 * tamanho, pe + Vector3(lado * 0.02, -0.03, 0.06) * tamanho, mat_sapato, Vector3(1.0, 0.65, 1.45))


## Carrega um modelo .glb, centraliza e ajusta a altura.
static func carregar_glb(pai: Node3D, caminho: String, altura := 2.4) -> void:
	var cena: Node3D = load(caminho).instantiate()
	pai.add_child(cena)
	var limites := AABB()
	var primeira := true
	for malha in cena.find_children("*", "MeshInstance3D", true, false):
		var caixa_malha: AABB = malha.global_transform * malha.get_aabb()
		limites = caixa_malha if primeira else limites.merge(caixa_malha)
		primeira = false
	if primeira:
		return
	var escala := altura / maxf(limites.size.y, 0.001)
	cena.scale = Vector3.ONE * escala
	cena.position = -limites.get_center() * escala
