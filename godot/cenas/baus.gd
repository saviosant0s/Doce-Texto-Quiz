extends Control
## Baús surpresa: os baús fechados do jogador (doce, prata e ouro) e a
## abertura com animação: o baú treme, abre, e os itens aparecem um por um
## como cartas virando, na cor da raridade. Regras em scripts/baus.gd.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_MOEDA := Itens.MOEDA
const ICONE_ACUCAR := Itens.ACUCAR
const ICONE_DOCE := preload("res://assets/icones/doce.svg")
const TEXTURAS := {
	"doce": Itens.BAU_DOCE,
	"prata": Itens.BAU_PRATA,
	"ouro": Itens.BAU_OURO,
}
const BAU_ABERTO := Itens.BAU_ABERTO
const DE_ONDE := {
	"doce": "Passe numa partida do quiz (até 5 por dia)",
	"prata": "Complete as missões do dia ou suba de nível",
	"ouro": "Missões da semana, 7º dia seguido e a cada 5 níveis",
}

var _contadores := {}
var _botoes := {}
var _rotulo_garantia: Label
var _rotulo_moedas: Label
var _painel: Control
var _abrindo := false


func _ready() -> void:
	_montar()
	_atualizar()


func ao_voltar() -> void:
	if is_instance_valid(_painel) and not _abrindo:
		_fechar()
		return
	Telas.voltar()


func _atualizar() -> void:
	for tipo in Baus.TIPOS:
		_contadores[tipo].text = "x%d" % Baus.quantos(tipo)
		_botoes[tipo].disabled = Baus.quantos(tipo) == 0
	_rotulo_garantia.text = "GARANTIA: UM DOCE ÉPICO OU LENDÁRIO EM ATÉ %d BAÚS" % Baus.faltam_para_garantia()
	_rotulo_moedas.text = Jogo.formatar(Progresso.moedas)


# --- Montagem -------------------------------------------------------------------------

func _montar() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 28)
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	margem.add_child(coluna)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	coluna.add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(60, 60)
	voltar.icon = ICONE_VOLTAR
	voltar.expand_icon = true
	voltar.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltar.pressed.connect(Telas.voltar)
	topo.add_child(voltar)
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"EtiquetaAmarela"
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var titulo := Label.new()
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.text = "BAÚS SURPRESA"
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(espaco)
	var colecao := Button.new()
	colecao.name = "Colecao"
	colecao.text = "MEUS DOCES"
	colecao.theme_type_variation = &"Alternativa"
	colecao.icon = ICONE_DOCE
	colecao.expand_icon = true
	colecao.custom_minimum_size = Vector2(0, 72)
	colecao.pressed.connect(Telas.abrir.bind("colecao"))
	topo.add_child(colecao)
	var moedas := PanelContainer.new()
	moedas.theme_type_variation = &"Etiqueta"
	moedas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	moedas.add_child(linha)
	var icone := TextureRect.new()
	icone.texture = ICONE_MOEDA
	icone.custom_minimum_size = Vector2(30, 30)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(icone)
	_rotulo_moedas = Label.new()
	_rotulo_moedas.theme_type_variation = &"TituloClaro"
	linha.add_child(_rotulo_moedas)
	topo.add_child(moedas)

	var baus := HBoxContainer.new()
	baus.alignment = BoxContainer.ALIGNMENT_CENTER
	baus.add_theme_constant_override("separation", 24)
	baus.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(baus)
	for tipo in Baus.TIPOS:
		baus.add_child(_cartao_bau(tipo))
	_rotulo_garantia = Label.new()
	_rotulo_garantia.theme_type_variation = &"TituloClaro"
	_rotulo_garantia.add_theme_font_size_override("font_size", 24)
	_rotulo_garantia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_rotulo_garantia)
	var ajuda := Label.new()
	ajuda.theme_type_variation = &"TextoClaro"
	ajuda.add_theme_font_size_override("font_size", 18)
	ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ajuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ajuda.text = "Dentro dos baús vêm pedaços de doces: junte 10 para ganhar o doce e mais pedaços para melhorar o bônus dele como companheiro."
	coluna.add_child(ajuda)


func _cartao_bau(tipo: String) -> PanelContainer:
	var cartao := PanelContainer.new()
	cartao.theme_type_variation = &"PainelEscuro"
	cartao.custom_minimum_size = Vector2(340, 0)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 8)
	cartao.add_child(coluna)
	var nome := Label.new()
	nome.theme_type_variation = &"TituloClaro"
	nome.add_theme_font_size_override("font_size", 34)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.text = Baus.NOMES[tipo]
	coluna.add_child(nome)
	var imagem := TextureRect.new()
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.texture = TEXTURAS[tipo]
	imagem.custom_minimum_size = Vector2(170, 140)
	coluna.add_child(imagem)
	var contador := Label.new()
	contador.theme_type_variation = &"TituloClaro"
	contador.add_theme_font_size_override("font_size", 40)
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(contador)
	_contadores[tipo] = contador
	var de_onde := Label.new()
	de_onde.theme_type_variation = &"TextoClaro"
	de_onde.add_theme_font_size_override("font_size", 16)
	de_onde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	de_onde.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	de_onde.custom_minimum_size = Vector2(280, 0)
	de_onde.text = "%s · %d itens" % [DE_ONDE[tipo], Baus.ITENS[tipo]]
	coluna.add_child(de_onde)
	var abrir := Button.new()
	abrir.name = "Abrir_" + tipo
	abrir.text = "ABRIR"
	abrir.theme_type_variation = &"BotaoRoxo"
	abrir.custom_minimum_size = Vector2(0, 72)
	abrir.pressed.connect(abrir_bau.bind(tipo))
	coluna.add_child(abrir)
	_botoes[tipo] = abrir
	return cartao


# --- Abrir ---------------------------------------------------------------------------

func abrir_bau(tipo: String, sorteio: RandomNumberGenerator = null) -> void:
	if _abrindo:
		return
	var itens := Baus.abrir(tipo, sorteio)
	if itens.is_empty():
		return
	_abrindo = true
	if is_instance_valid(_painel):
		_painel.queue_free()
	var camada := Control.new()
	camada.name = "Abertura"
	camada.set_anchors_preset(PRESET_FULL_RECT)
	add_child(camada)
	_painel = camada
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.8)
	escuro.set_anchors_preset(PRESET_FULL_RECT)
	camada.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(PRESET_FULL_RECT)
	camada.add_child(centro)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 18)
	centro.add_child(coluna)
	var titulo := Label.new()
	titulo.theme_type_variation = &"TituloClaro"
	titulo.add_theme_font_size_override("font_size", 48)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.text = "ABRINDO %s..." % Baus.NOMES[tipo]
	coluna.add_child(titulo)
	var imagem := TextureRect.new()
	imagem.name = "Bau"
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.texture = TEXTURAS[tipo]
	imagem.custom_minimum_size = Vector2(240, 200)
	coluna.add_child(imagem)
	var cartas := HBoxContainer.new()
	cartas.name = "Cartas"
	cartas.alignment = BoxContainer.ALIGNMENT_CENTER
	cartas.add_theme_constant_override("separation", 16)
	coluna.add_child(cartas)
	var pronto := Button.new()
	pronto.name = "Pronto"
	pronto.text = "OBA!"
	pronto.theme_type_variation = &"BotaoRoxo"
	pronto.custom_minimum_size = Vector2(260, 76)
	pronto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pronto.modulate.a = 0.0
	pronto.disabled = true
	pronto.pressed.connect(_fechar)
	coluna.add_child(pronto)
	await get_tree().process_frame
	# treme cada vez mais forte
	imagem.pivot_offset = imagem.size / 2
	var tween := create_tween()
	for forca in [0.07, 0.13, 0.2]:
		tween.tween_callback(Audio.tocar.bind("caixa", 0.8 + forca * 2))
		for lado in [1, -1, 1, -1]:
			tween.tween_property(imagem, "rotation", forca * lado, 0.05)
		tween.tween_property(imagem, "rotation", 0.0, 0.05)
		tween.tween_interval(0.15)
	tween.tween_callback(func():
		imagem.texture = Itens.bau_aberto(tipo)
		titulo.text = Baus.NOMES[tipo]
		Audio.tocar("construir"))
	tween.tween_property(imagem, "custom_minimum_size", Vector2(160, 130), 0.2)
	# as cartas aparecem uma por uma
	for i in itens.size():
		var carta := _carta(itens[i])
		carta.modulate.a = 0.0
		cartas.add_child(carta)
		tween.tween_callback(func():
			carta.pivot_offset = carta.size / 2
			carta.scale = Vector2(0.05, 1.0)
			carta.modulate.a = 1.0
			var raro: bool = itens[i].get("raridade", 0) >= Companheiros.Raridade.EPICO
			Audio.tocar("moeda" if not raro else "construir", 1.0 + i * 0.12))
		tween.tween_property(carta, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.25)
	tween.tween_callback(func():
		pronto.disabled = false
		_abrindo = false
		_atualizar())
	tween.tween_property(pronto, "modulate:a", 1.0, 0.2)


## Carta de um item: pedaços de doce (na cor da raridade), moedas ou açúcar.
func _carta(item: Dictionary) -> PanelContainer:
	var carta := PanelContainer.new()
	carta.name = "Carta"
	var estilo := StyleBoxFlat.new()
	estilo.set_corner_radius_all(18)
	estilo.set_border_width_all(6)
	estilo.border_color = Color.WHITE
	estilo.set_content_margin_all(12)
	estilo.shadow_color = Color(0, 0, 0, 0.3)
	estilo.shadow_size = 8
	carta.custom_minimum_size = Vector2(190, 250)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 4)
	carta.add_child(coluna)
	var imagem := TextureRect.new()
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.custom_minimum_size = Vector2(0, 120)
	coluna.add_child(imagem)
	var linha1 := Label.new()
	linha1.theme_type_variation = &"TituloClaro"
	linha1.add_theme_font_size_override("font_size", 30)
	linha1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(linha1)
	var linha2 := Label.new()
	linha2.theme_type_variation = &"TituloClaro"
	linha2.add_theme_font_size_override("font_size", 20)
	linha2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	linha2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(linha2)
	match item["tipo"]:
		"fragmentos":
			var id: String = item["doce"]
			estilo.bg_color = Companheiros.CORES_RARIDADE[item["raridade"]].darkened(0.15)
			imagem.texture = Personagens.textura(id)
			linha1.text = "+%d PEDAÇOS" % item["quantidade"]
			linha2.text = "%s\n%s" % [Colecao.dados(id)["nome"], Companheiros.NOMES_RARIDADE[item["raridade"]]]
			if item["ganhou_doce"]:
				var novo := Label.new()
				novo.theme_type_variation = &"TituloClaro"
				novo.add_theme_font_size_override("font_size", 24)
				novo.add_theme_color_override("font_color", Cores.AMARELO)
				novo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				novo.text = "DOCE NOVO!"
				coluna.add_child(novo)
				coluna.move_child(novo, 0)
		"moedas":
			estilo.bg_color = Cores.ROXO_ESCURO
			imagem.texture = ICONE_MOEDA
			linha1.text = "+%d" % item["quantidade"]
			linha2.text = "MOEDAS"
		_:
			estilo.bg_color = Cores.ROXO_ESCURO
			imagem.texture = ICONE_ACUCAR
			linha1.text = "+%d" % item["quantidade"]
			linha2.text = "DE AÇÚCAR"
	carta.add_theme_stylebox_override("panel", estilo)
	return carta


func _fechar() -> void:
	if is_instance_valid(_painel):
		_painel.queue_free()
	_painel = null
	_abrindo = false
	_atualizar()
