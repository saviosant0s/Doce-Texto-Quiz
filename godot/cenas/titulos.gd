extends Control
## Títulos de doceiro em forma de pódio: Mestre no centro, Pro e Noob dos lados.

const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")

## Na ordem em que aparecem no pódio (da esquerda para a direita).
const TITULOS := [
	{"id": "pro", "nome": "PRO", "personagem": "cupcake_pro", "meta": "60 A 80%",
		"altura": 150, "tamanho": 230, "cor": Color("#E4DCF2")},
	{"id": "mestre", "nome": "MESTRE", "personagem": "chocolate_mestre", "meta": "90 A 100%",
		"altura": 210, "tamanho": 270, "cor": Cores.AMARELO},
	{"id": "noob", "nome": "NOOB", "personagem": "maca_noob", "meta": "40 A 50%",
		"altura": 105, "tamanho": 210, "cor": Color("#F1B874")},
]


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	%Quantidade.text = "%d MOEDAS" % Jogo.moedas
	for i in TITULOS.size():
		var coluna := _criar_coluna(TITULOS[i])
		%Podio.add_child(coluna)
		Animacoes.entrar(coluna, Vector2(0, 80), 0.1 * i)


func _criar_coluna(titulo: Dictionary) -> VBoxContainer:
	var quantidade: int = Jogo.titulos[titulo["id"]]
	var conquistado := quantidade > 0

	var coluna := VBoxContainer.new()
	coluna.custom_minimum_size = Vector2(330, 0)
	coluna.alignment = BoxContainer.ALIGNMENT_END
	coluna.add_theme_constant_override("separation", 0)

	# Personagem (silhueta com cadeado se ainda não foi conquistado)
	var imagem := TextureRect.new()
	imagem.texture = Personagens.textura(titulo["personagem"])
	imagem.custom_minimum_size = Vector2(0, titulo["tamanho"])
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coluna.add_child(imagem)
	if conquistado:
		Animacoes.flutuar.call_deferred(imagem, 8.0)  # depois de entrar na tela
	else:
		imagem.self_modulate = Color(0.22, 0.13, 0.36, 0.85)
		var cadeado := TextureRect.new()
		cadeado.texture = ICONE_CADEADO
		cadeado.modulate = Cores.AMARELO
		cadeado.custom_minimum_size = Vector2(64, 64)
		cadeado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cadeado.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cadeado.set_anchors_preset(Control.PRESET_CENTER)
		cadeado.offset_left = -32
		cadeado.offset_top = -32
		cadeado.offset_right = 32
		cadeado.offset_bottom = 32
		imagem.add_child(cadeado)

	# Degrau do pódio
	var degrau := PanelContainer.new()
	degrau.custom_minimum_size = Vector2(0, titulo["altura"])
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = titulo["cor"]
	estilo.corner_radius_top_left = 22
	estilo.corner_radius_top_right = 22
	estilo.border_width_top = 8
	estilo.border_color = titulo["cor"].lightened(0.35)
	estilo.set_content_margin_all(12)
	degrau.add_theme_stylebox_override("panel", estilo)
	coluna.add_child(degrau)

	var textos := VBoxContainer.new()
	textos.alignment = BoxContainer.ALIGNMENT_BEGIN
	textos.add_theme_constant_override("separation", 0)
	degrau.add_child(textos)
	var nome := Label.new()
	nome.theme_type_variation = &"Titulo"
	nome.add_theme_font_size_override("font_size", 46)
	nome.text = "DOCEIRO " + titulo["nome"]
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	textos.add_child(nome)
	var detalhe := Label.new()
	detalhe.theme_type_variation = &"Subtitulo"
	detalhe.add_theme_font_size_override("font_size", 26)
	detalhe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if conquistado:
		detalhe.text = "CONQUISTADO %dX" % quantidade
	else:
		detalhe.text = "ACERTE %s EM UMA PARTIDA" % titulo["meta"]
		detalhe.modulate = Color(1, 1, 1, 0.75)
	detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(detalhe)
	return coluna
