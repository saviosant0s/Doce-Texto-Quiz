extends Control
## Uma fase do Laboratório do Office (Laboratorio.fase_atual).
## - Excel: planilha com barra de fórmulas. O jogador digita a fórmula (ou
##   toca nas células para colocar o endereço; tocar em outra logo depois vira
##   intervalo, B2:B6) e aperta CONFERIR. Botões de atalho para = ( ) ; : $...
## - Word: página com a barra de ferramentas (N, I, S, alinhamentos, fonte,
##   cores, TUDO, desfazer) e os atalhos do Word em português.
## Os chefes têm várias tarefas seguidas (corações do chefe no topo).
## Regras em scripts/laboratorio.gd, formulas.gd e documento_word.gd.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_DICA := preload("res://assets/icones/lampada.svg")
const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const ICONE_CORACAO := preload("res://assets/icones/coracao.svg")
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")
const ICONE_ACUCAR := preload("res://assets/icones/acucar.svg")
const ICONES_ACAO := {
	"esquerda": preload("res://assets/icones/alinhar_esquerda.svg"),
	"centro": preload("res://assets/icones/alinhar_centro.svg"),
	"direita": preload("res://assets/icones/alinhar_direita.svg"),
	"justificado": preload("res://assets/icones/justificar.svg"),
	"desfazer": preload("res://assets/icones/desfazer.svg"),
}
const FONTE_TEXTO := preload("res://assets/fontes/Nunito.ttf")
const NOMES_FUNCOES := {"MEDIA": "MÉDIA", "MAXIMO": "MÁXIMO", "MINIMO": "MÍNIMO"}
const LARGURA_CABECALHO := 46.0
const ALTURA_LINHA := 42.0

var fase: Dictionary
var passo := 0
var erros := 0
var dicas := 0
var terminou := false
## Excel: valores das células (vão sendo preenchidas a cada acerto).
var celulas: Dictionary = {}
## Word: o documento sendo formatado.
var doc: DocumentoWord

var _dica_usada := false
var _acertou_passo := false
var _rotulo_tarefa: Label
var _rotulo_pedido: Label
var _feedback: Label
var _botao_conferir: Button
var _coracoes: Array[TextureRect] = []
var _area: Control
# Excel
var _formula: LineEdit
var _caixa_nome: Label
var _grade: GridContainer
var _rotulos_celulas := {}  # "B4" -> Label
var _ultima_ref := ""
var _caret_depois_ref := -1
# Word
var _paragrafos: Array[RichTextLabel] = []
var _botoes_acao := {}


func _ready() -> void:
	fase = Laboratorio.fase(Laboratorio.fase_atual)
	if fase.is_empty():
		fase = Laboratorio.fases()[0]
	_montar()
	_comecar()


func ao_voltar() -> void:
	Telas.voltar()


func _comecar() -> void:
	passo = 0
	erros = 0
	dicas = 0
	terminou = false
	for filho in _area.get_children():
		_area.remove_child(filho)
		filho.queue_free()
	_rotulos_celulas.clear()
	_paragrafos.clear()
	_botoes_acao.clear()
	if fase["tipo"] == "excel":
		celulas = fase["planilha"]["celulas"].duplicate()
		_montar_excel()
	else:
		doc = DocumentoWord.new(fase["documento"])
		_montar_word()
	for c in _coracoes:
		c.modulate = Cores.VERMELHO
		c.scale = Vector2.ONE
	_mostrar_passo()


func _passo_atual() -> Dictionary:
	return fase["passos"][passo]


func _mostrar_passo() -> void:
	_dica_usada = false
	_acertou_passo = false
	var total: int = fase["passos"].size()
	_rotulo_tarefa.text = "TAREFA %d/%d" % [passo + 1, total]
	_rotulo_tarefa.visible = total > 1
	_rotulo_pedido.text = _passo_atual()["pedido"]
	_mostrar_feedback("", Color.WHITE)
	_botao_conferir.text = "CONFERIR"
	if fase["tipo"] == "excel":
		_marcar_celula_alvo()
		_formula.text = ""
		_formula.editable = true
		_atualizar_atalhos_excel()
	else:
		_desenhar_documento()


# --- Conferir, dica, próximo ------------------------------------------------------

## Botão principal: confere a tarefa ou, depois de acertar, vai para a próxima.
func conferir() -> void:
	if terminou:
		return
	if _acertou_passo:
		proximo()
		return
	var certo := false
	var mensagem := ""
	if fase["tipo"] == "excel":
		var r := Laboratorio.conferir_excel(_passo_atual(), _formula.text, celulas)
		certo = r["certo"]
		mensagem = r["mensagem"]
		var alvo: String = _passo_atual()["celula"]
		if certo:
			celulas[alvo] = r["valor"]
			_formula.editable = false
		var mostrar: Variant = r["valor"]
		if mostrar == null or (Formulas.eh_erro(mostrar) and not mostrar.codigo.begins_with("#")):
			mostrar = _formula.text  # problema de digitação: a célula mostra o que foi escrito
		_escrever_celula(alvo, mostrar, not certo)
	else:
		var faltas := doc.faltando(Laboratorio.metas_ate(fase, passo))
		certo = faltas.is_empty()
		mensagem = "" if certo else faltas[0]
	if certo:
		_acertou_passo = true
		Audio.tocar("acerto")
		_mostrar_feedback("CERTO! " + str(_passo_atual().get("explicacao", "")), Cores.VERDE)
		_botao_conferir.text = "PRÓXIMA" if passo + 1 < fase["passos"].size() else "TERMINAR"
		_acertar_chefe()
	else:
		erros += 1
		Audio.tocar("erro")
		_mostrar_feedback(mensagem, Color("#FF8A8A"))
		_tremer(_area)


func usar_dica() -> void:
	if terminou or _acertou_passo:
		return
	if not _dica_usada:
		_dica_usada = true
		dicas += 1
	_mostrar_feedback("DICA: " + str(_passo_atual()["dica"]), Cores.AMARELO)


func proximo() -> void:
	if passo + 1 < fase["passos"].size():
		passo += 1
		_mostrar_passo()
	else:
		_terminar()


func _mostrar_feedback(texto: String, cor: Color) -> void:
	_feedback.text = texto
	_feedback.add_theme_color_override("font_color", cor)
	if texto != "":
		_feedback.pivot_offset = _feedback.size / 2
		_feedback.scale = Vector2.ONE * 0.9
		_feedback.create_tween().tween_property(_feedback, "scale", Vector2.ONE, 0.15)


func _tremer(no: Control) -> void:
	var x := no.position.x
	var tween := no.create_tween()
	for d in [12.0, -10.0, 6.0, 0.0]:
		tween.tween_property(no, "position:x", x + d, 0.05)


## Chefe: cada tarefa certa tira um coração dele.
func _acertar_chefe() -> void:
	if _coracoes.is_empty():
		return
	var coracao := _coracoes[passo]
	coracao.pivot_offset = coracao.size / 2
	var tween := coracao.create_tween()
	tween.tween_property(coracao, "scale", Vector2.ONE * 1.5, 0.12)
	tween.tween_property(coracao, "scale", Vector2.ONE * 0.8, 0.15)
	tween.parallel().tween_property(coracao, "modulate", Color(1, 1, 1, 0.25), 0.15)
	Audio.tocar("estouro", 0.8)


# --- Fim da fase --------------------------------------------------------------------

func _terminar() -> void:
	terminou = true
	var n := Laboratorio.estrelas_por(erros, dicas)
	var r := Laboratorio.concluir(fase["id"], n)
	Laboratorio.recem_concluida = fase["id"]
	var camada := Control.new()
	camada.name = "Fim"
	camada.set_anchors_preset(PRESET_FULL_RECT)
	add_child(camada)
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.6)
	escuro.set_anchors_preset(PRESET_FULL_RECT)
	camada.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(PRESET_FULL_RECT)
	camada.add_child(centro)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)
	var titulo := Label.new()
	titulo.theme_type_variation = &"TituloClaro"
	titulo.add_theme_font_size_override("font_size", 60)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.text = "CHEFE DERROTADO!" if fase.get("chefe", false) else "FASE COMPLETA!"
	coluna.add_child(titulo)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_child(linha)
	var estrelas: Array[TextureRect] = []
	for i in 3:
		var e := TextureRect.new()
		e.texture = ICONE_ESTRELA
		e.custom_minimum_size = Vector2(84, 84)
		e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		e.modulate = Color(1, 1, 1, 0.25)
		linha.add_child(e)
		estrelas.append(e)
	var resumo := Label.new()
	resumo.theme_type_variation = &"SubtituloClaro"
	resumo.add_theme_font_size_override("font_size", 24)
	resumo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var partes := []
	partes.append("SEM ERROS!" if erros == 0 else ("%d ERRO" % erros + ("S" if erros > 1 else "")))
	if dicas > 0:
		partes.append("%d DICA" % dicas + ("S" if dicas > 1 else ""))
	resumo.text = " · ".join(partes)
	coluna.add_child(resumo)
	if r["acucar"] > 0 or r["moedas"] > 0:
		var premio := HBoxContainer.new()
		premio.alignment = BoxContainer.ALIGNMENT_CENTER
		premio.add_theme_constant_override("separation", 24)
		coluna.add_child(premio)
		if r["acucar"] > 0:
			_item_premio(premio, ICONE_ACUCAR, Color.WHITE, "+%d" % r["acucar"])
		if r["moedas"] > 0:
			_item_premio(premio, ICONE_MOEDA, Cores.AMARELO, "+%d" % r["moedas"])
	elif n < 3:
		var dica := Label.new()
		dica.theme_type_variation = &"TextoClaro"
		dica.add_theme_font_size_override("font_size", 20)
		dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dica.text = "Jogue de novo sem errar para ganhar mais estrelas!"
		coluna.add_child(dica)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	var de_novo := Button.new()
	de_novo.name = "DeNovo"
	de_novo.text = "DE NOVO"
	de_novo.theme_type_variation = &"Alternativa"
	de_novo.custom_minimum_size = Vector2(220, 80)
	de_novo.pressed.connect(func():
		camada.queue_free()
		_comecar())
	botoes.add_child(de_novo)
	var mapa := Button.new()
	mapa.name = "Mapa"
	mapa.text = "CONTINUAR"
	mapa.theme_type_variation = &"BotaoRoxo"
	mapa.custom_minimum_size = Vector2(260, 80)
	mapa.pressed.connect(Telas.voltar)
	botoes.add_child(mapa)
	await get_tree().process_frame
	painel.pivot_offset = painel.size / 2
	painel.scale = Vector2.ONE * 0.6
	var tween := painel.create_tween()
	tween.tween_property(painel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in n:
		var e := estrelas[i]
		tween.tween_callback(func():
			e.modulate = Cores.OURO
			e.pivot_offset = e.size / 2
			e.scale = Vector2.ONE * 1.6
			Audio.tocar("moeda", 1.0 + i * 0.15))
		tween.tween_property(e, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
		tween.tween_interval(0.12)


func _item_premio(pai: Control, textura: Texture2D, cor: Color, texto: String) -> void:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	var icone := TextureRect.new()
	icone.texture = textura
	icone.modulate = cor
	icone.custom_minimum_size = Vector2(40, 40)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	linha.add_child(icone)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 38)
	rotulo.text = texto
	linha.add_child(rotulo)
	pai.add_child(linha)


# --- Montagem comum ----------------------------------------------------------------

func _montar() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 16)
	margem.add_child(coluna)
	# topo
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	coluna.add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(72, 72)
	voltar.icon = ICONE_VOLTAR
	voltar.expand_icon = true
	voltar.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.pressed.connect(Telas.voltar)
	topo.add_child(voltar)
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"EtiquetaAmarela"
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var titulo := Label.new()
	titulo.theme_type_variation = &"Titulo"
	var programa := "EXCEL" if fase["tipo"] == "excel" else "WORD"
	titulo.text = "%s · %s" % [programa, str(fase["titulo"]).to_upper()]
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(espaco)
	if fase.get("chefe", false):
		var vida := HBoxContainer.new()
		vida.name = "VidaChefe"
		vida.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for i in fase["passos"].size():
			var c := TextureRect.new()
			c.texture = ICONE_CORACAO
			c.custom_minimum_size = Vector2(40, 40)
			c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			c.modulate = Cores.VERMELHO
			vida.add_child(c)
			_coracoes.append(c)
		topo.add_child(vida)
	_rotulo_tarefa = Label.new()
	_rotulo_tarefa.theme_type_variation = &"TituloClaro"
	_rotulo_tarefa.add_theme_font_size_override("font_size", 26)
	_rotulo_tarefa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(_rotulo_tarefa)
	var dica := Button.new()
	dica.name = "Dica"
	dica.theme_type_variation = &"BotaoIconeAmarelo"
	dica.custom_minimum_size = Vector2(72, 72)
	dica.icon = ICONE_DICA
	dica.expand_icon = true
	dica.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.tooltip_text = "Dica (conta como meio erro)"
	dica.focus_mode = Control.FOCUS_NONE
	dica.pressed.connect(usar_dica)
	topo.add_child(dica)
	# corpo: área de trabalho + painel da tarefa
	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 20)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(corpo)
	_area = VBoxContainer.new()
	_area.name = "Area"
	_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_area.add_theme_constant_override("separation", 10)
	corpo.add_child(_area)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelEscuro"
	painel.custom_minimum_size = Vector2(350, 0)
	corpo.add_child(painel)
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 14)
	painel.add_child(lado)
	var rotulo_tarefa := Label.new()
	rotulo_tarefa.theme_type_variation = &"SubtituloClaro"
	rotulo_tarefa.add_theme_font_size_override("font_size", 22)
	rotulo_tarefa.text = "SUA TAREFA"
	lado.add_child(rotulo_tarefa)
	_rotulo_pedido = Label.new()
	_rotulo_pedido.name = "Pedido"
	_rotulo_pedido.theme_type_variation = &"TextoClaro"
	_rotulo_pedido.add_theme_font_size_override("font_size", 24)
	_rotulo_pedido.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lado.add_child(_rotulo_pedido)
	_feedback = Label.new()
	_feedback.name = "Feedback"
	_feedback.add_theme_font_size_override("font_size", 21)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lado.add_child(_feedback)
	_botao_conferir = Button.new()
	_botao_conferir.name = "Conferir"
	_botao_conferir.theme_type_variation = &"BotaoRoxo"
	_botao_conferir.custom_minimum_size = Vector2(0, 84)
	_botao_conferir.focus_mode = Control.FOCUS_NONE
	_botao_conferir.pressed.connect(conferir)
	lado.add_child(_botao_conferir)


# --- Excel ------------------------------------------------------------------------

func _montar_excel() -> void:
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 8)
	_area.add_child(barra)
	var nome := PanelContainer.new()
	nome.theme_type_variation = &"Etiqueta"
	nome.custom_minimum_size = Vector2(84, 0)
	_caixa_nome = Label.new()
	_caixa_nome.theme_type_variation = &"TituloClaro"
	_caixa_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_child(_caixa_nome)
	barra.add_child(nome)
	var fx := Label.new()
	fx.theme_type_variation = &"TituloClaro"
	fx.text = "fx"
	barra.add_child(fx)
	_formula = LineEdit.new()
	_formula.name = "Formula"
	_formula.placeholder_text = "Digite a fórmula, começando com ="
	_formula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_formula.custom_minimum_size = Vector2(0, 60)
	_formula.add_theme_font_size_override("font_size", 28)
	_formula.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	_formula.text_submitted.connect(func(_t): conferir())
	_formula.text_changed.connect(_formula_mudou)
	barra.add_child(_formula)
	var atalhos := HFlowContainer.new()
	atalhos.name = "Atalhos"
	atalhos.add_theme_constant_override("h_separation", 6)
	atalhos.add_theme_constant_override("v_separation", 6)
	_area.add_child(atalhos)
	var moldura := PanelContainer.new()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("#FFFFFF")
	fundo.set_corner_radius_all(10)
	fundo.set_content_margin_all(6)
	moldura.add_theme_stylebox_override("panel", fundo)
	moldura.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_area.add_child(moldura)
	var colunas := int(fase["planilha"]["colunas"])
	var linhas := int(fase["planilha"]["linhas"])
	var largura := clampf(760.0 / colunas, 118.0, 260.0)
	_grade = GridContainer.new()
	_grade.name = "Planilha"
	_grade.columns = colunas + 1
	_grade.add_theme_constant_override("h_separation", 0)
	_grade.add_theme_constant_override("v_separation", 0)
	moldura.add_child(_grade)
	_grade.add_child(_celula_visual("", Vector2(LARGURA_CABECALHO, ALTURA_LINHA - 6), true))
	for x in colunas:
		_grade.add_child(_celula_visual(char(65 + x), Vector2(largura, ALTURA_LINHA - 6), true))
	for y in linhas:
		_grade.add_child(_celula_visual(str(y + 1), Vector2(LARGURA_CABECALHO, ALTURA_LINHA), true))
		for x in colunas:
			var ref := Formulas.nome_celula(Vector2i(x, y))
			var rotulo := _celula_visual("", Vector2(largura, ALTURA_LINHA), false)
			rotulo.name = "Celula_" + ref
			rotulo.mouse_filter = Control.MOUSE_FILTER_STOP
			rotulo.gui_input.connect(_toque_celula.bind(ref))
			_grade.add_child(rotulo)
			_rotulos_celulas[ref] = rotulo
			_escrever_celula(ref, celulas.get(ref), false)


func _celula_visual(texto: String, tamanho: Vector2, cabecalho: bool) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.custom_minimum_size = tamanho
	rotulo.clip_text = true
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if cabecalho else HORIZONTAL_ALIGNMENT_LEFT
	rotulo.add_theme_font_size_override("font_size", 20)
	rotulo.add_theme_color_override("font_color", Color("#555555") if cabecalho else Color("#1F1F1F"))
	rotulo.add_theme_stylebox_override("normal", _estilo_celula(Color("#E9E6EF") if cabecalho else Color.WHITE, Color("#C9C4D3"), 1))
	return rotulo


static func _estilo_celula(cor: Color, borda: Color, espessura: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = borda
	estilo.set_border_width_all(espessura)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	return estilo


## Mostra o valor na célula (números à direita, como no Excel).
func _escrever_celula(ref: String, valor: Variant, com_erro: bool) -> void:
	var rotulo: Label = _rotulos_celulas.get(ref)
	if rotulo == null:
		return
	var numero: bool = valor is float or valor is int or (valor is Object and Formulas.eh_erro(valor))
	rotulo.text = Formulas.texto(valor) if not valor is String else valor
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if numero else HORIZONTAL_ALIGNMENT_LEFT
	rotulo.add_theme_color_override("font_color", Cores.VERMELHO if com_erro else Color("#1F1F1F"))


func _marcar_celula_alvo() -> void:
	var alvo: String = _passo_atual()["celula"]
	_caixa_nome.text = alvo
	for ref in _rotulos_celulas:
		var r: Label = _rotulos_celulas[ref]
		if ref == alvo:
			r.add_theme_stylebox_override("normal", _estilo_celula(Color("#FFF6C2"), Color("#1B9E4B"), 3))
			if not celulas.has(ref):
				r.text = "?"
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			r.add_theme_stylebox_override("normal", _estilo_celula(Color.WHITE, Color("#C9C4D3"), 1))


func _formula_mudou(texto: String) -> void:
	if _acertou_passo:
		return
	var alvo: String = _passo_atual()["celula"]
	var rotulo: Label = _rotulos_celulas.get(alvo)
	if rotulo:
		rotulo.text = texto if texto != "" else "?"
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if texto != "" else HORIZONTAL_ALIGNMENT_CENTER
		rotulo.add_theme_color_override("font_color", Color("#1F1F1F"))


## Tocar numa célula escreve o endereço dela na fórmula. Se a última coisa
## escrita foi outra célula tocada, vira intervalo (B2 e depois B6 = B2:B6).
func _toque_celula(evento: InputEvent, ref: String) -> void:
	if not (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT):
		return
	tocar_celula(ref)


func tocar_celula(ref: String) -> void:
	if _acertou_passo or terminou:
		return
	var texto := _formula.text
	var caret := _formula.caret_column
	if texto == "":
		texto = "="
		caret = 1
	if _ultima_ref != "" and caret == _caret_depois_ref and texto.substr(0, caret).ends_with(_ultima_ref):
		var inicio := caret - _ultima_ref.length()
		var intervalo := _ultima_ref + ":" + ref
		texto = texto.substr(0, inicio) + intervalo + texto.substr(caret)
		caret = inicio + intervalo.length()
		_ultima_ref = ""
	else:
		texto = texto.substr(0, caret) + ref + texto.substr(caret)
		caret += ref.length()
		_ultima_ref = ref
	_formula.text = texto
	_formula.caret_column = caret
	_caret_depois_ref = caret
	_formula_mudou(texto)
	Audio.tocar("estouro", 1.6, -8.0)


func _atualizar_atalhos_excel() -> void:
	var atalhos: HFlowContainer = _area.get_node("Atalhos")
	for filho in atalhos.get_children():
		atalhos.remove_child(filho)
		filho.queue_free()
	var itens := ["=", "(", ")", ";", ":", "\"", "$", "+", "-", "*", "/", ">", "<", "&"]
	var funcoes := []
	for f in Formulas.funcoes_usadas(_passo_atual()["resposta"]):
		var nome: String = NOMES_FUNCOES.get(f, f)
		if not nome + "(" in funcoes:
			funcoes.append(nome + "(")
	for texto in funcoes + itens:
		var b := Button.new()
		b.text = texto
		b.theme_type_variation = &"Alternativa" if texto.length() > 2 else &"BotaoIconeAmarelo"
		b.custom_minimum_size = Vector2(56 if texto.length() <= 2 else 0, 52)
		b.add_theme_font_size_override("font_size", 24)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_inserir.bind(texto))
		atalhos.add_child(b)
	var apagar := Button.new()
	apagar.name = "Apagar"
	apagar.text = "⌫"
	apagar.theme_type_variation = &"Alternativa"
	apagar.custom_minimum_size = Vector2(64, 52)
	apagar.focus_mode = Control.FOCUS_NONE
	apagar.pressed.connect(func():
		var c := _formula.caret_column
		if c > 0:
			_formula.text = _formula.text.substr(0, c - 1) + _formula.text.substr(c)
			_formula.caret_column = c - 1
			_formula_mudou(_formula.text))
	atalhos.add_child(apagar)


func _inserir(texto: String) -> void:
	if _acertou_passo:
		return
	var c := _formula.caret_column
	_formula.text = _formula.text.substr(0, c) + texto + _formula.text.substr(c)
	_formula.caret_column = c + texto.length()
	_ultima_ref = ""
	_formula_mudou(_formula.text)


# --- Word -------------------------------------------------------------------------

func _montar_word() -> void:
	var fita := HFlowContainer.new()
	fita.name = "Fita"
	fita.add_theme_constant_override("h_separation", 6)
	fita.add_theme_constant_override("v_separation", 6)
	_area.add_child(fita)
	for acao in ["negrito", "italico", "sublinhado"]:
		_botao_fita(fita, acao, {"negrito": "N", "italico": "I", "sublinhado": "S"}[acao])
	_separador(fita)
	for acao in ["esquerda", "centro", "direita", "justificado"]:
		_botao_fita(fita, acao, "")
	_separador(fita)
	_botao_fita(fita, "menor", "A-")
	_botao_fita(fita, "maior", "A+")
	_separador(fita)
	for cor in DocumentoWord.CORES:
		var b := Button.new()
		b.name = "Acao_cor_" + cor
		b.custom_minimum_size = Vector2(46, 46)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "Cor: " + cor
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(DocumentoWord.CORES[cor])
		estilo.set_corner_radius_all(23)
		estilo.set_border_width_all(4)
		estilo.border_color = Color.WHITE
		for estado in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(estado, estilo)
		b.pressed.connect(fazer.bind("cor_" + cor))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fita.add_child(b)
	_separador(fita)
	_botao_fita(fita, "tudo", "TUDO")
	_botao_fita(fita, "desfazer", "")
	var pagina := PanelContainer.new()
	pagina.name = "Pagina"
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color.WHITE
	fundo.set_corner_radius_all(8)
	fundo.set_content_margin_all(28)
	fundo.shadow_color = Color(0, 0, 0, 0.25)
	fundo.shadow_size = 8
	pagina.add_theme_stylebox_override("panel", fundo)
	pagina.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_area.add_child(pagina)
	var texto := VBoxContainer.new()
	texto.add_theme_constant_override("separation", 14)
	pagina.add_child(texto)
	for i in doc.paragrafos.size():
		var rt := RichTextLabel.new()
		rt.name = "Paragrafo%d" % i
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.scroll_active = false
		rt.meta_underlined = false
		rt.selection_enabled = false
		rt.add_theme_color_override("default_color", Color("#222222"))
		rt.add_theme_font_override("normal_font", _fonte(400, false))
		rt.add_theme_font_override("bold_font", _fonte(850, false))
		rt.add_theme_font_override("italics_font", _fonte(400, true))
		rt.add_theme_font_override("bold_italics_font", _fonte(850, true))
		rt.meta_clicked.connect(_tocar_palavra)
		texto.add_child(rt)
		_paragrafos.append(rt)
	var ajuda := Label.new()
	ajuda.theme_type_variation = &"TextoClaro"
	ajuda.add_theme_font_size_override("font_size", 17)
	ajuda.text = "Toque numa palavra para selecionar; toque de novo para pegar o parágrafo todo."
	_area.add_child(ajuda)


## Nunito com o peso pedido (o tema do jogo usa negrito em tudo; na página
## o texto normal precisa ser normal para o negrito aparecer).
static func _fonte(peso: int, italico: bool) -> FontVariation:
	var fonte := FontVariation.new()
	fonte.base_font = FONTE_TEXTO
	fonte.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): peso}
	if italico:
		fonte.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.22, 1), Vector2.ZERO)
	return fonte


func _botao_fita(pai: Control, acao: String, texto: String) -> void:
	var b := Button.new()
	b.name = "Acao_" + acao
	b.text = texto
	b.custom_minimum_size = Vector2(60, 56) if texto.length() <= 2 else Vector2(0, 56)
	b.theme_type_variation = &"Alternativa"
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	if ICONES_ACAO.has(acao):
		# ícone como filho (o do botão fica pequeno por causa das margens do tema)
		var icone := TextureRect.new()
		icone.name = "Icone"
		icone.texture = ICONES_ACAO[acao]
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.set_anchors_preset(PRESET_FULL_RECT)
		icone.offset_left = 8
		icone.offset_right = -8
		icone.offset_top = 4
		icone.offset_bottom = -10
		icone.modulate = Cores.ROXO
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icone)
	b.pressed.connect(fazer.bind(acao))
	pai.add_child(b)
	_botoes_acao[acao] = b


func _separador(pai: Control) -> void:
	var s := VSeparator.new()
	s.custom_minimum_size = Vector2(8, 40)
	pai.add_child(s)


func _tocar_palavra(meta: Variant) -> void:
	if terminou:
		return
	doc.tocar(int(str(meta)), Input.is_key_pressed(KEY_SHIFT))
	_desenhar_documento()


## Botão da fita ou atalho do teclado.
func fazer(acao: String) -> void:
	if terminou or doc == null:
		return
	if acao != "tudo" and acao != "desfazer" and not doc.tem_selecao():
		Telas.mostrar_aviso("TOQUE NUMA PALAVRA PRIMEIRO")
		return
	if doc.fazer(acao):
		_desenhar_documento()


func _desenhar_documento() -> void:
	for i in _paragrafos.size():
		_paragrafos[i].text = doc.bbcode(i)
	for acao in ["negrito", "italico", "sublinhado"]:
		if _botoes_acao.has(acao):
			_botoes_acao[acao].theme_type_variation = &"BotaoRoxo" if doc.ligado(acao) else &"Alternativa"
	var alinhamento := doc.alinhamento_atual()
	for acao in DocumentoWord.ALINHAMENTOS:
		if _botoes_acao.has(acao):
			var ligado: bool = acao == alinhamento
			_botoes_acao[acao].theme_type_variation = &"BotaoRoxo" if ligado else &"Alternativa"
			_botoes_acao[acao].get_node("Icone").modulate = Cores.AMARELO if ligado else Cores.ROXO


func _input(evento: InputEvent) -> void:
	if fase.get("tipo", "") != "word" or not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	var acao := DocumentoWord.acao_do_atalho(evento.keycode, evento.ctrl_pressed or evento.meta_pressed, evento.shift_pressed)
	if acao != "":
		get_viewport().set_input_as_handled()
		fazer(acao)
