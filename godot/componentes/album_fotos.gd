class_name AlbumFotos
extends Control
## ÁLBUM DE FOTOS: as fotos tiradas nos pontos de foto da vila (PontosFoto),
## em miniaturas; tocar numa mostra ela grande. Ponha numa CanvasLayer.

signal fechou

var _grade: GridContainer
var _grande: Control
var _foto_grande: TextureRect
var _nome_grande: Label


func _ready() -> void:
	name = "Album"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.75)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 30)
	add_child(margem)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)
	var topo := HBoxContainer.new()
	coluna.add_child(topo)
	var titulo := Label.new()
	titulo.theme_type_variation = &"TituloClaro"
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.text = "ÁLBUM DE FOTOS · PONTOS %d/%d" % [PontosFoto.pontos_com_foto(), PontosFoto.PONTOS.size()]
	topo.add_child(titulo)
	var fechar := Button.new()
	fechar.name = "FecharAlbum"
	fechar.text = "FECHAR"
	fechar.theme_type_variation = &"BotaoSecundario"
	fechar.custom_minimum_size = Vector2(160, 56)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.pressed.connect(fechar_album)
	topo.add_child(fechar)
	var rolar := ScrollContainer.new()
	rolar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolar)
	_grade = GridContainer.new()
	_grade.name = "Fotos"
	_grade.columns = 4
	_grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grade.add_theme_constant_override("h_separation", 12)
	_grade.add_theme_constant_override("v_separation", 12)
	rolar.add_child(_grade)
	var fotos := PontosFoto.album()
	for caminho in fotos:
		var imagem := Image.load_from_file(caminho)
		if imagem == null or imagem.is_empty():
			continue
		imagem.resize(256, maxi(1, 256 * imagem.get_height() / imagem.get_width()), Image.INTERPOLATE_BILINEAR)
		var botao := Button.new()
		botao.name = "Foto%d" % _grade.get_child_count()
		botao.theme_type_variation = &"BotaoSecundario"
		botao.focus_mode = Control.FOCUS_NONE
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.custom_minimum_size = Vector2(0, 170)
		botao.icon = ImageTexture.create_from_image(imagem)
		botao.expand_icon = true
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.pressed.connect(ver.bind(caminho))
		_grade.add_child(botao)
	if _grade.get_child_count() == 0:
		var vazio := Label.new()
		vazio.theme_type_variation = &"TituloClaro"
		vazio.add_theme_font_size_override("font_size", 26)
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vazio.custom_minimum_size = Vector2(600, 0)
		vazio.text = "NENHUMA FOTO AINDA. PROCURE AS MARCAS COM CÂMERA PELA VILA E TOQUE EM TIRAR FOTO!"
		_grade.add_child(vazio)
	# foto grande (por cima da grade)
	_grande = PanelContainer.new()
	_grande.name = "FotoGrande"
	_grande.theme_type_variation = &"PainelRoxo"
	_grande.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grande.visible = false
	add_child(_grande)
	var coluna_grande := VBoxContainer.new()
	coluna_grande.add_theme_constant_override("separation", 10)
	_grande.add_child(coluna_grande)
	_foto_grande = TextureRect.new()
	_foto_grande.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_foto_grande.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foto_grande.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coluna_grande.add_child(_foto_grande)
	var baixo := HBoxContainer.new()
	coluna_grande.add_child(baixo)
	_nome_grande = Label.new()
	_nome_grande.theme_type_variation = &"TituloClaro"
	_nome_grande.add_theme_font_size_override("font_size", 30)
	_nome_grande.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baixo.add_child(_nome_grande)
	var voltar := Button.new()
	voltar.name = "VoltarAlbum"
	voltar.text = "VOLTAR"
	voltar.theme_type_variation = &"BotaoSecundario"
	voltar.custom_minimum_size = Vector2(160, 56)
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.pressed.connect(func(): _grande.visible = false)
	baixo.add_child(voltar)


## Mostra a foto grande.
func ver(caminho: String) -> void:
	var imagem := Image.load_from_file(caminho)
	if imagem == null or imagem.is_empty():
		return
	_foto_grande.texture = ImageTexture.create_from_image(imagem)
	_nome_grande.text = PontosFoto.nome_da_foto(caminho)
	_grande.visible = true


func fechar_album() -> void:
	fechou.emit()
	queue_free()
