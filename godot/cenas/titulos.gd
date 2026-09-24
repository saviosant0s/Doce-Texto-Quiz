extends Control
## Quantas vezes o jogador conquistou cada título de doceiro.

const TITULOS := [
	{"id": "noob", "nome": "NOOB", "personagem": "maca_noob"},
	{"id": "pro", "nome": "PRO", "personagem": "cupcake_pro"},
	{"id": "mestre", "nome": "MESTRE", "personagem": "chocolate_mestre"},
]


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	for i in TITULOS.size():
		var cartao := _criar_cartao(TITULOS[i])
		%Cartoes.add_child(cartao)
		Animacoes.entrar(cartao, Vector2(0, 50), 0.08 * i)


func _criar_cartao(titulo: Dictionary) -> PanelContainer:
	var quantidade: int = Jogo.titulos[titulo["id"]]
	var cartao := PanelContainer.new()
	cartao.custom_minimum_size = Vector2(290, 0)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	cartao.add_child(coluna)

	var imagem := TextureRect.new()
	imagem.texture = load("res://assets/personagens/%s.png" % titulo["personagem"])
	imagem.custom_minimum_size = Vector2(0, 220)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if quantidade == 0:
		imagem.modulate = Color(0.45, 0.32, 0.62, 0.55)  # silhueta: ainda não conquistado
	coluna.add_child(imagem)

	var nome := Label.new()
	nome.theme_type_variation = &"Titulo"
	nome.text = "DOCEIRO " + titulo["nome"]
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(nome)

	var caixa := PanelContainer.new()
	caixa.theme_type_variation = &"PainelRoxo"
	var contador := Label.new()
	contador.theme_type_variation = &"SubtituloClaro"
	contador.text = "CONQUISTADO %dX" % quantidade if quantidade > 0 else "AINDA NÃO CONQUISTADO"
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(contador)
	coluna.add_child(caixa)
	return cartao
