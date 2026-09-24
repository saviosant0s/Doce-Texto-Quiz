class_name CenarioVila
## Peças do cenário da Vila dos Doces, montadas por código (como os doces):
## chão, caminhos de biscoito, praça com fonte de chocolate, prédios com porta
## e enfeites (árvores de pirulito, bengalas doces, jujubas).

const FONTE := preload("res://assets/fontes/BebasNeue-Regular.ttf")


static func _m(cor: String, aspereza := 0.5, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


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
	plano.size = Vector2(metade * 2.6, metade * 2.6)
	var no := MeshInstance3D.new()
	no.mesh = plano
	no.material_override = _m("#6FCB8E", 0.95)  # gramado de menta
	pai.add_child(no)
	_parede(pai, Vector3(metade * 3, 1, metade * 3), Vector3(0, -0.5, 0))  # piso
	# cerca invisível em volta
	for lado in [-1, 1]:
		_parede(pai, Vector3(metade * 2, 4, 1), Vector3(0, 2, lado * metade))
		_parede(pai, Vector3(1, 4, metade * 2), Vector3(lado * metade, 2, 0))


## Caminho de biscoito reto, de `de` até `ate` (no chão).
static func caminho(pai: Node3D, de: Vector3, ate: Vector3, largura := 2.4) -> void:
	var no := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(largura, 0.06, de.distance_to(ate))
	no.mesh = caixa
	no.material_override = _m("#E8B86D", 0.9)
	no.position = (de + ate) / 2.0 + Vector3(0, 0.03, 0)
	no.rotation.y = atan2(ate.x - de.x, ate.z - de.z)
	pai.add_child(no)
	# pontinhos de açúcar nas bordas
	var passos := int(de.distance_to(ate) / 1.6)
	for i in passos:
		var t := (i + 0.5) / passos
		var ponto := de.lerp(ate, t)
		var lateral := (ate - de).normalized().cross(Vector3.UP) * (largura / 2.0 + 0.15)
		for lado in [-1, 1]:
			Pecas3D.esfera(pai, 0.12, ponto + lateral * lado + Vector3(0, 0.08, 0), _m("#FFFFFF", 0.4))


## Praça redonda com a fonte de chocolate no meio.
static func praca(pai: Node3D, raio: float) -> void:
	Pecas3D.cilindro(pai, raio, raio, 0.08, Vector3(0, 0.04, 0), _m("#F2D6A2", 0.9))
	Pecas3D.rosquinha(pai, raio - 0.25, raio + 0.1, Vector3(0, 0.08, 0), _m("#E9B97A", 0.8), Vector3(1, 0.4, 1))
	# fonte: bacia, coluna e pratinhos com chocolate escorrendo
	var chocolate := _m("#5A2E17", 0.15)
	var borda := _m("#FFF1F5", 0.3)
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
	_poste(pai, 2.2, 1.2, Vector3.ZERO)


# --- Prédios -----------------------------------------------------------------------

## Prédio com porta virado para o centro da vila. `dados`: {id, nome, posicao,
## parede, telhado, enfeite}. Retorna {"porta": ponto em frente à porta,
## "area": Area3D da porta}.
static func predio(pai: Node3D, dados: Dictionary) -> Dictionary:
	var no := Node3D.new()
	no.name = "Predio_" + dados["id"]
	no.position = dados["posicao"]
	pai.add_child(no)
	no.look_at(Vector3(0, 0, 0) * 1.0 + Vector3(0.001, 0, 0), Vector3.UP, true)  # porta (+z) para a praça
	var largura := 4.6
	var altura := 3.2
	var fundo := 3.8
	var parede := _m(dados["parede"], 0.6)
	Pecas3D.caixa(no, Vector3(largura, altura, fundo), Vector3(0, altura / 2.0, 0), parede)
	# cobertura de glacê no alto das paredes, com pingos na frente
	var glace := _m("#FFFFFF", 0.35)
	Pecas3D.caixa(no, Vector3(largura + 0.2, 0.3, fundo + 0.2), Vector3(0, altura + 0.05, 0), glace)
	for i in 7:
		var x := -largura / 2.0 + 0.35 + i * (largura - 0.7) / 6.0
		Pecas3D.esfera(no, 0.13, Vector3(x, altura - 0.06 - (i % 2) * 0.06, fundo / 2.0 + 0.05), glace, Vector3(1, 1.3, 0.6))
	# telhado: pirâmide colorida
	Pecas3D.cilindro(no, 0.0, largura * 0.78, 2.0, Vector3(0, altura + 1.15, 0),
		_m(dados["telhado"], 0.35), Vector3(1, 1, fundo / largura), Vector3(0, 45, 0))
	# porta de chocolate com maçaneta e janelas de bala
	Pecas3D.caixa(no, Vector3(1.2, 1.9, 0.12), Vector3(0, 0.95, fundo / 2.0 + 0.04), _m("#5A2E17", 0.4))
	Pecas3D.esfera(no, 0.6, Vector3(0, 1.9, fundo / 2.0 + 0.02), _m("#5A2E17", 0.4), Vector3(1, 0.55, 0.2))
	Pecas3D.esfera(no, 0.08, Vector3(0.38, 0.95, fundo / 2.0 + 0.12), _m("#F4E038", 0.2, 0.5))
	for lado in [-1, 1]:
		Pecas3D.caixa(no, Vector3(0.85, 0.8, 0.1), Vector3(lado * 1.6, 1.55, fundo / 2.0 + 0.03), _m("#BFE9FF", 0.1))
		Pecas3D.caixa(no, Vector3(1.0, 0.12, 0.14), Vector3(lado * 1.6, 1.1, fundo / 2.0 + 0.05), glace)
	# placa com o nome, em cima da porta (abaixo do telhado)
	Pecas3D.caixa(no, Vector3(3.0, 0.62, 0.14), Vector3(0, altura - 0.5, fundo / 2.0 + 0.1), _m("#7E57B1", 0.5))
	var placa := Label3D.new()
	placa.text = dados["nome"]
	placa.font = FONTE
	placa.font_size = 110
	placa.pixel_size = 0.0045
	placa.modulate = Color("#F4E038")
	placa.outline_size = 0
	placa.position = Vector3(0, altura - 0.5, fundo / 2.0 + 0.18)
	no.add_child(placa)
	_enfeite_telhado(no, dados.get("enfeite", ""), altura + 2.2)
	_parede(no, Vector3(largura, altura + 2, fundo), Vector3(0, (altura + 2) / 2.0, 0))
	# área na frente da porta: quando o doce entra, aparece o botão "ENTRAR"
	var area := Area3D.new()
	area.name = "Porta"
	area.position = Vector3(0, 1, fundo / 2.0 + 1.6)
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.0, 2, 3.0)
	forma.shape = caixa
	area.add_child(forma)
	no.add_child(area)
	return {"porta": no.to_global(Vector3(0, 0, fundo / 2.0 + 1.6)), "area": area, "no": no}


static func _enfeite_telhado(no: Node3D, enfeite: String, y: float) -> void:
	match enfeite:
		"sino":  # sino dourado da escola
			Pecas3D.esfera(no, 0.45, Vector3(0, y + 0.2, 0), _m("#F2C230", 0.2, 0.5), Vector3(1, 1.1, 1))
			Pecas3D.cilindro(no, 0.5, 0.5, 0.12, Vector3(0, y - 0.15, 0), _m("#F2C230", 0.2, 0.5))
		"cupcake":  # cupcake gigante da confeitaria
			Pecas3D.cilindro(no, 0.75, 0.55, 0.7, Vector3(0, y, 0), _m("#FF8FB8", 0.4))
			Pecas3D.rosquinha(no, 0.2, 0.85, Vector3(0, y + 0.45, 0), _m("#FFF6EE", 0.3), Vector3(1, 0.9, 1))
			Pecas3D.esfera(no, 0.4, Vector3(0, y + 0.8, 0), _m("#FFF6EE", 0.3))
			Pecas3D.esfera(no, 0.22, Vector3(0, y + 1.25, 0), _m("#E8263F", 0.15), Vector3(1, 1.2, 1))
		"trofeu":  # troféu dourado
			var ouro := _m("#F2C230", 0.15, 0.6)
			Pecas3D.cilindro(no, 0.55, 0.3, 0.9, Vector3(0, y + 0.55, 0), ouro)
			Pecas3D.cilindro(no, 0.12, 0.12, 0.5, Vector3(0, y - 0.1, 0), ouro)
			Pecas3D.cilindro(no, 0.45, 0.5, 0.18, Vector3(0, y - 0.35, 0), ouro)
			for lado in [-1, 1]:
				Pecas3D.rosquinha(no, 0.18, 0.28, Vector3(lado * 0.6, y + 0.6, 0), ouro, Vector3.ONE, Vector3(90, 0, 0))
		"fliperama":  # controle de videogame em cima
			Pecas3D.caixa(no, Vector3(1.4, 0.5, 0.8), Vector3(0, y, 0), _m("#3A2A5E", 0.4))
			Pecas3D.cano(no, Vector3(-0.35, y + 0.25, 0), Vector3(-0.35, y + 0.7, 0), 0.06, _m("#DDDDDD", 0.4))
			Pecas3D.esfera(no, 0.16, Vector3(-0.35, y + 0.75, 0), _m("#E8364F", 0.2))
			for i in 3:
				Pecas3D.esfera(no, 0.11, Vector3(0.15 + i * 0.22, y + 0.27, 0.1), _m(["#F4E038", "#5DBB46", "#6FD3FF"][i], 0.2))


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
