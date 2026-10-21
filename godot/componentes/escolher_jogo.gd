class_name EscolherJogo
extends Control
## Janela "GANHAR AÇÚCAR E MOEDAS": os jogos que dão açúcar (para as máquinas
## da Confeitaria) e moedas, em cartões grandes com o desenho de cada um. Abre
## por cima da tela atual (Telas.mostrar_escolha_de_jogo); o jogo escolhido abre
## lembrando a tela de `origem`, e no fim o jogador volta para ela (no quiz, o
## botão do resultado vira "CONFEITARIA", ver Telas.origem).

const JOGOS := [
	{"cena": "niveis", "nome": "QUIZ", "icone": preload("res://assets/icones/interrogacao.svg"), "cor": "#7B4FC9"},
	{"cena": "corrida", "nome": "CORRIDA", "icone": preload("res://assets/icones/bandeira.svg"), "cor": "#E8364F"},
	{"cena": "torre", "nome": "TORRE", "icone": preload("res://assets/icones/torre.svg"), "cor": "#FF6FAE"},
	{"cena": "fabrica", "nome": "FÁBRICA", "icone": preload("res://assets/icones/fabrica.svg"), "cor": "#B06A45"},
	{"cena": "doce_match", "nome": "DOCE MATCH", "icone": preload("res://assets/icones/controle.svg"), "cor": "#2E9BE8"},
]

var origem := ""


func _ready() -> void:
	name = "EscolherJogo"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var escurecer := ColorRect.new()
	escurecer.color = Color(0.1, 0.05, 0.18, 0.6)
	escurecer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escurecer.gui_input.connect(func(evento):
		if evento is InputEventMouseButton and evento.pressed:
			fechar())  # tocar fora = fechar
	add_child(escurecer)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var cartao := PanelContainer.new()
	cartao.name = "Cartao"
	centro.add_child(cartao)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	cartao.add_child(coluna)
	var topo := HBoxContainer.new()
	coluna.add_child(topo)
	var titulo := HBoxContainer.new()
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.alignment = BoxContainer.ALIGNMENT_CENTER
	titulo.add_theme_constant_override("separation", 10)
	topo.add_child(titulo)
	for icone in [Itens.ACUCAR, Itens.MOEDA]:
		var imagem := TextureRect.new()
		imagem.texture = icone
		imagem.custom_minimum_size = Vector2(40, 40)
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		titulo.add_child(imagem)
	var texto := Label.new()
	texto.text = "GANHAR AÇÚCAR E MOEDAS"
	texto.add_theme_font_size_override("font_size", 38)
	titulo.add_child(texto)
	var fechar_botao := Button.new()
	fechar_botao.name = "Fechar"
	fechar_botao.text = "X"
	fechar_botao.custom_minimum_size = Vector2(60, 60)
	fechar_botao.theme_type_variation = &"BotaoSecundario"
	fechar_botao.pressed.connect(fechar)
	topo.add_child(fechar_botao)
	var grade := HBoxContainer.new()
	grade.add_theme_constant_override("separation", 14)
	coluna.add_child(grade)
	for jogo in JOGOS:
		grade.add_child(_cartao_jogo(jogo))
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)


func _cartao_jogo(jogo: Dictionary) -> Button:
	var botao := Button.new()
	botao.name = "Jogo_" + str(jogo["cena"])
	botao.custom_minimum_size = Vector2(170, 190)
	botao.focus_mode = Control.FOCUS_NONE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(jogo["cor"])
	estilo.set_corner_radius_all(22)
	estilo.border_color = Color(1, 1, 1, 0.85)
	estilo.set_border_width_all(4)
	estilo.shadow_color = Color(0, 0, 0, 0.3)
	estilo.shadow_size = 6
	estilo.shadow_offset = Vector2(0, 5)
	for estado in ["normal", "hover", "pressed", "focus"]:
		botao.add_theme_stylebox_override(estado, estilo)
	var dentro := VBoxContainer.new()
	dentro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dentro.alignment = BoxContainer.ALIGNMENT_CENTER
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_theme_constant_override("separation", 10)
	botao.add_child(dentro)
	var imagem := TextureRect.new()
	imagem.texture = jogo["icone"]
	imagem.custom_minimum_size = Vector2(84, 84)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(imagem)
	var nome := Label.new()
	nome.text = jogo["nome"]
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_theme_font_size_override("font_size", 30)
	nome.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
	nome.add_theme_constant_override("outline_size", 8)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(nome)
	botao.pressed.connect(func():
		Audio.tocar("estouro", 1.1, -4.0)
		Telas.origem = origem
		queue_free()
		Telas.abrir(jogo["cena"]))
	return botao


func fechar() -> void:
	queue_free()
