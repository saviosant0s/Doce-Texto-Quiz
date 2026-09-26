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
## Personagens do jogo feitos em 3D que não estão à venda na coleção.
const PERSONAGENS := ["brigadeiro_triste", "bala_verde", "milho_doce", "fantasma"]


## Monta o doce `id` dentro de `pai`. Retorna falso se o id não existir.
static func montar(id: String, pai: Node3D) -> bool:
	var corpo := Node3D.new()
	corpo.name = "Corpo"
	pai.add_child(corpo)
	if Itens3D.existe(id):  # moeda, açúcar, XP e baús, no mesmo estilo
		Itens3D.montar(id, corpo)
		return true
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

## Brigadeiro: bolinha de chocolate com granulado e fio de chocolate branco,
## na forminha de papel (como o brigadeiro dos personagens do jogo).
static func _brigadeiro(c: Node3D) -> void:
	var chocolate := _m("#5A2E17", 0.55)
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.22, 0), chocolate)
	Pecas3D.granulado(c, Vector3(0, 0.22, 0), 0.62, 150, [Color("#2E150A"), Color("#3D1F10")], 7, -0.15, 1.0, 0.72)
	# fio de chocolate branco em zigue-zague no topo
	var branco := _m("#F3E3B5", 0.3)
	var anterior := Vector3(-0.42, 0.62, 0.12)
	for i in range(1, 7):
		var ponto := Vector3(-0.42 + i * 0.14, 0.62 + (0.14 if i % 2 == 1 else 0.0), 0.12 + (0.05 if i % 2 == 1 else 0.0))
		Pecas3D.cano(c, anterior, ponto, 0.035, branco)
		anterior = ponto
	var forminha := Pecas3D.material_textura(Pecas3D.listras([Color("#F1E4CC"), Color("#FFF6E6")], 24), 0.6)
	Pecas3D.cilindro(c, 0.6, 0.46, 0.36, Vector3(0, -0.3, 0), forminha)
	Pecas3D.rosto(c, Vector3(0, 0.2, 0.6), 0.95, 0.62)
	var membro := _m("#3B1E10", 0.5)
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


## Maçã (título Noob): vermelha, com cabinho e folha, luvas brancas e tênis
## verde, como a maçã dos personagens do jogo.
static func _maca(c: Node3D) -> void:
	var casca := _m("#D8261E", 0.3)
	Pecas3D.esfera(c, 0.64, Vector3(0, 0.1, 0), casca, Vector3(1.06, 0.94, 1.0))
	# covinha do cabinho
	Pecas3D.esfera(c, 0.16, Vector3(0, 0.66, 0), _m("#A81A14", 0.4), Vector3(1.2, 0.35, 1.2))
	Pecas3D.cano(c, Vector3(0, 0.62, 0), Vector3(0.06, 0.98, 0), 0.04, _m("#6B3D1E", 0.7))
	Pecas3D.esfera(c, 0.2, Vector3(0.3, 0.9, 0.02), _m("#3F9A35", 0.35), Vector3(1.5, 0.4, 0.8), Vector3(0, 0, 28))
	Pecas3D.rosto(c, Vector3(0, 0.05, 0.62), 1.0, 0.64, Color("#4CAF50"))
	var braco := _m("#C0201A", 0.35)
	Pecas3D.braco(c, Vector3(-0.6, -0.05, 0), -1, braco)
	Pecas3D.braco(c, Vector3(0.6, 0.0, 0), 1, braco, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.46, 0), 0.2, 0.42, _m("#3B1A12", 0.5), _m("#5DAA3A", 0.35))


## Cupcake (título Pro): forminha amarela, cobertura rosa com confeitos,
## braços e pernas escuros, luvas brancas e sapatos rosa.
static func _cupcake(c: Node3D) -> void:
	_montar_cupcake(c, [Color("#F5CF3F"), Color("#FBE58A")], _m("#FF6FAE", 0.2), true, false,
		_m("#3B2418", 0.5), _m("#E0408A", 0.25), Color("#FF5FA0"))


## Cupcake de chantili com morango em cima.
static func _cupcake_morango(c: Node3D) -> void:
	_montar_cupcake(c, [Color("#FF8FB8"), Color("#FFF1F5")], _m("#FFF6EE", 0.35), false, true,
		_m("#FF8FB8", 0.4), _m("#6A3DA6", 0.3))


static func _montar_cupcake(c: Node3D, cores_forminha: Array, cobertura: Material,
		confeitos: bool, morango: bool, membro: Material, sapato: Material, nariz := Color.TRANSPARENT) -> void:
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
	Pecas3D.rosto(c, Vector3(0, -0.3, 0.55), 0.8, 0.55, nariz)
	Pecas3D.braco(c, Vector3(-0.56, -0.25, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.56, -0.2, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.6, 0), 0.18, 0.38, membro, sapato)


## Barra de chocolate em gomos (título Mestre), com papel laminado, luvas
## brancas e sapatos vermelhos, como o chocolate dos personagens do jogo.
static func _chocolate(c: Node3D) -> void:
	var chocolate := _m("#6B3A1F", 0.35)
	var gomo := _m("#7A4526", 0.35)
	Pecas3D.caixa(c, Vector3(1.1, 1.62, 0.22), Vector3(0, 0.12, 0), chocolate)
	# gomos: 2 colunas x 4 linhas, em relevo
	for linha in 4:
		for coluna in 2:
			Pecas3D.caixa(c, Vector3(0.46, 0.34, 0.06), Vector3(-0.26 + coluna * 0.52, 0.72 - linha * 0.4, 0.13), gomo)
	# papel laminado prateado cobrindo a parte de baixo
	Pecas3D.caixa(c, Vector3(1.16, 0.5, 0.3), Vector3(0, -0.46, 0), _m("#C9CED6", 0.2, 0.8))
	Pecas3D.rosto(c, Vector3(0, 0.45, 0.17), 1.0, 3.0, Color("#E0262E"))
	var membro := _m("#3A1E10", 0.5)
	Pecas3D.braco(c, Vector3(-0.55, 0.0, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.55, 0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.7, 0), 0.25, 0.42, membro, _m("#D8262E", 0.25))


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


# --- Doces novos (catálogo ampliado) --------------------------------------------------

## Beijinho: bolinha de coco branca com cravo em cima, na forminha.
static func _beijinho(c: Node3D) -> void:
	var coco := _m("#FBF6EC", 0.75)
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.22, 0), coco)
	Pecas3D.granulado(c, Vector3(0, 0.22, 0), 0.62, 170, [Color("#FFFFFF"), Color("#EFE6D2")], 21, -0.15, 1.1, 0.72)
	Pecas3D.cano(c, Vector3(0, 0.8, 0), Vector3(0.02, 0.98, 0), 0.03, _m("#4A2A14", 0.6))
	Pecas3D.esfera(c, 0.07, Vector3(0.02, 1.0, 0), _m("#3A1E0E", 0.6), Vector3(1.2, 0.8, 1.2))
	var forminha := Pecas3D.material_textura(Pecas3D.listras([Color("#FFB3CF"), Color("#FFE3EE")], 24), 0.6)
	Pecas3D.cilindro(c, 0.6, 0.46, 0.36, Vector3(0, -0.3, 0), forminha)
	Pecas3D.rosto(c, Vector3(0, 0.2, 0.6), 0.95, 0.62)
	var membro := _m("#E9DFC8", 0.6)
	Pecas3D.braco(c, Vector3(-0.56, 0.05, 0.05), -1, membro)
	Pecas3D.braco(c, Vector3(0.56, 0.08, 0.05), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.46, 0), 0.18, 0.4, membro, _m("#FF8FB8", 0.3))


## Paçoca: disco de amendoim esfarelando, com a embalagem de papel embaixo.
static func _pacoca(c: Node3D) -> void:
	var amendoim := _m("#D6A866", 0.95)
	Pecas3D.cilindro(c, 0.66, 0.68, 0.9, Vector3(0, 0.12, 0), amendoim)
	Pecas3D.granulado(c, Vector3(0, 0.12, 0), 0.68, 120, [Color("#C08A48"), Color("#E6C084")], 5, -0.6, 1.4, 0.6)
	Pecas3D.cilindro(c, 0.7, 0.7, 0.3, Vector3(0, -0.42, 0), _m("#E5383B", 0.5))
	Pecas3D.cilindro(c, 0.71, 0.71, 0.06, Vector3(0, -0.34, 0), _m("#FFFFFF", 0.5))
	Pecas3D.rosto(c, Vector3(0, 0.14, 0.68), 0.9, 0.68)
	var membro := _m("#B07C3E", 0.7)
	Pecas3D.braco(c, Vector3(-0.66, 0.0, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.66, 0.04, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.56, 0), 0.22, 0.36, membro, _m("#E5383B", 0.3))


## Quindim: cúpula amarela brilhante com a base de coco queimadinho.
static func _quindim(c: Node3D) -> void:
	Pecas3D.cilindro(c, 0.5, 0.66, 0.3, Vector3(0, -0.36, 0), _m("#C98A2E", 0.85))
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.02, 0), _m("#FFC21A", 0.05), Vector3(1, 0.95, 1))
	Pecas3D.esfera(c, 0.16, Vector3(-0.2, 0.46, 0.3), _m("#FFE79A", 0.05), Vector3(1.3, 0.6, 0.6))
	Pecas3D.rosto(c, Vector3(0, 0.02, 0.6), 0.9, 0.62)
	var membro := _m("#E5A50E", 0.3)
	Pecas3D.braco(c, Vector3(-0.6, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.6, 0.0, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.5, 0), 0.2, 0.4, membro, _m("#C98A2E", 0.4))


## Cocada: montinho de coco com pedaços queimados.
static func _cocada(c: Node3D) -> void:
	var coco := _m("#F3E4C4", 0.9)
	Pecas3D.esfera(c, 0.66, Vector3(0, 0.02, 0), coco, Vector3(1.1, 0.8, 1.0))
	for b in [[-0.4, 0.3, 0.28], [0.38, 0.32, 0.26], [0.0, 0.5, 0.3], [-0.5, -0.1, 0.24], [0.5, -0.08, 0.24]]:
		Pecas3D.esfera(c, b[2], Vector3(b[0], b[1], -0.12), coco)
	Pecas3D.granulado(c, Vector3(0, 0.05, 0), 0.66, 110, [Color("#B9824A"), Color("#FFFFFF"), Color("#D9B98A")], 9, -0.4, 1.6, 0.65)
	Pecas3D.rosto(c, Vector3(0, 0.02, 0.62), 0.9, 0.7)
	var membro := _m("#D8C39A", 0.8)
	Pecas3D.braco(c, Vector3(-0.66, -0.1, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.66, -0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.46, 0), 0.22, 0.42, membro, _m("#8C5A2B", 0.4))


## Sorvete de casquinha com duas bolas (morango e creme) e cereja.
static func _sorvete(c: Node3D) -> void:
	var casquinha := Pecas3D.material_textura(Pecas3D.listras([Color("#D99A4E"), Color("#E8B570")], 18), 0.7)
	Pecas3D.cilindro(c, 0.5, 0.04, 1.1, Vector3(0, -0.55, 0), casquinha)
	Pecas3D.esfera(c, 0.5, Vector3(0, 0.12, 0), _m("#FFF3D6", 0.6))
	Pecas3D.rosquinha(c, 0.35, 0.53, Vector3(0, -0.05, 0), _m("#FFF3D6", 0.6), Vector3(1, 0.6, 1))
	Pecas3D.esfera(c, 0.42, Vector3(0, 0.66, 0), _m("#FF8FB8", 0.6))
	Pecas3D.esfera(c, 0.13, Vector3(0.05, 1.12, 0), _m("#D4142F", 0.1))
	Pecas3D.cano(c, Vector3(0.05, 1.2, 0), Vector3(0.14, 1.34, 0), 0.02, _m("#3F7F2A", 0.5))
	Pecas3D.rosto(c, Vector3(0, 0.12, 0.49), 0.8, 0.5)
	var membro := _m("#D99A4E", 0.6)
	Pecas3D.braco(c, Vector3(-0.42, -0.3, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.42, -0.25, 0), 1, membro, 1.0, true)


## Churros: bastão estriado, passado no açúcar com canela, recheado de doce de leite.
static func _churros(c: Node3D) -> void:
	var massa := _m("#C98038", 0.7)
	var no := Node3D.new()
	no.name = "Bastao"
	no.rotation_degrees = Vector3(0, 0, 8)
	c.add_child(no)
	for i in 8:
		var angulo := TAU * i / 8.0
		Pecas3D.cilindro(no, 0.16, 0.16, 1.6, Vector3(cos(angulo) * 0.2, 0.0, sin(angulo) * 0.2), massa)
	Pecas3D.cilindro(no, 0.3, 0.3, 1.6, Vector3.ZERO, massa)
	Pecas3D.granulado(no, Vector3(0, 0.3, 0), 0.4, 80, [Color("#F5E6C8"), Color("#9A5A24")], 13, -0.9, 0.9, 0.6)
	Pecas3D.esfera(no, 0.2, Vector3(0, 0.82, 0), _m("#7A3E14", 0.15), Vector3(1.1, 0.5, 1.1))
	Pecas3D.rosto(no, Vector3(0, 0.25, 0.38), 0.72, 0.42)
	var membro := _m("#A8642A", 0.6)
	Pecas3D.braco(c, Vector3(-0.38, 0.0, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.4, 0.1, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(-0.08, -0.8, 0), 0.16, 0.32, membro, _m("#7A3E14", 0.3))


## Pão de mel: bolinho coberto de chocolate, com fio de chocolate branco.
static func _pao_de_mel(c: Node3D) -> void:
	var chocolate := _m("#4A2412", 0.3)
	Pecas3D.cilindro(c, 0.62, 0.66, 0.95, Vector3(0, 0.0, 0), chocolate)
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.46, 0), chocolate, Vector3(1, 0.25, 1))
	var branco := _m("#F3E3B5", 0.3)
	for i in 5:
		var x := -0.45 + i * 0.225
		Pecas3D.cano(c, Vector3(x, 0.57, 0.1), Vector3(x + 0.12, 0.57, -0.1), 0.03, branco)
	Pecas3D.rosto(c, Vector3(0, 0.04, 0.66), 0.9, 0.66)
	var membro := _m("#3A1C0E", 0.5)
	Pecas3D.braco(c, Vector3(-0.64, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.64, 0.0, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.5, 0), 0.22, 0.4, membro, _m("#F2C230", 0.3))


## Jujuba: gota de goma verde, meio transparente, coberta de açúcar.
static func _jujuba(c: Node3D) -> void:
	var goma := _m("#3FD16A", 0.15)
	goma.albedo_color.a = 0.88
	goma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.0, 0), goma, Vector3(1, 1.05, 0.9))
	Pecas3D.esfera(c, 0.4, Vector3(0, 0.5, 0), goma, Vector3(1, 0.9, 0.9))
	Pecas3D.granulado(c, Vector3(0, 0.1, 0), 0.62, 90, [Color("#FFFFFF"), Color("#E8FFE8")], 17, -0.8, 0.6, 0.6)
	Pecas3D.rosto(c, Vector3(0, 0.05, 0.56), 0.85, 0.6)
	var membro := _m("#2FB055", 0.3)
	Pecas3D.braco(c, Vector3(-0.58, -0.1, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.58, -0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.55, 0), 0.2, 0.38, membro, _m("#FFFFFF", 0.3))


## Marshmallow: travesseirinho rosa e branco, bem fofo.
static func _marshmallow(c: Node3D) -> void:
	var corpo := Pecas3D.material_textura(Pecas3D.faixas([Color("#FFD1E3"), Color("#FFFFFF")], 4), 0.9)
	Pecas3D.cilindro(c, 0.62, 0.62, 1.1, Vector3(0, 0.05, 0), corpo)
	Pecas3D.rosquinha(c, 0.45, 0.62, Vector3(0, 0.6, 0), _m("#FFD1E3", 0.9), Vector3(1, 0.5, 1))
	Pecas3D.esfera(c, 0.5, Vector3(0, 0.6, 0), _m("#FFD1E3", 0.9), Vector3(1, 0.25, 1))
	Pecas3D.rosto(c, Vector3(0, 0.1, 0.62), 0.9, 0.62)
	var membro := _m("#FFB6D1", 0.8)
	Pecas3D.braco(c, Vector3(-0.62, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.62, 0.0, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.5, 0), 0.22, 0.4, membro, _m("#B07CFF", 0.3))


## Pé de moleque: placa de amendoim caramelizado.
static func _pe_de_moleque(c: Node3D) -> void:
	var caramelo := _m("#9C5A1E", 0.25)
	Pecas3D.caixa(c, Vector3(1.2, 1.3, 0.36), Vector3(0, 0.1, 0), caramelo)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 4
	var amendoim := _m("#E4B77A", 0.7)
	for i in 26:
		var p := Vector3(sorteio.randf_range(-0.5, 0.5), sorteio.randf_range(-0.45, 0.68), 0.18)
		if absf(p.x) < 0.38 and p.y > -0.1 and p.y < 0.45:
			continue  # rosto livre
		Pecas3D.esfera(c, 0.08, p, amendoim, Vector3(1.3, 0.9, 0.6), Vector3(0, 0, sorteio.randf_range(0, 180)))
	Pecas3D.rosto(c, Vector3(0, 0.2, 0.19), 0.95, 3.0)
	var membro := _m("#7A4212", 0.4)
	Pecas3D.braco(c, Vector3(-0.6, 0.0, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.6, 0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.56, 0), 0.24, 0.42, membro, _m("#E4B77A", 0.4))


## Brownie: quadrado de chocolate com casquinha rachada e nozes.
static func _brownie(c: Node3D) -> void:
	Pecas3D.caixa(c, Vector3(1.25, 1.0, 1.1), Vector3(0, -0.05, 0), _m("#3E1E0E", 0.75))
	Pecas3D.caixa(c, Vector3(1.28, 0.08, 1.13), Vector3(0, 0.48, 0), _m("#5A2E16", 0.35))
	var noz := _m("#C9975A", 0.7)
	for p in [Vector3(-0.3, 0.56, 0.1), Vector3(0.28, 0.56, -0.2), Vector3(0.05, 0.56, 0.3), Vector3(-0.25, 0.56, -0.3)]:
		Pecas3D.esfera(c, 0.1, p, noz, Vector3(1.4, 0.6, 1))
	Pecas3D.esfera(c, 0.35, Vector3(0.1, 0.62, 0), _m("#FFF6E6", 0.8), Vector3(1, 0.4, 1))
	Pecas3D.rosto(c, Vector3(0, 0.0, 0.56), 0.95, 3.0)
	var membro := _m("#2E160A", 0.5)
	Pecas3D.braco(c, Vector3(-0.63, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.63, 0.0, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.55, 0), 0.26, 0.42, membro, _m("#E5383B", 0.3))


## Bolo de aniversário: dois andares com cobertura, confeitos e velinha acesa.
static func _bolo(c: Node3D) -> void:
	var massa := Pecas3D.material_textura(Pecas3D.faixas([Color("#FFF1F6"), Color("#FF8FB8"), Color("#FFF1F6"),
		Color("#FFE2A8")], 4), 0.5)
	Pecas3D.cilindro(c, 0.72, 0.72, 0.7, Vector3(0, -0.3, 0), massa)
	Pecas3D.cilindro(c, 0.5, 0.5, 0.5, Vector3(0, 0.3, 0), _m("#FFF1F6", 0.5))
	var cobertura := _m("#FF6FA8", 0.2)
	Pecas3D.rosquinha(c, 0.62, 0.78, Vector3(0, 0.05, 0), cobertura, Vector3(1, 0.5, 1))
	Pecas3D.cilindro(c, 0.52, 0.52, 0.08, Vector3(0, 0.56, 0), cobertura)
	Pecas3D.granulado(c, Vector3(0, 0.3, 0), 0.52, 60, [Color("#FFE14D"), Color("#6FD3FF"), Color("#7BE07B"), Color("#B07CFF")], 23, 0.35, 1.0, 0.9)
	var vela := Pecas3D.material_textura(Pecas3D.faixas([Color("#6FD3FF"), Color("#FFFFFF")], 6), 0.4)
	Pecas3D.cilindro(c, 0.05, 0.05, 0.4, Vector3(0, 0.8, 0), vela)
	Pecas3D.esfera(c, 0.07, Vector3(0, 1.08, 0), Doces3D._brilhante(Color("#FFB020"), 2.0), Vector3(1, 1.6, 1))
	Pecas3D.rosto(c, Vector3(0, -0.28, 0.72), 0.95, 0.72)
	var membro := _m("#FF8FB8", 0.4)
	Pecas3D.braco(c, Vector3(-0.72, -0.3, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.72, -0.25, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.66, 0), 0.26, 0.36, membro, _m("#6A3DA6", 0.3))


# --- Doces dos eventos da temporada (ver Eventos; só se ganha no evento) ----------

## Flor de açúcar (Festival das Flores): biscoito em forma de flor com
## pétalas de glacê rosa e miolo amarelo.
static func _flor_de_acucar(c: Node3D) -> void:
	var petala := _m("#FF8FB8", 0.4)
	for i in 6:
		var a := i * TAU / 6.0
		Pecas3D.esfera(c, 0.36, Vector3(cos(a) * 0.5, 0.05 + sin(a) * 0.5, -0.05), petala, Vector3(1, 1, 0.45))
	Pecas3D.cilindro(c, 0.5, 0.5, 0.3, Vector3(0, 0.05, 0), _m("#FFD23F", 0.5), Vector3.ONE, Vector3(90, 0, 0))
	Pecas3D.granulado(c, Vector3(0, 0.05, 0.1), 0.45, 30, [Color("#FFFFFF"), Color("#FFB3D1")], 5, -1.0, 1.0, 0.95)
	Pecas3D.rosto(c, Vector3(0, 0.05, 0.16), 0.8, 2.0)
	var membro := _m("#3FA34D", 0.5)
	Pecas3D.braco(c, Vector3(-0.55, -0.35, 0), -1, membro, 0.8)
	Pecas3D.braco(c, Vector3(0.55, -0.35, 0), 1, membro, 0.8, true)
	Pecas3D.pernas(c, Vector3(0, -0.5, 0), 0.2, 0.45, membro, _m("#FF6FAE", 0.3))


## Abóbora de chocolate (Noite das Abóboras): abóbora laranja de chocolate
## com gomos, cabinho verde e um chapéu de bruxinha.
static func _abobora_choco(c: Node3D) -> void:
	var laranja := _m("#FF8A1F", 0.35)
	var gomo := _m("#F07A12", 0.35)
	for i in 8:
		var a := i * TAU / 8.0
		Pecas3D.esfera(c, 0.4, Vector3(cos(a) * 0.36, 0.0, sin(a) * 0.36), gomo if i % 2 == 0 else laranja, Vector3(0.75, 1.0, 0.75))
	Pecas3D.esfera(c, 0.55, Vector3(0, 0, 0), laranja, Vector3(1.0, 0.95, 1.0))
	Pecas3D.cilindro(c, 0.06, 0.09, 0.3, Vector3(0, 0.68, 0), _m("#3FA34D", 0.6))
	Pecas3D.cilindro(c, 0.55, 0.55, 0.05, Vector3(0.05, 0.62, 0), _m("#3B2A5C", 0.6), Vector3.ONE, Vector3(0, 0, 8))
	Pecas3D.cilindro(c, 0.0, 0.3, 0.6, Vector3(0.08, 0.95, 0), _m("#3B2A5C", 0.6), Vector3.ONE, Vector3(0, 0, 12))
	Pecas3D.rosto(c, Vector3(0, 0.0, 0.68), 0.9, 0.7)
	var membro := _m("#5A2E17", 0.5)
	Pecas3D.braco(c, Vector3(-0.66, -0.1, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.66, -0.1, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.52, 0), 0.24, 0.4, membro, _m("#3B2A5C", 0.3))


## Biscoito de gengibre (Natal Doce): bonequinho de biscoito com glacê
## branco em zigue-zague, botões de bala e gorro de Papai Noel.
static func _biscoito_gengibre(c: Node3D) -> void:
	var biscoito := _m("#B5723A", 0.85)
	Pecas3D.esfera(c, 0.42, Vector3(0, 0.45, 0), biscoito, Vector3(1, 1, 0.55))
	Pecas3D.esfera(c, 0.5, Vector3(0, -0.2, 0), biscoito, Vector3(0.95, 1.1, 0.5))
	var glace := _m("#FFFFFF", 0.3)
	for i in 3:
		Pecas3D.esfera(c, 0.07, Vector3(0, -0.05 - i * 0.2, 0.26), _m(["#E8364F", "#3FA34D", "#FFD23F"][i], 0.2))
	var anterior := Vector3(-0.35, -0.62, 0.22)
	for i in range(1, 8):
		var ponto := Vector3(-0.35 + i * 0.1, -0.62 + (0.07 if i % 2 == 1 else 0.0), 0.22)
		Pecas3D.cano(c, anterior, ponto, 0.025, glace)
		anterior = ponto
	Pecas3D.cilindro(c, 0.0, 0.36, 0.45, Vector3(0.05, 0.95, 0), _m("#E8364F", 0.5), Vector3.ONE, Vector3(0, 0, -15))
	Pecas3D.rosquinha(c, 0.28, 0.4, Vector3(0, 0.76, 0), glace, Vector3(1, 0.6, 1))
	Pecas3D.esfera(c, 0.1, Vector3(0.18, 1.18, 0), glace)
	Pecas3D.rosto(c, Vector3(0, 0.45, 0.22), 0.75, 1.2)
	Pecas3D.braco(c, Vector3(-0.45, -0.05, 0), -1, biscoito)
	Pecas3D.braco(c, Vector3(0.45, -0.05, 0), 1, biscoito, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.72, 0), 0.22, 0.3, biscoito, _m("#E8364F", 0.3))


## Confete (Carnaval de Confeitos): pastilha de chocolate coberta de açúcar
## colorido, com uma máscara de carnaval.
static func _confete(c: Node3D) -> void:
	Pecas3D.esfera(c, 0.7, Vector3(0, 0.05, 0), _m("#B07CFF", 0.2), Vector3(1, 1, 0.55))
	Pecas3D.granulado(c, Vector3(0, 0.05, 0), 0.7, 40, [Color("#FFD23F"), Color("#6FD3FF"), Color("#FF6FAE"), Color("#7BE07B")], 9, -1.0, 1.0, 0.55)
	# chapéu de festa listrado com pompom e uma serpentina
	var chapeu := Pecas3D.material_textura(Pecas3D.faixas([Color("#FFD23F"), Color("#FF6FAE")], 6), 0.4)
	Pecas3D.cilindro(c, 0.0, 0.26, 0.55, Vector3(0.12, 0.95, 0), chapeu, Vector3.ONE, Vector3(0, 0, -12))
	Pecas3D.esfera(c, 0.09, Vector3(0.18, 1.23, 0), _m("#6FD3FF", 0.4))
	Pecas3D.cano(c, Vector3(-0.5, 0.55, 0.1), Vector3(-0.75, 0.95, 0.05), 0.03, _m("#7BE07B", 0.4))
	Pecas3D.rosto(c, Vector3(0, 0.1, 0.4), 0.8, 1.2)
	var membro := _m("#6A3DA6", 0.4)
	Pecas3D.braco(c, Vector3(-0.66, -0.1, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.66, -0.1, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.36, 0), 0.26, 0.55, membro, _m("#FFD23F", 0.3))


## Ovo de Páscoa (Caça aos Ovos): ovo de chocolate embrulhado pela metade
## em papel brilhante azul com laço.
static func _ovo_pascoa(c: Node3D) -> void:
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.1, 0), _m("#6B3A1F", 0.25), Vector3(0.95, 1.25, 0.95))
	var papel := _m("#6FD3FF", 0.15, 0.5)
	Pecas3D.cilindro(c, 0.62, 0.45, 0.55, Vector3(0, -0.45, 0), papel)
	Pecas3D.rosquinha(c, 0.52, 0.66, Vector3(0, -0.18, 0), _m("#FF6FAE", 0.3), Vector3(1, 0.4, 1))
	for lado in [-1, 1]:
		Pecas3D.esfera(c, 0.16, Vector3(lado * 0.18, -0.18, 0.62), _m("#FF6FAE", 0.3), Vector3(1.2, 0.7, 0.5))
	Pecas3D.rosto(c, Vector3(0, 0.25, 0.6), 0.85, 0.7)
	var membro := _m("#4A2412", 0.5)
	Pecas3D.braco(c, Vector3(-0.58, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.58, -0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.72, 0), 0.24, 0.3, membro, _m("#6FD3FF", 0.3))


## Pipoca doce (Arraiá Doce): baldinho listrado cheio de pipoca rosa com
## chapéu de palha.
static func _pipoca_doce(c: Node3D) -> void:
	var balde := Pecas3D.material_textura(Pecas3D.listras([Color("#E8364F"), Color("#FFFFFF")], 10), 0.5)
	Pecas3D.cilindro(c, 0.62, 0.48, 0.85, Vector3(0, -0.25, 0), balde)
	var pipoca := _m("#FFC2DA", 0.85)
	for i in 14:
		var a := i * 2.4
		var r := 0.2 + (i % 3) * 0.14
		Pecas3D.esfera(c, 0.2, Vector3(cos(a) * r, 0.25 + (i % 4) * 0.06, sin(a) * r), pipoca)
	Pecas3D.cilindro(c, 0.55, 0.55, 0.04, Vector3(0, 0.62, 0), _m("#E3C07A", 0.9))
	Pecas3D.cilindro(c, 0.28, 0.32, 0.25, Vector3(0, 0.75, 0), _m("#E3C07A", 0.9))
	Pecas3D.rosto(c, Vector3(0, -0.2, 0.58), 0.85, 0.65)
	var membro := _m("#E8364F", 0.4)
	Pecas3D.braco(c, Vector3(-0.6, -0.2, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.6, -0.2, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.66, 0), 0.24, 0.36, membro, _m("#6B3A1F", 0.3))


# --- Personagens do jogo (não estão à venda na coleção) ------------------------------

## Brigadeiro triste (quem não passou no nível).
static func _brigadeiro_triste(c: Node3D) -> void:
	_brigadeiro(c)
	for no in c.get_children():
		if String(no.name) in ["Olhos", "Boca", "Braco", "Aceno"] or no.position.distance_to(Vector3(0, 0.1, 0.6)) < 0.3:
			c.remove_child(no)
			no.free()
	var chocolate := _m("#3B1E10", 0.5)
	Pecas3D.rosto(c, Vector3(0, 0.2, 0.6), 0.95, 0.62, Color.TRANSPARENT, true)
	Pecas3D.braco(c, Vector3(-0.56, 0.0, 0.05), -1, chocolate)
	Pecas3D.braco(c, Vector3(0.56, 0.0, 0.05), 1, chocolate)


## Bala verde listrada embrulhada (mascote do nível fácil).
static func _bala_verde(c: Node3D) -> void:
	var listras := Pecas3D.material_textura(Pecas3D.faixas([Color("#3FA84A"), Color("#A8E05F")], 10), 0.18)
	var corpo := CapsuleMesh.new()
	corpo.radius = 0.4
	corpo.height = 1.35
	var no := MeshInstance3D.new()
	no.mesh = corpo
	no.material_override = listras
	no.position = Vector3(0, 0.05, 0)
	no.rotation_degrees = Vector3(0, 0, 8)
	c.add_child(no)
	# ponta torcida do papel, em cima
	var papel := _m("#57B84A", 0.25)
	Pecas3D.cilindro(c, 0.02, 0.2, 0.25, Vector3(-0.08, 0.8, 0), papel, Vector3.ONE, Vector3(0, 0, 8))
	for i in 4:
		var angulo := i * TAU / 4.0
		Pecas3D.esfera(c, 0.12, Vector3(-0.1 + cos(angulo) * 0.1, 0.98, sin(angulo) * 0.1), papel, Vector3(0.7, 1.3, 0.7), Vector3(0, 0, cos(angulo) * 30))
	Pecas3D.rosto(c, Vector3(0.0, 0.12, 0.39), 0.85, 0.4)
	var membro := _m("#2F8F3A", 0.4)
	Pecas3D.braco(c, Vector3(-0.38, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.4, 0.05, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0.04, -0.6, 0), 0.15, 0.42, membro, _m("#2F8F3A", 0.3))


## Milho doce (candy corn): branco, amarelo e laranja (mascote do nível médio).
static func _milho_doce(c: Node3D) -> void:
	# gota arredondada com três faixas: creme em cima, amarelo e laranja
	var faixas := Pecas3D.material_textura(Pecas3D.faixas([Color("#FFF1D8"), Color("#FFC21A"), Color("#FFC21A"),
		Color("#FF7A1A"), Color("#FF7A1A")], 5), 0.25)
	var gota := Pecas3D.esfera(c, 0.7, Vector3(0, 0.05, 0), faixas, Vector3(0.92, 1.0, 0.72))
	# afina em cima como um grão de milho
	var topo := Pecas3D.esfera(c, 0.36, Vector3(0, 0.58, 0), _m("#FFF1D8", 0.25), Vector3(0.95, 0.9, 0.8))
	topo.name = "Topo"
	gota.name = "Gota"
	Pecas3D.rosto(c, Vector3(0, 0.02, 0.5), 0.85, 0.6)
	var membro := _m("#E8601A", 0.35)
	Pecas3D.braco(c, Vector3(-0.5, -0.05, 0), -1, membro)
	Pecas3D.braco(c, Vector3(0.5, -0.02, 0), 1, membro, 1.0, true)
	Pecas3D.pernas(c, Vector3(0, -0.58, 0), 0.22, 0.4, membro, _m("#E8601A", 0.3))


## Fantasminha de chocolate branco (tela de carregamento): corpo liso, barra
## ondulada embaixo, rosto sorridente e bracinhos.
static func _fantasma(c: Node3D) -> void:
	var chocolate_branco := _m("#F6EBCF", 0.3)
	# cabeça redonda + corpo que alarga um pouco para baixo
	Pecas3D.esfera(c, 0.62, Vector3(0, 0.3, 0), chocolate_branco)
	Pecas3D.cilindro(c, 0.62, 0.68, 0.72, Vector3(0, -0.06, 0), chocolate_branco)
	# barra ondulada: bolinhas em volta da borda de baixo
	for i in 10:
		var angulo := i * TAU / 10.0
		Pecas3D.esfera(c, 0.17, Vector3(cos(angulo) * 0.56, -0.42, sin(angulo) * 0.56), chocolate_branco)
	Pecas3D.rosto(c, Vector3(0, 0.22, 0.61), 1.1, 0.62)
	Pecas3D.braco(c, Vector3(-0.6, -0.02, 0.05), -1, chocolate_branco)
	Pecas3D.braco(c, Vector3(0.6, 0.02, 0.05), 1, chocolate_branco, 1.0, true)


# --- Enfeites por nível ----------------------------------------------------------
## O doce muda de visual ao subir de nível (Companheiros.melhorar):
##   nível 2: brilhos girando em volta (na cor da raridade)
##   nível 3: + laço no alto da cabeça
##   nível 4: o laço vira uma COROA de ouro
##   nível 5 (máximo): coroa com joias, brilhos dourados e um círculo de luz no chão
const NOMES_ENFEITES := ["", "", "BRILHOS", "LAÇO", "COROA", "COROA DE JOIAS E LUZ"]


static func enfeitar(modelo: Node3D, id: String, nivel: int) -> void:
	if nivel < 2:
		return
	var corpo := modelo.get_node_or_null("Corpo") as Node3D
	if corpo == null:
		return
	var limites := _limites(corpo)
	var topo := limites.end.y
	var chao := limites.position.y
	var cor := Companheiros.cor(id)
	var ouro := Color("#FFC83D")
	var maximo := nivel >= Companheiros.NIVEL_MAXIMO
	# brilhos em volta (a AnimacaoDoce gira o nó "Orbita")
	var orbita := Node3D.new()
	orbita.name = "Orbita"
	orbita.position.y = (topo + chao) * 0.5
	modelo.add_child(orbita)
	var quantos := 6 if maximo else 3
	for i in quantos:
		var angulo := TAU * i / quantos
		var raio := maxf(limites.size.x, limites.size.z) * 0.5 + 0.35
		var brilho := Pecas3D.esfera(orbita, 0.07 if not maximo else 0.08,
			Vector3(cos(angulo) * raio, sin(angulo * 2.0) * 0.35, sin(angulo) * raio), _brilhante(ouro if maximo else cor))
		brilho.name = "Brilho"
	var cabeca := Vector3(0, topo - 0.06, 0)
	if nivel == 3:
		_laco(corpo, cabeca + Vector3(0.22, 0.02, 0.08), cor)
	elif nivel >= 4:
		_coroa(corpo, cabeca, maximo)
	if maximo:
		var luz := Pecas3D.rosquinha(modelo, 0.62, 0.78, Vector3(0, chao + 0.02, 0), _brilhante(ouro, 0.85), Vector3(1, 0.08, 1))
		luz.name = "Luz"


## Tamanho do doce (sem os braços, que se mexem), em coordenadas do Corpo.
static func _limites(corpo: Node3D) -> AABB:
	var total := AABB()
	var primeiro := true
	for malha in corpo.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D.IDENTITY
		var no: Node = malha
		var de_braco := false
		while no != corpo:
			if no.name.begins_with("Braco") or no.name.begins_with("Aceno"):
				de_braco = true
			t = (no as Node3D).transform * t
			no = no.get_parent()
		if de_braco or malha.mesh == null:
			continue
		var caixa: AABB = t * malha.mesh.get_aabb()
		total = caixa if primeiro else total.merge(caixa)
		primeiro = false
	return total if not primeiro else AABB(Vector3(-0.6, -0.8, -0.6), Vector3(1.2, 1.8, 1.2))


static func _brilhante(cor: Color, forca := 1.4) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.emission_enabled = true
	mat.emission = cor
	mat.emission_energy_multiplier = forca
	mat.roughness = 0.2
	return mat


## Laço de fita (duas voltas e o nó do meio), meio de lado na cabeça.
static func _laco(pai: Node3D, posicao: Vector3, cor: Color) -> void:
	var laco := Node3D.new()
	laco.name = "Laco"
	laco.position = posicao
	laco.rotation_degrees = Vector3(0, 0, -18)
	laco.scale = Vector3.ONE * 1.9
	pai.add_child(laco)
	var fita := Pecas3D.material(cor.lightened(0.1), 0.35)
	for lado in [-1, 1]:
		Pecas3D.esfera(laco, 0.17, Vector3(lado * 0.17, 0.04, 0), fita, Vector3(1.2, 0.75, 0.45), Vector3(0, 0, lado * 20))
	Pecas3D.esfera(laco, 0.075, Vector3(0, 0.03, 0.02), Pecas3D.material(cor.darkened(0.2), 0.35))


## Coroa de ouro; no nível máximo, com joias coloridas nas pontas.
static func _coroa(pai: Node3D, posicao: Vector3, joias: bool) -> void:
	var coroa := Node3D.new()
	coroa.name = "Coroa"
	coroa.position = posicao
	coroa.rotation_degrees = Vector3(-8, 0, 10)
	coroa.scale = Vector3.ONE * 1.5
	pai.add_child(coroa)
	var ouro := Pecas3D.material(Color("#FFC83D"), 0.25, 0.7)
	Pecas3D.cilindro(coroa, 0.3, 0.27, 0.16, Vector3(0, 0.08, 0), ouro)
	var cores_joias := [Color("#FF4F8B"), Color("#4DA3FF"), Color("#3DDC97"), Color("#B36BFF"), Color("#FF8A3D")]
	for i in 5:
		var angulo := TAU * i / 5.0 + PI / 2
		var base := Vector3(cos(angulo) * 0.26, 0.16, sin(angulo) * 0.26)
		Pecas3D.cilindro(coroa, 0.0, 0.08, 0.2, base + Vector3(0, 0.1, 0), ouro)
		if joias:
			Pecas3D.esfera(coroa, 0.045, base + Vector3(0, 0.22, 0), _brilhante(cores_joias[i], 0.8))
	if joias:
		Pecas3D.esfera(coroa, 0.06, Vector3(0, 0.09, 0.29), _brilhante(Color("#FF4F8B"), 0.8))
