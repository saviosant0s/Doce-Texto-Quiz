class_name BairroVila
## Peças da parte nova da Vila dos Doces (ver Terrenos): lotes à venda, o que
## se constrói neles (moinho, cofre, casa, jardim, fonte), o Lago de
## Chocolate, o Mirante do Sorvete, os presentes do dia, a placa de direções
## e os anexos da Confeitaria que cresce. Tudo montado por código, no estilo
## do resto da vila (CenarioVila).

const FONTE := preload("res://assets/fontes/BebasNeue-Regular.ttf")


static func _m(cor: String, aspereza := 0.5, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


static func _texto(pai: Node3D, texto: String, posicao: Vector3, tamanho := 110, cor := Color("#F4E038"),
		virado := true) -> Label3D:
	var rotulo := Label3D.new()
	rotulo.text = texto
	rotulo.font = FONTE
	rotulo.font_size = tamanho
	rotulo.pixel_size = 0.0045
	rotulo.modulate = cor
	rotulo.outline_size = 12
	rotulo.outline_modulate = Color("#45256F")
	rotulo.position = posicao
	if virado:
		rotulo.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	pai.add_child(rotulo)
	return rotulo


## Área que avisa quando o doce chega perto (mesmo esquema das portas).
static func area(pai: Node3D, nome: String, posicao: Vector3, tamanho: Vector3) -> Area3D:
	var a := Area3D.new()
	a.name = nome
	a.collision_mask = 3
	a.position = posicao + Vector3(0, 1, 0)
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	forma.shape = caixa
	a.add_child(forma)
	pai.add_child(a)
	return a


# --- Lotes -----------------------------------------------------------------------

## Cerquinha de palitos com bolinhas em volta do lote (aberta do lado da rua).
## Não muda nunca: fica no cenário (juntada com o resto da vila).
static func cerca(pai: Node3D, id: String) -> void:
	var l := Terrenos.lote(id)
	var aberto: Vector3 = l["aberto"]
	var giro := atan2(aberto.x, aberto.z)
	var metade := Terrenos.TAMANHO_LOTE / 2.0
	var palito := _m("#FFF3E0", 0.5)
	var bolinha := _m("#FF8FB8", 0.3)
	for i in 9:
		var t := -metade + i * (Terrenos.TAMANHO_LOTE / 8.0)
		for local in [Vector3(-metade, 0, t), Vector3(metade, 0, t), Vector3(t, 0, -metade)]:
			var ponto: Vector3 = l["posicao"] + local.rotated(Vector3.UP, giro)
			Pecas3D.cano(pai, ponto, ponto + Vector3(0, 0.7, 0), 0.05, palito)
			Pecas3D.esfera(pai, 0.09, ponto + Vector3(0, 0.75, 0), bolinha)

## Monta o lote `id` dentro de `no` (que fica na posição do lote): cerquinha
## de biscoito e, conforme o estado, placa À VENDA, terreno vazio ou a
## construção. Chame de novo para atualizar (apaga o que tinha).
static func montar_lote(no: Node3D, id: String) -> void:
	for filho in no.get_children():
		if not filho is Area3D:
			no.remove_child(filho)
			filho.queue_free()
	var metade := Terrenos.TAMANHO_LOTE / 2.0
	var comprado := Terrenos.comprado(id)
	# chão do lote: terra de chocolate em pó (comprado) ou grama mais clara
	Pecas3D.caixa(no, Vector3(Terrenos.TAMANHO_LOTE, 0.05, Terrenos.TAMANHO_LOTE), Vector3(0, 0.025, 0),
		_m("#B98552" if comprado else "#CFEFC0", 0.9))
	var aberto: Vector3 = Terrenos.lote(id)["aberto"]
	var giro := atan2(aberto.x, aberto.z)  # 0 = aberto para +z
	var canto := aberto * (metade - 0.8) + aberto.cross(Vector3.UP) * (metade - 1.2)
	var tipo := Terrenos.construcao(id)
	if not comprado:
		_placa_venda(no, canto, Terrenos.lote(id)["preco"], giro)
	elif tipo == "":
		_placa(no, "CONSTRUA AQUI!", canto, giro)
		# montinho de tijolos de biscoito esperando a obra
		for i in 6:
			Pecas3D.caixa(no, Vector3(0.5, 0.25, 0.3), Vector3(-0.6 + (i % 3) * 0.55, 0.15 + (i / 3) * 0.26, 0.5),
				_m("#D9A05B", 0.9))
	else:
		CenarioVila.sombra_contato(no, Vector3.ZERO, 3.2, 0.45)
		var obra := Node3D.new()
		obra.name = "Obra"
		obra.rotation.y = giro  # de frente para a rua
		no.add_child(obra)
		var nivel := Terrenos.nivel(id)
		match tipo:
			"moinho":
				_moinho(obra, nivel)
			"cofre":
				_cofre(obra, nivel)
			"casa":
				_casa(obra, id, nivel)
			"jardim":
				_jardim(obra, id, nivel)
			"fonte":
				_fonte(obra, nivel)
		if Terrenos.em_obra(id):
			_andaime(obra)
		# estrelinhas do nível na frente do lote
		for i in nivel:
			Pecas3D.esfera(no, 0.13, canto + Vector3(0, 0.2, 0) - aberto.cross(Vector3.UP) * (0.35 * i),
				_m("#FFC83D", 0.25, 0.6), Vector3(1, 1, 0.5))


static func _placa(no: Node3D, texto: String, posicao: Vector3, giro: float) -> void:
	var placa := Node3D.new()
	placa.position = posicao
	placa.rotation.y = giro
	no.add_child(placa)
	Pecas3D.cano(placa, Vector3(0, 0, 0), Vector3(0, 1.3, 0), 0.07, _m("#8A5A2B", 0.8))
	Pecas3D.caixa(placa, Vector3(2.0, 0.7, 0.1), Vector3(0, 1.45, 0), Texturas.real("madeira_pintada", "#8A62C0", 1.2))
	_texto(placa, texto, Vector3(0, 1.45, 0.07), 100, Color("#F4E038"), false)


static func _placa_venda(no: Node3D, posicao: Vector3, preco: int, giro: float) -> void:
	_placa(no, "À VENDA · %d" % preco, posicao, giro)
	var moeda := Pecas3D.cilindro(no, 0.3, 0.3, 0.08, posicao + Vector3(0, 2.2, 0), _m("#FFC83D", 0.25, 0.7),
		Vector3.ONE, Vector3(90, 0, 0))
	moeda.name = "MoedaGirando"


## Andaime da obra: canos, tábuas em dois andares, tela de proteção e uma
## placa "EM OBRA" (aparece enquanto a construção está subindo de nível).
static func _andaime(no: Node3D) -> void:
	var ferro := _m("#B8BEC6", 0.4, 0.6)
	var tabua := Texturas.real("madeira_pintada", "#C8914F", 1.2)
	var r := 2.25
	for x in [-r, r]:
		for z in [-r, r]:
			Pecas3D.cilindro(no, 0.06, 0.06, 4.2, Vector3(x, 2.1, z), ferro)
	for y in [1.6, 3.2]:
		for z in [-r, r]:
			Pecas3D.caixa(no, Vector3(r * 2 + 0.3, 0.08, 0.45), Vector3(0, y, z), tabua)
		for x in [-r, r]:
			Pecas3D.caixa(no, Vector3(0.45, 0.08, r * 2 + 0.3), Vector3(x, y, 0), tabua)
	var tela := _m("#3FA34D", 0.9)
	tela.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tela.albedo_color.a = 0.45
	Pecas3D.caixa(no, Vector3(r * 2, 1.4, 0.03), Vector3(0, 3.9, -r - 0.05), tela)
	# placa amarela e preta
	var placa := Node3D.new()
	placa.position = Vector3(r - 0.6, 0, r + 0.5)
	no.add_child(placa)
	Pecas3D.cano(placa, Vector3.ZERO, Vector3(0, 1.0, 0), 0.05, ferro)
	Pecas3D.caixa(placa, Vector3(1.3, 0.5, 0.06), Vector3(0, 1.15, 0), _m("#F4C430", 0.5))
	_texto(placa, "EM OBRA", Vector3(0, 1.15, 0.04), 80, Color("#2A1D45"), false)
	# cone e pilha de tijolos
	Pecas3D.cilindro(no, 0.03, 0.22, 0.5, Vector3(-r + 0.4, 0.25, r + 0.5), _m("#FF7A1F", 0.5))
	for k in 3:
		Pecas3D.caixa(no, Vector3(0.45, 0.2, 0.25), Vector3(-r + 1.2 + k * 0.48, 0.1, r + 0.55), _m("#C8663F", 0.9))


## Moinho de açúcar: torre de pão de mel com pás de bolacha wafer. Cada nível
## acrescenta algo (ver Terrenos.CONSTRUCOES["moinho"]["niveis"]).
static func _moinho(no: Node3D, nivel: int) -> void:
	var escala := 0.82 + 0.08 * nivel
	var torre := Node3D.new()
	torre.scale = Vector3.ONE * escala
	no.add_child(torre)
	var reboco := Texturas.real("reboco", "#FFF3E0", 0.5)
	var alta := 0.8 if nivel >= 4 else 0.0  # nível 4: a torre ganha um andar
	Pecas3D.cilindro(torre, 0.9, 1.3, 3.2 + alta, Vector3(0, (3.2 + alta) / 2.0, 0), reboco)
	var telhado := _m("#FFC83D", 0.2, 0.7) if nivel >= 5 else _m("#E8364F", 0.35)
	Pecas3D.cilindro(torre, 0.0, 1.25, 1.2, Vector3(0, 3.8 + alta, 0), telhado)
	Pecas3D.caixa(torre, Vector3(0.8, 1.2, 0.1), Vector3(0, 0.6, 1.2), _m("#7A4322", 0.6))
	var pas := Node3D.new()
	pas.name = "Pas"  # a vila gira este nó
	pas.position = Vector3(0, 2.9 + alta, 1.15 - alta * 0.1)
	torre.add_child(pas)
	for i in 4:
		var braco := Node3D.new()
		braco.rotation.z = i * PI / 2
		pas.add_child(braco)
		Pecas3D.caixa(braco, Vector3(0.12, 1.6, 0.06), Vector3(0, 0.85, 0), _m("#8A5A2B", 0.7))
		Pecas3D.caixa(braco, Vector3(0.55, 1.2, 0.05), Vector3(0.3, 1.0, 0.03), _m("#F2D29B", 0.8))
	Pecas3D.esfera(pas, 0.18, Vector3.ZERO, _m("#F4E038", 0.3))
	# sacos de açúcar na porta
	for x in [-0.9, 0.9]:
		Pecas3D.esfera(no, 0.35, Vector3(x, 0.3, 1.5), _m("#FFFFFF", 0.8), Vector3(1, 1.2, 1))
	if nivel >= 2:
		for x in [-1.2, 1.2]:
			Pecas3D.cano(no, Vector3(x, 0, -1.2), Vector3(x, 2.2, -1.2), 0.04, _m("#FFFFFF", 0.4))
			Pecas3D.cilindro(no, 0.0, 0.25, 0.4, Vector3(x + 0.2, 2.0, -1.2), _m("#6FD3FF", 0.4), Vector3(1, 1, 0.2), Vector3(0, 0, -90))
		Pecas3D.rosquinha(torre, 1.25, 1.55, Vector3(0, 0.15, 0), Texturas.real("calcamento", "#CFC6B8", 1.3), Vector3(1, 0.6, 1))
	if nivel >= 3:
		# galpão de madeira do lado, cheio de sacos
		var galpao := Vector3(-1.9, 0, 0.2)
		Pecas3D.caixa(no, Vector3(1.3, 1.2, 1.6), galpao + Vector3(0, 0.6, 0), Texturas.real("madeira_pintada", "#B5773F", 1.2))
		Pecas3D.caixa(no, Vector3(1.5, 0.12, 1.8), galpao + Vector3(0, 1.25, 0), _m("#8C3B2E", 0.6), Vector3(0, 0, 12))
		for k in 3:
			Pecas3D.esfera(no, 0.22, galpao + Vector3(0.75, 0.22, -0.5 + k * 0.5), _m("#FFFFFF", 0.8), Vector3(1, 1.2, 1))
	if nivel >= 4:
		for k in 3:
			var a := -0.6 + k * 0.6
			Pecas3D.caixa(torre, Vector3(0.3, 0.4, 0.06), Vector3(sin(a) * 1.08, 2.5, cos(a) * 1.08), _m("#8FBCD6", 0.06, 0.35),
				Vector3(-8, rad_to_deg(a), 0))
	if nivel >= 5:
		var ouro := _m("#FFC83D", 0.15, 0.8)
		Pecas3D.esfera(torre, 0.28, Vector3(0, 4.6 + alta, 0), ouro)
		Pecas3D.cilindro(torre, 0.35, 0.35, 0.06, Vector3(0, 5.0 + alta, 0), ouro, Vector3.ONE, Vector3(90, 0, 0))
	CenarioVila._poste(no, 1.3 * escala, 3.2 * escala, Vector3.ZERO)


## Cofre de moedas: porquinho gigante de açúcar cor-de-rosa (cofrinho).
static func _cofre(no: Node3D, nivel: int) -> void:
	var escala := 0.8 + 0.08 * nivel
	var porco := Node3D.new()
	porco.scale = Vector3.ONE * escala
	no.add_child(porco)
	var moeda := _m("#FFC83D", 0.25, 0.7)
	if nivel >= 3:
		# pedestal de pedra: o porquinho sobe
		Pecas3D.cilindro(no, 1.9, 2.1, 0.45, Vector3(0, 0.22, 0), Texturas.real("calcamento", "#D8D0C4", 1.3))
		Pecas3D.cilindro(no, 1.95, 1.95, 0.06, Vector3(0, 0.47, 0), _m("#FFFFFF", 0.35))
		porco.position.y = 0.45
	var rosa := _m("#FFC83D", 0.18, 0.75) if nivel >= 5 else _m("#FF9EC4", 0.35)
	var focinho := _m("#F2B233", 0.2, 0.75) if nivel >= 5 else _m("#FF7FB0", 0.35)
	Pecas3D.esfera(porco, 1.3, Vector3(0, 1.5, 0), rosa, Vector3(1.25, 1, 1))
	Pecas3D.cilindro(porco, 0.45, 0.45, 0.35, Vector3(0, 1.4, 1.25), focinho, Vector3.ONE, Vector3(90, 0, 0))
	for x in [-0.15, 0.15]:
		Pecas3D.esfera(porco, 0.07, Vector3(x, 1.4, 1.43), _m("#B0406A", 0.4))
	for x in [-0.5, 0.5]:
		Pecas3D.esfera(porco, 0.12, Vector3(x, 1.95, 1.05), _m("#2A1D45", 0.2))
		Pecas3D.cilindro(porco, 0.0, 0.3, 0.45, Vector3(x * 1.2, 2.75, 0.2), rosa)
	for p in [Vector3(-0.8, 0.3, 0.6), Vector3(0.8, 0.3, 0.6), Vector3(-0.8, 0.3, -0.6), Vector3(0.8, 0.3, -0.6)]:
		Pecas3D.cilindro(porco, 0.3, 0.3, 0.6, p, rosa)
	Pecas3D.caixa(porco, Vector3(0.9, 0.08, 0.2), Vector3(0, 2.82, 0), _m("#B0406A", 0.4))
	Pecas3D.cilindro(porco, 0.35, 0.35, 0.08, Vector3(0, 3.2, 0), moeda, Vector3.ONE, Vector3(90, 0, 0))
	if nivel >= 2:
		for i in 6:
			Pecas3D.cilindro(no, 0.25, 0.25, 0.08, Vector3(1.9, 0.05 + i * 0.08, 1.3), moeda)
		for i in 4:
			Pecas3D.cilindro(no, 0.25, 0.25, 0.08, Vector3(1.4, 0.05 + i * 0.08, 1.7), moeda)
	if nivel >= 4:
		var coroa := Vector3(0, 2.7, -0.3)
		Pecas3D.cilindro(porco, 0.42, 0.36, 0.3, coroa, moeda)
		for k in 5:
			var a := k * TAU / 5.0
			Pecas3D.esfera(porco, 0.08, coroa + Vector3(cos(a) * 0.4, 0.2, sin(a) * 0.4), _m("#E8364F", 0.1))
		for i in 7:
			Pecas3D.cilindro(no, 0.25, 0.25, 0.08, Vector3(-1.9, 0.05 + i * 0.08, 1.3), moeda)
	CenarioVila._poste(no, 1.5 * escala, 3.0 * escala, Vector3.ZERO)


## Casa de doce: casinha de bolo com telhado de chantili e morango; cresce a
## cada nível (chaminé e cerquinha, segundo andar, varanda, torrezinha).
static func _casa(no: Node3D, id: String, nivel := 1) -> void:
	var cores := ["#C9F2D2", "#FFE08A", "#C9E4FF", "#FFD1E3", "#E4D4FF", "#FFD8B0"]
	var cor: String = cores[Terrenos.LOTES.map(func(l): return l["id"]).find(id) % cores.size()]
	var parede := Texturas.real("reboco", cor, 0.5)
	var andar := 2.0 if nivel >= 3 else 0.0  # nível 3: segundo andar
	Pecas3D.caixa(no, Vector3(3.4, 2.4, 3.0), Vector3(0, 1.2, 0), parede)
	if andar > 0.0:
		Pecas3D.caixa(no, Vector3(3.6, 0.15, 3.2), Vector3(0, 2.45, 0), _m("#FFFFFF", 0.4))
		Pecas3D.caixa(no, Vector3(3.2, 2.0, 2.8), Vector3(0, 3.5, 0), parede)
		for x in [-0.8, 0.8]:
			Pecas3D.caixa(no, Vector3(0.6, 0.6, 0.1), Vector3(x, 3.5, 1.42), _m("#8FBCD6", 0.06, 0.35))
	Pecas3D.cilindro(no, 0.0, 2.6, 1.6, Vector3(0, 3.2 + andar, 0), _m("#FFFFFF", 0.6), Vector3(1, 1, 0.9), Vector3(0, 45, 0))
	Pecas3D.esfera(no, 0.35, Vector3(0, 4.1 + andar, 0), _m("#E8263F", 0.15))
	Pecas3D.caixa(no, Vector3(0.9, 1.5, 0.1), Vector3(0, 0.75, 1.52), _m("#7A4322", 0.6))
	for x in [-1.05, 1.05]:
		Pecas3D.caixa(no, Vector3(0.7, 0.7, 0.1), Vector3(x, 1.5, 1.52), _m("#8FBCD6", 0.06, 0.35))
	if nivel >= 2:
		Pecas3D.caixa(no, Vector3(0.5, 1.4, 0.5), Vector3(1.0, 3.4 + andar, -0.5), Texturas.real("tijolos", "#B8664A", 1.0))
		var branco := _m("#FFFFFF", 0.4)
		for k in 9:
			var x := -2.6 + k * 0.65
			if absf(x) < 0.7:
				continue  # portão
			Pecas3D.caixa(no, Vector3(0.1, 0.6, 0.06), Vector3(x, 0.3, 2.5), branco)
		for x in [-1.65, 1.65]:
			Pecas3D.caixa(no, Vector3(1.9, 0.07, 0.06), Vector3(x, 0.45, 2.5), branco)
		for x in [-1.05, 1.05]:
			Pecas3D.caixa(no, Vector3(0.8, 0.18, 0.22), Vector3(x, 1.08, 1.62), _m("#8C3B2E", 0.7))
			for k in 3:
				Pecas3D.esfera(no, 0.08, Vector3(x - 0.25 + k * 0.25, 1.22, 1.64), _m(["#FF6FAE", "#FFD23F", "#FFFFFF"][k], 0.4))
	if nivel >= 4:
		# varanda: piso, duas colunas e um telhadinho
		var madeira := Texturas.real("madeira_pintada", "#FFFFFF", 1.2)
		Pecas3D.caixa(no, Vector3(2.2, 0.12, 0.9), Vector3(0, 0.06, 1.95), madeira)
		for x in [-0.95, 0.95]:
			Pecas3D.cilindro(no, 0.08, 0.08, 2.2, Vector3(x, 1.1, 2.3), madeira)
		Pecas3D.caixa(no, Vector3(2.4, 0.1, 1.0), Vector3(0, 2.25, 2.0), _m("#E8364F", 0.4), Vector3(-10, 0, 0))
	if nivel >= 5:
		var torre := Vector3(-1.5, 0, -1.2)
		Pecas3D.cilindro(no, 0.6, 0.6, 4.4 + andar, torre + Vector3(0, (4.4 + andar) / 2.0, 0), parede)
		Pecas3D.cilindro(no, 0.0, 0.8, 1.3, torre + Vector3(0, 5.05 + andar, 0), _m("#8B7CF6", 0.4))
		Pecas3D.cano(no, torre + Vector3(0, 5.6 + andar, 0), torre + Vector3(0, 6.4 + andar, 0), 0.03, _m("#FFFFFF", 0.4))
		Pecas3D.caixa(no, Vector3(0.5, 0.3, 0.03), torre + Vector3(0.25, 6.2 + andar, 0), _m("#FFD23F", 0.4))
	CenarioVila._parede(no, Vector3(3.4, 3.0 + andar, 3.0), Vector3(0, (3.0 + andar) / 2.0, 0))


static func _jardim(no: Node3D, id: String, nivel := 1) -> void:
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF"]
	var k := Terrenos.LOTES.map(func(l): return l["id"]).find(id)
	var arvores := 2 if nivel <= 1 else 4
	for i in arvores:
		var p := Vector3(-1.9 + (i % 2) * 3.8, 0, -1.9 + (i / 2) * 3.8) if arvores == 4 else Vector3(-1.6 + i * 3.2, 0, -1.4)
		CenarioVila.arvore_pirulito(no, p, cores[(i + k) % cores.size()])
	for i in 10:
		var angulo := i * TAU / 10.0
		Pecas3D.esfera(no, 0.18, Vector3(cos(angulo) * 0.9, 0.2, sin(angulo) * 0.9), _m(cores[i % cores.size()], 0.3))
	if nivel >= 3:
		var pedra := Texturas.real("calcamento", "#D8D0C4", 1.4)
		Pecas3D.caixa(no, Vector3(0.9, 0.04, 5.6), Vector3(0, 0.04, 0), pedra)
		Pecas3D.caixa(no, Vector3(5.6, 0.04, 0.9), Vector3(0, 0.045, 0), pedra)
		var madeira := Texturas.real("madeira_pintada", "#B5773F", 1.2)
		for x in [-1.6, 1.6]:
			Pecas3D.caixa(no, Vector3(1.1, 0.1, 0.4), Vector3(x, 0.45, 1.0), madeira)
			Pecas3D.caixa(no, Vector3(1.1, 0.4, 0.08), Vector3(x, 0.7, 0.8), madeira)
			for dx in [-0.45, 0.45]:
				Pecas3D.caixa(no, Vector3(0.08, 0.45, 0.35), Vector3(x + dx, 0.22, 1.0), _m("#2B2B30", 0.4, 0.6))
	if nivel >= 4:
		# coreto: piso redondo, seis colunas e cúpula de chantili
		Pecas3D.cilindro(no, 1.2, 1.3, 0.2, Vector3(0, 0.1, 0), Texturas.real("calcamento", "#FFF3E0", 1.2))
		for c in 6:
			var a := c * TAU / 6.0
			Pecas3D.cilindro(no, 0.07, 0.07, 1.9, Vector3(cos(a) * 1.05, 1.15, sin(a) * 1.05), _m("#FFFFFF", 0.4))
		Pecas3D.esfera(no, 1.25, Vector3(0, 2.1, 0), _m("#FFD1E3", 0.5), Vector3(1, 0.55, 1))
		Pecas3D.esfera(no, 0.2, Vector3(0, 2.8, 0), _m("#E8263F", 0.15))
	else:
		Pecas3D.esfera(no, 0.35, Vector3(0, 0.3, 0), _m("#FFF3E0", 0.5))
	if nivel >= 5:
		# arco de balas na entrada e postes de luz
		for c in 9:
			var a := PI * c / 8.0
			Pecas3D.esfera(no, 0.2, Vector3(cos(a) * 1.1, 0.2 + sin(a) * 2.2, 2.6), _m(cores[c % cores.size()], 0.2))
		for x in [-2.5, 2.5]:
			Pecas3D.cilindro(no, 0.05, 0.05, 2.0, Vector3(x, 1.0, 2.5), _m("#2B2B30", 0.4, 0.6))
			var luz := _m("#FFF1C4", 0.2)
			luz.emission_enabled = true
			luz.emission = Color("#FFD27A")
			luz.emission_energy_multiplier = 1.2
			Pecas3D.esfera(no, 0.16, Vector3(x, 2.1, 2.5), luz)


static func _fonte(no: Node3D, nivel := 1) -> void:
	var borda := _m("#FFC83D", 0.2, 0.7) if nivel >= 5 else _m("#FFFFFF", 0.4)
	var calda := _m("#E8364F", 0.1)
	var bacia := 2.2 if nivel >= 5 else 1.6
	Pecas3D.cilindro(no, bacia, bacia + 0.2, 0.6, Vector3(0, 0.3, 0), _m("#FFFFFF", 0.4))
	Pecas3D.cilindro(no, bacia - 0.15, bacia - 0.15, 0.05, Vector3(0, 0.58, 0), calda)
	var alto := 0.7 if nivel >= 2 else 0.0
	Pecas3D.cilindro(no, 0.25, 0.3, 1.6 + alto, Vector3(0, 1.1 + alto / 2.0, 0), borda)
	Pecas3D.cilindro(no, 0.8, 0.55, 0.25, Vector3(0, 1.95, 0), borda)
	Pecas3D.cilindro(no, 0.75, 0.75, 0.04, Vector3(0, 2.07, 0), calda)
	if nivel >= 2:
		Pecas3D.cilindro(no, 0.5, 0.35, 0.2, Vector3(0, 2.65, 0), borda)
	if nivel >= 5:
		Pecas3D.cilindro(no, 0.3, 0.2, 0.18, Vector3(0, 3.2, 0), borda)
		Pecas3D.cilindro(no, 0.1, 0.1, 0.5, Vector3(0, 3.0, 0), borda)
	var topo := 2.3 + alto + (0.5 if nivel >= 5 else 0.0)
	Pecas3D.esfera(no, 0.45 if nivel < 2 else 0.3, Vector3(0, topo, 0), calda, Vector3(1, 1.2, 1))
	for i in 5:
		var angulo := i * TAU / 5.0
		Pecas3D.esfera(no, 0.12, Vector3(cos(angulo) * 0.2, topo + 0.45, sin(angulo) * 0.2), _m("#3FA34D", 0.4), Vector3(1.3, 0.4, 0.6))
	for i in 8:
		var angulo := i * TAU / 8.0
		var saida := Vector3(cos(angulo) * 0.78, 1.9, sin(angulo) * 0.78)
		Pecas3D.cano(no, saida, saida + Vector3(0, -0.3, 0), 0.06, calda)
	if nivel >= 3:
		var flores := ["#FF6FAE", "#FFD23F", "#FFFFFF", "#B07CFF"]
		for i in 12:
			var a := i * TAU / 12.0
			var p := Vector3(cos(a), 0, sin(a)) * (bacia + 0.55)
			Pecas3D.esfera(no, 0.28, p + Vector3(0, 0.18, 0), _m("#3E7A34", 0.8), Vector3(1, 0.7, 1))
			Pecas3D.esfera(no, 0.08, p + Vector3(0, 0.4, 0), _m(flores[i % flores.size()], 0.4))
	if nivel >= 4:
		# ursinhos de goma na borda, jogando calda para o meio
		var gomas := ["#E8364F", "#7BE07B", "#FFD23F", "#6FD3FF"]
		for i in 4:
			var a := i * TAU / 4.0 + PI / 4.0
			var p := Vector3(cos(a), 0, sin(a)) * (bacia - 0.1)
			var goma := _m(gomas[i], 0.15)
			goma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			goma.albedo_color.a = 0.85
			Pecas3D.esfera(no, 0.25, p + Vector3(0, 0.85, 0), goma, Vector3(1, 1.2, 1))
			Pecas3D.esfera(no, 0.17, p + Vector3(0, 1.25, 0), goma)
			Pecas3D.cano(no, p + Vector3(0, 1.3, 0), p * 0.45 + Vector3(0, 1.5, 0), 0.05, calda)
	CenarioVila._poste(no, bacia + 0.2, 1.0, Vector3.ZERO)


# --- Lugares longe -----------------------------------------------------------------

## Lago de Chocolate com um deque de biscoito e um barquinho de bolacha.
static func lago(pai: Node3D, centro: Vector3) -> void:
	var chocolate := _m("#5A2E17", 0.08)
	Pecas3D.cilindro(pai, 6.5, 6.5, 0.06, centro + Vector3(0, 0.04, 0), chocolate)
	Pecas3D.rosquinha(pai, 6.3, 7.0, centro + Vector3(0, 0.06, 0), _m("#E9B97A", 0.8), Vector3(1, 0.3, 1))
	# redemoinhos de chantili
	for p in [Vector3(-2, 0, -2), Vector3(2.5, 0, 1.5), Vector3(-1, 0, 3)]:
		Pecas3D.rosquinha(pai, 0.4, 0.7, centro + p + Vector3(0, 0.1, 0), _m("#F3E3B5", 0.3), Vector3(1, 0.25, 1))
	# deque de biscoito indo do lado da vila (x maior) para o meio
	var biscoito := CenarioVila._texturizado("#D9A05B", "biscoito", 2.5, 0.9)
	Pecas3D.caixa(pai, Vector3(4.5, 0.1, 2.2), centro + Vector3(4.6, 0.08, 0), biscoito)
	for x in [2.6, 4.6, 6.6]:
		for z in [-0.8, 0.8]:
			Pecas3D.cilindro(pai, 0.12, 0.12, 0.5, centro + Vector3(x, 0.3, z * 1.2), _m("#8A5A2B", 0.8))
	# barquinho de bolacha waffle com vela de wafer
	var barco := centro + Vector3(-1.5, 0.15, -1.0)
	Pecas3D.esfera(pai, 1.0, barco, _m("#E0A45A", 0.8), Vector3(1.6, 0.45, 0.8))
	Pecas3D.cano(pai, barco, barco + Vector3(0, 1.8, 0), 0.05, _m("#FFFFFF", 0.4))
	Pecas3D.cilindro(pai, 0.0, 0.7, 1.4, barco + Vector3(0.35, 1.1, 0), _m("#FF8FB8", 0.5), Vector3(1, 1, 0.1), Vector3(0, 0, -90))
	# colisão: não dá para entrar no lago (só no deque)
	for i in 10:
		var angulo := i * TAU / 10.0
		var p := centro + Vector3(cos(angulo) * 4.8, 0, sin(angulo) * 4.8)
		if absf(angulo) < 0.4 or absf(angulo - TAU) < 0.4:
			continue  # o deque (lado +x) fica livre
		CenarioVila._poste(pai, 2.2, 1.0, p)
	CenarioVila._poste(pai, 3.2, 1.0, centro + Vector3(-1.0, 0, 0))


## Mirante do Sorvete: roda de colunas de casquinha com uma bola gigante de sorvete.
static func mirante(pai: Node3D, centro: Vector3) -> void:
	Pecas3D.cilindro(pai, 4.0, 4.3, 0.1, centro + Vector3(0, 0.05, 0), Texturas.real("calcamento", "#FFF3E0", 0.45))
	var casquinha := Pecas3D.material_textura(Pecas3D.listras([Color("#D99A4E"), Color("#E8B570")], 18), 0.7)
	for i in 6:
		var angulo := i * TAU / 6.0 + PI / 6
		var p := centro + Vector3(cos(angulo) * 3.2, 0, sin(angulo) * 3.2)
		Pecas3D.cilindro(pai, 0.18, 0.18, 3.2, p + Vector3(0, 2.0, 0), casquinha)
		CenarioVila._poste(pai, 0.25, 3.2, p)
	# no alto das colunas, só um anel de glacê (aberto: a câmera vê lá dentro)
	Pecas3D.rosquinha(pai, 2.95, 3.45, centro + Vector3(0, 3.65, 0), _m("#FFB0D5", 0.4), Vector3(1, 0.6, 1))
	for i in 6:
		var angulo := i * TAU / 6.0 + PI / 6
		Pecas3D.esfera(pai, 0.28, centro + Vector3(cos(angulo) * 3.2, 3.95, sin(angulo) * 3.2), _m("#E8263F", 0.15))
	# estátua: casquinha gigante com três bolas
	var estatua := centro + Vector3(0, 0.1, -0.5)
	Pecas3D.cilindro(pai, 0.7, 0.05, 1.8, estatua + Vector3(0, 0.9, 0), casquinha, Vector3.ONE, Vector3(180, 0, 0))
	Pecas3D.esfera(pai, 0.75, estatua + Vector3(0, 2.1, 0), _m("#FFF3D6", 0.6))
	Pecas3D.esfera(pai, 0.62, estatua + Vector3(0, 2.9, 0), _m("#FF8FB8", 0.6))
	Pecas3D.esfera(pai, 0.5, estatua + Vector3(0, 3.5, 0), _m("#8B4A2B", 0.5))
	CenarioVila._poste(pai, 0.8, 3.0, estatua)


## Presente do dia (caixa com laço); aberto, fica só a caixa sem tampa.
static func presente(no: Node3D, aberto: bool) -> void:
	for filho in no.get_children():
		if not filho is Area3D and not filho is CPUParticles3D:
			no.remove_child(filho)
			filho.queue_free()
	var caixa := _m("#B07CFF", 0.4)
	var fita := _m("#F4E038", 0.3)
	Pecas3D.caixa(no, Vector3(0.9, 0.7, 0.9), Vector3(0, 0.35, 0), caixa)
	Pecas3D.caixa(no, Vector3(0.95, 0.72, 0.18), Vector3(0, 0.36, 0), fita)
	Pecas3D.caixa(no, Vector3(0.18, 0.72, 0.95), Vector3(0, 0.36, 0), fita)
	if not aberto:
		var tampa := Node3D.new()
		tampa.name = "Tampa"
		tampa.position.y = 0.78
		no.add_child(tampa)
		Pecas3D.caixa(tampa, Vector3(1.0, 0.18, 1.0), Vector3.ZERO, caixa)
		for lado in [-1, 1]:
			Pecas3D.esfera(tampa, 0.2, Vector3(lado * 0.2, 0.2, 0), fita, Vector3(1.2, 0.7, 0.5), Vector3(0, 0, lado * 25))


## Placa de direções no cruzamento da avenida.
static func placa_direcoes(pai: Node3D, posicao: Vector3) -> void:
	Pecas3D.cano(pai, posicao, posicao + Vector3(0, 1.9, 0), 0.08, _m("#FFFFFF", 0.4))
	var setas := [["← LAGO DE CHOCOLATE", Vector3(-1, 0, 0), 1.7], ["MIRANTE DO SORVETE →", Vector3(1, 0, 0), 1.3],
		["TERRENOS ↑ (ATRÁS DA ESCOLA)", Vector3(0, 0, -1), 0.9]]
	for s in setas:
		var placa := Node3D.new()
		placa.position = posicao + Vector3(0, s[2], 0)
		pai.add_child(placa)
		Pecas3D.caixa(placa, Vector3(2.4, 0.34, 0.08), Vector3(0, 0, 0.1), Texturas.real("madeira_pintada", "#8A62C0", 1.2))
		_texto(placa, s[0], Vector3(0, 0, 0.16), 62, Color("#F4E038"), false)
	CenarioVila._poste(pai, 0.2, 2.0, posicao)


# --- Confeitaria que cresce ------------------------------------------------------

## Anexos da Confeitaria (no nó do prédio; +z é a frente): estágio 2 ganha um
## terraço com mesinhas e guarda-sóis; estágio 3, uma segunda torre-cupcake.
static func anexos_confeitaria(no: Node3D, estagio: int) -> void:
	if estagio >= 2:
		var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F"]
		for i in 3:
			var lado := -1 if i % 2 == 0 else 1
			var p := Vector3(lado * (3.6 + (i / 2) * 1.2), 0, 3.2 - (i / 2) * 1.6)
			Pecas3D.cilindro(no, 0.55, 0.55, 0.08, p + Vector3(0, 0.8, 0), _m("#FFFFFF", 0.4))
			Pecas3D.cano(no, p, p + Vector3(0, 0.8, 0), 0.06, _m("#DDDDDD", 0.4))
			Pecas3D.cano(no, p + Vector3(0, 0.8, 0), p + Vector3(0, 2.3, 0), 0.04, _m("#FFFFFF", 0.4))
			Pecas3D.cilindro(no, 0.0, 1.0, 0.5, p + Vector3(0, 2.4, 0), _m(cores[i], 0.4))
			Pecas3D.esfera(no, 0.15, p + Vector3(0.3, 0.9, 0.1), _m("#FF6FAE", 0.3))  # cupcake na mesa
			for s in [-1, 1]:
				Pecas3D.cilindro(no, 0.22, 0.22, 0.45, p + Vector3(s * 0.8, 0.22, 0), _m("#FFD1E3", 0.5))
			CenarioVila._poste(no, 0.6, 1.0, p)
	if estagio >= 3:
		var torre := Vector3(4.3, 0, -1.4)
		var forminha := Pecas3D.material_textura(Pecas3D.listras([Color("#FFD23F"), Color("#FFFFFF")], 20), 0.5)
		Pecas3D.cilindro(no, 1.4, 1.2, 2.6, torre + Vector3(0, 1.3, 0), forminha)
		Pecas3D.rosquinha(no, 0.8, 1.6, torre + Vector3(0, 2.85, 0), _m("#C9B3EC", 0.3), Vector3(1, 1.2, 1))
		Pecas3D.esfera(no, 0.8, torre + Vector3(0, 3.4, 0), _m("#C9B3EC", 0.3), Vector3(1, 0.9, 1))
		Pecas3D.cano(no, torre + Vector3(0, 3.9, 0), torre + Vector3(0, 5.2, 0), 0.05, _m("#FFFFFF", 0.4))
		Pecas3D.cilindro(no, 0.0, 0.4, 0.8, torre + Vector3(0.35, 4.9, 0), _m("#E8364F", 0.4), Vector3(1, 1, 0.15), Vector3(0, 0, -90))
		CenarioVila._poste(no, 1.4, 3.5, torre)
