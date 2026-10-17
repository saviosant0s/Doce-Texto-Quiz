class_name CenarioGP
extends RefCounted
## Peças do cenário dos GPs das cidades (ver GPs): coqueiros, guarda-sóis,
## casarões coloniais, prédios, mata, pedras e morros, e os pontos famosos
## (igreja barroca, farol, elevador, fábrica antiga, torre, museu e o pico).
## Formas simples (caixas, cilindros e esferas) para ficar leve no celular; o
## que se repete usa o mesmo material (JuntarMalhas junta tudo em poucos blocos).

const CORES_CASAROES := ["#F2C230", "#2E9BE8", "#E8364F", "#7BC96F", "#FF8A5C", "#B07CFF", "#FFFFFF", "#6FD3FF"]

static var _janelas: ImageTexture
static var _janelas_casarao: ImageTexture


## Textura de janelas acesas e apagadas (prédios).
static func textura_janelas() -> ImageTexture:
	if _janelas:
		return _janelas
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color("#D9DCE3"))
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 4
	for linha in 8:
		for coluna in 4:
			var cor := Color("#3E5A7A") if sorteio.randf() < 0.75 else Color("#FFE7A3")
			img.fill_rect(Rect2i(coluna * 16 + 3, linha * 8 + 2, 10, 5), cor)
	_janelas = ImageTexture.create_from_image(img)
	return _janelas


## Janelas coloniais (moldura branca, folha azul) numa parede clara.
static func textura_casarao() -> ImageTexture:
	if _janelas_casarao:
		return _janelas_casarao
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for coluna in 2:
		for linha in 2:
			var r := Rect2i(coluna * 32 + 8, linha * 32 + 6, 16, 22)
			img.fill_rect(r, Color("#FFFFFF"))
			img.fill_rect(r.grow(-2), Color("#2C5D9E"))
	_janelas_casarao = ImageTexture.create_from_image(img)
	return _janelas_casarao


static func coqueiro(pai: Node3D, p: Vector3, altura := 7.0, inclinacao := 0.0, giro := 0.0) -> void:
	var tronco := Pecas3D.material(Color("#9C7652"), 0.85)
	var folha := Pecas3D.material(Color("#3E9B4A"), 0.6)
	var no := Node3D.new()
	no.position = p
	no.rotation = Vector3(inclinacao, giro, 0)
	pai.add_child(no)
	var gomos := 5
	for k in gomos:
		Pecas3D.cilindro(no, 0.2, 0.26, altura / gomos + 0.05, Vector3(0, altura / gomos * (k + 0.5), 0), tronco)
	for k in 7:
		var a := k * TAU / 7.0
		var folha_no := Pecas3D.caixa(no, Vector3(0.55, 0.06, 3.0), Vector3(sin(a) * 1.3, altura - 0.25, cos(a) * 1.3), folha,
			Vector3(28, rad_to_deg(a), 0))
		folha_no.name = "Folha"
	for k in 3:
		Pecas3D.esfera(no, 0.22, Vector3(cos(k * 2.1) * 0.3, altura - 0.5, sin(k * 2.1) * 0.3), Pecas3D.material(Color("#6B4A2B"), 0.7))
	CenarioVila.sombra_contato(pai, p, 1.6, 0.35)


static func guarda_sol(pai: Node3D, p: Vector3, cor: Color) -> void:
	Pecas3D.cilindro(pai, 0.06, 0.06, 2.6, p + Vector3(0, 1.3, 0), Pecas3D.material(Color("#FFFFFF"), 0.4))
	var topo := Pecas3D.material_textura(Pecas3D.listras([cor, Color("#FFFFFF")], 8), 0.6)
	Pecas3D.cilindro(pai, 0.05, 1.5, 0.5, p + Vector3(0, 2.65, 0), topo)
	Pecas3D.caixa(pai, Vector3(0.7, 0.15, 1.7), p + Vector3(0.9, 0.2, 0.3), Pecas3D.material(cor.lightened(0.3), 0.6))


## Fileira de casarões coloniais geminados (sobrados coloridos com janelas,
## telhado de barro), de frente para `olhar`.
static func casaroes(pai: Node3D, p: Vector3, olhar: Vector3, quantos: int, sorteio: RandomNumberGenerator) -> void:
	var no := Node3D.new()
	no.position = p
	pai.add_child(no)
	var frente := Vector3(olhar.x - p.x, 0, olhar.z - p.z)
	if frente.length() > 0.1:
		no.rotation.y = atan2(frente.x, frente.z)
	var telhado := Pecas3D.material(Color("#B5532E"), 0.8)
	var janelas := Pecas3D.material_textura(textura_casarao(), 0.6)
	janelas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var largura := 4.2
	for k in quantos:
		var x := (k - (quantos - 1) / 2.0) * largura
		var altura := 5.0 if sorteio.randf() < 0.6 else 7.2
		var cor := Color(CORES_CASAROES[sorteio.randi() % CORES_CASAROES.size()])
		Pecas3D.caixa(no, Vector3(largura - 0.05, altura, 5.0), Vector3(x, altura / 2.0, 0), Texturas.real("reboco", cor.to_html(false), 0.5))
		# barrado branco nas quinas e na base
		Pecas3D.caixa(no, Vector3(largura + 0.02, 0.5, 5.04), Vector3(x, 0.25, 0), Pecas3D.material(Color("#F4EFE6"), 0.8))
		Pecas3D.caixa(no, Vector3(largura, 0.3, 5.3), Vector3(x, altura + 0.15, 0), Pecas3D.material(Color("#F4EFE6"), 0.8))
		var prisma := PrismMesh.new()
		prisma.size = Vector3(largura, 1.6, 5.6)
		var teto := MeshInstance3D.new()
		teto.mesh = prisma
		teto.material_override = telhado
		teto.position = Vector3(x, altura + 1.1, 0)
		no.add_child(teto)
		CenarioVila._placa_plana(no, Vector2(largura - 0.8, altura - 1.4), Vector3(x, altura / 2.0 + 0.4, 2.53), janelas)
		Pecas3D.caixa(no, Vector3(1.1, 2.0, 0.12), Vector3(x, 1.0, 2.53), Pecas3D.material(Color("#5B3A22"), 0.7))


static func predio(pai: Node3D, p: Vector3, tamanho: Vector3, cor: Color) -> void:
	var mat := Pecas3D.material_textura(textura_janelas(), 0.4, Vector3(maxf(1.0, roundf(tamanho.x / 6.0)), maxf(1.0, roundf(tamanho.y / 8.0)), 1))
	mat.albedo_color = cor
	Pecas3D.caixa(pai, tamanho, p + Vector3(0, tamanho.y / 2.0, 0), mat)
	Pecas3D.caixa(pai, Vector3(tamanho.x + 0.4, 0.5, tamanho.z + 0.4), p + Vector3(0, tamanho.y + 0.25, 0),
		Pecas3D.material(cor.darkened(0.25), 0.6))


static func arvore_mata(pai: Node3D, p: Vector3, tamanho: float, cor: Color) -> void:
	Pecas3D.cilindro(pai, 0.25 * tamanho, 0.35 * tamanho, 2.4 * tamanho, p + Vector3(0, 1.2 * tamanho, 0), Pecas3D.material(Color("#6E4E33"), 0.9))
	Pecas3D.esfera(pai, 1.7 * tamanho, p + Vector3(0, 3.4 * tamanho, 0), Pecas3D.material(cor, 0.8), Vector3(1, 0.85, 1))
	Pecas3D.esfera(pai, 1.2 * tamanho, p + Vector3(0.9 * tamanho, 2.9 * tamanho, 0.4 * tamanho), Pecas3D.material(cor.lightened(0.12), 0.8))
	CenarioVila.sombra_contato(pai, p, 2.0 * tamanho, 0.35)


static func pedra(pai: Node3D, p: Vector3, tamanho: float) -> void:
	Pecas3D.esfera(pai, tamanho, p + Vector3(0, tamanho * 0.35, 0), Pecas3D.material(Color("#8D8378"), 0.95), Vector3(1.3, 0.7, 1.0))


## Morro verde ao longe (com uma mancha de pedra no alto).
static func morro(pai: Node3D, centro: Vector3, raio: float, cor: Color) -> void:
	Pecas3D.esfera(pai, raio, centro, Pecas3D.material(cor, 0.95), Vector3(1.3, 0.75, 1.0))
	Pecas3D.esfera(pai, raio * 0.35, centro + Vector3(raio * 0.2, raio * 0.62, 0), Pecas3D.material(Color("#9A8F84"), 0.95), Vector3(1.2, 0.5, 1.0))


# --- Pontos famosos -------------------------------------------------------------------------

## Um marco do GP ({"tipo", "lugar", ...}), de frente para `olhar` (a pista).
static func marco(pai: Node3D, dados: Dictionary, olhar: Vector3) -> void:
	var no := Node3D.new()
	no.name = "Marco_" + str(dados["tipo"])
	no.position = dados["lugar"]
	var frente := Vector3(olhar.x - no.position.x, 0, olhar.z - no.position.z)
	if frente.length() > 0.1:
		no.rotation.y = atan2(frente.x, frente.z)
	pai.add_child(no)
	match dados["tipo"]:
		"igreja":
			_igreja(no, Color(dados.get("cor", "#FFFFFF")), Color(dados.get("detalhe", "#C9932E")))
		"farol":
			_farol(no)
		"elevador":
			_elevador(no)
		"fabrica":
			_fabrica(no)
		"torre":
			_torre(no)
		"museu":
			_museu(no)
		"pico":
			_pico(no)


## Igreja barroca de duas torres (fachada clara, cantos e frontão coloridos).
static func _igreja(no: Node3D, parede: Color, detalhe: Color) -> void:
	var branco := Texturas.real("reboco", parede.to_html(false), 0.5)
	var cor := Pecas3D.material(detalhe, 0.6)
	Pecas3D.caixa(no, Vector3(10, 9, 16), Vector3(0, 4.5, -3), branco)
	var prisma := PrismMesh.new()
	prisma.size = Vector3(10.4, 3.0, 16.4)
	var teto := MeshInstance3D.new()
	teto.mesh = prisma
	teto.material_override = Pecas3D.material(Color("#B5532E"), 0.8)
	teto.position = Vector3(0, 10.5, -3)
	no.add_child(teto)
	for lado in [-1, 1]:
		var x: float = lado * 6.0
		Pecas3D.caixa(no, Vector3(3.2, 15, 3.2), Vector3(x, 7.5, 4.6), branco)
		Pecas3D.caixa(no, Vector3(3.5, 0.5, 3.5), Vector3(x, 9.0, 4.6), cor)
		Pecas3D.caixa(no, Vector3(1.2, 2.0, 0.1), Vector3(x, 12.0, 6.22), Pecas3D.material(Color("#2E1D4A"), 0.6))
		Pecas3D.cilindro(no, 0.4, 1.9, 2.4, Vector3(x, 16.2, 4.6), cor)
		Pecas3D.cilindro(no, 0.06, 0.06, 1.6, Vector3(x, 18.2, 4.6), Pecas3D.material(Color("#E6C35A"), 0.3, 0.6))
		Pecas3D.caixa(no, Vector3(0.7, 0.12, 0.12), Vector3(x, 18.5, 4.6), Pecas3D.material(Color("#E6C35A"), 0.3, 0.6))
	# frontão curvo e portada
	Pecas3D.caixa(no, Vector3(8.8, 10, 1.0), Vector3(0, 5.0, 5.4), branco)
	Pecas3D.cilindro(no, 3.0, 3.0, 1.0, Vector3(0, 10.0, 5.4), branco, Vector3.ONE, Vector3(90, 0, 0))
	Pecas3D.cilindro(no, 0.9, 0.9, 0.2, Vector3(0, 10.4, 5.95), cor, Vector3.ONE, Vector3(90, 0, 0))
	Pecas3D.caixa(no, Vector3(2.6, 4.0, 0.15), Vector3(0, 2.0, 5.95), Pecas3D.material(Color("#5B3A22"), 0.6))
	Pecas3D.caixa(no, Vector3(3.4, 0.4, 0.3), Vector3(0, 4.2, 6.0), cor)
	for x in [-2.6, 2.6]:
		Pecas3D.caixa(no, Vector3(1.0, 1.6, 0.1), Vector3(x, 6.5, 5.95), CenarioVila.vidro_janela())
	# escadaria
	Pecas3D.caixa(no, Vector3(12, 0.5, 3.0), Vector3(0, 0.25, 7.4), Pecas3D.material(Color("#D8D2C6"), 0.9))


## Farol da Barra: torre branca com faixa preta, sobre o forte.
static func _farol(no: Node3D) -> void:
	var forte := Pecas3D.material(Color("#E8DCC4"), 0.9)
	Pecas3D.cilindro(no, 9.0, 10.0, 3.5, Vector3(0, 1.75, 0), forte)
	Pecas3D.cilindro(no, 9.3, 9.3, 0.5, Vector3(0, 3.75, 0), Pecas3D.material(Color("#D2C3A6"), 0.9))
	var branco := Pecas3D.material(Color("#FFFFFF"), 0.5)
	Pecas3D.cilindro(no, 1.5, 1.9, 13.0, Vector3(0, 10.0, 0), branco)
	Pecas3D.cilindro(no, 1.62, 1.68, 2.0, Vector3(0, 10.5, 0), Pecas3D.material(Color("#1E1E24"), 0.5))
	Pecas3D.cilindro(no, 2.0, 2.0, 0.4, Vector3(0, 16.7, 0), Pecas3D.material(Color("#1E1E24"), 0.5))
	var luz := Pecas3D.material(Color("#FFF2B0"), 0.2)
	luz.emission_enabled = true
	luz.emission = Color("#FFE27A")
	luz.emission_energy_multiplier = 1.2
	Pecas3D.cilindro(no, 1.1, 1.1, 1.8, Vector3(0, 17.8, 0), luz)
	Pecas3D.cilindro(no, 0.2, 1.4, 1.0, Vector3(0, 19.2, 0), Pecas3D.material(Color("#E8364F"), 0.4))


## Elevador Lacerda: torre art déco clara com a passarela para a cidade alta.
static func _elevador(no: Node3D) -> void:
	var claro := Pecas3D.material(Color("#EDE6D6"), 0.7)
	Pecas3D.caixa(no, Vector3(9, 26, 7), Vector3(0, 13, 0), claro)
	for y in [6.0, 12.0, 18.0, 24.0]:
		Pecas3D.caixa(no, Vector3(9.2, 0.4, 7.2), Vector3(0, y, 0), Pecas3D.material(Color("#C9BFAA"), 0.7))
	for x in [-2.6, 0.0, 2.6]:
		Pecas3D.caixa(no, Vector3(1.4, 22, 0.1), Vector3(x, 13, 3.56), CenarioVila.vidro_janela())
	Pecas3D.caixa(no, Vector3(6, 4, 22), Vector3(0, 24, -14), claro)
	Pecas3D.caixa(no, Vector3(9.4, 1.2, 7.4), Vector3(0, 26.6, 0), Pecas3D.material(Color("#C9BFAA"), 0.7))
	var letreiro := Label3D.new()
	letreiro.text = "ELEVADOR"
	letreiro.font = CenarioVila.FONTE
	letreiro.font_size = 90
	letreiro.pixel_size = 0.012
	letreiro.modulate = Color("#2E1D4A")
	letreiro.position = Vector3(0, 25.0, 3.6)
	letreiro.double_sided = false
	no.add_child(letreiro)


## Fábrica antiga de tecidos: galpão de tijolo com a chaminé alta.
static func _fabrica(no: Node3D) -> void:
	var tijolo := Texturas.real("tijolos", "#C46A4A", 0.5)
	Pecas3D.caixa(no, Vector3(26, 7, 12), Vector3(0, 3.5, 0), tijolo)
	for k in 4:
		var prisma := PrismMesh.new()
		prisma.size = Vector3(6.5, 2.4, 12.4)
		var teto := MeshInstance3D.new()
		teto.mesh = prisma
		teto.material_override = Pecas3D.material(Color("#8A8F99"), 0.6, 0.3)
		teto.position = Vector3(-9.75 + k * 6.5, 8.2, 0)
		no.add_child(teto)
	for k in 6:
		Pecas3D.caixa(no, Vector3(2.0, 2.6, 0.1), Vector3(-10 + k * 4.0, 3.8, 6.05), CenarioVila.vidro_janela())
	Pecas3D.cilindro(no, 0.9, 1.4, 20.0, Vector3(14.5, 10.0, -3), tijolo)
	Pecas3D.cilindro(no, 1.15, 1.15, 0.8, Vector3(14.5, 19.8, -3), Pecas3D.material(Color("#5A2E1F"), 0.8))


## Torre de prédio alto com antena vermelha e branca.
static func _torre(no: Node3D) -> void:
	predio(no, Vector3.ZERO, Vector3(14, 46, 14), Color("#C9CED8"))
	predio(no, Vector3(0, 46, 0), Vector3(9, 8, 9), Color("#B8BEC9"))
	var antena := Pecas3D.material_textura(Pecas3D.faixas([Color("#E8364F"), Color("#FFFFFF")], 8), 0.4)
	Pecas3D.cilindro(no, 0.25, 0.5, 14.0, Vector3(0, 61.0, 0), antena)


## Museu suspenso: caixa de vidro sobre duas vigas vermelhas (vão livre embaixo).
static func _museu(no: Node3D) -> void:
	var vermelho := Pecas3D.material(Color("#D7262E"), 0.4)
	for x in [-11.0, 11.0]:
		Pecas3D.caixa(no, Vector3(1.6, 13, 1.6), Vector3(x, 6.5, -5.0), vermelho)
		Pecas3D.caixa(no, Vector3(1.6, 13, 1.6), Vector3(x, 6.5, 5.0), vermelho)
		Pecas3D.caixa(no, Vector3(1.6, 1.6, 11.6), Vector3(x, 13.0, 0), vermelho)
	var vidro := CenarioVila.vidro_janela()
	Pecas3D.caixa(no, Vector3(20.4, 6.0, 9.0), Vector3(0, 9.0, 0), vidro)
	Pecas3D.caixa(no, Vector3(20.6, 0.4, 9.2), Vector3(0, 6.0, 0), Pecas3D.material(Color("#5C6470"), 0.6))
	Pecas3D.caixa(no, Vector3(24, 0.2, 14), Vector3(0, 0.1, 0), Pecas3D.material(Color("#C7C2BA"), 0.9))


## Pico do Itacolomi: morro alto com as duas pedras no alto.
static func _pico(no: Node3D) -> void:
	morro(no, Vector3(0, 0, 0), 30.0, Color("#5E8F4A"))
	Pecas3D.caixa(no, Vector3(5, 9, 5), Vector3(-2, 27, 0), Pecas3D.material(Color("#8D8378"), 0.95), Vector3(0, 0, 8))
	Pecas3D.caixa(no, Vector3(3, 5, 3), Vector3(3, 25, 1), Pecas3D.material(Color("#9A8F84"), 0.95), Vector3(0, 0, -6))
