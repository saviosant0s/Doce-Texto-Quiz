class_name BotoesProgresso
extends HBoxContainer
## Nível do jogador (com a barrinha de XP) e os botões MISSÕES e BAÚS, com
## a bolinha vermelha contando o que está esperando (prêmios para resgatar e
## baús fechados). Fica na tela inicial e na vila.

const ICONE_MISSOES := preload("res://assets/icones/missoes.svg")
const BAU := Itens.BAU_DOCE

var _nivel: Label
var _barra: ProgressBar
var _missoes: Button
var _baus: Button


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var selo := PanelContainer.new()
	selo.name = "Nivel"
	var fundo_selo := StyleBoxFlat.new()
	fundo_selo.bg_color = Cores.ROXO_ESCURO
	fundo_selo.set_corner_radius_all(14)
	fundo_selo.content_margin_left = 12
	fundo_selo.content_margin_right = 12
	fundo_selo.content_margin_top = 2
	fundo_selo.content_margin_bottom = 6
	selo.add_theme_stylebox_override("panel", fundo_selo)
	selo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 2)
	selo.add_child(coluna)
	_nivel = Label.new()
	_nivel.theme_type_variation = &"TituloClaro"
	_nivel.add_theme_font_size_override("font_size", 18)
	_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_nivel)
	_barra = ProgressBar.new()
	_barra.theme_type_variation = &"BarraClara"
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(84, 8)
	coluna.add_child(_barra)
	add_child(selo)
	_missoes = _botao("Missoes", "MISSÕES", ICONE_MISSOES, "missoes")
	_baus = _botao("BausSurpresa", "BAÚS", BAU, "baus")
	atualizar()


func _botao(nome: String, texto: String, icone: Texture2D, tela: String) -> Button:
	var b := Button.new()
	b.name = nome
	b.text = texto
	b.icon = icone
	b.theme_type_variation = &"Alternativa"
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_constant_override("icon_max_width", 26)
	b.add_theme_constant_override("h_separation", 6)
	for estado in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(estado, Color.WHITE)  # ícones coloridos, sem a tinta roxa do tema
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(Telas.abrir_rapido.bind(tela))  # na vila, abre por cima, na hora
	var bolinha := Label.new()
	bolinha.name = "Bolinha"
	bolinha.add_theme_font_size_override("font_size", 15)
	bolinha.add_theme_color_override("font_color", Color.WHITE)
	bolinha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bolinha.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Cores.VERMELHO
	fundo.set_corner_radius_all(12)
	fundo.set_border_width_all(2)
	fundo.border_color = Color.WHITE
	bolinha.add_theme_stylebox_override("normal", fundo)
	bolinha.custom_minimum_size = Vector2(24, 24)
	bolinha.size = Vector2(24, 24)
	bolinha.position = Vector2(-10, -10)
	bolinha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bolinha)
	add_child(b)
	return b


func atualizar() -> void:
	_nivel.text = "NÍVEL %d" % Experiencia.nivel()
	_barra.max_value = Experiencia.xp_para(Experiencia.nivel())
	_barra.value = Experiencia.xp()
	_marcar(_missoes, Missoes.para_resgatar())
	_marcar(_baus, Baus.total_fechados())


func _marcar(botao: Button, quantidade: int) -> void:
	var bolinha: Label = botao.get_node("Bolinha")
	bolinha.visible = quantidade > 0
	bolinha.text = str(quantidade) if quantidade < 100 else "99+"
	if quantidade > 0 and Telas.animacoes_continuas:
		bolinha.pivot_offset = Vector2(12, 12)
		var tween := bolinha.create_tween().set_loops()
		tween.tween_property(bolinha, "scale", Vector2.ONE * 1.2, 0.35)
		tween.tween_property(bolinha, "scale", Vector2.ONE, 0.35)
		tween.tween_interval(1.2)
