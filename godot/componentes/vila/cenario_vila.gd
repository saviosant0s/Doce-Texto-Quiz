class_name CenarioVila
## Peças do cenário da Vila dos Doces, montadas por código (como os doces):
## chão, caminhos de biscoito, praça com fonte de chocolate, prédios com porta
## e enfeites (árvores de pirulito, bengalas doces, jujubas, flores, morros de
## sorvete, nuvens) e o estilo de desenho animado (luz em degraus e contorno).

const FONTE := preload("res://assets/fontes/BebasNeue-Regular.ttf")


static func _m(cor: String, aspereza := 0.5, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


## Material com textura de relevo (assets/texturas, ver
## scripts/ferramentas/gerar_texturas.gd): biscoito, telhas, pedras, glacê.
## Projetada pelo mundo (triplanar), então fica certa em qualquer forma e
## continua certa depois de as peças serem juntadas. `escala` = repetições
## por metro.
static func _texturizado(cor: String, textura: String, escala := 1.0, aspereza := 0.7) -> StandardMaterial3D:
	var mat := _m(cor, aspereza)
	mat.albedo_texture = load("res://assets/texturas/%s.png" % textura)
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/texturas/%s_relevo.png" % textura)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_triplanar_sharpness = 4.0
	mat.uv1_scale = Vector3.ONE * escala
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


## Colisão em forma de caixa (paredes, bancos...).
static func _parede(pai: Node3D, tamanho: Vector3, posicao: Vector3) -> void:
	var corpo := StaticBody3D.new()
	corpo.position = posicao
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	forma.shape = caixa
	corpo.add_child(forma)
	pai.add_child(corpo)


## Colisão em forma de cilindro (troncos, fonte).
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




# --- Chão, caminhos e limites --------------------------------------------------

static func chao(pai: Node3D, metade: float) -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2(metade * 4.0, metade * 4.0)
	var no := MeshInstance3D.new()
	no.name = "Chao"
	no.mesh = plano
	# gramado de menta com manchas de dois tons (estilo desenho, bordas duras)
	no.material_override = Texturas.real("grama", "#FFFFFF", 0.3)  # grama de verdade (foto)
	pai.add_child(no)
	_parede(pai, Vector3(metade * 4, 1, metade * 4), Vector3(0, -0.5, 0))  # piso
	# cerca invisível em volta
	for lado in [-1, 1]:
		_parede(pai, Vector3(metade * 2, 4, 1), Vector3(0, 2, lado * metade))
		_parede(pai, Vector3(1, 4, metade * 2), Vector3(lado * metade, 2, 0))


## Caminho de `de` até `ate` (no chão): areia de açúcar com biscoitos de
## gotas de chocolate servindo de pedras de passagem.
static func caminho(pai: Node3D, de: Vector3, ate: Vector3, largura := 2.4) -> void:
	var no := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(largura, 0.04, de.distance_to(ate))
	no.mesh = caixa
	no.material_override = Texturas.real("areia", "#F7D9A6", 0.6)
	no.position = (de + ate) / 2.0 + Vector3(0, 0.02, 0)
	no.rotation.y = atan2(ate.x - de.x, ate.z - de.z)
	pai.add_child(no)
	var biscoito := _texturizado("#D9A05B", "biscoito", 2.5, 0.9)
	var gota := _m("#5A2E17", 0.4)
	var acucar := _m("#FFFFFF", 0.4)
	var lateral := (ate - de).normalized().cross(Vector3.UP)
	var passos := int(de.distance_to(ate) / 1.25)
	for i in passos:
		var t := (i + 0.5) / passos
		var centro := de.lerp(ate, t) + lateral * (0.4 if i % 2 == 0 else -0.4) + Vector3(0, 0.06, 0)
		Pecas3D.cilindro(pai, 0.5, 0.52, 0.08, centro, biscoito)
		for j in 4:
			var angulo := j * TAU / 4.0 + i
			Pecas3D.esfera(pai, 0.07, centro + Vector3(cos(angulo) * 0.26, 0.05, sin(angulo) * 0.26), gota, Vector3(1, 0.6, 1))
		# pontinhos de açúcar nas bordas
		for lado in [-1, 1]:
			Pecas3D.esfera(pai, 0.1, de.lerp(ate, t) + lateral * lado * (largura / 2.0 + 0.1) + Vector3(0, 0.06, 0), acucar)


## Praça redonda com a fonte de chocolate no meio.
static func praca(pai: Node3D, raio: float) -> void:
	Pecas3D.cilindro(pai, raio, raio, 0.08, Vector3(0, 0.04, 0), Texturas.real("calcamento", "#FFF3E0", 0.45))
	Pecas3D.rosquinha(pai, raio - 0.25, raio + 0.1, Vector3(0, 0.08, 0), _m("#E9B97A", 0.8), Vector3(1, 0.4, 1))
	# fonte: bacia, coluna e pratinhos com chocolate escorrendo
	var chocolate := _m("#5A2E17", 0.15)
	var borda := _texturizado("#FFF1F5", "glace", 1.5, 0.3)
	Pecas3D.cilindro(pai, 2.0, 2.2, 0.7, Vector3(0, 0.35, 0), borda)
	Pecas3D.cilindro(pai, 1.8, 1.8, 0.06, Vector3(0, 0.68, 0), chocolate)
	Pecas3D.cilindro(pai, 0.3, 0.35, 2.2, Vector3(0, 1.4, 0), borda)
	Pecas3D.cilindro(pai, 1.0, 0.7, 0.3, Vector3(0, 2.3, 0), borda)
	Pecas3D.cilindro(pai, 0.95, 0.95, 0.05, Vector3(0, 2.46, 0), chocolate)
	Pecas3D.esfera(pai, 0.45, Vector3(0, 2.75, 0), chocolate, Vector3(1, 0.8, 1))
	# pingos de chocolate escorrendo pela borda do pratinho de cima
	for i in 10:
		var angulo := i * TAU / 10.0
		var saida := Vector3(cos(angulo) * 0.98, 2.3, sin(angulo) * 0.98)
		Pecas3D.cano(pai, saida, saida + Vector3(0, -0.22 - (i % 3) * 0.12, 0), 0.08, chocolate)
	# confeitos coloridos na borda da bacia
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF"]
	for i in 16:
		var angulo := i * TAU / 16.0
		Pecas3D.esfera(pai, 0.13, Vector3(cos(angulo) * 2.05, 0.72, sin(angulo) * 2.05), _m(cores[i % cores.size()], 0.25))
	_poste(pai, 2.2, 1.2, Vector3.ZERO)


# --- Prédios -----------------------------------------------------------------------

## Prédio com porta virado para o centro da vila. Cada um tem o seu jeito
## (Escola de biscoito com torre do sino, Confeitaria-cupcake, torre dos
## Troféus, Fliperama em forma de máquina). `dados`: {id, nome, posicao,
## parede, telhado}. Retorna {"porta": ponto em frente à porta,
## "area": Area3D da porta, "no": o prédio, "folha": dobradiça da porta,
## "entrada": ponto já do lado de dentro}.
static func predio(pai: Node3D, dados: Dictionary) -> Dictionary:
	var no := Node3D.new()
	no.name = "Predio_" + dados["id"]
	no.position = dados["posicao"]
	pai.add_child(no)
	no.look_at(Vector3(0.001, 0, 0), Vector3.UP, true)  # porta (+z) para a praça
	# cada construtor monta o prédio e diz onde fica a frente e a placa
	var forma: Dictionary
	match dados["id"]:
		"escola":
			forma = _escola(no)
		"confeitaria":
			forma = _confeitaria(no)
		"trofeus":
			forma = _torre_trofeus(no)
		"fliperama":
			forma = _fliperama(no)
		_:
			forma = _casa_simples(no, dados)
	no.set_meta("pecas", no.find_children("*", "MeshInstance3D", true, false).size())
	var frente: float = forma["frente"]
	# porta e placa num plano na frente do prédio; "inclinacao" deita esse
	# plano para trás junto com paredes inclinadas (a forminha do cupcake)
	var fachada := Node3D.new()
	fachada.name = "Fachada"
	fachada.position.z = frente
	fachada.rotation.x = forma.get("inclinacao", 0.0)
	no.add_child(fachada)
	var folha := _porta(fachada, 0.0)
	if not forma.get("placa_propria", false):
		_placa(fachada, dados["nome"], Vector3(0, forma["placa"], 0.1))
	# área na frente da porta: quando o doce entra, aparece o botão "ENTRAR"
	var area := Area3D.new()
	area.name = "Porta"
	area.position = Vector3(0, 1, frente + 1.6)
	var forma_area := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.0, 2, 3.0)
	forma_area.shape = caixa
	area.add_child(forma_area)
	no.add_child(area)
	return {"porta": no.to_global(Vector3(0, 0, frente + 1.6)), "area": area, "no": no,
		"folha": folha, "entrada": no.to_global(Vector3(0, 0, frente - 0.6))}


## Porta de barra de chocolate com arco e maçaneta, na frente (z = `frente`).
## A folha da porta gira numa dobradiça (nó "Folha", do lado esquerdo) e
## atrás dela fica o escuro do lado de dentro. Retorna a dobradiça.
static func _porta(no: Node3D, frente: float) -> Node3D:
	var chocolate := Texturas.real("madeira_pintada", "#7A4322", 1.2)
	Pecas3D.caixa(no, Vector3(1.2, 1.9, 0.02), Vector3(0, 0.95, frente + 0.005), _m("#2A1D45", 0.9))  # lado de dentro
	Pecas3D.esfera(no, 0.6, Vector3(0, 1.9, frente + 0.02), chocolate, Vector3(1, 0.55, 0.2))
	var dobradica := Node3D.new()
	dobradica.name = "Folha"
	dobradica.position = Vector3(-0.6, 0, frente + 0.04)
	no.add_child(dobradica)
	Pecas3D.caixa(dobradica, Vector3(1.2, 1.9, 0.12), Vector3(0.6, 0.95, 0), chocolate)
	var gomo := _m("#6B3A1F", 0.35)
	for linha in 3:
		for coluna in 2:
			Pecas3D.caixa(dobradica, Vector3(0.44, 0.44, 0.06), Vector3(0.35 + coluna * 0.5, 0.35 + linha * 0.52, 0.08), gomo)
	Pecas3D.esfera(dobradica, 0.08, Vector3(1.05, 0.95, 0.16), _m("#F4E038", 0.2, 0.5))
	return dobradica


## Placa roxa com o nome em amarelo.
static func _placa(no: Node3D, nome: String, posicao: Vector3, largura := 3.0) -> void:
	Pecas3D.caixa(no, Vector3(largura, 0.62, 0.14), posicao, Texturas.real("madeira_pintada", "#8A62C0", 1.2))
	var texto := Label3D.new()
	texto.text = nome
	texto.font = FONTE
	texto.font_size = 110
	texto.pixel_size = 0.0045
	texto.modulate = Color("#F4E038")
	texto.outline_size = 0
	texto.position = posicao + Vector3(0, 0, 0.08)
	no.add_child(texto)


## Janela de bala: vidro azul com moldura e cruz de glacê.
static func _janela(no: Node3D, posicao: Vector3, moldura := "#FFFFFF") -> void:
	var janela := Node3D.new()
	janela.position = posicao
	no.add_child(janela)
	Pecas3D.caixa(janela, Vector3(0.95, 0.95, 0.08), Vector3.ZERO, Texturas.real("madeira_pintada", moldura, 1.2))
	Pecas3D.caixa(janela, Vector3(0.75, 0.75, 0.1), Vector3(0, 0, 0.02), _m("#BFE9FF", 0.1))
	var glace := _m("#FFFFFF", 0.35)
	Pecas3D.caixa(janela, Vector3(0.75, 0.08, 0.12), Vector3(0, 0, 0.04), glace)
	Pecas3D.caixa(janela, Vector3(0.08, 0.75, 0.12), Vector3(0, 0, 0.04), glace)


## Casa simples (caixa com telhado de pirâmide), para prédios novos.
static func _casa_simples(no: Node3D, dados: Dictionary) -> Dictionary:
	var largura := 4.6
	var altura := 3.2
	var fundo := 3.8
	Pecas3D.caixa(no, Vector3(largura, altura, fundo), Vector3(0, altura / 2.0, 0), Texturas.real("reboco", dados.get("parede", "#FFB3D1"), 0.5))
	Pecas3D.cilindro(no, 0.0, largura * 0.78, 2.0, Vector3(0, altura + 1.15, 0),
		_m(dados.get("telhado", "#7E57B1"), 0.35), Vector3(1, 1, fundo / largura), Vector3(0, 45, 0))
	for lado in [-1, 1]:
		_janela(no, Vector3(lado * 1.6, 1.55, fundo / 2.0 + 0.03))
	_parede(no, Vector3(largura, altura + 2, fundo), Vector3(0, (altura + 2) / 2.0, 0))
	return {"frente": fundo / 2.0, "placa": altura - 0.5}


## ESCOLA: casinha de biscoito de gengibre com telhado roxo de duas águas,
## glacê nas bordas, balas de goma no alto e a torre do sino amarela.
static func _escola(no: Node3D) -> Dictionary:
	var largura := 5.4
	var altura := 3.3
	var fundo := 4.2
	var biscoito := Texturas.real("reboco_barro", "#E6A56E", 0.5)
	var glace := _texturizado("#FFFFFF", "glace", 1.5, 0.35)
	Pecas3D.caixa(no, Vector3(largura, altura, fundo), Vector3(0, altura / 2.0, 0), biscoito)
	# glacê nos cantos e no rodapé da frente
	for x in [-1, 1]:
		for z in [-1, 1]:
			Pecas3D.cano(no, Vector3(x * largura / 2.0, 0.1, z * fundo / 2.0), Vector3(x * largura / 2.0, altura, z * fundo / 2.0), 0.1, glace)
	Pecas3D.cano(no, Vector3(-largura / 2.0, 0.1, fundo / 2.0), Vector3(largura / 2.0, 0.1, fundo / 2.0), 0.1, glace)
	# telhado de duas águas (cumeeira de frente para trás), com beiral
	var telhado := PrismMesh.new()
	telhado.size = Vector3(largura + 0.8, 2.3, fundo + 0.6)
	var roxo := Texturas.real("ardosia", "#B590EC", 0.6)
	var no_telhado := MeshInstance3D.new()
	no_telhado.mesh = telhado
	no_telhado.material_override = roxo
	no_telhado.position = Vector3(0, altura + 1.15, 0)
	no.add_child(no_telhado)
	# glacê nas bordas inclinadas do telhado, na frente e atrás
	var topo := altura + 2.3
	for z in [-1, 1]:
		var borda: float = z * (fundo / 2.0 + 0.3)
		for lado in [-1, 1]:
			Pecas3D.cano(no, Vector3(lado * (largura / 2.0 + 0.4), altura, borda), Vector3(0, topo, borda), 0.13, glace)
	# glacê escorrendo embaixo do beiral
	for i in 8:
		var x := -largura / 2.0 + 0.4 + i * (largura - 0.8) / 7.0
		Pecas3D.esfera(no, 0.14, Vector3(x, altura - 0.08 - (i % 2) * 0.1, fundo / 2.0 + 0.04), glace, Vector3(1, 1.4, 0.6))
	# balas de goma coloridas na cumeeira
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#FF8A5B"]
	for i in 5:
		var z := -fundo / 2.0 + 0.4 + i * (fundo - 0.8) / 4.0
		Pecas3D.esfera(no, 0.26, Vector3(0, topo + 0.05, z), _m(cores[i], 0.2), Vector3(1, 0.8, 1))
	# janela redonda no triângulo da frente
	Pecas3D.rosquinha(no, 0.3, 0.45, Vector3(0, altura + 0.75, fundo / 2.0 + 0.32), glace, Vector3.ONE, Vector3(90, 0, 0))
	Pecas3D.cilindro(no, 0.32, 0.32, 0.05, Vector3(0, altura + 0.75, fundo / 2.0 + 0.3), _m("#BFE9FF", 0.1), Vector3.ONE, Vector3(90, 0, 0))
	for lado in [-1, 1]:
		_janela(no, Vector3(lado * 1.75, 1.5, fundo / 2.0 + 0.03), "#F4E038")
	# torre do sino (amarela, com telhado roxo em cone), no fundo do telhado
	var amarelo := Texturas.real("reboco", "#F7E36A", 0.8)
	var base_torre := Vector3(0, topo - 0.4, -fundo / 2.0 + 0.9)
	Pecas3D.caixa(no, Vector3(1.3, 0.6, 1.3), base_torre + Vector3(0, 0.3, 0), amarelo)
	for x in [-1, 1]:
		for z in [-1, 1]:
			Pecas3D.cano(no, base_torre + Vector3(x * 0.5, 0.6, z * 0.5), base_torre + Vector3(x * 0.5, 1.6, z * 0.5), 0.09, amarelo)
	Pecas3D.cilindro(no, 0.0, 1.05, 1.1, base_torre + Vector3(0, 2.15, 0), roxo)
	Pecas3D.esfera(no, 0.14, base_torre + Vector3(0, 2.75, 0), _m("#F4E038", 0.2, 0.5))
	var ouro := Texturas.real("metal", "#FFD04A", 1.0, 0.6)
	Pecas3D.cilindro(no, 0.16, 0.38, 0.5, base_torre + Vector3(0, 1.2, 0), ouro)
	Pecas3D.esfera(no, 0.1, base_torre + Vector3(0, 0.92, 0), ouro)
	_parede(no, Vector3(largura, altura + 2.3, fundo), Vector3(0, (altura + 2.3) / 2.0, 0))
	return {"frente": fundo / 2.0, "placa": altura - 0.55}


## CONFEITARIA: um cupcake gigante (forminha listrada, cobertura em
## camadas, confeitos e uma cereja em cima).
static func _confeitaria(no: Node3D) -> Dictionary:
	var raio_base := 2.6
	var raio_topo := 3.0
	var altura := 3.5
	var forminha := Pecas3D.material_textura(Pecas3D.listras([Color("#FF8FB8"), Color("#FFFFFF")], 28), 0.5)
	Pecas3D.cilindro(no, raio_topo, raio_base, altura, Vector3(0, altura / 2.0, 0), forminha)
	# cobertura: rosquinhas empilhadas, cada vez menores
	var rosa := _texturizado("#FFC2DA", "glace", 1.2, 0.3)
	var creme := _texturizado("#FFF1F5", "glace", 1.2, 0.3)
	var camadas := [[2.3, 3.3, 0.0], [1.5, 2.6, 0.75], [0.7, 1.8, 1.4]]
	for i in camadas.size():
		var c: Array = camadas[i]
		Pecas3D.rosquinha(no, c[0], c[1], Vector3(0, altura + 0.35 + c[2], 0), rosa if i % 2 == 0 else creme, Vector3(1, 1.25, 1))
	Pecas3D.esfera(no, 0.95, Vector3(0, altura + 2.2, 0), rosa, Vector3(1, 0.9, 1))
	# confeitos coloridos por cima da cobertura
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 21
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF", "#FFFFFF"]
	var materiais := cores.map(func(c): return _m(c, 0.3))
	for i in 46:
		var camada: Array = camadas[i % camadas.size()]
		var angulo := sorteio.randf() * TAU
		var r: float = (camada[0] + camada[1]) / 2.0
		var meia_altura: float = (camada[1] - camada[0]) / 2.0 * 1.25
		var ponto := Vector3(cos(angulo) * r, altura + 0.35 + camada[2] + meia_altura * 0.95, sin(angulo) * r)
		var giro := Vector3(sorteio.randf_range(-1, 1), 0, sorteio.randf_range(-1, 1)).normalized() * 0.1
		Pecas3D.cano(no, ponto - giro, ponto + giro, 0.05, materiais[i % materiais.size()])
	# cereja com cabinho
	var topo := altura + 3.05
	Pecas3D.esfera(no, 0.55, Vector3(0, topo, 0), _m("#E8263F", 0.12))
	Pecas3D.cano(no, Vector3(0, topo + 0.4, 0), Vector3(0.3, topo + 1.0, -0.1), 0.05, _m("#5DBB46", 0.4))
	# janelas redondas acompanhando a curva da forminha
	var raio_janela := raio_base + (raio_topo - raio_base) * 0.55
	for angulo in [-0.75, 0.75]:
		var janela := Node3D.new()
		janela.position = Vector3(sin(angulo) * raio_janela, 1.65, cos(angulo) * raio_janela)
		janela.rotation.y = angulo
		no.add_child(janela)
		Pecas3D.rosquinha(janela, 0.35, 0.5, Vector3.ZERO, _m("#FFFFFF", 0.35), Vector3.ONE, Vector3(90, 0, 0))
		Pecas3D.cilindro(janela, 0.37, 0.37, 0.05, Vector3(0, 0, -0.02), _m("#BFE9FF", 0.1), Vector3.ONE, Vector3(90, 0, 0))
	_poste(no, raio_topo, altura + 2.5, Vector3.ZERO)
	# a porta e a placa acompanham a parede inclinada da forminha
	return {"frente": raio_base + 0.03, "placa": 2.75, "inclinacao": atan((raio_topo - raio_base) / altura)}


## TROFÉUS: torre lilás de dois andares com colunas de bengala doce, faixas
## douradas e cúpula de ouro com uma estrela no alto.
static func _torre_trofeus(no: Node3D) -> Dictionary:
	var largura := 4.8
	var altura := 3.5
	var fundo := 4.2
	var ouro := Texturas.real("metal", "#FFD04A", 1.0, 0.6)
	Pecas3D.caixa(no, Vector3(largura, altura, fundo), Vector3(0, altura / 2.0, 0), Texturas.real("tijolos", "#E4D4FF", 0.6))
	Pecas3D.caixa(no, Vector3(largura + 0.3, 0.25, fundo + 0.3), Vector3(0, altura + 0.12, 0), ouro)
	# segundo andar e cúpula
	var andar := 1.5
	var base_andar := altura + 0.25
	Pecas3D.caixa(no, Vector3(3.2, andar, 3.0), Vector3(0, base_andar + andar / 2.0, 0), Texturas.real("tijolos", "#C7B0F0", 0.6))
	Pecas3D.caixa(no, Vector3(3.5, 0.2, 3.3), Vector3(0, base_andar + andar + 0.1, 0), ouro)
	var cupula := SphereMesh.new()
	cupula.radius = 1.45
	cupula.height = 1.45
	cupula.is_hemisphere = true
	var no_cupula := MeshInstance3D.new()
	no_cupula.mesh = cupula
	no_cupula.material_override = ouro
	no_cupula.position = Vector3(0, base_andar + andar + 0.2, 0)
	no.add_child(no_cupula)
	var ponta := base_andar + andar + 1.6
	Pecas3D.cano(no, Vector3(0, ponta, 0), Vector3(0, ponta + 0.7, 0), 0.07, ouro)
	_estrela(no, Vector3(0, ponta + 1.1, 0), 0.5, ouro)
	_estrela(no, Vector3(0, base_andar + andar / 2.0, 1.58), 0.45, ouro)
	# colunas de bengala doce: dos lados da porta e nos cantos
	var listras := Pecas3D.material_textura(Pecas3D.faixas([Color("#E8364F"), Color("#FFFFFF")], 12), 0.25)
	for x in [-largura / 2.0 - 0.05, -1.2, 1.2, largura / 2.0 + 0.05]:
		var z := fundo / 2.0 + 0.3
		Pecas3D.cilindro(no, 0.22, 0.22, altura, Vector3(x, altura / 2.0, z), listras)
		Pecas3D.esfera(no, 0.28, Vector3(x, altura + 0.15, z), ouro)
	for x in [-1, 1]:
		Pecas3D.cilindro(no, 0.22, 0.22, altura, Vector3(x * (largura / 2.0 + 0.05), altura / 2.0, -fundo / 2.0 - 0.1), listras)
	for lado in [-1, 1]:
		_janela(no, Vector3(lado * 1.85, 1.6, fundo / 2.0 + 0.03), "#F2C230")
	_parede(no, Vector3(largura + 0.6, altura + andar + 2, fundo + 0.6), Vector3(0, (altura + andar + 2) / 2.0, 0))
	return {"frente": fundo / 2.0, "placa": altura - 0.55}


## Estrela de 5 pontas achatada, de frente (+z).
static func _estrela(no: Node3D, centro: Vector3, raio: float, mat: Material) -> void:
	var estrela := Node3D.new()
	estrela.position = centro
	no.add_child(estrela)
	Pecas3D.cilindro(estrela, raio * 0.45, raio * 0.45, 0.16, Vector3.ZERO, mat, Vector3.ONE, Vector3(90, 0, 0))
	for i in 5:
		var angulo := i * TAU / 5.0
		var ponta := Pecas3D.cilindro(estrela, 0.0, raio * 0.3, raio * 0.7, Vector3.ZERO, mat, Vector3(1, 1, 0.45))
		ponta.rotation = Vector3(0, 0, -angulo)
		ponta.position = Vector3(sin(angulo), cos(angulo), 0) * raio * 0.62


## FLIPERAMA: prédio em forma de máquina de fliperama, com letreiro aceso,
## tela de joguinho e painel com alavanca e botões em cima da porta.
static func _fliperama(no: Node3D) -> Dictionary:
	var largura := 4.4
	var altura := 5.4
	var fundo := 3.6
	var frente := fundo / 2.0
	var azul := Texturas.real("reboco", "#A6E0FA", 0.5)
	Pecas3D.caixa(no, Vector3(largura, altura, fundo), Vector3(0, altura / 2.0, 0), Texturas.real("reboco", "#7F5ABD", 0.5))
	# laterais azuis mais altas, com listras amarelas
	var amarelo := _m("#F4E038", 0.4)
	for lado in [-1, 1]:
		var x: float = lado * (largura / 2.0 + 0.12)
		Pecas3D.caixa(no, Vector3(0.24, altura + 0.3, fundo + 0.3), Vector3(x, (altura + 0.3) / 2.0, 0), azul)
		for i in 3:
			Pecas3D.caixa(no, Vector3(0.28, 0.16, fundo + 0.34), Vector3(x, 1.0 + i * 0.35, 0), amarelo)
	# letreiro aceso no alto (é a placa com o nome)
	var letreiro := _m("#F4E038", 0.3)
	letreiro.emission_enabled = true
	letreiro.emission = Color("#F4E038")
	letreiro.emission_energy_multiplier = 0.1
	Pecas3D.caixa(no, Vector3(largura - 0.1, 0.95, 0.4), Vector3(0, altura - 0.5, frente + 0.12), letreiro)
	var texto := Label3D.new()
	texto.text = "FLIPERAMA"
	texto.font = FONTE
	texto.font_size = 140
	texto.pixel_size = 0.0055
	texto.modulate = Color("#5E3D8E")
	texto.outline_size = 0
	texto.position = Vector3(0, altura - 0.5, frente + 0.34)
	no.add_child(texto)
	# tela com um joguinho de blocos
	var tela := Pecas3D.material_textura(_textura_tela(), 0.3)
	tela.emission_enabled = true
	tela.emission_texture = tela.albedo_texture
	tela.emission = Color.WHITE
	tela.emission_energy_multiplier = 0.12
	tela.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	Pecas3D.caixa(no, Vector3(3.3, 1.9, 0.12), Vector3(0, 3.6, frente + 0.02), Texturas.real("metal", "#3A2A5E", 1.0, 0.4))
	Pecas3D.caixa(no, Vector3(3.0, 1.6, 0.1), Vector3(0, 3.6, frente + 0.06), tela)
	# painel inclinado com alavanca e botões, acima da porta
	var painel := Node3D.new()
	painel.position = Vector3(0, 2.4, frente + 0.45)
	painel.rotation.x = deg_to_rad(18)
	no.add_child(painel)
	Pecas3D.caixa(painel, Vector3(largura - 0.2, 0.3, 1.0), Vector3.ZERO, azul)
	Pecas3D.cano(painel, Vector3(-1.3, 0.15, 0), Vector3(-1.3, 0.6, 0), 0.06, _m("#DDDDDD", 0.4))
	Pecas3D.esfera(painel, 0.2, Vector3(-1.3, 0.68, 0), _m("#E8364F", 0.2))
	var cores := ["#E8364F", "#F4E038", "#5DBB46", "#6FD3FF"]
	for i in 4:
		Pecas3D.cilindro(painel, 0.16, 0.16, 0.12, Vector3(0.3 + i * 0.42, 0.2, (i % 2) * 0.2 - 0.1), _m(cores[i], 0.2))
	_parede(no, Vector3(largura + 0.5, altura + 0.3, fundo + 0.3), Vector3(0, (altura + 0.3) / 2.0, 0))
	return {"frente": frente, "placa": altura - 0.5, "placa_propria": true}


## Tela do fliperama: fundo azul-escuro, fileiras de blocos, raquete e bolinha.
static func _textura_tela() -> ImageTexture:
	var imagem := Image.create(30, 16, false, Image.FORMAT_RGBA8)
	imagem.fill(Color("#1B1340"))
	var cores := [Color("#FF6FAE"), Color("#6FD3FF"), Color("#FFD23F"), Color("#7BE07B")]
	for linha in 3:
		for coluna in 7:
			imagem.fill_rect(Rect2i(2 + coluna * 4, 2 + linha * 2, 3, 1), cores[(linha + coluna) % cores.size()])
	imagem.fill_rect(Rect2i(12, 13, 6, 1), Color.WHITE)
	imagem.fill_rect(Rect2i(16, 10, 1, 1), Color("#F4E038"))
	return ImageTexture.create_from_image(imagem)


# --- Enfeites -------------------------------------------------------------------------

static func arvore_pirulito(pai: Node3D, posicao: Vector3, cor: String) -> void:
	Pecas3D.cano(pai, posicao, posicao + Vector3(0, 2.0, 0), 0.09, _m("#FFFFFF", 0.4))
	var doce := _m(cor, 0.2)
	Pecas3D.esfera(pai, 0.85, posicao + Vector3(0, 2.7, 0), doce)
	Pecas3D.rosquinha(pai, 0.5, 0.9, posicao + Vector3(0, 2.7, 0), _m("#FFFFFF", 0.25), Vector3(1, 1, 0.5), Vector3(90, 0, 0))
	_poste(pai, 0.25, 2.0, posicao)


static func bengala(pai: Node3D, posicao: Vector3) -> void:
	var listras := Pecas3D.material_textura(Pecas3D.faixas([Color("#E8364F"), Color("#FFFFFF")], 8), 0.2)
	Pecas3D.cilindro(pai, 0.15, 0.15, 2.2, posicao + Vector3(0, 1.1, 0), listras)
	var gancho := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.28
	toro.outer_radius = 0.58
	gancho.mesh = toro
	gancho.material_override = _m("#E8364F", 0.2)
	gancho.position = posicao + Vector3(0.43, 2.2, 0)
	gancho.rotation_degrees = Vector3(90, 0, 0)
	pai.add_child(gancho)
	_poste(pai, 0.2, 2.2, posicao)


static func jujuba(pai: Node3D, posicao: Vector3, cor: String, tamanho := 1.0) -> void:
	var meia := SphereMesh.new()
	meia.radius = 0.5 * tamanho
	meia.height = 0.55 * tamanho
	meia.is_hemisphere = true
	var no := MeshInstance3D.new()
	no.mesh = meia
	no.material_override = _m(cor, 0.25)
	no.position = posicao
	pai.add_child(no)
	Pecas3D.granulado(pai, posicao, 0.45 * tamanho, 10, [Color("#FFFFFF")], int(posicao.x * 100 + posicao.z), 0.3, tamanho)


## Florzinhas espalhadas (MultiMesh: centenas de peças desenhadas de uma vez
## só, leve até no celular).
static func flores(pai: Node3D, pontos: Array, semente: int) -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = semente
	var cores := [Color("#FF8FB8"), Color("#FFFFFF"), Color("#FFD23F"), Color("#B07CFF"), Color("#6FD3FF")]
	var petala := SphereMesh.new()
	petala.radius = 0.09
	petala.height = 0.1
	petala.radial_segments = 10
	petala.rings = 5
	var miolo := SphereMesh.new()
	miolo.radius = 0.06
	miolo.height = 0.1
	miolo.radial_segments = 10
	miolo.rings = 5
	var petalas := _multimesh(pai, petala, pontos.size() * 5)
	var miolos := _multimesh(pai, miolo, pontos.size())
	for i in pontos.size():
		var centro: Vector3 = pontos[i] + Vector3(0, 0.12, 0)
		var cor: Color = cores[sorteio.randi() % cores.size()]
		for j in 5:
			var angulo := j * TAU / 5.0
			petalas.multimesh.set_instance_transform(i * 5 + j, Transform3D(Basis(), centro + Vector3(cos(angulo), 0, sin(angulo)) * 0.1))
			petalas.multimesh.set_instance_color(i * 5 + j, cor)
		miolos.multimesh.set_instance_transform(i, Transform3D(Basis(), centro + Vector3(0, 0.03, 0)))
		miolos.multimesh.set_instance_color(i, Color("#F4A53A") if cor != Color("#FFD23F") else Color("#FF6FAE"))


## Grama com volume: um tufo de folhinhas em cada ponto, balançando com o
## vento (tema/grama.gdshader). Um MultiMesh só para todos os tufos.
static func grama(pai: Node3D, pontos: Array, semente: int) -> MultiMeshInstance3D:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = semente
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = _tufo_de_grama()
	multi.instance_count = pontos.size()
	for i in pontos.size():
		var base := Basis(Vector3.UP, sorteio.randf() * TAU).scaled(Vector3.ONE * sorteio.randf_range(0.6, 1.1))
		multi.set_instance_transform(i, Transform3D(base, pontos[i]))
		var tom := sorteio.randf_range(0.85, 1.1)
		multi.set_instance_color(i, Color(tom, tom * sorteio.randf_range(0.97, 1.05), tom))
	var no := MultiMeshInstance3D.new()
	no.name = "Grama"
	no.multimesh = multi
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://tema/grama.gdshader")
	no.material_override = mat
	no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(no)
	return no


## Tufo com 5 folhinhas finas e curvadas (UV.y vai de 0 na base a 1 na ponta).
static func _tufo_de_grama() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in 5:
		var angulo := f * TAU / 5.0 + 0.3
		var lado := Vector3(cos(angulo), 0, sin(angulo))
		var frente := Vector3(-lado.z, 0, lado.x)
		var inclina := lado.rotated(Vector3.UP, PI / 2) * 0.12 * (1 + f % 2)
		var altura := 0.34 + (f % 3) * 0.08
		var largura := 0.045
		var meio := frente * 0.08 * (f % 2) + lado * 0.05
		var pontos := [
			[meio - frente * largura, 0.0], [meio + frente * largura, 0.0],
			[meio - frente * largura * 0.6 + inclina * 0.5 + Vector3(0, altura * 0.5, 0), 0.5],
			[meio + frente * largura * 0.6 + inclina * 0.5 + Vector3(0, altura * 0.5, 0), 0.5],
			[meio + inclina + Vector3(0, altura, 0), 1.0],
		]
		for tri in [[0, 1, 2], [1, 3, 2], [2, 3, 4]]:
			for k in tri:
				st.set_uv(Vector2(0.5, pontos[k][1]))
				st.set_normal(Vector3.UP)
				st.add_vertex(pontos[k][0])
	return st.commit()


static func _multimesh(pai: Node3D, malha: Mesh, quantidade: int) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = malha
	multi.instance_count = quantidade
	var no := MultiMeshInstance3D.new()
	no.multimesh = multi
	var mat := Pecas3D.material(Color.WHITE, 0.5)
	mat.vertex_color_use_as_albedo = true
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	no.material_override = mat
	no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(no)
	return no


## Morros de sorvete no horizonte (fora da área de andar), com cobertura
## escorrendo e uma cereja, para a vila não terminar "no nada".
static func morros(pai: Node3D, raio: float) -> void:
	var sorvetes := [["#FFC2DA", "#FFFFFF"], ["#C9B3EC", "#FFF1F5"], ["#A8E6C1", "#FFFFFF"], ["#FFE08A", "#8B4A2B"], ["#9FD4F7", "#FFFFFF"]]
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 99
	for i in 14:
		var angulo := i * TAU / 14.0 + sorteio.randf_range(-0.1, 0.1)
		var distancia := raio + sorteio.randf_range(0.0, 6.0)
		var tamanho := sorteio.randf_range(5.0, 8.5)
		var centro := Vector3(cos(angulo) * distancia, -tamanho * 0.35, sin(angulo) * distancia)
		var par: Array = sorvetes[i % sorvetes.size()]
		Pecas3D.esfera(pai, tamanho, centro, _texturizado(par[0], "glace", 0.35, 0.7), Vector3(1, 0.75, 1))
		# cobertura: calota achatada em cima
		Pecas3D.esfera(pai, tamanho * 0.62, centro + Vector3(0, tamanho * 0.52, 0), _texturizado(par[1], "glace", 0.35, 0.4), Vector3(1, 0.45, 1))
		if i % 3 == 0:
			Pecas3D.esfera(pai, tamanho * 0.14, centro + Vector3(0, tamanho * 0.8, 0), _m("#E8263F", 0.15))


## Nuvens de algodão-doce flutuando no céu.
static func nuvens(pai: Node3D) -> Array:
	var lista := []
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 5
	var cores := ["#FFFFFF", "#FFE3F0", "#F3EAFF"]
	for i in 7:
		var nuvem := Node3D.new()
		nuvem.name = "Nuvem"
		var angulo := i * TAU / 7.0
		nuvem.position = Vector3(cos(angulo) * sorteio.randf_range(14, 30), sorteio.randf_range(13, 18), sin(angulo) * sorteio.randf_range(14, 30))
		pai.add_child(nuvem)
		var mat := _m(cores[i % cores.size()], 0.9)
		for j in 5:
			var x := (j - 2) * 1.1
			Pecas3D.esfera(nuvem, 1.3 - absf(j - 2) * 0.25, Vector3(x, sorteio.randf_range(-0.2, 0.3), sorteio.randf_range(-0.4, 0.4)), mat)
		lista.append(nuvem)
	return lista


# --- Estilo de desenho animado -----------------------------------------------------

## Verdadeiro no modo leve de desenho (navegador e aparelhos sem Vulkan), que
## ilumina mais forte: as cenas usam luzes mais fracas nele.
static func modo_leve() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


## Qualidade do 3D nas cenas grandes (vila e cozinha): antisserrilhado leve e
## o 3D desenhado a 80% do tamanho da tela (a interface continua nítida) —
## bem mais leve em celular de tela grande. Devolve o que havia antes, para
## restaurar_qualidade() ao sair da cena.
static func qualidade_3d(viewport: Viewport) -> Dictionary:
	var antes := {"msaa": viewport.msaa_3d, "escala": viewport.scaling_3d_scale}
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.scaling_3d_scale = 0.8
	return antes


static func restaurar_qualidade(viewport: Viewport, antes: Dictionary) -> void:
	viewport.msaa_3d = antes["msaa"]
	viewport.scaling_3d_scale = antes["escala"]


## Acabamento de imagem do modo Mobile (APK e Windows): cores um pouco mais
## vivas. (Brilho/"glow" e tonemap deixavam tudo esbranquiçado.) No modo leve
## não faz nada.
static func acabamento(ambiente: Environment) -> void:
	if modo_leve():
		return
	# o céu reflete nos metais (ouro, inox); no modo leve deixava tudo desbotado
	ambiente.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	ambiente.adjustment_enabled = true
	ambiente.adjustment_saturation = 1.1
	ambiente.adjustment_contrast = 1.04

const CONTORNO := preload("res://tema/contorno.gdshader")
const COR_CONTORNO := Color("#3A2060")

## Deixa tudo em `raiz` com cara de desenho: luz em degraus (toon) e contorno
## escuro nas peças maiores (as pequenas, como olhos e confeitos, ficam sem).
static func estilo_desenho(raiz: Node, espessura := 0.035) -> void:
	var contornos := {}
	for no in raiz.find_children("*", "MeshInstance3D", true, false):
		var peca := no as MeshInstance3D
		var mat := peca.material_override as StandardMaterial3D
		if mat == null or mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			continue
		if not mat.has_meta("real"):  # texturas reais ficam com a luz normal (mais natural)
			mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or peca.mesh is PlaneMesh:
			continue
		var caixa := peca.get_aabb()
		var tamanho := (caixa.size * peca.global_transform.basis.get_scale()).abs()
		if maxf(tamanho.x, maxf(tamanho.y, tamanho.z)) < 0.45:
			continue
		var forma := 0
		if peca.mesh is BoxMesh:
			forma = 1
		elif peca.mesh is CylinderMesh:
			forma = 2
		elif peca.mesh is PrismMesh:
			forma = 3
		var cor := COR_CONTORNO
		if mat.albedo_texture == null:
			cor = mat.albedo_color.darkened(0.55).lerp(COR_CONTORNO, 0.45)
		var chave := "%s_%d" % [cor.to_html(), forma]
		if not contornos.has(chave):
			var contorno := ShaderMaterial.new()
			contorno.shader = CONTORNO
			contorno.set_shader_parameter("cor", cor)
			contorno.set_shader_parameter("espessura", espessura)
			contorno.set_shader_parameter("forma", forma)
			contornos[chave] = contorno
		peca.material_overlay = contornos[chave]
