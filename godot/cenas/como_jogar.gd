extends Control
## Como jogar: passo a passo e os títulos de doceiro.

const PASSOS := [
	{"icone": "camadas", "titulo": "ESCOLHA O NÍVEL",
		"texto": "Fácil, médio ou difícil: cada nível tem 10 perguntas sobre Word e Excel."},
	{"icone": "relogio", "titulo": "RESPONDA RÁPIDO",
		"texto": "Você tem 30 segundos por pergunta. Se o tempo acabar, conta como erro."},
	{"icone": "grafico", "titulo": "VEJA O RESULTADO",
		"texto": "No fim, você confere cada resposta e o seu aproveitamento."},
	{"icone": "trofeu", "titulo": "GANHE SEU TÍTULO",
		"texto": "Quanto maior o aproveitamento, mais doce é o título que você leva!"},
]
const FAIXAS := [
	{"personagem": "brigadeiro_triste", "faixa": "ATÉ 30%", "nome": "AINDA NÃO É DOCEIRO"},
	{"personagem": "maca_noob", "faixa": "40 A 50%", "nome": "DOCEIRO NOOB"},
	{"personagem": "cupcake_pro", "faixa": "60 A 80%", "nome": "DOCEIRO PRO"},
	{"personagem": "chocolate_mestre", "faixa": "90 A 100%", "nome": "DOCEIRO MESTRE"},
]


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	%Jogar.pressed.connect(Jogo.ir_para.bind("niveis"))
	for i in PASSOS.size():
		var cartao := _criar_passo(i + 1, PASSOS[i])
		%Passos.add_child(cartao)
		Animacoes.entrar(cartao, Vector2(0, 40), 0.07 * i)
	for faixa in FAIXAS:
		%Faixas.add_child(_criar_faixa(faixa))
	Animacoes.entrar(%Coluna.get_node("Titulos"), Vector2(0, 40), 0.3)


func _criar_passo(numero: int, passo: Dictionary) -> PanelContainer:
	var cartao := PanelContainer.new()
	cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	cartao.add_child(coluna)

	var topo := HBoxContainer.new()
	coluna.add_child(topo)
	var bolinha := PanelContainer.new()
	bolinha.theme_type_variation = &"PainelRoxo"
	bolinha.custom_minimum_size = Vector2(60, 60)
	var num := Label.new()
	num.theme_type_variation = &"TituloClaro"
	num.text = str(numero)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bolinha.add_child(num)
	bolinha.add_theme_stylebox_override("panel", _circulo(Cores.ROXO))
	topo.add_child(bolinha)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(espaco)
	var icone := TextureRect.new()
	icone.texture = load("res://assets/icones/%s.svg" % passo["icone"])
	icone.modulate = Cores.ROXO
	icone.custom_minimum_size = Vector2(60, 60)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	topo.add_child(icone)

	var titulo := Label.new()
	titulo.theme_type_variation = &"Subtitulo"
	titulo.add_theme_font_size_override("font_size", 38)
	titulo.text = passo["titulo"]
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(titulo)
	var texto := Label.new()
	texto.theme_type_variation = &"Texto"
	texto.add_theme_font_size_override("font_size", 22)
	texto.text = passo["texto"]
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(100, 0)
	coluna.add_child(texto)
	return cartao


func _criar_faixa(faixa: Dictionary) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_theme_constant_override("separation", 8)
	var imagem := TextureRect.new()
	imagem.texture = Personagens.textura(faixa["personagem"])
	imagem.custom_minimum_size = Vector2(72, 84)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(imagem)
	var textos := VBoxContainer.new()
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", -2)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(textos)
	var porcentagem := Label.new()
	porcentagem.theme_type_variation = &"TituloClaro"
	porcentagem.add_theme_font_size_override("font_size", 32)
	porcentagem.text = faixa["faixa"]
	textos.add_child(porcentagem)
	var nome := Label.new()
	nome.theme_type_variation = &"TextoClaro"
	nome.add_theme_font_size_override("font_size", 15)
	nome.text = faixa["nome"]
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size = Vector2(90, 0)
	textos.add_child(nome)
	return linha


func _circulo(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(999)
	return estilo
