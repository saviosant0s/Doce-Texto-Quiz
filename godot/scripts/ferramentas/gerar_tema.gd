extends SceneTree
## Gera o tema visual do jogo (res://tema/tema.tres): fontes, cores, botões,
## painéis, barras, controles deslizantes e chaves liga/desliga.
##
## Rodar (na pasta do repositório):
##     godot --headless --path godot --script res://scripts/ferramentas/gerar_tema.gd
##
## Atenção: o tema é gerado a partir deste arquivo. Mudanças feitas direto no
## tema.tres pelo editor são perdidas ao gerar de novo; prefira mudar aqui.

const ROXO := Color("#7E57B1")
const ROXO_ESCURO := Color("#5E3D8E")
const AMARELO := Color("#F4E038")
const AMARELO_ESCURO := Color("#CDB91E")
const AMARELO_CLARO := Color("#FAEE84")
const CREME := Color("#F6EEDC")
const VERMELHO := Color("#E5484D")
const VERMELHO_ESCURO := Color("#B42F34")

var bebas: FontFile
var nunito: FontFile


func _init() -> void:
	bebas = load("res://assets/fontes/BebasNeue-Regular.ttf")
	nunito = load("res://assets/fontes/Nunito.ttf")
	var t := Theme.new()

	var texto := peso(700)
	var texto_forte := peso(850)
	t.default_font = texto
	t.default_font_size = 26

	# --- Rótulos
	t.set_color("font_color", "Label", ROXO)
	variacao(t, "TituloGrande", "Label", bebas, 120, AMARELO)
	variacao(t, "Titulo", "Label", bebas, 56, ROXO)
	variacao(t, "TituloClaro", "Label", bebas, 44, AMARELO)
	variacao(t, "Subtitulo", "Label", bebas, 36, ROXO)
	variacao(t, "SubtituloClaro", "Label", bebas, 36, AMARELO)
	variacao(t, "Texto", "Label", texto, 24, ROXO)
	variacao(t, "TextoClaro", "Label", texto, 24, AMARELO)
	variacao(t, "Pergunta", "Label", texto_forte, 34, ROXO)
	variacao(t, "Numero", "Label", bebas, 72, AMARELO)

	# --- Painéis
	t.set_stylebox("panel", "PanelContainer", caixa(AMARELO, 26, 28, true))
	t.set_type_variation("PainelRoxo", "PanelContainer")
	t.set_stylebox("panel", "PainelRoxo", caixa(ROXO, 18, 18))
	t.set_type_variation("PainelEscuro", "PanelContainer")
	t.set_stylebox("panel", "PainelEscuro", caixa(ROXO_ESCURO, 30, 36, true))
	t.set_type_variation("Etiqueta", "PanelContainer")
	var etiqueta := caixa(ROXO, 14, 0)
	etiqueta.content_margin_left = 26
	etiqueta.content_margin_right = 26
	etiqueta.content_margin_top = 4
	etiqueta.content_margin_bottom = 2
	t.set_stylebox("panel", "Etiqueta", etiqueta)
	t.set_type_variation("EtiquetaAmarela", "PanelContainer")
	var etiqueta_amarela := etiqueta.duplicate()
	etiqueta_amarela.bg_color = AMARELO
	t.set_stylebox("panel", "EtiquetaAmarela", etiqueta_amarela)

	# --- Botões
	botao(t, "Button", AMARELO, AMARELO_CLARO, AMARELO_ESCURO, ROXO, bebas, 44, 18)
	botao(t, "BotaoRoxo", ROXO, Color("#8F69C4"), ROXO_ESCURO, AMARELO, bebas, 40, 18)
	botao(t, "Alternativa", AMARELO, AMARELO_CLARO, AMARELO_ESCURO, ROXO, texto_forte, 28, 18)
	botao(t, "BotaoIcone", ROXO, Color("#8F69C4"), ROXO_ESCURO, AMARELO, bebas, 32, 999, 14)
	botao(t, "BotaoPerigo", VERMELHO, Color("#EE6B6F"), VERMELHO_ESCURO, Color.WHITE, bebas, 36, 18)
	botao(t, "BotaoIconeAmarelo", AMARELO, AMARELO_CLARO, AMARELO_ESCURO, ROXO, bebas, 32, 999, 14)
	# cartão de nível: botão grande amarelo
	botao(t, "CartaoNivel", AMARELO, AMARELO_CLARO, AMARELO_ESCURO, ROXO, bebas, 40, 28, 20)

	# --- Barras de progresso
	var fundo_barra := caixa(Color(ROXO, 0.22), 999, 0)
	var cheio_barra := caixa(ROXO, 999, 0)
	t.set_stylebox("background", "ProgressBar", fundo_barra)
	t.set_stylebox("fill", "ProgressBar", cheio_barra)
	t.set_type_variation("BarraClara", "ProgressBar")
	t.set_stylebox("background", "BarraClara", caixa(Color(CREME, 0.25), 999, 0))
	t.set_stylebox("fill", "BarraClara", caixa(CREME, 999, 0))

	# --- Controle deslizante (volume)
	var trilho := caixa(Color(ROXO_ESCURO, 0.35), 999, 0)
	trilho.content_margin_top = 7
	trilho.content_margin_bottom = 7
	t.set_stylebox("slider", "HSlider", trilho)
	t.set_stylebox("grabber_area", "HSlider", caixa(ROXO, 999, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", caixa(Color("#8F69C4"), 999, 0))
	t.set_icon("grabber", "HSlider", load("res://assets/icones/ui/bolinha.svg"))
	t.set_icon("grabber_highlight", "HSlider", load("res://assets/icones/ui/bolinha_destaque.svg"))
	t.set_stylebox("focus", "HSlider", StyleBoxEmpty.new())

	# --- Chave liga/desliga
	for estado in ["checked", "checked_disabled"]:
		t.set_icon(estado, "CheckButton", load("res://assets/icones/ui/chave_ligada.svg"))
	for estado in ["unchecked", "unchecked_disabled"]:
		t.set_icon(estado, "CheckButton", load("res://assets/icones/ui/chave_desligada.svg"))
	for estado in ["normal", "pressed", "hover", "hover_pressed", "focus", "disabled"]:
		t.set_stylebox(estado, "CheckButton", StyleBoxEmpty.new())
	t.set_font("font", "CheckButton", texto)
	t.set_font_size("font_size", "CheckButton", 24)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(estado, "CheckButton", ROXO)

	# --- Texto rico (tela "Sobre")
	t.set_color("default_color", "RichTextLabel", ROXO)
	t.set_font("normal_font", "RichTextLabel", texto)
	t.set_font("bold_font", "RichTextLabel", peso(900))
	t.set_font_size("normal_font_size", "RichTextLabel", 22)
	t.set_font_size("bold_font_size", "RichTextLabel", 22)

	# --- Barra de rolagem fina
	t.set_stylebox("scroll", "VScrollBar", caixa(Color(ROXO, 0.15), 999, 0))
	t.set_stylebox("grabber", "VScrollBar", caixa(ROXO, 999, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", caixa(ROXO_ESCURO, 999, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", caixa(ROXO_ESCURO, 999, 0))

	var erro := ResourceSaver.save(t, "res://tema/tema.tres")
	print("tema salvo: ", erro)
	quit()


func peso(wght: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = nunito
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	return f


func variacao(t: Theme, nome: String, base: String, fonte: Font, tamanho: int, cor: Color) -> void:
	t.set_type_variation(nome, base)
	t.set_font("font", nome, fonte)
	t.set_font_size("font_size", nome, tamanho)
	t.set_color("font_color", nome, cor)


func caixa(cor: Color, raio: int, margem: int, sombra := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.set_corner_radius_all(raio)
	s.corner_detail = 10
	s.set_content_margin_all(margem)
	s.anti_aliasing = true
	if sombra:
		s.shadow_color = Color(0, 0, 0, 0.18)
		s.shadow_size = 12
		s.shadow_offset = Vector2(0, 6)
	return s


## Botão "de bala": base colorida com uma borda inferior mais escura que afunda ao apertar.
func botao(t: Theme, nome: String, cor: Color, cor_hover: Color, cor_borda: Color, cor_texto: Color,
		fonte: Font, tamanho: int, raio: int, margem := 22) -> void:
	if nome != "Button":
		t.set_type_variation(nome, "Button")
	var normal := caixa(cor, raio, margem)
	normal.content_margin_top = margem * 0.5
	normal.content_margin_bottom = margem * 0.5
	normal.border_width_bottom = 7
	normal.border_color = cor_borda
	var hover := normal.duplicate()
	hover.bg_color = cor_hover
	var pressionado := normal.duplicate()
	pressionado.border_width_bottom = 2
	pressionado.expand_margin_top = -5
	pressionado.content_margin_top += 5
	pressionado.content_margin_bottom -= 5
	var desativado := normal.duplicate()
	desativado.bg_color = cor.lerp(Color.GRAY, 0.5)
	t.set_stylebox("normal", nome, normal)
	t.set_stylebox("hover", nome, hover)
	t.set_stylebox("pressed", nome, pressionado)
	t.set_stylebox("hover_pressed", nome, pressionado)
	t.set_stylebox("disabled", nome, desativado)
	t.set_stylebox("focus", nome, StyleBoxEmpty.new())
	t.set_font("font", nome, fonte)
	t.set_font_size("font_size", nome, tamanho)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(estado, nome, cor_texto)
	t.set_color("font_disabled_color", nome, Color(cor_texto, 0.6))
	for estado in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		t.set_color(estado, nome, cor_texto)
	t.set_constant("h_separation", nome, 12)
	t.set_constant("icon_max_width", nome, 48)
