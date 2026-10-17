class_name Itens
## Imagens dos itens do jogo (moeda, açúcar, XP e baús), todas no mesmo estilo
## 3D dos doces (ver Itens3D e ferramentas/gerar_itens_3d.sh). Use sempre
## estas, sem pintar por cima (modulate): assim o jogo tem uma cara só.

const MOEDA := preload("res://assets/itens/moeda.png")
const ACUCAR := preload("res://assets/itens/acucar.png")
const XP := preload("res://assets/itens/xp.png")
const ESTRELA := preload("res://assets/itens/estrela.png")
## Estrela ainda não ganha: a mesma estrela, apagada.
const ESTRELA_APAGADA := Color(0.28, 0.18, 0.45, 0.4)
const BAU_DOCE := preload("res://assets/itens/bau_doce.png")
const BAU_PRATA := preload("res://assets/itens/bau_prata.png")
const BAU_OURO := preload("res://assets/itens/bau_ouro.png")
const BAU_MADEIRA := preload("res://assets/itens/bau_madeira.png")
const BAU_CHEFE := preload("res://assets/itens/bau_chefe.png")
const BAU_ABERTO := preload("res://assets/itens/bau_aberto.png")
const BAU_ABERTO_DOCE := preload("res://assets/itens/bau_aberto_doce.png")
const BAU_ABERTO_PRATA := preload("res://assets/itens/bau_aberto_prata.png")
const BAU_ABERTO_OURO := preload("res://assets/itens/bau_aberto_ouro.png")


static func bau(tipo: String) -> Texture2D:
	return {"doce": BAU_DOCE, "prata": BAU_PRATA, "ouro": BAU_OURO}.get(tipo, BAU_DOCE)


static func bau_aberto(tipo: String) -> Texture2D:
	return {"doce": BAU_ABERTO_DOCE, "prata": BAU_ABERTO_PRATA, "ouro": BAU_ABERTO_OURO}.get(tipo, BAU_ABERTO)


## Botão com a imagem de um item: tira a tinta do tema (senão o item fica roxo).
static func sem_tinta(botao: Button) -> void:
	for estado in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color",
			"icon_hover_pressed_color", "icon_disabled_color"]:
		botao.add_theme_color_override(estado, Color.WHITE if estado != "icon_disabled_color" else Color(1, 1, 1, 0.5))


# --- Prêmios com ícones (nunca só em texto) ------------------------------------------

## Palavras de prêmio que viram ícone nos avisos ("+20 MOEDAS" -> "+20" + moeda).
const ICONES_PALAVRAS := {"AÇÚCAR": ACUCAR, "MOEDAS": MOEDA, "MOEDA": MOEDA, "XP": XP,
	"EXPERIÊNCIA": XP, "ESTRELAS": ESTRELA, "ESTRELA": ESTRELA}
static var _padrao_premio: RegEx


## Uma "fichinha" de prêmio: o ícone do item e o número (+20), lado a lado.
static func ficha(icone: Texture2D, texto: String, tamanho := 32, cor := Color.WHITE) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 4)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var imagem := TextureRect.new()
	imagem.texture = icone
	imagem.custom_minimum_size = Vector2.ONE * tamanho * 1.25
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(imagem)
	if texto != "":
		var rotulo := Label.new()
		rotulo.theme_type_variation = &"TituloClaro"
		rotulo.add_theme_font_size_override("font_size", tamanho)
		rotulo.add_theme_color_override("font_color", cor)
		rotulo.add_theme_constant_override("outline_size", maxi(4, tamanho / 5))
		rotulo.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
		rotulo.text = texto
		linha.add_child(rotulo)
	return linha


## As fichinhas de um prêmio {"moedas", "acucar", "xp", "bau", "estrelas"} (o que tiver).
static func fichas_premio(premio: Dictionary, tamanho := 32) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.name = "Fichas"
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", tamanho)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for par in [["moedas", MOEDA], ["acucar", ACUCAR], ["xp", XP], ["estrelas", ESTRELA]]:
		if int(premio.get(par[0], 0)) > 0:
			linha.add_child(ficha(par[1], "+%d" % int(premio[par[0]]), tamanho))
	var tipo_bau := str(premio.get("bau", ""))
	if tipo_bau != "":
		linha.add_child(ficha(bau(tipo_bau), "+1", tamanho))
	return linha


## Texto de aviso com os prêmios em ícone: "PRESENTE: +20 AÇÚCAR +10 MOEDAS"
## vira "PRESENTE:" + [+20 açúcar] + [+10 moeda] (o resto continua texto).
static func texto_com_icones(texto: String, tamanho := 28) -> HBoxContainer:
	if _padrao_premio == null:
		_padrao_premio = RegEx.create_from_string("([+\\-]?\\d+)\\s+(?:DE\\s+)?(AÇÚCAR|MOEDAS|MOEDA|XP|EXPERIÊNCIA|ESTRELAS|ESTRELA)\\b")
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 8)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inicio := 0
	for achado in _padrao_premio.search_all(texto):
		var antes := texto.substr(inicio, achado.get_start() - inicio).strip_edges()
		if antes != "":
			linha.add_child(_rotulo_aviso(antes, tamanho))
		linha.add_child(ficha(ICONES_PALAVRAS[achado.get_string(2)], achado.get_string(1), tamanho))
		inicio = achado.get_end()
	var resto := texto.substr(inicio).strip_edges()
	if resto != "" or linha.get_child_count() == 0:
		linha.add_child(_rotulo_aviso(resto, tamanho))
	return linha


static func _rotulo_aviso(texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.text = texto
	return rotulo
