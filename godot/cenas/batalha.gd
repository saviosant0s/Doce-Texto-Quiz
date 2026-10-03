extends Control
## ARENA DOS DOCES: batalhas de doces movidas a perguntas do quiz (regras em
## scripts/batalha.gd).
## - ARENA: o seu time e a escada de desafiantes (LUTAR / REVANCHE).
## - TROCAR TIME: escolha até 3 doces da sua coleção.
## - LUTA: o seu doce (esquerda) contra o do desafiante (direita), cada um com
##   a barra de vida e o time embaixo. A pergunta fica na parte de baixo: acertou,
##   o seu doce avança e bate; errou ou acabou o tempo, apanha.
## - FIM: vitória (prêmio) ou derrota (açúcar do esforço e tentar de novo).

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const BRILHO := preload("res://assets/doce_match/brilho.svg")
const FOTOS := "res://assets/doces_3d/fotos/%s.png"
const VERDE := Color("#7BE07B")
const AMARELO := Color("#F4E038")
const VERMELHO := Color("#FF5A5A")

var luta: Batalha
var _painel: Control
var _palco: Control
var _topo_titulo: Label
var _visor_meu: Doce3D
var _visor_deles: Doce3D
var _lado := {}  # "meu"/"deles" -> {"nome": Label, "vida": ProgressBar, "texto": Label, "banco": HBoxContainer}
var _super: HBoxContainer
var _quadro_pergunta: PanelContainer
var _enunciado: Label
var _barra_tempo: ProgressBar
var _cor_tempo: StyleBoxFlat
var _alternativas: GridContainer
var _tempo_resta := 0.0
var respondendo := false
var _escolha_time: Array = []


func _ready() -> void:
	_montar_fundo()
	_montar_topo()
	mostrar_arena()
	Telas.dica_primeira_vez("arena", "ARENA DOS DOCES",
		"Monte um time com até 3 doces da sua coleção e desafie os lutadores da vila. Cada rodada é uma pergunta: acertou, o seu doce ataca; errou, leva um golpe. Responda rápido para bater mais forte e acerte 3 seguidas para o SUPER!")


func ao_voltar() -> void:
	if is_instance_valid(_painel) and _painel.name == "Time":
		mostrar_arena()
		return
	if luta != null and not luta.acabou():
		desistir()
		return
	Telas.voltar()


func _process(delta: float) -> void:
	if not respondendo:
		return
	_tempo_resta = maxf(0.0, _tempo_resta - delta)
	_barra_tempo.value = _tempo_resta
	# o tempo vai do verde ao vermelho e pisca nos últimos segundos
	var fracao := _tempo_resta / Batalha.TEMPO
	_cor_tempo.bg_color = VERDE if fracao > 0.5 else (AMARELO if fracao > 0.25 else VERMELHO)
	_barra_tempo.modulate.a = 1.0 if _tempo_resta > 5.0 else 0.6 + 0.4 * absf(sin(_tempo_resta * 6.0))
	if _tempo_resta <= 0.0:
		responder(-1)


# --- Montagem ------------------------------------------------------------------------

func _montar_fundo() -> void:
	var ceu := TextureRect.new()
	ceu.set_anchors_preset(PRESET_FULL_RECT)
	ceu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ceu.stretch_mode = TextureRect.STRETCH_SCALE
	ceu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var degrade := Gradient.new()
	degrade.set_color(0, Color("#3B2A5C"))
	degrade.set_color(1, Color("#C25A9A"))
	var textura := GradientTexture2D.new()
	textura.gradient = degrade
	textura.fill_to = Vector2(0, 1)
	textura.width = 4
	textura.height = 256
	ceu.texture = textura
	add_child(ceu)
	# holofotes e brilhos de estádio
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 5
	for i in 26:
		var brilho := TextureRect.new()
		brilho.texture = BRILHO
		brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
		brilho.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var tamanho := sorteio.randf_range(10, 26)
		brilho.size = Vector2(tamanho, tamanho)
		brilho.anchor_left = sorteio.randf()
		brilho.anchor_right = brilho.anchor_left
		brilho.anchor_top = sorteio.randf() * 0.45
		brilho.anchor_bottom = brilho.anchor_top
		brilho.modulate.a = sorteio.randf_range(0.25, 0.7)
		add_child(brilho)
	# chão da arena: um palco oval de biscoito
	var chao := Panel.new()
	chao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#E0A95E")
	estilo.border_color = Color("#B97A3A")
	estilo.set_border_width_all(10)
	estilo.set_corner_radius_all(400)
	chao.add_theme_stylebox_override("panel", estilo)
	chao.anchor_left = 0.08
	chao.anchor_right = 0.92
	chao.anchor_top = 0.42
	chao.anchor_bottom = 0.62
	add_child(chao)


func _montar_topo() -> void:
	var topo := HBoxContainer.new()
	topo.name = "Topo"
	topo.set_anchors_preset(PRESET_TOP_WIDE)
	topo.offset_left = 18
	topo.offset_right = -18
	topo.offset_top = 14
	topo.add_theme_constant_override("separation", 12)
	add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(60, 60)
	voltar.icon = ICONE_VOLTAR
	voltar.expand_icon = true
	voltar.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.pressed.connect(ao_voltar)
	topo.add_child(voltar)
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"EtiquetaAmarela"
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_topo_titulo = Label.new()
	_topo_titulo.name = "TituloArena"
	_topo_titulo.theme_type_variation = &"Titulo"
	_topo_titulo.add_theme_font_size_override("font_size", 34)
	_topo_titulo.text = "ARENA DOS DOCES"
	etiqueta.add_child(_topo_titulo)
	topo.add_child(etiqueta)


## Monta a luta: os dois lados, o super no meio e o quadro da pergunta.
func _montar_palco() -> void:
	if is_instance_valid(_palco):
		_palco.queue_free()
	_palco = Control.new()
	_palco.name = "Palco"
	_palco.set_anchors_preset(PRESET_FULL_RECT)
	_palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_palco)
	move_child(_palco, get_node("Topo").get_index())  # o topo (voltar) fica por cima
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(PRESET_FULL_RECT)
	coluna.offset_left = 20
	coluna.offset_right = -20
	coluna.offset_top = 84
	coluna.offset_bottom = -14
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 8)
	_palco.add_child(coluna)
	var lados := HBoxContainer.new()
	lados.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lados.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(lados)
	_visor_meu = _montar_lado(lados, "meu")
	var meio := VBoxContainer.new()
	meio.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.custom_minimum_size = Vector2(150, 0)
	meio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lados.add_child(meio)
	var vs := Label.new()
	vs.name = "VS"
	vs.theme_type_variation = &"Numero"
	vs.add_theme_font_size_override("font_size", 64)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.text = "VS"
	meio.add_child(vs)
	var rotulo_super := Label.new()
	rotulo_super.theme_type_variation = &"SubtituloClaro"
	rotulo_super.add_theme_font_size_override("font_size", 22)
	rotulo_super.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_super.text = "SUPER"
	meio.add_child(rotulo_super)
	_super = HBoxContainer.new()
	_super.name = "Super"
	_super.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_child(_super)
	for i in Batalha.SUPER_COM:
		var estrela := TextureRect.new()
		estrela.texture = BRILHO
		estrela.custom_minimum_size = Vector2(34, 34)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_super.add_child(estrela)
	_visor_deles = _montar_lado(lados, "deles")
	# pergunta
	_quadro_pergunta = PanelContainer.new()
	_quadro_pergunta.name = "QuadroPergunta"
	_quadro_pergunta.theme_type_variation = &"PainelRoxo"
	coluna.add_child(_quadro_pergunta)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 8)
	_quadro_pergunta.add_child(dentro)
	_enunciado = Label.new()
	_enunciado.name = "Enunciado"
	_enunciado.theme_type_variation = &"TituloClaro"
	_enunciado.add_theme_font_size_override("font_size", 26)
	_enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enunciado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dentro.add_child(_enunciado)
	_barra_tempo = ProgressBar.new()
	_barra_tempo.name = "Tempo"
	_barra_tempo.show_percentage = false
	_barra_tempo.custom_minimum_size = Vector2(0, 14)
	var fundo_tempo := StyleBoxFlat.new()
	fundo_tempo.bg_color = Color(0, 0, 0, 0.3)
	fundo_tempo.set_corner_radius_all(999)
	_cor_tempo = StyleBoxFlat.new()
	_cor_tempo.bg_color = VERDE
	_cor_tempo.set_corner_radius_all(999)
	_barra_tempo.add_theme_stylebox_override("background", fundo_tempo)
	_barra_tempo.add_theme_stylebox_override("fill", _cor_tempo)
	_barra_tempo.max_value = Batalha.TEMPO
	dentro.add_child(_barra_tempo)
	_alternativas = GridContainer.new()
	_alternativas.name = "Alternativas"
	_alternativas.columns = 2
	_alternativas.add_theme_constant_override("h_separation", 10)
	_alternativas.add_theme_constant_override("v_separation", 8)
	dentro.add_child(_alternativas)


## Um lado da luta: plaquinha (nome, estrelas do nível, raridade e a barra de
## vida com rastro), o doce 3D e o time embaixo.
func _montar_lado(pai: Control, quem: String) -> Doce3D:
	var coluna := VBoxContainer.new()
	coluna.name = "Lado_" + quem
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 4)
	pai.add_child(coluna)
	var placa := PanelContainer.new()
	placa.name = "Placa"
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#2E1D4A", 0.92)
	estilo.set_corner_radius_all(16)
	estilo.set_border_width_all(4)
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 8
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 6
	placa.add_theme_stylebox_override("panel", estilo)
	coluna.add_child(placa)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 2)
	placa.add_child(dentro)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	dentro.add_child(linha)
	var nome := Label.new()
	nome.theme_type_variation = &"TituloClaro"
	nome.add_theme_font_size_override("font_size", 26)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(nome)
	var raridade := Label.new()
	raridade.theme_type_variation = &"TituloClaro"
	raridade.add_theme_font_size_override("font_size", 18)
	linha.add_child(raridade)
	var estrelas := Label.new()
	estrelas.theme_type_variation = &"TituloClaro"
	estrelas.add_theme_font_size_override("font_size", 20)
	estrelas.add_theme_color_override("font_color", Color("#FFC83D"))
	dentro.add_child(estrelas)
	# barra de vida: a de trás (branca) vai atrás da de cor, devagar (rastro do golpe)
	var barras := Control.new()
	barras.custom_minimum_size = Vector2(0, 24)
	dentro.add_child(barras)
	var rastro := _barra(Color(1, 1, 1, 0.85), Color(0, 0, 0, 0.4))
	barras.add_child(rastro)
	var vida := _barra(VERDE, Color(0, 0, 0, 0))
	vida.name = "Vida"
	barras.add_child(vida)
	var texto := Label.new()
	texto.theme_type_variation = &"TituloClaro"
	texto.add_theme_font_size_override("font_size", 18)
	texto.add_theme_constant_override("outline_size", 6)
	texto.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(PRESET_FULL_RECT)
	barras.add_child(texto)
	# o doce fica numa "vaga" fora do container: dá para ele avançar e tremer
	var vaga := Control.new()
	vaga.name = "Vaga"
	vaga.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vaga.custom_minimum_size = Vector2(0, 150)
	vaga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(vaga)
	var visor := Doce3D.new()
	visor.name = "Doce_" + quem
	visor.giravel = false
	visor.distancia = 6.3  # cabe a coroa dos doces de nível alto
	visor.angulo_inicial = -0.55 if quem == "meu" else 0.55
	visor.set_anchors_preset(PRESET_FULL_RECT)
	visor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vaga.add_child(visor)
	var banco := HBoxContainer.new()
	banco.name = "Banco"
	banco.alignment = BoxContainer.ALIGNMENT_CENTER
	banco.add_theme_constant_override("separation", 6)
	coluna.add_child(banco)
	_lado[quem] = {"nome": nome, "vida": vida, "rastro": rastro, "texto": texto, "banco": banco,
		"cheio": vida.get_theme_stylebox("fill"), "estilo": estilo, "raridade": raridade, "estrelas": estrelas}
	return visor


## Barra redonda de uma cor (vida, ataque...), ocupando o pai inteiro.
func _barra(cor: Color, fundo: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.set_anchors_preset(PRESET_FULL_RECT)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_fundo := StyleBoxFlat.new()
	estilo_fundo.bg_color = fundo
	estilo_fundo.set_corner_radius_all(999)
	var estilo_cheio := StyleBoxFlat.new()
	estilo_cheio.bg_color = cor
	estilo_cheio.set_corner_radius_all(999)
	barra.add_theme_stylebox_override("background", estilo_fundo)
	barra.add_theme_stylebox_override("fill", estilo_cheio)
	return barra


## "★★★☆☆" do nível do doce.
static func estrelas(nivel: int) -> String:
	var n := clampi(nivel, 0, Companheiros.NIVEL_MAXIMO)
	return "★".repeat(n) + "☆".repeat(Companheiros.NIVEL_MAXIMO - n)


# --- Arena (escada de desafiantes) --------------------------------------------------

func mostrar_arena() -> void:
	luta = null
	respondendo = false
	if is_instance_valid(_palco):
		_palco.queue_free()
	_topo_titulo.text = "ARENA DOS DOCES"
	var coluna := _abrir_painel("Arena", "ARENA DOS DOCES")
	# meu time
	var linha_time := HBoxContainer.new()
	linha_time.add_theme_constant_override("separation", 10)
	linha_time.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_child(linha_time)
	_texto(linha_time, "MEU TIME:", 30)
	var forca_time := 0
	for id in Batalha.time():
		linha_time.add_child(_moldura(id, 70, Companheiros.nivel(id)))
		forca_time += Batalha.forca(id, Companheiros.nivel(id))
	_texto(linha_time, "FORÇA %d" % forca_time, 24).name = "ForcaTime"
	var trocar := _botao("TrocarTime", "TROCAR TIME", &"BotaoAzul", mostrar_time)
	trocar.custom_minimum_size = Vector2(220, 60)
	linha_time.add_child(trocar)
	# desafiantes
	var rolar := ScrollContainer.new()
	rolar.custom_minimum_size = Vector2(1060, 430)
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolar)
	var lista := VBoxContainer.new()
	lista.name = "Desafiantes"
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	rolar.add_child(lista)
	var rolar_ate: Control = null
	for i in Batalha.DESAFIANTES.size():
		var d: Dictionary = Batalha.DESAFIANTES[i]
		var cartao := PanelContainer.new()
		cartao.name = "Desafiante%d" % i
		cartao.theme_type_variation = &"PainelEscuro" if Batalha.liberado(i) else &"Etiqueta"
		lista.add_child(cartao)
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 12)
		cartao.add_child(linha)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(info)
		_texto(info, "%d. %s" % [i + 1, d["nome"]], 30)
		var premio := Batalha.premio(i)
		var texto_premio := "PRÊMIO: %d MOEDAS + %d AÇÚCAR" % [premio["moedas"], premio["acucar"]]
		if premio.has("bau"):
			texto_premio += " + BAÚ " + ("DE OURO" if premio["bau"] == "ouro" else "DE DOCE")
		if premio.has("movel"):
			texto_premio += " + " + Casa.MOVEIS[premio["movel"]]["nome"]
		if Batalha.vencido(i):
			texto_premio = "VENCIDO ✓  REVANCHE: %d MOEDAS + %d AÇÚCAR" % [premio["moedas"], premio["acucar"]]
		_texto(info, texto_premio, 20)
		var forca_deles := 0
		for par in d["time"]:
			forca_deles += Batalha.forca(par[0], int(par[1]))
		if Batalha.liberado(i):
			var comparar := _texto(info, "FORÇA DELES: %d  %s" % [forca_deles,
				"(MAIS FRACOS QUE O SEU TIME)" if forca_deles < forca_time else "(MAIS FORTES: CAPRICHE NAS RESPOSTAS!)"], 18)
			comparar.add_theme_color_override("font_color", VERDE if forca_deles < forca_time else Color("#FFB36B"))
		for par in d["time"]:
			linha.add_child(_moldura(par[0], 62, int(par[1]), not Batalha.liberado(i)))
		if Batalha.liberado(i):
			var lutar_botao := _botao("Lutar%d" % i, "REVANCHE" if Batalha.vencido(i) else "LUTAR",
				&"BotaoAzul" if Batalha.vencido(i) else &"BotaoComprar", lutar.bind(i))
			lutar_botao.custom_minimum_size = Vector2(190, 64)
			linha.add_child(lutar_botao)
			if not Batalha.vencido(i):
				rolar_ate = cartao
		else:
			var falta_titulo := not Quiz.tem_titulo(str(d.get("titulo", "")))
			var trancado := _texto(linha, "JOGUE O QUIZ:\nTÍTULO " + Colecao.NOMES_TITULOS[d["titulo"]]
				if falta_titulo and (i == 0 or Batalha.vencido(i - 1)) else "VENÇA O ANTERIOR", 22)
			trancado.custom_minimum_size = Vector2(190, 0)
	if rolar_ate:
		await get_tree().process_frame
		if is_instance_valid(rolar) and is_instance_valid(rolar_ate):
			rolar.ensure_control_visible(rolar_ate)


## Escolha do time: cartões dos doces da coleção (raridade, estrelas do
## nível, vida e ataque). Toque para pôr ou tirar (até 3) e PRONTO.
func mostrar_time() -> void:
	_escolha_time = Batalha.time()
	var coluna := _abrir_painel("Time", "MONTE SEU TIME")
	_texto(coluna, "Até %d doces. Doce mais raro e de nível mais alto tem mais vida e ataque!" % Batalha.TAMANHO_TIME, 22)
	var vagas := HBoxContainer.new()
	vagas.name = "Vagas"
	vagas.alignment = BoxContainer.ALIGNMENT_CENTER
	vagas.add_theme_constant_override("separation", 14)
	coluna.add_child(vagas)
	var rolar := ScrollContainer.new()
	rolar.custom_minimum_size = Vector2(1080, 330)
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolar)
	var grade := GridContainer.new()
	grade.name = "GradeTime"
	grade.columns = 6
	grade.add_theme_constant_override("h_separation", 10)
	grade.add_theme_constant_override("v_separation", 10)
	rolar.add_child(grade)
	var maior_vida := 1
	var maior_ataque := 1
	for doce in Colecao.LISTA:
		if Colecao.tem(doce["id"]):
			maior_vida = maxi(maior_vida, Batalha.vida(doce["id"], Companheiros.nivel(doce["id"])))
			maior_ataque = maxi(maior_ataque, Batalha.ataque(doce["id"], Companheiros.nivel(doce["id"])))
	for doce in Colecao.LISTA:
		var id: String = doce["id"]
		if not Colecao.tem(id):
			continue
		var cartao := _cartao_doce(id, Companheiros.nivel(id), maior_vida, maior_ataque)
		cartao.name = "Escolher_" + id
		cartao.gui_input.connect(func(evento: InputEvent):
			if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed:
				_alternar_no_time(id, grade))
		grade.add_child(cartao)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("VoltarTime", "VOLTAR", &"BotaoSecundario", mostrar_arena))
	botoes.add_child(_botao("ProntoTime", "PRONTO", &"BotaoComprar", func():
		if Batalha.escolher_time(_escolha_time):
			mostrar_arena()
		else:
			Telas.mostrar_aviso("ESCOLHA PELO MENOS 1 DOCE")))
	_atualizar_escolha(grade)


## Cartão de um doce: moldura na cor da raridade, foto, nome, estrelas do
## nível e as barras de vida e ataque (comparadas com o mais forte da coleção).
func _cartao_doce(id: String, nivel: int, maior_vida: int, maior_ataque: int) -> PanelContainer:
	var cor := Companheiros.cor(id)
	var cartao := PanelContainer.new()
	cartao.custom_minimum_size = Vector2(168, 0)
	cartao.mouse_filter = Control.MOUSE_FILTER_STOP
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#2E1D4A")
	estilo.set_corner_radius_all(16)
	estilo.set_border_width_all(4)
	estilo.border_color = cor
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 8
	cartao.add_theme_stylebox_override("panel", estilo)
	cartao.set_meta("estilo", estilo)
	cartao.set_meta("id", id)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 2)
	cartao.add_child(coluna)
	var raridade := Label.new()
	raridade.theme_type_variation = &"TituloClaro"
	raridade.add_theme_font_size_override("font_size", 15)
	raridade.add_theme_color_override("font_color", cor.lightened(0.3))
	raridade.text = Companheiros.nome_raridade(id)
	raridade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cima := HBoxContainer.new()
	cima.custom_minimum_size = Vector2(0, 28)
	cima.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(cima)
	cima.add_child(raridade)
	var foto := _foto(id, 92)
	foto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(foto)
	var nome := Label.new()
	nome.theme_type_variation = &"TituloClaro"
	nome.add_theme_font_size_override("font_size", 18)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.clip_text = true
	nome.text = Batalha.nome_doce(id)
	coluna.add_child(nome)
	var estrelas_nivel := Label.new()
	estrelas_nivel.theme_type_variation = &"TituloClaro"
	estrelas_nivel.add_theme_font_size_override("font_size", 16)
	estrelas_nivel.add_theme_color_override("font_color", Color("#FFC83D"))
	estrelas_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estrelas_nivel.text = estrelas(nivel)
	coluna.add_child(estrelas_nivel)
	for par in [["♥", Batalha.vida(id, nivel), maior_vida, Color("#FF6F8E")], ["⚔", Batalha.ataque(id, nivel), maior_ataque, Color("#FFC83D")]]:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 4)
		coluna.add_child(linha)
		var rotulo := Label.new()
		rotulo.theme_type_variation = &"TituloClaro"
		rotulo.add_theme_font_size_override("font_size", 16)
		rotulo.custom_minimum_size = Vector2(52, 0)
		rotulo.text = "%s %d" % [par[0], par[1]]
		linha.add_child(rotulo)
		var caixa := Control.new()
		caixa.custom_minimum_size = Vector2(0, 10)
		caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caixa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(caixa)
		var barra := _barra(par[3], Color(0, 0, 0, 0.35))
		barra.max_value = par[2]
		barra.value = par[1]
		caixa.add_child(barra)
	var marca := Label.new()
	marca.name = "Marca"
	marca.theme_type_variation = &"Titulo"
	marca.add_theme_font_size_override("font_size", 20)
	marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fundo_marca := StyleBoxFlat.new()
	fundo_marca.bg_color = AMARELO
	fundo_marca.set_corner_radius_all(999)
	fundo_marca.content_margin_left = 9
	fundo_marca.content_margin_right = 9
	marca.add_theme_stylebox_override("normal", fundo_marca)
	marca.visible = false
	cima.add_child(marca)
	return cartao


func _alternar_no_time(id: String, grade: Control) -> void:
	if id in _escolha_time:
		_escolha_time.erase(id)
	elif _escolha_time.size() < Batalha.TAMANHO_TIME:
		_escolha_time.append(id)
		Audio.tocar("estouro", 1.2, -6.0)
	else:
		Telas.mostrar_aviso("O TIME TEM NO MÁXIMO %d DOCES" % Batalha.TAMANHO_TIME)
		return
	_atualizar_escolha(grade)


## Marca os escolhidos (número da ordem, moldura acesa) e mostra as vagas do time.
func _atualizar_escolha(grade: Control) -> void:
	for cartao in grade.get_children():
		var id: String = cartao.get_meta("id")
		var ordem := _escolha_time.find(id)
		var estilo: StyleBoxFlat = cartao.get_meta("estilo")
		estilo.bg_color = Color("#5B3A8E") if ordem >= 0 else Color("#2E1D4A")
		estilo.shadow_color = Color(AMARELO, 0.6) if ordem >= 0 else Color(0, 0, 0, 0)
		estilo.shadow_size = 10 if ordem >= 0 else 0
		var marca: Label = cartao.find_child("Marca", true, false)
		marca.visible = ordem >= 0
		marca.text = str(ordem + 1)
	var vagas: HBoxContainer = _painel.find_child("Vagas", true, false)
	if vagas == null:
		return
	for filho in vagas.get_children():
		filho.queue_free()
	for i in Batalha.TAMANHO_TIME:
		if i < _escolha_time.size():
			var moldura := _moldura(_escolha_time[i], 76, Companheiros.nivel(_escolha_time[i]))
			vagas.add_child(moldura)
			moldura.pivot_offset = Vector2(38, 38)
			moldura.scale = Vector2.ONE * 0.6
			moldura.create_tween().tween_property(moldura, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			var vazia := PanelContainer.new()
			vazia.custom_minimum_size = Vector2(76, 76)
			var estilo := StyleBoxFlat.new()
			estilo.bg_color = Color(0, 0, 0, 0.25)
			estilo.set_corner_radius_all(14)
			estilo.set_border_width_all(3)
			estilo.border_color = Color(1, 1, 1, 0.25)
			vazia.add_theme_stylebox_override("panel", estilo)
			vagas.add_child(vazia)


# --- Luta -----------------------------------------------------------------------------

func lutar(indice: int) -> void:
	if not Batalha.liberado(indice):
		return
	_fechar_painel()
	luta = Batalha.new(indice, Batalha.time())
	_topo_titulo.text = "ARENA · " + str(luta.desafiante["nome"])
	_montar_palco()
	_mostrar_lutador("meu", true)
	_mostrar_lutador("deles", true)
	_atualizar_super()
	_quadro_pergunta.visible = false
	Audio.tocar("especial")
	# entrada: os doces deslizam de cada lado, o VS bate na tela e o
	# desafiante provoca num balão
	_visor_meu.position.x = -500.0
	_visor_deles.position.x = 500.0
	var entrada := create_tween().set_parallel()
	entrada.tween_property(_visor_meu, "position:x", 0.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada.tween_property(_visor_deles, "position:x", 0.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var vs: Label = _palco.find_child("VS", true, false)
	vs.pivot_offset = vs.size / 2.0
	vs.scale = Vector2.ONE * 3.0
	vs.modulate.a = 0.0
	var batida := create_tween().set_parallel()
	batida.tween_property(vs, "scale", Vector2.ONE, 0.35).set_delay(0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	batida.tween_property(vs, "modulate:a", 1.0, 0.2).set_delay(0.45)
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(_palco):
			Audio.tocar("explosao", 1.3, -6.0)
			_tremer(_palco, 10.0))
	_balao('%s: "%s"' % [luta.desafiante["nome"], luta.desafiante["fala"]])
	await get_tree().create_timer(1.9).timeout
	if luta != null and not luta.acabou():
		_nova_pergunta()


func _nova_pergunta() -> void:
	var p := luta.proxima_pergunta()
	_quadro_pergunta.visible = true
	_enunciado.text = str(p["enunciado"])
	for filho in _alternativas.get_children():
		_alternativas.remove_child(filho)
		filho.queue_free()
	for k in p["alternativas"].size():
		var b := Button.new()
		b.name = "Alternativa%d" % k
		b.theme_type_variation = &"Alternativa"
		b.text = str(p["alternativas"][k])
		b.custom_minimum_size = Vector2(0, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 21)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(responder.bind(k))
		_alternativas.add_child(b)
	_tempo_resta = Batalha.TEMPO
	_barra_tempo.max_value = Batalha.TEMPO
	_barra_tempo.value = Batalha.TEMPO
	respondendo = true


## Responde (k = -1: acabou o tempo). Mostra a certa, anima o golpe e segue.
func responder(k: int) -> void:
	if not respondendo or luta == null:
		return
	respondendo = false
	var certa := int(luta.pergunta["resposta"])
	for i in _alternativas.get_child_count():
		var b: Button = _alternativas.get_child(i)
		b.disabled = true
		if i == certa:
			b.modulate = VERDE.lightened(0.3)
		elif i == k:
			b.modulate = VERMELHO.lightened(0.3)
	var r := luta.responder(k, Batalha.TEMPO - _tempo_resta)
	Audio.tocar("acerto" if r["acertou"] else "erro")
	if k < 0:
		_texto_voando("ACABOU O TEMPO!", Vector2(0.5, 0.52), 34, 0.9)
	await get_tree().create_timer(0.55).timeout
	await _animar_golpe(r)
	if luta == null:
		return
	if r["fim"] != "":
		_terminar()
	else:
		_nova_pergunta()


func _animar_golpe(r: Dictionary) -> void:
	var meu_bate: bool = r["atacante"] == "meu"
	var atacante := _visor_meu if meu_bate else _visor_deles
	var alvo := _visor_deles if meu_bate else _visor_meu
	var quem_apanha := "deles" if meu_bate else "meu"
	# o atacante avança, bate e volta
	var avanco := create_tween()
	avanco.tween_property(atacante, "position:x", 150.0 if meu_bate else -150.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	avanco.tween_property(atacante, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.16).timeout
	if luta == null:
		return
	Audio.tocar("explosao" if r["super"] else "estouro")
	var centro_alvo := alvo.get_global_rect().get_center()
	_faiscas(centro_alvo, 40 if r["super"] else 18, r["super"])
	_tremer(_palco, 16.0 if r["super"] else 6.0)
	if r["super"]:
		var flash := ColorRect.new()
		flash.color = Color(1, 1, 0.85, 0.7)
		flash.set_anchors_preset(PRESET_FULL_RECT)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(flash)
		var some := flash.create_tween()
		some.tween_property(flash, "color:a", 0.0, 0.45)
		some.tween_callback(flash.queue_free)
	# o alvo treme e fica vermelho
	var tremor := create_tween()
	for i in 4:
		tremor.tween_property(alvo, "position:x", 14.0 if i % 2 == 0 else -14.0, 0.04)
	tremor.tween_property(alvo, "position:x", 0.0, 0.04)
	alvo.modulate = Color(1, 0.45, 0.45)
	create_tween().tween_property(alvo, "modulate", Color.WHITE, 0.35)
	var texto := "-%d" % r["dano"]
	if r["super"]:
		texto = "SUPER! " + texto
	elif r["rapido"]:
		texto = "RÁPIDO! " + texto
	var onde := Vector2(0.72 if meu_bate else 0.28, 0.3)
	_texto_voando(texto, onde, 44 if r["super"] else 36, 0.9)
	_atualizar_vida(quem_apanha)
	_atualizar_super()
	await get_tree().create_timer(0.55).timeout
	if luta == null:
		return
	if r["nocaute"]:
		Audio.tocar("caixa", 0.8)
		_texto_voando("NOCAUTE!", onde + Vector2(0, 0.08), 40, 0.9)
		_estrelas_tontas(centro_alvo + Vector2(0, -70))
		var queda := create_tween().set_parallel()
		queda.tween_property(alvo, "modulate:a", 0.0, 0.4)
		queda.tween_property(alvo, "position:y", 60.0, 0.4)
		await queda.finished
		alvo.position.y = 0.0
		if r["entrou"] != "":
			_mostrar_lutador(quem_apanha, false)
			alvo.modulate.a = 0.0
			create_tween().tween_property(alvo, "modulate:a", 1.0, 0.35)
			await get_tree().create_timer(0.4).timeout
	_atualizar_bancos()


## Põe no lado o doce da vez (nome, nível, vida e o modelo 3D).
func _mostrar_lutador(quem: String, inicio: bool) -> void:
	var dados: Dictionary = luta.meu() if quem == "meu" else luta.deles()
	if dados.is_empty():
		return
	var visor := _visor_meu if quem == "meu" else _visor_deles
	visor.nivel = int(dados["nivel"])
	visor.mostrar(dados["id"])
	var l: Dictionary = _lado[quem]
	l["nome"].text = "%s · NV %d" % [Batalha.nome_doce(dados["id"]), dados["nivel"]]
	l["estrelas"].text = estrelas(int(dados["nivel"])) + "   ⚔ %d" % dados["ataque"]
	var cor := Companheiros.cor(dados["id"])
	l["raridade"].text = Companheiros.nome_raridade(dados["id"])
	l["raridade"].add_theme_color_override("font_color", cor.lightened(0.3))
	l["estilo"].border_color = cor
	for barra in [l["vida"], l["rastro"]]:
		barra.max_value = int(dados["vida_max"])
		barra.value = int(dados["vida"])
	_atualizar_vida(quem, inicio)
	_atualizar_bancos()


func _atualizar_vida(quem: String, na_hora := false) -> void:
	var dados: Dictionary = luta.meu() if quem == "meu" else luta.deles()
	var l: Dictionary = _lado[quem]
	# o nocauteado já saiu da vez: a barra vai a zero
	var vida := 0 if dados.is_empty() else int(dados["vida"])
	if not dados.is_empty() and l["vida"].max_value != int(dados["vida_max"]):
		vida = 0
	var fracao := float(vida) / maxf(1.0, l["vida"].max_value)
	l["cheio"].bg_color = VERDE if fracao > 0.5 else (AMARELO if fracao > 0.25 else VERMELHO)
	l["texto"].text = "♥ %d / %d" % [vida, l["vida"].max_value]
	if na_hora:
		l["vida"].value = vida
		l["rastro"].value = vida
	else:
		create_tween().tween_property(l["vida"], "value", float(vida), 0.2)
		# o rastro branco espera um pouco e desce devagar atrás
		create_tween().tween_property(l["rastro"], "value", float(vida), 0.6).set_delay(0.35).set_trans(Tween.TRANS_SINE)


func _atualizar_bancos() -> void:
	for quem in ["meu", "deles"]:
		var banco: HBoxContainer = _lado[quem]["banco"]
		for filho in banco.get_children():
			filho.queue_free()
		var time: Array = luta.meu_time if quem == "meu" else luta.time_deles
		var atual := luta.meu_atual if quem == "meu" else luta.deles_atual
		for i in time.size():
			var foto := _moldura(time[i]["id"], 56 if i == atual else 44, 0, int(time[i]["vida"]) <= 0)
			banco.add_child(foto)


func _atualizar_super() -> void:
	for i in _super.get_child_count():
		var estrela: TextureRect = _super.get_child(i)
		var cheia := i < luta.sequencia
		estrela.modulate = AMARELO if cheia else Color(0.2, 0.1, 0.3, 0.45)
		estrela.pivot_offset = estrela.size / 2.0
		estrela.scale = Vector2.ONE * (1.25 if cheia else 1.0)
	if luta.sequencia == Batalha.SUPER_COM - 1:
		_texto_voando("MAIS UM ACERTO: SUPER!", Vector2(0.5, 0.44), 28, 1.0)


## Sai da luta sem prêmio (voltar no meio).
func desistir() -> void:
	respondendo = false
	luta = null
	mostrar_arena()


func _terminar() -> void:
	respondendo = false
	_quadro_pergunta.visible = false
	var venceu := luta.venceu()
	var ganho := luta.concluir()
	if venceu:
		Audio.tocar("vitoria")
		_visor_meu.comemorar()
		_confete()
	else:
		_visor_deles.comemorar()
	await get_tree().create_timer(0.8).timeout
	if not is_instance_valid(_palco):
		return
	var coluna := _abrir_painel("Fim", "VITÓRIA!" if venceu else "NÃO FOI DESTA VEZ...")
	var titulo: Label = coluna.get_node("TituloPainel")
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.pivot_offset = Vector2(200, 40)
	titulo.scale = Vector2.ONE * 0.3
	titulo.create_tween().tween_property(titulo, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if venceu:
		var premios := HBoxContainer.new()
		premios.alignment = BoxContainer.ALIGNMENT_CENTER
		premios.add_theme_constant_override("separation", 26)
		coluna.add_child(premios)
		for par in [[Itens.MOEDA, int(ganho["moedas"])], [Itens.ACUCAR, int(ganho["acucar"])]]:
			var icone := TextureRect.new()
			icone.texture = par[0]
			icone.custom_minimum_size = Vector2(56, 56)
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			premios.add_child(icone)
			var numero := _texto(premios, "+0", 44)
			numero.name = "Premio"
			var total: int = par[1]
			numero.create_tween().tween_method(func(v: float): numero.text = "+%d" % roundi(v), 0.0, float(total), 0.9)
		var extras := ""
		if ganho.has("bau"):
			extras += "+ BAÚ " + ("DE OURO" if ganho["bau"] == "ouro" else "DE DOCE")
		if ganho.has("movel"):
			extras += ("\n" if extras != "" else "") + "+ " + Casa.MOVEIS[ganho["movel"]]["nome"] + " PARA A MINHA CASA!"
		if extras != "":
			_texto(coluna, extras, 30)
		_texto(coluna, "%d ACERTOS EM %d PERGUNTAS" % [luta.acertos, luta.rodadas], 24)
	else:
		_texto(coluna, "+%d AÇÚCAR PELO ESFORÇO" % ganho["acucar"], 30)
		_texto(coluna, "Dica: suba seus doces de nível ou troque o time!", 24)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	var indice := luta.indice
	botoes.add_child(_botao("VoltarArena", "ARENA", &"BotaoSecundario", mostrar_arena))
	if venceu and indice + 1 < Batalha.DESAFIANTES.size():
		botoes.add_child(_botao("ProximoDesafiante", "PRÓXIMO DESAFIANTE", &"BotaoComprar", lutar.bind(indice + 1)))
	elif not venceu:
		botoes.add_child(_botao("TentarDeNovo", "TENTAR DE NOVO", &"BotaoComprar", lutar.bind(indice)))


# --- Peças de interface ---------------------------------------------------------------

func _abrir_painel(nome: String, titulo: String) -> VBoxContainer:
	_fechar_painel()
	var camada := Control.new()
	camada.name = nome
	camada.set_anchors_preset(PRESET_FULL_RECT)
	add_child(camada)
	move_child(camada, get_node("Topo").get_index())
	_painel = camada
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.55)
	escuro.set_anchors_preset(PRESET_FULL_RECT)
	camada.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(PRESET_FULL_RECT)
	centro.offset_top = 70
	camada.add_child(centro)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)
	var rotulo := _texto(coluna, titulo, 46)
	rotulo.name = "TituloPainel"
	return coluna


func _fechar_painel() -> void:
	if is_instance_valid(_painel):
		_painel.queue_free()
	_painel = null


func _texto(pai: Control, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 30 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.text = texto
	pai.add_child(rotulo)
	return rotulo


func _botao(nome: String, texto: String, estilo: StringName, acao: Callable) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.text = texto
	botao.theme_type_variation = estilo
	botao.custom_minimum_size = Vector2(260, 68)
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(acao)
	return botao


## Foto do doce (com o nível num cantinho; apagada = nocauteado ou trancado).
func _foto(id: String, tamanho: int, nivel := 0, apagada := false) -> Control:
	var foto := TextureRect.new()
	foto.texture = load(FOTOS % id) if ResourceLoader.exists(FOTOS % id) else null
	foto.custom_minimum_size = Vector2(tamanho, tamanho)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if apagada:
		foto.modulate = Color(0.35, 0.3, 0.45, 0.8)
	if nivel > 0:
		var n := Label.new()
		n.theme_type_variation = &"TituloClaro"
		n.add_theme_font_size_override("font_size", 16)
		n.add_theme_constant_override("outline_size", 6)
		n.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
		n.text = "NV%d" % nivel
		n.set_anchors_preset(PRESET_BOTTOM_RIGHT)
		n.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		n.grow_vertical = Control.GROW_DIRECTION_BEGIN
		foto.add_child(n)
	return foto


## Foto do doce numa moldura redonda na cor da raridade, com as estrelas
## do nível embaixo (apagada = nocauteado ou trancado).
func _moldura(id: String, tamanho: int, nivel := 0, apagada := false) -> Control:
	var caixa := PanelContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#2E1D4A", 0.85)
	estilo.set_corner_radius_all(tamanho / 4)
	estilo.set_border_width_all(3)
	estilo.border_color = Companheiros.cor(id) if not apagada else Color(0.4, 0.4, 0.45)
	caixa.add_theme_stylebox_override("panel", estilo)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", -4)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(coluna)
	coluna.add_child(_foto(id, tamanho, 0, apagada))
	if nivel > 0:
		var n := Label.new()
		n.theme_type_variation = &"TituloClaro"
		n.add_theme_font_size_override("font_size", maxi(11, tamanho / 6))
		n.add_theme_color_override("font_color", Color("#FFC83D"))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.text = estrelas(nivel)
		coluna.add_child(n)
	return caixa


## Faíscas do golpe (estrelinhas que espirram do ponto atingido).
func _faiscas(onde: Vector2, quantas: int, forte: bool) -> void:
	var faiscas := CPUParticles2D.new()
	faiscas.position = onde
	faiscas.one_shot = true
	faiscas.explosiveness = 0.95
	faiscas.amount = quantas
	faiscas.lifetime = 0.6
	faiscas.texture = BRILHO
	faiscas.direction = Vector2.UP
	faiscas.spread = 180.0
	faiscas.initial_velocity_min = 220.0
	faiscas.initial_velocity_max = 480.0 if forte else 340.0
	faiscas.gravity = Vector2(0, 600)
	faiscas.scale_amount_min = 0.25
	faiscas.scale_amount_max = 0.6 if forte else 0.4
	var cores := Gradient.new()
	cores.set_color(0, Color("#FFF6C8"))
	cores.set_color(1, Color("#FF6FAE", 0.0) if forte else Color("#FFC83D", 0.0))
	faiscas.color_ramp = cores
	if forte:
		faiscas.hue_variation_min = -0.5
		faiscas.hue_variation_max = 0.5
	add_child(faiscas)
	faiscas.emitting = true
	faiscas.finished.connect(faiscas.queue_free)


## Tremidinha num nó (a tela inteira, no golpe forte).
func _tremer(no: Control, forca: float) -> void:
	var tween := no.create_tween()
	for i in 6:
		tween.tween_property(no, "position", Vector2(randf_range(-forca, forca), randf_range(-forca, forca)) * (1.0 - i / 6.0), 0.035)
	tween.tween_property(no, "position", Vector2.ZERO, 0.04)


## Estrelinhas girando em cima do doce nocauteado.
func _estrelas_tontas(onde: Vector2) -> void:
	var roda := Node2D.new()
	roda.position = onde
	add_child(roda)
	for i in 3:
		var estrela := Sprite2D.new()
		estrela.texture = BRILHO
		estrela.scale = Vector2.ONE * 0.35
		estrela.modulate = AMARELO
		estrela.position = Vector2(cos(i * TAU / 3.0) * 44, sin(i * TAU / 3.0) * 14)
		roda.add_child(estrela)
	var giro := roda.create_tween().set_parallel()
	giro.tween_method(func(a: float):
		for i in roda.get_child_count():
			roda.get_child(i).position = Vector2(cos(a + i * TAU / 3.0) * 44, sin(a + i * TAU / 3.0) * 14), 0.0, TAU * 2.0, 0.9)
	giro.tween_property(roda, "modulate:a", 0.0, 0.3).set_delay(0.6)
	giro.chain().tween_callback(roda.queue_free)


## Balão de fala do desafiante no começo da luta.
func _balao(texto: String) -> void:
	var balao := PanelContainer.new()
	balao.name = "Fala"
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFFDF7")
	estilo.set_corner_radius_all(22)
	estilo.content_margin_left = 22
	estilo.content_margin_right = 22
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	estilo.shadow_color = Color(0, 0, 0, 0.3)
	estilo.shadow_size = 8
	balao.add_theme_stylebox_override("panel", estilo)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Titulo"
	rotulo.add_theme_font_size_override("font_size", 28)
	rotulo.text = texto
	balao.add_child(rotulo)
	balao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(balao)
	balao.position = Vector2(size.x - balao.get_combined_minimum_size().x - 60, size.y * 0.5)
	balao.pivot_offset = balao.get_combined_minimum_size() / 2.0
	balao.scale = Vector2.ZERO
	var tween := balao.create_tween()
	tween.tween_property(balao, "scale", Vector2.ONE, 0.3).set_delay(0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.4)
	tween.tween_property(balao, "modulate:a", 0.0, 0.3)
	tween.tween_callback(balao.queue_free)


## Chuva de confete da vitória.
func _confete() -> void:
	var confete := CPUParticles2D.new()
	confete.position = Vector2(size.x / 2.0, -20)
	confete.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confete.emission_rect_extents = Vector2(size.x / 2.0, 10)
	confete.amount = 120
	confete.lifetime = 3.0
	confete.one_shot = true
	confete.explosiveness = 0.6
	confete.direction = Vector2.DOWN
	confete.initial_velocity_min = 80.0
	confete.initial_velocity_max = 220.0
	confete.gravity = Vector2(0, 160)
	confete.angular_velocity_min = -360.0
	confete.angular_velocity_max = 360.0
	confete.scale_amount_min = 6.0
	confete.scale_amount_max = 11.0
	confete.hue_variation_min = -1.0
	confete.hue_variation_max = 1.0
	confete.color = Color("#FF6FAE")
	add_child(confete)
	confete.emitting = true
	confete.finished.connect(confete.queue_free)


## Texto que sobe e some (posição em fração da tela).
func _texto_voando(texto: String, onde: Vector2, tamanho: int, duracao: float) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_constant_override("outline_size", 12)
	rotulo.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rotulo)
	rotulo.position = size * onde - rotulo.get_combined_minimum_size() / 2.0
	var tween := rotulo.create_tween().set_parallel()
	tween.tween_property(rotulo, "position:y", rotulo.position.y - 60.0, duracao)
	tween.tween_property(rotulo, "modulate:a", 0.0, duracao).set_delay(duracao * 0.5)
	tween.chain().tween_callback(rotulo.queue_free)
	return rotulo
