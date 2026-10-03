class_name Itens3D
## Itens do jogo (moeda, açúcar, XP e baús) feitos em 3D no mesmo estilo dos
## doces personagens (mesma luz, brilho e contorno), para o jogo ter uma cara
## só. As "fotos" deles (assets/itens/*.png) são o que as telas mostram; gere
## de novo com ferramentas/gerar_itens_3d.sh depois de mudar algo aqui.
## Uso nas telas: as constantes da classe Itens (scripts/itens.gd).

const IDS := ["moeda", "acucar", "xp", "estrela", "bau_doce", "bau_prata", "bau_ouro",
	"bau_madeira", "bau_chefe", "bau_aberto", "bau_aberto_doce", "bau_aberto_prata", "bau_aberto_ouro"]

## Cores dos baús: [corpo, tampa, faixas, metal (0 a 1)].
const BAUS := {
	"bau_doce": ["#E8559A", "#FF8CC4", "#FFD84A", 0.1],
	"bau_prata": ["#8E9DB2", "#C3CFDE", "#F4F8FC", 0.55],
	"bau_ouro": ["#E09A0B", "#FFC62E", "#FFF0A0", 0.55],
	"bau_madeira": ["#9A5A26", "#C47A3A", "#F4C542", 0.0],
	"bau_chefe": ["#7A45C9", "#A77BEA", "#FFD84A", 0.1],
	"bau_aberto": ["#9A5A26", "#C47A3A", "#F4C542", 0.0],
	"bau_aberto_doce": ["#E8559A", "#FF8CC4", "#FFD84A", 0.1],
	"bau_aberto_prata": ["#8E9DB2", "#C3CFDE", "#F4F8FC", 0.55],
	"bau_aberto_ouro": ["#E09A0B", "#FFC62E", "#FFF0A0", 0.55],
}


static func existe(id: String) -> bool:
	return id in IDS


static func montar(id: String, c: Node3D) -> void:
	match id:
		"moeda":
			_moeda(c)
		"acucar":
			_acucar(c)
		"xp":
			_xp(c)
		"estrela":
			_estrela(c)
		_:
			var tipo: String = id.trim_prefix("bau_aberto_").trim_prefix("bau_")
			_bau(c, BAUS[id], id.begins_with("bau_aberto"), "madeira" if id == "bau_aberto" else tipo)


static func _m(cor: String, aspereza := 0.3, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


## Moeda de ouro com uma bala em relevo no meio (a "moeda de doce").
static func _moeda(c: Node3D) -> void:
	var ouro := _m("#FFCB2E", 0.2, 0.25)
	var borda := _m("#F2A516", 0.22, 0.3)
	var relevo := _m("#FFF0A8", 0.2, 0.2)
	var no := Node3D.new()
	no.rotation_degrees = Vector3(0, 38, -8)
	c.add_child(no)
	Pecas3D.cilindro(no, 0.82, 0.82, 0.2, Vector3.ZERO, ouro, Vector3.ONE, Vector3(90, 0, 0))
	for z in [-0.1, 0.1]:
		Pecas3D.rosquinha(no, 0.7, 0.84, Vector3(0, 0, z), borda, Vector3(1, 0.6, 1), Vector3(90, 0, 0))
	# bala embrulhada no centro
	Pecas3D.esfera(no, 0.24, Vector3(0, 0, 0.12), relevo, Vector3(1.35, 1.0, 0.45))
	for lado in [-1, 1]:
		Pecas3D.cilindro(no, 0.0, 0.17, 0.2, Vector3(lado * 0.4, 0, 0.1), relevo, Vector3(1, 1, 0.4), Vector3(0, 0, -90 * lado))
	# brilho
	Pecas3D.esfera(no, 0.07, Vector3(-0.42, 0.42, 0.13), _m("#FFFFFF", 0.1), Vector3(1, 1, 0.3))


## Dois cubinhos de açúcar com cristais brilhando em volta.
static func _acucar(c: Node3D) -> void:
	var acucar := _m("#F4F1EA", 0.9)
	var sombra := _m("#E6EEFB", 0.9)
	Pecas3D.caixa(c, Vector3(0.9, 0.9, 0.9), Vector3(-0.22, -0.3, 0), acucar, Vector3(28, 40, 12))
	Pecas3D.caixa(c, Vector3(0.72, 0.72, 0.72), Vector3(0.36, 0.42, -0.2), sombra, Vector3(-30, -25, 28))
	var cristal := _m("#DDF3FF", 0.05, 0.2)
	var pontos := [Vector3(0.72, -0.55, 0.3), Vector3(-0.85, 0.35, 0.2), Vector3(0.75, 0.05, 0.4), Vector3(-0.55, -0.85, 0.4)]
	for i in pontos.size():
		Pecas3D.caixa(c, Vector3.ONE * (0.16 - i * 0.02), pontos[i], cristal, Vector3(45, 30 * i, 45))
	for p in [Vector3(-0.35, 0.3, 0.52), Vector3(0.62, 0.62, 0.35)]:
		Pecas3D.esfera(c, 0.05, p, _m("#FFFFFF", 0.05))


## XP: uma estrela de bala roxa, gordinha, com "XP" em amarelo.
static func _xp(c: Node3D) -> void:
	var instancia := MeshInstance3D.new()
	instancia.mesh = _malha_estrela(0.95, 0.45, 0.22, 0.2)
	instancia.material_override = _m("#8E4FE0", 0.2)
	instancia.rotation_degrees = Vector3(0, 30, -6)
	c.add_child(instancia)
	var texto := Label3D.new()
	texto.text = "XP"
	texto.font = load("res://assets/fontes/BebasNeue-Regular.ttf")
	texto.font_size = 120
	texto.pixel_size = 0.0055
	texto.modulate = Color("#FFE23A")
	texto.outline_modulate = Color("#4A2380")
	texto.outline_size = 24
	texto.position = Vector3(0, -0.02, 0.44)
	instancia.add_child(texto)
	Pecas3D.esfera(instancia, 0.07, Vector3(-0.28, 0.42, 0.3), _m("#FFFFFF", 0.1), Vector3(1, 1, 0.4))


## Estrela de ouro (a nota das fases e partidas), gordinha como bala.
static func _estrela(c: Node3D) -> void:
	var instancia := MeshInstance3D.new()
	instancia.mesh = _malha_estrela(0.95, 0.45, 0.22, 0.24)
	instancia.material_override = _m("#FFC21A", 0.18, 0.2)
	instancia.rotation_degrees = Vector3(0, 22, -4)
	c.add_child(instancia)
	Pecas3D.esfera(instancia, 0.08, Vector3(-0.25, 0.4, 0.32), _m("#FFFFFF", 0.1), Vector3(1, 1, 0.4))


## Estrela de 5 pontas com volume: a frente e as costas sobem para o centro
## (como uma bala estufada).
static func _malha_estrela(fora: float, dentro: float, espessura: float, estufado: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var borda: Array[Vector2] = []
	for i in 10:
		var r := fora if i % 2 == 0 else dentro
		var a := PI / 2 + i * TAU / 10
		borda.append(Vector2(cos(a), sin(a)) * r)
	for lado in [1, -1]:
		var centro := Vector3(0, 0, lado * (espessura / 2 + estufado))
		for i in 10:
			var a := borda[i]
			var b := borda[(i + 1) % 10]
			var va := Vector3(a.x, a.y, lado * espessura / 2)
			var vb := Vector3(b.x, b.y, lado * espessura / 2)
			if lado == 1:
				st.add_vertex(centro)
				st.add_vertex(vb)
				st.add_vertex(va)
			else:
				st.add_vertex(centro)
				st.add_vertex(va)
				st.add_vertex(vb)
	for i in 10:
		var a := borda[i]
		var b := borda[(i + 1) % 10]
		var fa := Vector3(a.x, a.y, espessura / 2)
		var fb := Vector3(b.x, b.y, espessura / 2)
		var ta := Vector3(a.x, a.y, -espessura / 2)
		var tb := Vector3(b.x, b.y, -espessura / 2)
		st.add_vertex(fa)
		st.add_vertex(fb)
		st.add_vertex(tb)
		st.add_vertex(fa)
		st.add_vertex(tb)
		st.add_vertex(ta)
	st.generate_normals()
	return st.commit()


## Baú de tesouro caprichado: corpo de tábuas, tampa curva, cantoneiras e
## faixas de metal com rebites, alças, fechadura grande em coração e joias.
## Fechado, uma luz escapa pela fresta da tampa ("tem coisa boa aí dentro").
## Aberto: tampa levantada, luz forte saindo e o tesouro aparecendo.
## Cada tipo tem um enfeite: doce (listras e laço), prata (safira), ouro
## (rubi e coroa), chefe (coroa e ametista), madeira (simples).
static func _bau(c: Node3D, cores: Array, aberto: bool, tipo := "") -> void:
	var metal: float = cores[3]
	var corpo := _m(cores[0], 0.4, metal)
	var tampa_mat := _m(cores[1], 0.3, metal)
	var faixa := _m(cores[2], 0.25, 0.3)
	var escuro := _m("#2A1540", 0.5)
	if tipo == "doce":
		corpo = Pecas3D.material_textura(Pecas3D.listras([Color(cores[0]), Color("#FFF1F6")], 10), 0.35)
	var no := Node3D.new()
	no.rotation_degrees = Vector3(14, 38, 0)
	no.position = Vector3(0, -0.25, 0)
	c.add_child(no)
	var largura := 1.6
	var fundo := 1.0
	var altura := 0.85
	Pecas3D.caixa(no, Vector3(largura, altura, fundo), Vector3(0, -0.1, 0), corpo)
	# tábuas (frisos) no corpo
	if tipo != "doce":
		for y in [-0.33, -0.1, 0.13]:
			Pecas3D.caixa(no, Vector3(largura + 0.01, 0.025, fundo + 0.01), Vector3(0, y, 0), _escurecido(cores[0]))
	# cantoneiras de metal nos 4 cantos de baixo e rebites
	for x in [-1, 1]:
		for z in [-1, 1]:
			var canto := Vector3(x * (largura / 2 - 0.08), -0.1, z * (fundo / 2 - 0.08))
			Pecas3D.caixa(no, Vector3(0.2, altura + 0.04, 0.2), canto, faixa)
	for x in [-0.5, 0.5]:
		Pecas3D.caixa(no, Vector3(0.16, altura + 0.02, fundo + 0.06), Vector3(x, -0.1, 0), faixa)
		for y in [-0.4, -0.1, 0.2]:
			Pecas3D.esfera(no, 0.035, Vector3(x, y, fundo / 2 + 0.05), escuro)
	# alças nas laterais
	for x in [-1, 1]:
		Pecas3D.rosquinha(no, 0.07, 0.16, Vector3(x * (largura / 2 + 0.05), -0.05, 0), faixa, Vector3.ONE, Vector3(0, 0, 90))
	# tampa: meio cilindro deitado, com faixas e joia em cima
	var dobradica := Node3D.new()
	dobradica.position = Vector3(0, 0.32, -fundo / 2)
	if aberto:
		dobradica.rotation_degrees = Vector3(-75, 0, 0)
	no.add_child(dobradica)
	var tampa := Node3D.new()
	tampa.position = Vector3(0, 0, fundo / 2)
	dobradica.add_child(tampa)
	Pecas3D.cilindro(tampa, fundo / 2, fundo / 2, largura, Vector3.ZERO, tampa_mat, Vector3(1, 0.8, 1), Vector3(0, 0, 90))
	Pecas3D.caixa(tampa, Vector3(largura, 0.08, fundo), Vector3(0, -0.04, 0), tampa_mat)
	for x in [-0.5, 0.5]:
		Pecas3D.cilindro(tampa, fundo / 2 + 0.03, fundo / 2 + 0.03, 0.16, Vector3(x, 0, 0), faixa, Vector3(1, 0.8, 1), Vector3(0, 0, 90))
	for x in [-1, 1]:
		Pecas3D.cilindro(tampa, fundo / 2 + 0.04, fundo / 2 + 0.04, 0.12, Vector3(x * (largura / 2 - 0.06), 0, 0), faixa,
			Vector3(1, 0.8, 1), Vector3(0, 0, 90))
	var joia_cor: String = {"prata": "#3E8EF0", "ouro": "#E8263F", "chefe": "#A45CE6", "doce": "#FFFFFF"}.get(tipo, "")
	if joia_cor != "":
		var joia := _brilho(joia_cor, 0.5)
		joia.roughness = 0.05
		# joia na frente da tampa, bem à vista, com moldura
		Pecas3D.esfera(tampa, 0.15, Vector3(0, 0.2, 0.4), joia, Vector3(1, 1, 0.6))
		Pecas3D.rosquinha(tampa, 0.12, 0.2, Vector3(0, 0.2, 0.37), faixa, Vector3.ONE, Vector3(90, 0, 0))
	if tipo == "ouro" or tipo == "chefe":
		_coroinha(tampa, Vector3(0, 0.52, 0.05), faixa)
	if tipo == "doce":
		for lado in [-1, 1]:
			Pecas3D.esfera(tampa, 0.18, Vector3(lado * 0.2, 0.46, 0.05), _m("#FF4F8B", 0.3), Vector3(1.3, 0.7, 0.5), Vector3(0, 0, lado * 25))
		Pecas3D.esfera(tampa, 0.09, Vector3(0, 0.45, 0.07), _m("#FF7AA8", 0.3))
	Pecas3D.caixa(no, Vector3(largura + 0.06, 0.12, fundo + 0.06), Vector3(0, 0.3, 0), faixa)
	if aberto:
		# luz forte saindo e o tesouro aparecendo
		var luz := _brilho("#FFD23F", 2.2)
		Pecas3D.caixa(no, Vector3(largura - 0.1, 0.05, fundo - 0.1), Vector3(0, 0.3, 0), luz)
		var moeda := _m("#FFC83D", 0.25, 0.8)
		for i in 9:
			Pecas3D.cilindro(no, 0.12, 0.12, 0.04, Vector3(-0.55 + (i % 5) * 0.27, 0.36 + (i / 5) * 0.05, -0.2 + (i % 3) * 0.15),
				moeda, Vector3.ONE, Vector3(20 * (i % 3), 0, 15 * (i % 2)))
		var cores_joias := ["#E8263F", "#3E8EF0", "#3DDC97", "#A45CE6"]
		for i in 4:
			Pecas3D.esfera(no, 0.09, Vector3(-0.45 + i * 0.3, 0.45, 0.1 - (i % 2) * 0.2), _brilho(cores_joias[i], 0.6))
	else:
		# luz escapando pela fresta da tampa
		Pecas3D.caixa(no, Vector3(largura - 0.3, 0.05, 0.02), Vector3(0, 0.33, fundo / 2 + 0.035), _brilho("#FFB800", 3.0))
		# fechadura grande em coração, com buraco de fechadura
		var placa := Node3D.new()
		placa.position = Vector3(0, 0.2, fundo / 2 + 0.07)
		no.add_child(placa)
		for lado in [-1, 1]:
			Pecas3D.esfera(placa, 0.13, Vector3(lado * 0.1, 0.08, 0), faixa, Vector3(1, 1, 0.45))
		Pecas3D.cilindro(placa, 0.0, 0.2, 0.28, Vector3(0, -0.1, 0), faixa, Vector3(1, 1, 0.45), Vector3(180, 0, 0))
		Pecas3D.esfera(placa, 0.045, Vector3(0, 0.02, 0.06), escuro)
		Pecas3D.caixa(placa, Vector3(0.035, 0.1, 0.02), Vector3(0, -0.05, 0.06), escuro)


static func _escurecido(cor: String) -> StandardMaterial3D:
	return _m(Color(cor).darkened(0.25).to_html(), 0.6)


static func _brilho(cor: String, forca: float) -> StandardMaterial3D:
	var mat := _m(cor, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(cor)
	mat.emission_energy_multiplier = forca
	return mat


static func _coroinha(pai: Node3D, posicao: Vector3, mat: Material) -> void:
	Pecas3D.cilindro(pai, 0.2, 0.18, 0.1, posicao, mat)
	for i in 5:
		var angulo := TAU * i / 5.0
		Pecas3D.cilindro(pai, 0.0, 0.05, 0.14, posicao + Vector3(cos(angulo) * 0.17, 0.11, sin(angulo) * 0.17), mat)