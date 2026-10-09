class_name RegioesVila
## O 3D das regiões em volta da vila (regras em scripts/regioes.gd): a cerca
## de bengalinhas em volta da vila com as três entradas, os portões (fechados
## até liberar), o Lago de Morango com a ponte e a Ilha do Algodão-Doce, o Rio
## de Calda com a ponte e o Bosque de Pirulitos, a Montanha de Sorvete, os
## morros de sorvete na borda do mundo e as coisinhas para pegar.

const FONTE := preload("res://assets/fontes/BebasNeue-Regular.ttf")
const LAGO_CENTRO := Vector3(-67, 0, 2)
const LAGO_RAIOS := Vector2(24, 30)  # x e z
const ILHA_CENTRO := Vector3(-70, 0, 2)
const ILHA_RAIO := 10.0
const RIO_Z := Vector2(43, 49)  # margens do rio (z)
const PONTE_SUL_X := -8.0


static func _m(cor: String, aspereza := 0.5, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


static func _brilho(cor: String, forca := 1.0) -> StandardMaterial3D:
	var mat := _m(cor, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(cor)
	mat.emission_energy_multiplier = forca
	return mat


static func _parede(pai: Node3D, de: Vector3, ate: Vector3, grossura := 1.0) -> void:
	var meio := (de + ate) / 2.0
	var tamanho := Vector3(absf(ate.x - de.x) + grossura, 4.0, absf(ate.z - de.z) + grossura)
	CenarioVila._parede(pai, tamanho, meio + Vector3(0, 2, 0))


## Monta tudo. Retorna {"portoes": {id: Node3D do portão}, "regioes": {id: Node3D}}.
static func montar(pai: Node3D) -> Dictionary:
	var portoes := {}
	var regioes := {}
	_cerca_vila(pai)
	_limites_mundo(pai)
	for r in Regioes.LISTA:
		var no := Node3D.new()
		no.name = "Regiao_" + r["id"]
		pai.add_child(no)
		regioes[r["id"]] = no
		match r["id"]:
			"ilha":
				_ilha(no)
			"bosque":
				_bosque(no)
			"montanha":
				_montanha(no)
		portoes[r["id"]] = portao(pai, r)
	morros_borda(pai)
	return {"portoes": portoes, "regioes": regioes}


# --- Cerca da vila, limites e portões -------------------------------------------------

## Cerca baixa de bengalinhas em volta da vila, aberta nas entradas das regiões
## (com colisão; a vila antes tinha paredes invisíveis).
static func _cerca_vila(pai: Node3D) -> void:
	var no := Node3D.new()
	no.name = "CercaVila"
	pai.add_child(no)
	var v := Regioes.VILA
	var branco := _m("#FFFFFF", 0.4)
	var rosa := _m("#FF8FB8", 0.4)
	var cantos := [Vector3(v.position.x, 0, v.position.y), Vector3(v.end.x, 0, v.position.y),
		Vector3(v.end.x, 0, v.end.y), Vector3(v.position.x, 0, v.end.y)]
	var entradas := Regioes.LISTA.map(func(r): return r["entrada"])
	for i in 4:
		var de: Vector3 = cantos[i]
		var ate: Vector3 = cantos[(i + 1) % 4]
		# pedaços do lado, pulando as entradas
		var cortes := [0.0]
		var comprimento := de.distance_to(ate)
		for e: Vector3 in entradas:
			var t := (e - de).dot((ate - de).normalized())
			if absf((de + (ate - de).normalized() * t).distance_to(e)) < 0.5 and t > 0 and t < comprimento:
				cortes.append(t - Regioes.LARGURA_ENTRADA / 2.0)
				cortes.append(t + Regioes.LARGURA_ENTRADA / 2.0)
		cortes.append(comprimento)
		var direcao := (ate - de).normalized()
		for k in range(0, cortes.size(), 2):
			var a: Vector3 = de + direcao * float(cortes[k])
			var b: Vector3 = de + direcao * float(cortes[k + 1])
			_parede(pai, a, b, 0.6)
			var postes := maxi(1, int(a.distance_to(b) / 2.5))
			for p in postes + 1:
				var ponto := a.lerp(b, float(p) / postes)
				Pecas3D.cilindro(no, 0.07, 0.07, 1.1, ponto + Vector3(0, 0.55, 0), branco if p % 2 == 0 else rosa)
			Pecas3D.cano(no, a + Vector3(0, 0.95, 0), b + Vector3(0, 0.95, 0), 0.06, rosa)
			Pecas3D.cano(no, a + Vector3(0, 0.55, 0), b + Vector3(0, 0.55, 0), 0.05, branco)


## Paredes invisíveis na borda do mundo (os morros ficam do lado de fora).
static func _limites_mundo(pai: Node3D) -> void:
	var m := Regioes.MUNDO
	var a := Vector3(m.position.x, 0, m.position.y)
	var b := Vector3(m.end.x, 0, m.position.y)
	var c := Vector3(m.end.x, 0, m.end.y)
	var d := Vector3(m.position.x, 0, m.end.y)
	for par in [[a, b], [b, c], [c, d], [d, a]]:
		_parede(pai, par[0], par[1], 1.0)
	# os cantos entre a vila e a borda norte/sul que não são de nenhuma região
	# (atrás dos terrenos): o norte da vila já é borda; ao sul, o bosque ocupa
	# só a largura da vila, então fecha os lados dele
	var v := Regioes.VILA
	_parede(pai, Vector3(v.position.x, 0, v.end.y), Vector3(v.position.x, 0, m.end.y), 0.6)
	_parede(pai, Vector3(v.end.x, 0, v.end.y), Vector3(v.end.x, 0, m.end.y), 0.6)


## Portão da região: arco de bengalas com o nome; fechado (grade, parede,
## névoa rosa e o aviso do que falta) até a região liberar. Retorna o nó.
static func portao(pai: Node3D, r: Dictionary) -> Node3D:
	var no := Node3D.new()
	no.name = "Portao_" + r["id"]
	no.position = r["entrada"]
	pai.add_child(no)
	# o arco fica atravessado na entrada, de frente (+z local) para a vila; a
	# névoa fica atrás, do lado da região
	var e: Vector3 = r["entrada"]
	no.rotation.y = atan2(-e.x, -e.z) if absf(e.x) >= absf(e.z) else (PI if e.z > 0 else 0.0)
	var metade := Regioes.LARGURA_ENTRADA / 2.0
	var listras := Pecas3D.material_textura(Pecas3D.faixas([Color("#FFFFFF"), Color("#E8364F")], 14), 0.35)
	for lado in [-1, 1]:
		Pecas3D.cilindro(no, 0.22, 0.22, 4.2, Vector3(lado * metade, 2.1, 0), listras)
		Pecas3D.esfera(no, 0.35, Vector3(lado * metade, 4.4, 0), _m(r["cor"], 0.3))
	Pecas3D.caixa(no, Vector3(Regioes.LARGURA_ENTRADA + 0.6, 0.8, 0.2), Vector3(0, 3.9, 0), _m("#5E3D8E", 0.5))
	var nome := Label3D.new()
	nome.name = "NomeRegiao"
	nome.text = r["nome"]
	nome.font = FONTE
	nome.font_size = 110
	nome.pixel_size = 0.005
	nome.modulate = Color("#F4E038")
	nome.outline_size = 12
	nome.outline_modulate = Color("#45256F")
	nome.position = Vector3(0, 3.9, 0.12)
	no.add_child(nome)
	var fechado := Node3D.new()
	fechado.name = "Fechado"
	no.add_child(fechado)
	# grade de pirulito, névoa rosa do outro lado e o aviso
	for k in 7:
		var x := -metade + 0.5 + k * (Regioes.LARGURA_ENTRADA - 1.0) / 6.0
		Pecas3D.cilindro(fechado, 0.08, 0.08, 3.2, Vector3(x, 1.6, 0), _m("#8B4A2B", 0.4))
	Pecas3D.caixa(fechado, Vector3(Regioes.LARGURA_ENTRADA, 0.18, 0.16), Vector3(0, 2.2, 0), _m("#8B4A2B", 0.4))
	var nevoa := _m("#FFE3F0", 0.9)
	nevoa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	nevoa.albedo_color.a = 0.8
	for k in 6:
		Pecas3D.esfera(fechado, 1.8 + (k % 3) * 0.5, Vector3(-metade + k * 1.4, 1.0 + (k % 2) * 0.8, -2.5 - (k % 3)), nevoa)
	var aviso := Label3D.new()
	aviso.name = "Aviso"
	aviso.font = FONTE
	aviso.font_size = 80
	aviso.pixel_size = 0.005
	aviso.modulate = Color.WHITE
	aviso.outline_size = 14
	aviso.outline_modulate = Color("#45256F")
	aviso.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	aviso.position = Vector3(0, 2.7, 0.6)
	fechado.add_child(aviso)
	var parede := StaticBody3D.new()
	parede.name = "Parede"
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(Regioes.LARGURA_ENTRADA, 4, 0.8)
	forma.shape = caixa
	forma.position.y = 2
	parede.add_child(forma)
	fechado.add_child(parede)
	atualizar_portao(no, r["id"])
	return no


## Abre ou fecha o portão conforme a região está liberada.
static func atualizar_portao(no: Node3D, id: String) -> void:
	var fechado: Node3D = no.get_node("Fechado")
	var aberta := Regioes.liberada(id)
	fechado.visible = not aberta
	var parede: StaticBody3D = fechado.get_node("Parede")
	parede.collision_layer = 0 if aberta else 1
	(fechado.get_node("Aviso") as Label3D).text = "FECHADO\n" + Regioes.texto_requisito(id)


# --- Ilha do Algodão-Doce (oeste) -----------------------------------------------------

static func _ilha(no: Node3D) -> void:
	# Lago de Morango: água rosada com borda de areia de açúcar
	var agua := _m("#FF8FB8", 0.06)
	agua.metallic = 0.2
	agua.emission_enabled = true
	agua.emission = Color("#FF8FB8")
	agua.emission_energy_multiplier = 0.15
	var agua_viva := VisualRealista.liquido("morango", agua, Vector2(LAGO_CENTRO.x, LAGO_CENTRO.z), LAGO_RAIOS)
	var lago := Pecas3D.cilindro(no, 1.0, 1.0, 0.06, LAGO_CENTRO + Vector3(0, 0.04, 0), agua_viva)
	lago.scale = Vector3(LAGO_RAIOS.x, 1, LAGO_RAIOS.y)
	var areia := _m("#F6E3C6", 0.9)
	var borda := Pecas3D.cilindro(no, 1.0, 1.0, 0.05, LAGO_CENTRO + Vector3(0, 0.02, 0), areia)
	borda.scale = Vector3(LAGO_RAIOS.x + 1.5, 1, LAGO_RAIOS.y + 1.5)
	# colisão: postes em volta do lago (menos onde a ponte começa)
	var inicio_ponte := Vector3(LAGO_CENTRO.x + LAGO_RAIOS.x, 0, ILHA_CENTRO.z)
	for i in 64:
		var a := i * TAU / 64.0
		var p := LAGO_CENTRO + Vector3(cos(a) * LAGO_RAIOS.x, 0, sin(a) * LAGO_RAIOS.y)
		if p.distance_to(inicio_ponte) < 3.4:
			continue
		CenarioVila._poste(no, 1.5, 2.0, p)
	# redemoinhos de chantili na água
	for p in [Vector3(-52, 0, -14), Vector3(-84, 0, 18), Vector3(-60, 0, 22), Vector3(-80, 0, -16)]:
		Pecas3D.rosquinha(no, 0.5, 0.9, p + Vector3(0, 0.08, 0), _m("#FFFFFF", 0.4), Vector3(1, 0.25, 1))
	# a ilha
	Pecas3D.cilindro(no, ILHA_RAIO + 0.6, ILHA_RAIO + 1.2, 0.2, ILHA_CENTRO + Vector3(0, 0.06, 0), areia)
	Pecas3D.cilindro(no, ILHA_RAIO - 0.8, ILHA_RAIO, 0.1, ILHA_CENTRO + Vector3(0, 0.14, 0), CenarioVila.gramado())
	var chegada := Vector3(ILHA_CENTRO.x + ILHA_RAIO + 0.6, 0, ILHA_CENTRO.z)
	for i in 28:
		var a := i * TAU / 28.0
		var p := ILHA_CENTRO + Vector3(cos(a), 0, sin(a)) * (ILHA_RAIO + 1.4)
		if p.distance_to(chegada) < 3.0:
			continue
		CenarioVila._poste(no, 1.0, 2.0, p)
	# a ponte de biscoito até a ilha, com corrimão de bengala
	var de := inicio_ponte + Vector3(2.0, 0, 0)
	var ate := chegada + Vector3(-0.5, 0, 0)
	var comprimento := de.distance_to(ate)
	var biscoito := Texturas.real("madeira_pintada", "#D9A35E", 1.0)
	Pecas3D.caixa(no, Vector3(comprimento, 0.12, 3.4), (de + ate) / 2.0 + Vector3(0, 0.1, 0), biscoito)
	for k in int(comprimento / 1.2):
		Pecas3D.caixa(no, Vector3(0.08, 0.13, 3.3), de + Vector3(-k * 1.2 - 0.6, 0.12, 0), _m("#B97A3A", 0.7))
	for lado in [-1, 1]:
		var a := de + Vector3(0, 0, lado * 1.75)
		var b := ate + Vector3(0, 0, lado * 1.75)
		_parede(no, a, b, 0.4)
		for k in int(comprimento / 2.0) + 1:
			var p := a.lerp(b, float(k) / int(comprimento / 2.0))
			Pecas3D.cilindro(no, 0.08, 0.08, 1.1, p + Vector3(0, 0.6, 0), _m("#FFFFFF" if k % 2 == 0 else "#E8364F", 0.35))
		Pecas3D.cano(no, a + Vector3(0, 1.1, 0), b + Vector3(0, 1.1, 0), 0.07, _m("#E8364F", 0.35))
	# árvores de algodão-doce (na ilha e nas margens)
	var cores := ["#FF9EC7", "#9FD4F7", "#FFFFFF", "#C9B3EC"]
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 41
	for p in [Vector3(-66, 0, 8), Vector3(-73, 0, 9), Vector3(-66, 0, -6), Vector3(-77, 0, 1), Vector3(-63, 0, 1)]:
		arvore_algodao(no, p, cores[sorteio.randi() % cores.size()], sorteio.randf_range(0.9, 1.3))
	for i in 26:
		var p := Vector3(sorteio.randf_range(-92, -44), 0, sorteio.randf_range(36, 84))
		if i % 2 == 0:
			p = Vector3(sorteio.randf_range(-92, -44), 0, sorteio.randf_range(-38, -30))
		arvore_algodao(no, p, cores[i % cores.size()], sorteio.randf_range(1.0, 1.6))
	# farol de pirulito
	var farol := Vector3(-74, 0, -4)
	var faixas := Pecas3D.material_textura(Pecas3D.faixas([Color("#FFFFFF"), Color("#E8364F")], 7), 0.35)
	Pecas3D.cilindro(no, 1.0, 1.4, 7.0, farol + Vector3(0, 3.6, 0), faixas)
	Pecas3D.cilindro(no, 1.3, 1.3, 0.2, farol + Vector3(0, 7.1, 0), _m("#5E3D8E", 0.5))
	Pecas3D.cilindro(no, 0.8, 0.8, 1.1, farol + Vector3(0, 7.8, 0), _brilho("#FFE27A", 1.8))
	Pecas3D.cilindro(no, 0.0, 1.2, 1.2, farol + Vector3(0, 8.9, 0), _m("#E8364F", 0.35))
	Pecas3D.esfera(no, 0.25, farol + Vector3(0, 9.6, 0), _m("#FFD23F", 0.3))
	CenarioVila._poste(no, 1.4, 8.0, farol)


## Árvore de algodão-doce: palito de biscoito com nuvens fofas.
static func arvore_algodao(pai: Node3D, p: Vector3, cor: String, tamanho := 1.0) -> void:
	Pecas3D.cilindro(pai, 0.12 * tamanho, 0.16 * tamanho, 2.6 * tamanho, p + Vector3(0, 1.3 * tamanho, 0), _m("#F2D8A7", 0.8))
	var fofo := _m(cor, 0.95)
	for k in 3:
		var a := k * TAU / 3.0
		Pecas3D.esfera(pai, 0.9 * tamanho, p + Vector3(cos(a) * 0.5, 3.0 + (k % 2) * 0.4, sin(a) * 0.5) * tamanho, fofo)
	Pecas3D.esfera(pai, 1.0 * tamanho, p + Vector3(0, 3.6, 0) * tamanho, fofo)
	CenarioVila._poste(pai, 0.3 * tamanho, 3.0, p)


# --- Bosque de Pirulitos (sul) --------------------------------------------------------

static func _bosque(no: Node3D) -> void:
	var v := Regioes.VILA
	# Rio de Calda atravessando de um lado ao outro
	var calda := _m("#C98A3A", 0.05)
	calda.metallic = 0.25
	var largura := v.size.x
	Pecas3D.caixa(no, Vector3(largura, 0.06, RIO_Z.y - RIO_Z.x), Vector3(0, 0.04, (RIO_Z.x + RIO_Z.y) / 2.0),
		VisualRealista.liquido("calda", calda, Vector2.ZERO, Vector2.ZERO, Vector2(1.0, 0.0)))
	for z in [RIO_Z.x - 0.5, RIO_Z.y + 0.5]:
		Pecas3D.caixa(no, Vector3(largura, 0.08, 1.2), Vector3(0, 0.04, z), _m("#F6E3C6", 0.9))
	# colisão nas margens, menos na ponte
	var ponte_de := PONTE_SUL_X - 1.9
	var ponte_ate := PONTE_SUL_X + 1.9
	for z in [RIO_Z.x - 0.4, RIO_Z.y + 0.4]:
		_parede(no, Vector3(v.position.x, 0, z), Vector3(ponte_de, 0, z), 0.4)
		_parede(no, Vector3(ponte_ate, 0, z), Vector3(v.end.x, 0, z), 0.4)
	# ponte em arco de biscoito com corrimão
	var biscoito := Texturas.real("madeira_pintada", "#D9A35E", 1.0)
	var comprimento := RIO_Z.y - RIO_Z.x + 2.0
	Pecas3D.caixa(no, Vector3(3.4, 0.14, comprimento), Vector3(PONTE_SUL_X, 0.1, (RIO_Z.x + RIO_Z.y) / 2.0), biscoito)
	for lado in [-1, 1]:
		var x: float = PONTE_SUL_X + lado * 1.75
		var a := Vector3(x, 0, RIO_Z.x - 1.0)
		var b := Vector3(x, 0, RIO_Z.y + 1.0)
		_parede(no, a, b, 0.4)
		for k in 5:
			Pecas3D.cilindro(no, 0.08, 0.08, 1.1, a.lerp(b, k / 4.0) + Vector3(0, 0.6, 0), _m("#FFFFFF" if k % 2 == 0 else "#7BE07B", 0.35))
		Pecas3D.cano(no, a + Vector3(0, 1.1, 0), b + Vector3(0, 1.1, 0), 0.07, _m("#7BE07B", 0.35))
	CenarioVila.caminho(no, Vector3(PONTE_SUL_X, 0, v.end.y), Vector3(PONTE_SUL_X, 0, RIO_Z.x - 1.0))
	CenarioVila.caminho(no, Vector3(PONTE_SUL_X, 0, RIO_Z.y + 1.0), Vector3(0, 0, 66))
	# bosque de pirulitos e cogumelos de marshmallow
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF", "#FF8A5B"]
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 77
	var colocados := 0
	var tentativas := 0
	while colocados < 46 and tentativas < 600:
		tentativas += 1
		var p := Vector3(sorteio.randf_range(v.position.x + 3, v.end.x - 3), 0, sorteio.randf_range(RIO_Z.y + 4, 85))
		if p.distance_to(Vector3(0, 0, 68)) < 9.0 or absf(p.x - lerpf(PONTE_SUL_X, 0.0, clampf((p.z - 50.0) / 16.0, 0, 1))) < 2.5 and p.z < 66:
			continue  # clareira e caminho livres
		if Regioes.LUGARES_ITENS["bosque"].any(func(q): return q.distance_to(p) < 2.5):
			continue
		colocados += 1
		if colocados % 4 == 0:
			_cogumelo(no, p, sorteio.randf_range(0.8, 1.5))
		else:
			CenarioVila.arvore_pirulito(no, p, cores[colocados % cores.size()])
			CenarioVila._poste(no, 0.4, 3.0, p)
	# clareira: a casa na árvore de pirulito gigante
	var tronco := Vector3(0, 0, 70)
	Pecas3D.cilindro(no, 0.9, 1.3, 7.0, tronco + Vector3(0, 3.5, 0), Texturas.real("madeira_pintada", "#8B5A2B", 1.0))
	Pecas3D.cilindro(no, 3.2, 3.2, 0.3, tronco + Vector3(0, 5.0, 0), Texturas.real("madeira_pintada", "#D9A35E", 1.0))
	Pecas3D.caixa(no, Vector3(3.0, 2.0, 2.6), tronco + Vector3(0, 6.2, 0), Texturas.real("reboco", "#FFE3EE", 0.6))
	var telhado := PrismMesh.new()
	telhado.size = Vector3(3.6, 1.4, 3.2)
	var peca := MeshInstance3D.new()
	peca.mesh = telhado
	peca.material_override = CenarioVila._texturizado("#7BE07B", "telhas", 1.2, 0.6)
	peca.position = tronco + Vector3(0, 7.9, 0)
	no.add_child(peca)
	CenarioVila._janela(no, tronco + Vector3(0, 6.3, 1.32), "#7BE07B")
	for k in 8:  # escada de corda
		Pecas3D.caixa(no, Vector3(0.9, 0.08, 0.1), tronco + Vector3(0, 0.6 + k * 0.55, 1.4), _m("#B97A3A", 0.8))
	for lado in [-1, 1]:
		Pecas3D.cano(no, tronco + Vector3(lado * 0.45, 0.3, 1.4), tronco + Vector3(lado * 0.45, 5.0, 1.4), 0.04, _m("#E9D3A4", 0.9))
	Pecas3D.esfera(no, 4.2, tronco + Vector3(0, 10.4, 0), _m("#FF6FAE", 0.35), Vector3(1, 1, 0.35))
	CenarioVila._poste(no, 1.4, 8.0, tronco)


## Cogumelo de marshmallow com pintinhas.
static func _cogumelo(pai: Node3D, p: Vector3, tamanho: float) -> void:
	Pecas3D.cilindro(pai, 0.25 * tamanho, 0.32 * tamanho, 0.9 * tamanho, p + Vector3(0, 0.45 * tamanho, 0), _m("#FFF6FA", 0.85))
	var chapeu := MeshInstance3D.new()
	var meia := SphereMesh.new()
	meia.radius = 0.8 * tamanho
	meia.height = 0.8 * tamanho
	meia.is_hemisphere = true
	chapeu.mesh = meia
	chapeu.material_override = _m("#FF6FAE", 0.5)
	chapeu.position = p + Vector3(0, 0.85 * tamanho, 0)
	pai.add_child(chapeu)
	for k in 5:
		var a := k * TAU / 5.0
		Pecas3D.esfera(pai, 0.1 * tamanho, p + Vector3(cos(a) * 0.45, 1.3, sin(a) * 0.45) * tamanho, _m("#FFFFFF", 0.5), Vector3(1, 0.5, 1))
	CenarioVila._poste(pai, 0.35 * tamanho, 1.5, p)


# --- Montanha de Sorvete (leste) ------------------------------------------------------

static func _montanha(no: Node3D) -> void:
	var sabores := [["#FFC2DA", "#FFFFFF"], ["#9FD4F7", "#FFFFFF"], ["#A8E6C1", "#FFF1F5"], ["#FFE08A", "#8B4A2B"],
		["#C9B3EC", "#FFFFFF"], ["#FFB36B", "#FFFFFF"]]
	var montanhas := [[Vector3(74, 0, -28), 13.0], [Vector3(90, 0, 0), 12.0], [Vector3(84, 0, 38), 14.0],
		[Vector3(62, 0, 62), 12.0], [Vector3(88, 0, 76), 11.0], [Vector3(52, 0, -32), 8.0], [Vector3(46, 0, 50), 8.0]]
	for i in montanhas.size():
		var centro: Vector3 = montanhas[i][0]
		var raio: float = montanhas[i][1]
		var par: Array = sabores[i % sabores.size()]
		# casquinha de wafer virada (a base) e bolas de sorvete empilhadas
		Pecas3D.cilindro(no, raio * 0.55, raio, raio * 0.9, centro + Vector3(0, raio * 0.45, 0),
			CenarioVila._texturizado(par[0], "glace", 0.3, 0.7))
		_poucas_faces(Pecas3D.esfera(no, raio * 0.62, centro + Vector3(0, raio * 1.05, 0),
			CenarioVila._texturizado(par[1], "glace", 0.3, 0.45), Vector3(1, 0.7, 1)), 24)
		Pecas3D.esfera(no, raio * 0.12, centro + Vector3(0, raio * 1.5, 0), _m("#E8263F", 0.15))
		CenarioVila._poste(no, raio * 0.95, raio, centro)
	# trilha pelo vale até o iglu, e a pista de gelo
	CenarioVila.caminho(no, Vector3(Regioes.VILA.end.x, 0, 2), Vector3(66, 0, 6))
	CenarioVila.caminho(no, Vector3(66, 0, 6), Vector3(62, 0, 22))
	var iglu := Vector3(72, 0, 8)
	var neve := _m("#F7FBFF", 0.6)
	var cupula := MeshInstance3D.new()
	var meia := SphereMesh.new()
	meia.radius = 3.2
	meia.height = 3.2
	meia.is_hemisphere = true
	cupula.mesh = meia
	cupula.material_override = neve
	cupula.position = iglu
	no.add_child(cupula)
	Pecas3D.cilindro(no, 1.1, 1.1, 1.8, iglu + Vector3(-3.0, 0.9, 0), neve, Vector3(1, 1, 1), Vector3(0, 0, 90))
	Pecas3D.cilindro(no, 0.8, 0.8, 0.2, iglu + Vector3(-3.95, 0.9, 0), _m("#5E7BB5", 0.3), Vector3.ONE, Vector3(0, 0, 90))
	for k in 5:  # blocos de açúcar
		Pecas3D.rosquinha(no, 3.15 - k * 0.55, 3.25 - k * 0.55, iglu + Vector3(0, 0.55 + k * 0.55, 0), _m("#DDEBF7", 0.5), Vector3(1, 0.3, 1))
	CenarioVila._poste(no, 3.2, 3.2, iglu)
	var gelo := _m("#CDEBFF", 0.03)
	gelo.metallic = 0.3
	Pecas3D.cilindro(no, 6.0, 6.0, 0.06, Vector3(60, 0.04, 26), gelo)
	Pecas3D.rosquinha(no, 6.0, 6.4, Vector3(60, 0.06, 26), _m("#FFFFFF", 0.5), Vector3(1, 0.3, 1))
	# bonecos de marshmallow
	for p in [Vector3(54, 0, 12), Vector3(76, 0, 20), Vector3(68, 0, -10)]:
		Pecas3D.esfera(no, 0.7, p + Vector3(0, 0.7, 0), _m("#FFFFFF", 0.8))
		Pecas3D.esfera(no, 0.5, p + Vector3(0, 1.75, 0), _m("#FFFFFF", 0.8))
		Pecas3D.esfera(no, 0.36, p + Vector3(0, 2.5, 0), _m("#FFFFFF", 0.8))
		Pecas3D.cilindro(no, 0.0, 0.06, 0.35, p + Vector3(0, 2.5, 0.45), _m("#FF8A1F", 0.5), Vector3.ONE, Vector3(90, 0, 0))
		CenarioVila._poste(no, 0.7, 2.8, p)


# --- Borda do mundo e coisinhas -------------------------------------------------------

## Morros de sorvete do lado de fora da borda do mundo (o horizonte).
static func morros_borda(pai: Node3D) -> void:
	var m := Regioes.MUNDO
	var sorvetes := [["#FFC2DA", "#FFFFFF"], ["#C9B3EC", "#FFF1F5"], ["#A8E6C1", "#FFFFFF"], ["#FFE08A", "#8B4A2B"], ["#9FD4F7", "#FFFFFF"]]
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 99
	var pontos := []
	for x in range(int(m.position.x), int(m.end.x) + 1, 22):
		pontos.append(Vector3(x, 0, m.position.y - 9))
		pontos.append(Vector3(x, 0, m.end.y + 9))
	for z in range(int(m.position.y), int(m.end.y) + 1, 22):
		pontos.append(Vector3(m.position.x - 9, 0, z))
		pontos.append(Vector3(m.end.x + 9, 0, z))
	for i in pontos.size():
		var tamanho := sorteio.randf_range(8.0, 13.0)
		var centro: Vector3 = pontos[i] + Vector3(sorteio.randf_range(-3, 3), -tamanho * 0.35, sorteio.randf_range(-3, 3))
		var par: Array = sorvetes[i % sorvetes.size()]
		# (longe: poucas faces; metade fica enterrada)
		_poucas_faces(Pecas3D.esfera(pai, tamanho, centro, CenarioVila._texturizado(par[0], "glace", 0.35, 0.7), Vector3(1, 0.75, 1)), 18)
		_poucas_faces(Pecas3D.esfera(pai, tamanho * 0.62, centro + Vector3(0, tamanho * 0.52, 0),
			CenarioVila._texturizado(par[1], "glace", 0.35, 0.4), Vector3(1, 0.45, 1)), 16)


## Menos faces numa bola grande que fica longe.
static func _poucas_faces(no: MeshInstance3D, lados: int) -> void:
	var bola := no.mesh as SphereMesh
	bola.radial_segments = lados
	bola.rings = lados / 2


## Uma coisinha para pegar (concha, morango ou cristal), girando e flutuando.
static func item(pai: Node3D, regiao: String, posicao: Vector3) -> Node3D:
	var no := Node3D.new()
	no.position = posicao
	pai.add_child(no)
	var desenho := Node3D.new()
	desenho.name = "Desenho"
	desenho.position.y = 0.6
	no.add_child(desenho)
	match regiao:
		"ilha":  # concha: leque rosado com a base
			Pecas3D.esfera(desenho, 0.26, Vector3.ZERO, _brilho("#FFC2DA", 0.5), Vector3(1.2, 0.9, 0.35))
			Pecas3D.esfera(desenho, 0.1, Vector3(0, -0.2, 0), _brilho("#FFE3EE", 0.5), Vector3(1.4, 0.7, 0.5))
		"bosque":  # morango com as folhinhas
			Pecas3D.esfera(desenho, 0.22, Vector3.ZERO, _brilho("#E8364F", 0.4), Vector3(1, 1.15, 1))
			Pecas3D.esfera(desenho, 0.16, Vector3(0, 0.22, 0), _m("#3FA34D", 0.6), Vector3(1.4, 0.35, 1.4))
		_:
			var cristal := MeshInstance3D.new()
			var forma := SphereMesh.new()
			forma.radial_segments = 4
			forma.rings = 2
			forma.radius = 0.22
			forma.height = 0.7
			cristal.mesh = forma
			cristal.material_override = _brilho("#BFE6FF", 1.2)
			desenho.add_child(cristal)
	return no
