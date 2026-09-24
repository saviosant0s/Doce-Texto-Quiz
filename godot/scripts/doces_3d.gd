class_name Doces3D
## Modelos 3D dos doces da coleção, montados por código com Pecas3D (sem
## arquivos de modelo: são originais do projeto e leves para o celular).
##
## Para trocar um doce por um modelo feito em outro programa (Blender, IA de
## 3D...), salve `assets/doces_3d/<id>.glb`: ele é usado no lugar do montado.
##
## Cada doce tem um nó "Corpo" (respira), "Olhos" (piscam) e, se tiver,
## "Aceno" (braço que acena) — animados pelo Doce3D.

const PASTA_GLB := "res://assets/doces_3d/%s.glb"

const SAPATO_ROXO := Color("#6A3DA6")


## Monta o doce `id` dentro de `pai`. Retorna falso se o id não existir.
static func montar(id: String, pai: Node3D) -> bool:
	var corpo := Node3D.new()
	corpo.name = "Corpo"
	pai.add_child(corpo)
	if ResourceLoader.exists(PASTA_GLB % id):
		Pecas3D.carregar_glb(corpo, PASTA_GLB % id)
		return true
	var construtor := Callable(Doces3D, "_" + id)
	if not construtor.is_valid():
		push_error("Doce 3D desconhecido: " + id)
		return false
	construtor.call(corpo)
	return true


static func _m(cor: String, aspereza := 0.3, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


# --- Doces ---------------------------------------------------------------------

## Brigadeiro: bolinha de chocolate com granulado, na forminha de papel.
static func _brigadeiro(c: Node3D) -> void:
	var chocolate := _m("#5A2E17", 0.55)
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.22, 0), chocolate)
	Pecas3D.granulado(c, Vector3(0, 0.22, 0), 0.62, 150, [Color("#2E150A"), Color("#3D1F10")], 7, -0.15, 1.0, 0.72)
	var forminha := Pecas3D.material_textura(Pecas3D.listras([Color("#8A5A2E"), Color("#A8763F")], 24), 0.7)
	Pecas3D.cilindro(c, 0.6, 0.46, 0.36, Vector3(0, -0.3, 0), forminha)
	Pecas3D.rosto(c, Vector3(0, 0.2, 0.6), 0.95, 0.62)
	var membro := _m("#6B3A1F", 0.5)
	Pecas3D.braco(c, Vector3(-0.56, 0.05, 0.05), -1, membro)
	Pecas3D.braco(c, Vector3(0.56, 0.08, 0.05), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.46, 0), 0.18, 0.4, membro, _m("#E8A33D", 0.3))


## Rosquinha (donut) com cobertura rosa e confeitos coloridos.
static func _rosquinha(c: Node3D) -> void:
	var centro := Vector3(0, 0.2, 0)
	Pecas3D.rosquinha(c, 0.3, 0.8, centro, _m("#D99A55", 0.65), Vector3.ONE, Vector3(90, 0, 0))
	Pecas3D.rosquinha(c, 0.33, 0.78, centro + Vector3(0, 0, 0.07), _m("#FF6FA8", 0.18), Vector3(1, 1, 0.75), Vector3(90, 0, 0))
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 3
	var cores := ["#FFFFFF", "#FFE14D", "#6FD3FF", "#7BE07B", "#B07CFF"]
	for i in 46:
		var angulo := sorteio.randf() * TAU
		var raio := sorteio.randf_range(0.4, 0.7)
		if angulo > PI * 0.3 and angulo < PI * 0.7:
			continue  # deixa livre o espaço do rosto (em cima)
		var ponto := centro + Vector3(cos(angulo) * raio, sin(angulo) * raio, 0.25)
		var giro := Vector3(cos(angulo + 1.6), sin(angulo + 1.6), 0) * 0.035
		Pecas3D.cano(c, ponto - giro, ponto + giro, 0.016, _m(cores[i % cores.size()], 0.35))
	Pecas3D.rosto(c, centro + Vector3(0, 0.5, 0.3), 0.72, 0.5)
	var membro := _m("#C9864A", 0.55)
	Pecas3D.braco(c, centro + Vector3(-0.75, -0.05, 0), -1, membro)
	Pecas3D.braco(c, centro + Vector3(0.75, 0.0, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, centro + Vector3(0, -0.72, 0), 0.2, 0.35, membro, _m(SAPATO_ROXO.to_html(), 0.3))


## Pirulito em espiral vermelha, com palito.
static func _pirulito(c: Node3D) -> void:
	var centro := Vector3(0, 0.3, 0)
	Pecas3D.cilindro(c, 0.72, 0.72, 0.2, centro, _m("#FFF3F6", 0.15), Vector3.ONE, Vector3(90, 0, 0))
	var vermelho := _m("#E8364F", 0.15)
	for face in [1, -1]:
		var anterior := centro + Vector3(0, 0, face * 0.09)
		var inicio := centro + Vector3(0.36, 0, face * 0.09)
		anterior = inicio
		for i in range(1, 70):
			var t := i / 69.0
			var angulo := t * 2.0 * TAU
			var raio := 0.36 + 0.28 * t
			var ponto := centro + Vector3(cos(angulo) * raio, sin(angulo) * raio, face * 0.09)
			Pecas3D.cano(c, anterior, ponto, 0.05, vermelho)
			anterior = ponto
	Pecas3D.cano(c, centro + Vector3(0, -0.6, 0), Vector3(0, -1.12, 0), 0.05, _m("#F4EFE6", 0.5))
	Pecas3D.rosto(c, centro + Vector3(0, -0.02, 0.11), 0.8, 3.0)
	var membro := _m("#E8364F", 0.3)
	Pecas3D.braco(c, centro + Vector3(-0.7, -0.1, 0), -1, membro)
	Pecas3D.braco(c, centro + Vector3(0.7, -0.05, 0), 1, membro, 1.0, true)


## Macaron verde de pistache com recheio de creme.
static func _macaron(c: Node3D) -> void:
	var casca := _m("#9FD9A2", 0.55)
	var pe := _m("#86C58A", 0.7)
	for y in [0.3, -0.24]:
		Pecas3D.esfera(c, 0.66, Vector3(0, y, 0), casca, Vector3(1, 0.42, 1))
		var sinal := -1.0 if y > 0 else 1.0
		Pecas3D.rosquinha(c, 0.5, 0.64, Vector3(0, y + sinal * 0.12, 0), pe, Vector3(1, 0.45, 1))
	Pecas3D.cilindro(c, 0.58, 0.58, 0.2, Vector3(0, 0.03, 0), _m("#FFF4DE", 0.4))
	Pecas3D.rosto(c, Vector3(0, 0.3, 0.62), 0.78, 0.66)
	var membro := _m("#7FBF83", 0.5)
	Pecas3D.braco(c, Vector3(-0.6, 0.03, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.6, 0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.45, 0), 0.2, 0.4, membro, _m("#FF7EA8", 0.3))


## Picolé coberto de chocolate, com palito de madeira.
static func _picole(c: Node3D) -> void:
	var cobertura := _m("#4B2412", 0.35)
	var corpo := CapsuleMesh.new()
	corpo.radius = 0.5
	corpo.height = 1.75
	var no := MeshInstance3D.new()
	no.mesh = corpo
	no.material_override = cobertura
	no.position = Vector3(0, 0.22, 0)
	no.scale = Vector3(1.0, 1.0, 0.42)
	c.add_child(no)
	# pingos de chocolate descendo
	for x in [-0.3, 0.05, 0.28]:
		Pecas3D.esfera(c, 0.07, Vector3(x, -0.55 + absf(x) * 0.3, 0.1), cobertura, Vector3(1, 1.4, 1))
	Pecas3D.caixa(c, Vector3(0.18, 0.7, 0.07), Vector3(0, -0.85, 0), _m("#E2BE82", 0.8))
	Pecas3D.rosto(c, Vector3(0, 0.3, 0.21), 0.95, 2.0)
	var membro := _m("#5C2E17", 0.4)
	Pecas3D.braco(c, Vector3(-0.5, 0.0, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.5, 0.05, 0), 1, membro, 1.0, true)


## Bala de menta redonda com listras, embrulhada em papel celofane.
static func _bala(c: Node3D) -> void:
	var listras := Pecas3D.material_textura(Pecas3D.listras([Color("#E8364F"), Color("#FFF6F2")], 16), 0.12)
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.15, 0), listras, Vector3(1, 0.55, 1), Vector3(90, 0, 0))
	Pecas3D.cilindro(c, 0.3, 0.3, 0.06, Vector3(0, 0.15, 0.31), _m("#FFF6F2", 0.12), Vector3.ONE, Vector3(90, 0, 0))
	var celofane := _m("#FFD6E0", 0.1)
	for lado in [-1, 1]:
		Pecas3D.cilindro(c, 0.0, 0.22, 0.42, Vector3(lado * 0.78, 0.15, 0), celofane, Vector3(1, 1, 0.55), Vector3(0, 0, lado * 90))
	Pecas3D.rosto(c, Vector3(0, 0.15, 0.34), 0.68, 3.0)
	var membro := _m("#E8364F", 0.3)
	Pecas3D.braco(c, Vector3(-0.5, -0.2, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.5, -0.15, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.4, 0), 0.2, 0.45, membro, _m("#FFF6F2", 0.3))


## Maçã do amor: maçã com calda vermelha brilhante e palito (título Noob).
static func _maca_do_amor(c: Node3D) -> void:
	var calda := _m("#D1162C", 0.08)
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.12, 0), calda, Vector3(1.05, 0.95, 1.0))
	Pecas3D.cano(c, Vector3(0, 0.6, 0), Vector3(0.05, 1.12, 0), 0.045, _m("#D9B37A", 0.8))
	Pecas3D.esfera(c, 0.13, Vector3(0.2, 0.72, 0), _m("#4CAF50", 0.4), Vector3(1.4, 0.45, 0.8), Vector3(0, 0, 25))
	Pecas3D.rosto(c, Vector3(0, 0.1, 0.62), 0.95, 0.62)
	var membro := _m("#4CAF50", 0.4)
	Pecas3D.braco(c, Vector3(-0.58, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.58, 0.0, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.5, 0), 0.2, 0.4, membro, _m("#3A8E3E", 0.3))


## Cupcake de baunilha com cobertura rosa e confeitos (título Pro).
static func _cupcake(c: Node3D) -> void:
	_montar_cupcake(c, [Color("#F5C542"), Color("#FFDB6E")], _m("#FF7FB0", 0.2), true, false)


## Cupcake de chantili com morango em cima.
static func _cupcake_morango(c: Node3D) -> void:
	_montar_cupcake(c, [Color("#FF8FB8"), Color("#FFF1F5")], _m("#FFF6EE", 0.35), false, true)


static func _montar_cupcake(c: Node3D, cores_forminha: Array, cobertura: Material,
		confeitos: bool, morango: bool) -> void:
	var forminha := Pecas3D.material_textura(Pecas3D.listras(cores_forminha, 28), 0.5)
	Pecas3D.cilindro(c, 0.62, 0.46, 0.62, Vector3(0, -0.32, 0), forminha)
	Pecas3D.rosquinha(c, 0.22, 0.7, Vector3(0, 0.04, 0), cobertura, Vector3(1, 0.85, 1))
	Pecas3D.rosquinha(c, 0.16, 0.55, Vector3(0, 0.26, 0), cobertura, Vector3(1, 0.85, 1))
	Pecas3D.rosquinha(c, 0.1, 0.38, Vector3(0, 0.45, 0), cobertura, Vector3(1, 0.85, 1))
	Pecas3D.esfera(c, 0.2, Vector3(0, 0.55, 0), cobertura)
	if confeitos:
		# confeitos em cima de cada camada da cobertura
		var sorteio := RandomNumberGenerator.new()
		sorteio.seed = 11
		var cores := ["#FFFFFF", "#6FD3FF", "#FFE14D", "#7BE07B"]
		var camadas := [[0.12, 0.66], [0.33, 0.5], [0.51, 0.34]]  # [altura, raio] na parte de fora de cada camada
		for i in 54:
			var camada: Array = camadas[i % camadas.size()]
			var angulo := sorteio.randf_range(-PI * 0.1, PI * 1.1)  # frente e lados
			var ponto := Vector3(cos(angulo) * camada[1], camada[0], sin(angulo) * camada[1])
			var giro := Vector3(sorteio.randf_range(-1, 1), sorteio.randf_range(-0.3, 0.3), sorteio.randf_range(-1, 1)).normalized() * 0.035
			Pecas3D.cano(c, ponto - giro, ponto + giro, 0.015, _m(cores[i % cores.size()], 0.35))
	if morango:
		Pecas3D.esfera(c, 0.2, Vector3(0, 0.82, 0), _m("#E8263F", 0.15), Vector3(1, 1.2, 1))
		for i in 5:
			var angulo := i * TAU / 5.0
			Pecas3D.esfera(c, 0.09, Vector3(cos(angulo) * 0.1, 1.02, sin(angulo) * 0.1), _m("#3FA34D", 0.4),
				Vector3(1.3, 0.35, 0.6), Vector3(0, -rad_to_deg(angulo), 20))
	else:
		Pecas3D.esfera(c, 0.1, Vector3(0, 0.76, 0), cobertura)
	Pecas3D.rosto(c, Vector3(0, -0.3, 0.55), 0.8, 0.55)
	var membro := _m(cores_forminha[0].to_html(), 0.4)
	Pecas3D.braco(c, Vector3(-0.56, -0.25, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.56, -0.2, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.6, 0), 0.18, 0.38, membro, _m("#6A3DA6", 0.3))


## Barra de chocolate meio embrulhada em papel dourado (título Mestre).
static func _chocolate(c: Node3D) -> void:
	var chocolate := _m("#6B3A1F", 0.4)
	Pecas3D.caixa(c, Vector3(1.1, 1.6, 0.24), Vector3(0, 0.15, 0), chocolate)
	# gomos em cima do rosto
	for x in [-0.27, 0.27]:
		Pecas3D.caixa(c, Vector3(0.46, 0.3, 0.08), Vector3(x, 0.78, 0.13), _m("#7A4526", 0.4))
	Pecas3D.caixa(c, Vector3(1.16, 0.72, 0.3), Vector3(0, -0.36, 0), _m("#F2C230", 0.22, 0.25))
	Pecas3D.caixa(c, Vector3(1.17, 0.22, 0.31), Vector3(0, -0.36, 0), _m("#C0182E", 0.3))
	Pecas3D.rosto(c, Vector3(0, 0.3, 0.12), 0.95, 3.0)
	Pecas3D.braco(c, Vector3(-0.55, 0.0, 0), -1, chocolate)
	Pecas3D.braco(c, Vector3(0.55, 0.05, 0), 1, chocolate, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.7, 0), 0.25, 0.4, chocolate, _m("#C0182E", 0.3))


## Bombom de chocolate brilhante com avelã, na forminha dourada.
static func _bombom(c: Node3D) -> void:
	var chocolate := _m("#4E2511", 0.18)
	Pecas3D.esfera(c, 0.6, Vector3(0, 0.18, 0), chocolate)
	for i in 3:
		Pecas3D.rosquinha(c, 0.02, 0.07 + i * 0.07, Vector3(0, 0.76 - i * 0.015, 0), chocolate, Vector3(1, 0.5, 1))
	Pecas3D.esfera(c, 0.1, Vector3(0, 0.84, 0), _m("#C68B4E", 0.5), Vector3(1, 1.2, 1))
	var forminha := Pecas3D.material_textura(Pecas3D.listras([Color("#F2C230"), Color("#FFE07A")], 24), 0.2)
	forminha.metallic = 0.2
	Pecas3D.cilindro(c, 0.6, 0.44, 0.34, Vector3(0, -0.3, 0), forminha)
	Pecas3D.rosto(c, Vector3(0, 0.17, 0.58), 0.95, 0.6)
	var membro := _m("#5E2E17", 0.3)
	Pecas3D.braco(c, Vector3(-0.56, 0.02, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.56, 0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.46, 0), 0.18, 0.4, membro, _m("#F2C230", 0.25, 0.2))


## Pudim de leite com calda de caramelo escorrendo, no pratinho.
static func _pudim(c: Node3D) -> void:
	Pecas3D.cilindro(c, 0.5, 0.72, 0.82, Vector3(0, -0.08, 0), _m("#F4C95D", 0.3))
	var calda := _m("#8A3F12", 0.08)
	Pecas3D.cilindro(c, 0.51, 0.53, 0.08, Vector3(0, 0.34, 0), calda)
	for i in 9:
		var angulo := -PI * 0.1 - i * PI * 0.1  # só na frente e nos lados
		var ponto := Vector3(cos(angulo) * 0.52, 0.32, -sin(angulo) * 0.52)
		var comprimento: float = [0.18, 0.32, 0.12, 0.26, 0.2, 0.3, 0.14, 0.24, 0.16][i]
		if absf(ponto.x) < 0.2:
			continue  # sem calda na frente do rosto
		var fora: Vector3 = Vector3(ponto.x, 0, ponto.z).normalized() * 0.04 * comprimento
		Pecas3D.cano(c, ponto, ponto + Vector3(0, -comprimento, 0) + fora, 0.045, calda)
	Pecas3D.cilindro(c, 0.95, 0.9, 0.07, Vector3(0, -0.52, 0), _m("#FFFFFF", 0.2))
	Pecas3D.rosto(c, Vector3(0, -0.08, 0.62), 0.85, 0.62)
	var membro := _m("#E0B040", 0.35)
	Pecas3D.braco(c, Vector3(-0.6, -0.1, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.6, -0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.56, 0), 0.25, 0.36, membro, _m("#8A3F12", 0.2))


## Algodão-doce rosa fofinho no palito.
static func _algodao_doce(c: Node3D) -> void:
	var algodao := _m("#FFB0D5", 0.95)
	var centro := Vector3(0, 0.35, 0)
	Pecas3D.esfera(c, 0.52, centro, algodao)
	var bolinhas := [[-0.45, 0.2, 0.34], [0.45, 0.22, 0.34], [-0.3, 0.52, 0.32], [0.3, 0.55, 0.3],
		[0.0, 0.72, 0.32], [-0.52, -0.12, 0.3], [0.52, -0.1, 0.3], [0.0, -0.3, 0.34], [-0.28, -0.35, 0.28], [0.3, -0.33, 0.28]]
	for b in bolinhas:
		Pecas3D.esfera(c, b[2], centro + Vector3(b[0], b[1] - 0.35, -0.1), algodao)
	Pecas3D.cano(c, Vector3(0, -0.2, 0), Vector3(0, -1.12, 0), 0.05, _m("#F4EFE6", 0.5))
	Pecas3D.rosto(c, centro + Vector3(0, -0.05, 0.5), 0.9, 0.52)
	Pecas3D.braco(c, centro + Vector3(-0.72, -0.2, 0), -1, algodao)
	Pecas3D.braco(c, centro + Vector3(0.72, -0.15, 0), 1, algodao, 1.0, true)
