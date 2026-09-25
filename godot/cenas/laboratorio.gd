extends Control
## Laboratório do Office: o mapa de aventura. Um caminho com as fases (bolinhas
## numeradas), os baús e os chefes de cada capítulo. Tocar numa fase abre um
## resumo com o botão JOGAR; tocar num baú pronto abre ele com animação.
## Regras em scripts/laboratorio.gd.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_ESTRELA := Itens.ESTRELA
const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")
const ICONE_COROA := preload("res://assets/icones/coroa.svg")
const ICONE_MOEDA := Itens.MOEDA
const ICONE_ACUCAR := Itens.ACUCAR
const BAU := Itens.BAU_MADEIRA
const BAU_CHEFE := Itens.BAU_CHEFE
const BAU_ABERTO := Itens.BAU_ABERTO
const PASSO_X := 150.0
const INICIO_X := 150.0
const ESPACO_CAPITULO := 110.0
const ALTURA_MAPA := 560.0
const CORES_TIPO := {"excel": Color("#1B9E4B"), "word": Color("#1E6FD9")}

var _rolagem: ScrollContainer
var _mapa: Control
var _botoes := {}  # id da fase ou do baú -> Control
var _posicoes := {}  # id -> Vector2 (centro)
var _rotulo_estrelas: Label
var _rotulo_moedas: Label
var _rotulo_acucar: Label
var _painel: Control
var _arrastando := false
var _arrasto_inicio := 0.0
var _rolagem_inicio := 0


func _ready() -> void:
	_montar_topo()
	_montar_mapa()
	_atualizar_placar()
	_centralizar.call_deferred()
	Telas.dica_primeira_vez("laboratorio", "LABORATÓRIO DO OFFICE",
		"Aqui você usa o Excel e o Word de verdade! Cada fase é uma tarefa: faça sem errar e sem dica para ganhar 3 estrelas. No fim de cada capítulo tem um CHEFE, e no caminho tem baús.")


## Botão "voltar" do celular.
func ao_voltar() -> void:
	if is_instance_valid(_painel):
		_fechar_painel()
		return
	Telas.voltar()


func _atualizar_placar() -> void:
	_rotulo_estrelas.text = "%d/%d" % [Laboratorio.total_estrelas(), Laboratorio.estrelas_possiveis()]
	_rotulo_moedas.text = Jogo.formatar(Progresso.moedas)
	_rotulo_acucar.text = str(Confeitaria.acucar())


## Rola o mapa até a próxima fase (ou até o baú pronto) e anima a fase nova.
func _centralizar() -> void:
	await get_tree().process_frame
	var alvo := Laboratorio.proxima_fase()
	for b in Laboratorio.baus():
		if Laboratorio.bau_pronto(b["id"]):
			alvo = b["id"]
			break
	if alvo == "":
		alvo = Laboratorio.fases()[-1]["id"]
	var x: float = _posicoes[alvo].x
	_rolagem.scroll_horizontal = int(x - _rolagem.size.x / 2)
	if Laboratorio.recem_concluida != "" and _botoes.has(Laboratorio.proxima_fase()):
		var novo: Control = _botoes[Laboratorio.proxima_fase()]
		novo.pivot_offset = novo.size / 2
		novo.scale = Vector2.ZERO
		novo.create_tween().tween_property(novo, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.3)
		Audio.tocar("estouro", 1.2)
	Laboratorio.recem_concluida = ""


# --- Topo -----------------------------------------------------------------------

func _montar_topo() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_TOP_WIDE)
	for lado in ["left", "right", "top"]:
		margem.add_theme_constant_override("margin_" + lado, 28)
	add_child(margem)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	margem.add_child(topo)
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
	titulo.text = "LABORATÓRIO DO OFFICE"
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(espaco)
	_rotulo_estrelas = _contador(topo, ICONE_ESTRELA, Color.WHITE)
	_rotulo_acucar = _contador(topo, ICONE_ACUCAR, Color.WHITE)
	_rotulo_moedas = _contador(topo, ICONE_MOEDA, Color.WHITE)


func _contador(pai: Control, icone_textura: Texture2D, cor: Color) -> Label:
	var caixa := PanelContainer.new()
	caixa.theme_type_variation = &"Etiqueta"
	caixa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	caixa.add_child(linha)
	var icone := TextureRect.new()
	icone.texture = icone_textura
	icone.modulate = cor
	icone.custom_minimum_size = Vector2(30, 30)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(icone)
	var valor := Label.new()
	valor.theme_type_variation = &"TituloClaro"
	linha.add_child(valor)
	pai.add_child(caixa)
	return valor


# --- Mapa -----------------------------------------------------------------------

func _montar_mapa() -> void:
	_rolagem = ScrollContainer.new()
	_rolagem.name = "Rolagem"
	_rolagem.set_anchors_preset(PRESET_FULL_RECT)
	_rolagem.offset_top = 120
	_rolagem.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_rolagem)
	move_child(_rolagem, 1)  # atrás do topo, na frente do fundo
	_mapa = Control.new()
	_mapa.name = "Mapa"
	_mapa.gui_input.connect(_arrastar_mapa)
	_rolagem.add_child(_mapa)

	# posições: capítulo (faixa), 4 fases, baú, 4 fases (a última é o chefe), baú
	var x := INICIO_X
	var k := 0
	var caminho: Array[Vector2] = []
	var feito_ate := 0
	var baus := Laboratorio.baus()
	for c in Laboratorio.capitulos().size():
		var capitulo: Dictionary = Laboratorio.capitulos()[c]
		_faixa_capitulo(c, capitulo, x)
		var fases: Array = capitulo["fases"]
		for i in fases.size():
			var id: String = fases[i]["id"]
			var ponto := Vector2(x, _altura(k))
			_posicoes[id] = ponto
			caminho.append(ponto)
			if Laboratorio.concluida(id):
				feito_ate = caminho.size()
			x += PASSO_X
			k += 1
			var bau_aqui := baus.filter(func(b): return b["depois_de"] == id)
			if not bau_aqui.is_empty():
				var id_bau: String = bau_aqui[0]["id"]
				ponto = Vector2(x, _altura(k))
				_posicoes[id_bau] = ponto
				caminho.append(ponto)
				if Laboratorio.concluida(id):
					feito_ate = caminho.size()
				x += PASSO_X
				k += 1
		x += ESPACO_CAPITULO
	_mapa.custom_minimum_size = Vector2(x, ALTURA_MAPA)

	var linha := Line2D.new()
	linha.points = caminho
	linha.width = 22
	linha.default_color = Color(1, 1, 1, 0.35)
	linha.joint_mode = Line2D.LINE_JOINT_ROUND
	linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
	linha.end_cap_mode = Line2D.LINE_CAP_ROUND
	_mapa.add_child(linha)
	if feito_ate > 1:
		var feita := linha.duplicate()
		feita.points = caminho.slice(0, feito_ate)
		feita.default_color = Cores.AMARELO
		feita.width = 14
		_mapa.add_child(feita)

	for f in Laboratorio.fases():
		_criar_fase(f)
	for b in baus:
		_criar_bau(b)


func _altura(k: int) -> float:
	return ALTURA_MAPA * 0.52 + sin(k * 0.8) * 150.0


func _faixa_capitulo(c: int, capitulo: Dictionary, x: float) -> void:
	var faixa := PanelContainer.new()
	faixa.theme_type_variation = &"PainelEscuro"
	faixa.position = Vector2(x - 70, 8)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 0)
	faixa.add_child(coluna)
	var titulo := Label.new()
	titulo.theme_type_variation = &"TituloClaro"
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.text = "CAPÍTULO %d · %s" % [c + 1, capitulo["titulo"]]
	coluna.add_child(titulo)
	var sub := Label.new()
	sub.theme_type_variation = &"TextoClaro"
	sub.add_theme_font_size_override("font_size", 18)
	sub.text = capitulo.get("subtitulo", "")
	coluna.add_child(sub)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mapa.add_child(faixa)


static func _estilo_circulo(cor: Color, borda: Color, raio: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(int(raio))
	estilo.set_border_width_all(6)
	estilo.border_color = borda
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 6
	estilo.shadow_offset = Vector2(0, 5)
	return estilo


func _criar_fase(f: Dictionary) -> void:
	var id: String = f["id"]
	var chefe: bool = f.get("chefe", false)
	var liberada := Laboratorio.liberada(id)
	var atual := id == Laboratorio.proxima_fase()
	var lado := 124.0 if chefe else 96.0
	var botao := Button.new()
	botao.name = "Fase_" + id
	botao.focus_mode = Control.FOCUS_NONE
	botao.custom_minimum_size = Vector2(lado, lado)
	botao.size = Vector2(lado, lado)
	botao.position = _posicoes[id] - botao.size / 2
	var cor := Cores.ROXO
	if chefe:
		cor = Cores.VERMELHO
	if atual:
		cor = Cores.AMARELO_ESCURO if not chefe else Cores.VERMELHO
	if not liberada:
		cor = Color("#8C8499")
	var estilo := _estilo_circulo(cor, Color.WHITE if liberada else Color("#D9D4E2"), lado / 2)
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		botao.add_theme_stylebox_override(estado, estilo)
	var numero := Laboratorio.fases().map(func(x): return x["id"]).find(id) % 8 + 1
	if not liberada:
		botao.icon = ICONE_CADEADO
	elif chefe:
		botao.icon = ICONE_COROA
	else:
		botao.text = str(numero)
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.add_theme_constant_override("icon_max_width", int(lado * 0.5))
	botao.add_theme_font_size_override("font_size", 44)
	botao.add_theme_color_override("font_color", Color.WHITE)
	botao.pressed.connect(_tocar_fase.bind(id))
	_mapa.add_child(botao)
	_botoes[id] = botao
	# selo do programa (X verde = Excel, W azul = Word)
	var selo := Label.new()
	selo.text = "X" if f["tipo"] == "excel" else "W"
	selo.add_theme_font_size_override("font_size", 20)
	selo.add_theme_color_override("font_color", Color.WHITE)
	selo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selo.custom_minimum_size = Vector2(34, 34)
	selo.size = Vector2(34, 34)
	var fundo_selo := _estilo_circulo(CORES_TIPO[f["tipo"]], Color.WHITE, 17)
	fundo_selo.set_border_width_all(3)
	fundo_selo.shadow_size = 0
	selo.add_theme_stylebox_override("normal", fundo_selo)
	selo.position = Vector2(lado - 30, -6)
	selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao.add_child(selo)
	# estrelas embaixo
	var estrelas := HBoxContainer.new()
	estrelas.add_theme_constant_override("separation", 0)
	estrelas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		var e := TextureRect.new()
		e.texture = ICONE_ESTRELA
		e.custom_minimum_size = Vector2(28, 28)
		e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		e.modulate = Color.WHITE if i < Laboratorio.estrelas(id) else Itens.ESTRELA_APAGADA
		estrelas.add_child(e)
	estrelas.position = Vector2(lado / 2 - 42, lado + 2)
	if liberada:
		botao.add_child(estrelas)
	else:
		estrelas.free()  # fase trancada não mostra estrelas (e não pode sobrar solta)
	if chefe:
		var nome := Label.new()
		nome.theme_type_variation = &"TituloClaro"
		nome.add_theme_font_size_override("font_size", 20)
		nome.text = "CHEFE"
		nome.position = Vector2(lado / 2 - 30, -34)
		nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(nome)
	if atual:
		_marcar_atual(botao, lado)


## Doce do jogador em cima da fase atual, pulando.
func _marcar_atual(botao: Control, lado: float) -> void:
	var id_doce := Colecao.companheiro()
	if id_doce == "":
		id_doce = "brigadeiro"
	var foto := TextureRect.new()
	foto.name = "Jogador"
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foto.texture = Personagens.textura(id_doce)
	foto.custom_minimum_size = Vector2(84, 84)
	foto.size = Vector2(84, 84)
	foto.position = Vector2(lado / 2 - 42, -92)
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao.add_child(foto)
	if Telas.animacoes_continuas:
		var tween := foto.create_tween().set_loops()
		tween.tween_property(foto, "position:y", -106.0, 0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_property(foto, "position:y", -92.0, 0.45).set_trans(Tween.TRANS_SINE)


func _criar_bau(b: Dictionary) -> void:
	var id: String = b["id"]
	var botao := TextureButton.new()
	botao.name = "Bau_" + id
	botao.ignore_texture_size = true
	botao.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var lado := Vector2(110, 96) if b["tipo"] == "chefe" else Vector2(90, 78)
	botao.custom_minimum_size = lado
	botao.size = lado
	botao.position = _posicoes[id] - lado / 2
	botao.pivot_offset = lado / 2
	if Laboratorio.bau_aberto(id):
		botao.texture_normal = BAU_ABERTO
		botao.modulate = Color(1, 1, 1, 0.55)
	else:
		botao.texture_normal = BAU_CHEFE if b["tipo"] == "chefe" else BAU
		if not Laboratorio.bau_pronto(id):
			botao.modulate = Color(0.65, 0.62, 0.72)
		else:
			var aviso := Label.new()
			aviso.name = "Abra"
			aviso.theme_type_variation = &"TituloClaro"
			aviso.add_theme_font_size_override("font_size", 26)
			aviso.add_theme_color_override("font_color", Cores.AMARELO)
			aviso.text = "ABRA!"
			aviso.position = Vector2(lado.x / 2 - 30, -34)
			aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
			botao.add_child(aviso)
		if Laboratorio.bau_pronto(id) and Telas.animacoes_continuas:
			var tween := botao.create_tween().set_loops()
			tween.tween_property(botao, "rotation", 0.12, 0.12)
			tween.tween_property(botao, "rotation", -0.12, 0.12)
			tween.tween_property(botao, "rotation", 0.0, 0.12)
			tween.tween_interval(0.9)
	botao.pressed.connect(_tocar_bau.bind(id))
	_mapa.add_child(botao)
	_botoes[id] = botao


## No computador, arrastar o mapa com o mouse também rola (no celular o
## ScrollContainer já rola com o dedo).
func _arrastar_mapa(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_arrastando = evento.pressed
		_arrasto_inicio = evento.global_position.x
		_rolagem_inicio = _rolagem.scroll_horizontal
	elif evento is InputEventMouseMotion and _arrastando:
		_rolagem.scroll_horizontal = _rolagem_inicio - int(evento.global_position.x - _arrasto_inicio)


# --- Fase escolhida ---------------------------------------------------------------

func _tocar_fase(id: String) -> void:
	if not Laboratorio.liberada(id):
		Telas.mostrar_aviso("PASSE NA FASE ANTERIOR PRIMEIRO!")
		return
	var f := Laboratorio.fase(id)
	var painel := _painel_central()
	var coluna: VBoxContainer = painel.get_child(0)
	var programa := "EXCEL" if f["tipo"] == "excel" else "WORD"
	_rotulo(coluna, ("CHEFE · " if f.get("chefe", false) else "") + programa, 26)
	_rotulo(coluna, str(f["titulo"]).to_upper(), 48)
	var estrelas := HBoxContainer.new()
	estrelas.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var e := TextureRect.new()
		e.texture = ICONE_ESTRELA
		e.custom_minimum_size = Vector2(56, 56)
		e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		e.modulate = Color.WHITE if i < Laboratorio.estrelas(id) else Itens.ESTRELA_APAGADA
		estrelas.add_child(e)
	coluna.add_child(estrelas)
	var tarefas: int = f["passos"].size()
	var recompensa := "" if Laboratorio.concluida(id) else "\nPRÊMIO: %d DE AÇÚCAR + %d MOEDAS" % [
		Laboratorio.ACUCAR_CHEFE if f.get("chefe", false) else Laboratorio.ACUCAR_FASE,
		Laboratorio.MOEDAS_CHEFE if f.get("chefe", false) else Laboratorio.MOEDAS_FASE]
	_rotulo(coluna, ("%d TAREFAS" % tarefas if tarefas > 1 else "1 TAREFA") + recompensa, 22)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	var fechar := Button.new()
	fechar.name = "Fechar"
	fechar.text = "VOLTAR"
	fechar.theme_type_variation = &"Alternativa"
	fechar.custom_minimum_size = Vector2(200, 80)
	fechar.pressed.connect(_fechar_painel)
	botoes.add_child(fechar)
	var jogar := Button.new()
	jogar.name = "Jogar"
	jogar.text = "JOGAR"
	jogar.theme_type_variation = &"BotaoRoxo"
	jogar.custom_minimum_size = Vector2(240, 80)
	jogar.pressed.connect(jogar_fase.bind(id))
	botoes.add_child(jogar)
	_abrir_painel(painel)


func jogar_fase(id: String) -> void:
	Laboratorio.fase_atual = id
	Telas.abrir("lab_fase")


# --- Baús -------------------------------------------------------------------------

func _tocar_bau(id: String) -> void:
	if Laboratorio.bau_aberto(id):
		Telas.mostrar_aviso("ESSE BAÚ JÁ FOI ABERTO")
		return
	if not Laboratorio.bau_pronto(id):
		var b := Laboratorio.bau(id)
		Telas.mostrar_aviso("PASSE NA FASE \"%s\" PARA ABRIR" % str(Laboratorio.fase(b["depois_de"])["titulo"]).to_upper())
		return
	abrir_bau(id)


## Abre o baú: ele treme cada vez mais, abre com um brilho e mostra o prêmio.
func abrir_bau(id: String, sorteio: RandomNumberGenerator = null) -> void:
	var b := Laboratorio.bau(id)
	var conteudo := Laboratorio.abrir_bau(id, sorteio)
	if conteudo.is_empty():
		return
	var painel := _painel_central()
	var coluna: VBoxContainer = painel.get_child(0)
	var titulo := _rotulo(coluna, conteudo["nome"], 44)
	var imagem := TextureRect.new()
	imagem.name = "Bau"
	imagem.texture = BAU_CHEFE if b["tipo"] == "chefe" else BAU
	imagem.custom_minimum_size = Vector2(220, 190)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coluna.add_child(imagem)
	var premio := VBoxContainer.new()
	premio.name = "Premio"
	premio.alignment = BoxContainer.ALIGNMENT_CENTER
	premio.modulate.a = 0.0
	coluna.add_child(premio)
	if conteudo["sorte"]:
		var sorte := _rotulo(premio, "SORTE GRANDE! PRÊMIO EM DOBRO!", 30)
		sorte.add_theme_color_override("font_color", Cores.AMARELO)
	_linha_premio(premio, ICONE_MOEDA, Color.WHITE, conteudo["moedas"], "MOEDAS")
	_linha_premio(premio, ICONE_ACUCAR, Color.WHITE, conteudo["acucar"], "DE AÇÚCAR")
	_linha_premio(premio, Itens.bau(conteudo["surpresa"]), Color.WHITE, 1, Baus.NOMES[conteudo["surpresa"]])
	var ok := Button.new()
	ok.name = "Pegar"
	ok.text = "PEGAR!"
	ok.theme_type_variation = &"BotaoRoxo"
	ok.custom_minimum_size = Vector2(240, 80)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.disabled = true
	ok.pressed.connect(_fechar_painel)
	coluna.add_child(ok)
	_abrir_painel(painel)
	titulo.text = "ABRINDO..."
	await get_tree().process_frame
	if not is_instance_valid(imagem):
		return
	imagem.pivot_offset = imagem.custom_minimum_size / 2
	var tween := create_tween()
	for forca in [0.08, 0.14, 0.22]:
		tween.tween_callback(Audio.tocar.bind("caixa", 0.8 + forca * 2))
		for lado in [1, -1, 1, -1]:
			tween.tween_property(imagem, "rotation", forca * lado, 0.06)
		tween.tween_property(imagem, "rotation", 0.0, 0.06)
		tween.tween_interval(0.18)
	tween.tween_callback(func():
		imagem.texture = BAU_ABERTO
		titulo.text = conteudo["nome"]
		Audio.tocar("construir")
		Audio.tocar("moeda", 1.2)
		ok.disabled = false
		_atualizar_placar())
	tween.tween_property(imagem, "scale", Vector2.ONE * 1.15, 0.12)
	tween.tween_property(imagem, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(premio, "modulate:a", 1.0, 0.3)
	# o baú do mapa passa a aparecer aberto
	_botoes[id].queue_free()
	_criar_bau(b)


func _linha_premio(pai: Control, icone_textura: Texture2D, cor: Color, valor: int, nome: String) -> void:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 10)
	var icone := TextureRect.new()
	icone.texture = icone_textura
	icone.modulate = cor
	icone.custom_minimum_size = Vector2(40, 40)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	linha.add_child(icone)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 36)
	rotulo.text = "+%d %s" % [valor, nome]
	linha.add_child(rotulo)
	pai.add_child(linha)


# --- Painéis ----------------------------------------------------------------------

func _painel_central() -> PanelContainer:
	if is_instance_valid(_painel):
		_painel.queue_free()
	var camada := Control.new()
	camada.name = "Painel"
	camada.set_anchors_preset(PRESET_FULL_RECT)
	add_child(camada)
	_painel = camada
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
	coluna.add_theme_constant_override("separation", 14)
	painel.add_child(coluna)
	return painel


func _abrir_painel(painel: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(painel):
		return
	painel.pivot_offset = painel.size / 2
	painel.scale = Vector2.ONE * 0.6
	painel.create_tween().tween_property(painel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fechar_painel() -> void:
	if is_instance_valid(_painel):
		_painel.queue_free()
	_painel = null
	_atualizar_placar()


func _rotulo(pai: Control, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 40 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.text = texto
	pai.add_child(rotulo)
	return rotulo
