class_name Itens3D
## Itens do jogo (moeda, açúcar, XP e baús) feitos em 3D no mesmo estilo dos
## doces personagens (mesma luz, brilho e contorno), para o jogo ter uma cara
## só. As "fotos" deles (assets/itens/*.png) são o que as telas mostram; gere
## de novo com ferramentas/gerar_itens_3d.sh depois de mudar algo aqui.
## Uso nas telas: as constantes da classe Itens (scripts/itens.gd).

const IDS := ["moeda", "acucar", "xp", "bau_doce", "bau_prata", "bau_ouro",
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
		_:
			_bau(c, BAUS[id], id.begins_with("bau_aberto"))


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


## Baú arredondado: corpo, tampa curva, faixas, fechadura. Aberto: a tampa
## levantada e um brilho dourado saindo de dentro.
static func _bau(c: Node3D, cores: Array, aberto: bool) -> void:
	var metal: float = cores[3]
	var corpo := _m(cores[0], 0.35, metal)
	var tampa_mat := _m(cores[1], 0.3, metal)
	var faixa := _m(cores[2], 0.25, 0.5)
	var no := Node3D.new()
	no.rotation_degrees = Vector3(14, 48, 0)
	no.position = Vector3(0, -0.2, 0)
	c.add_child(no)
	var largura := 1.6
	var fundo := 1.0
	Pecas3D.caixa(no, Vector3(largura, 0.85, fundo), Vector3(0, -0.1, 0), corpo)
	# tampa: meio cilindro deitado (o de baixo fica escondido no corpo)
	var dobradica := Node3D.new()
	dobradica.position = Vector3(0, 0.32, -fundo / 2)
	if aberto:
		dobradica.rotation_degrees = Vector3(-70, 0, 0)
	no.add_child(dobradica)
	var tampa := Node3D.new()
	tampa.position = Vector3(0, 0, fundo / 2)
	dobradica.add_child(tampa)
	Pecas3D.cilindro(tampa, fundo / 2, fundo / 2, largura, Vector3.ZERO, tampa_mat, Vector3(1, 0.8, 1), Vector3(0, 0, 90))
	Pecas3D.caixa(tampa, Vector3(largura, 0.08, fundo), Vector3(0, -0.04, 0), tampa_mat)
	for x in [-0.5, 0.5]:
		Pecas3D.cilindro(tampa, fundo / 2 + 0.03, fundo / 2 + 0.03, 0.16, Vector3(x, 0, 0), faixa, Vector3(1, 0.8, 1), Vector3(0, 0, 90))
		Pecas3D.caixa(no, Vector3(0.16, 0.87, fundo + 0.06), Vector3(x, -0.1, 0), faixa)
	Pecas3D.caixa(no, Vector3(largura + 0.06, 0.12, fundo + 0.06), Vector3(0, 0.3, 0), faixa)
	if aberto:
		var brilho := _m("#FFE27A", 0.2, 0.3)
		brilho.emission_enabled = true
		brilho.emission = Color("#FFD23F")
		brilho.emission_energy_multiplier = 0.6
		for i in 5:
			Pecas3D.esfera(no, 0.2, Vector3(-0.5 + i * 0.25, 0.32 + (i % 2) * 0.08, 0.05 * (i % 3)), brilho)
	else:
		# fechadura
		Pecas3D.caixa(no, Vector3(0.34, 0.4, 0.1), Vector3(0, 0.22, fundo / 2 + 0.05), faixa)
		Pecas3D.cilindro(no, 0.06, 0.06, 0.12, Vector3(0, 0.26, fundo / 2 + 0.1), _m("#3B1F66", 0.4), Vector3.ONE, Vector3(90, 0, 0))
