extends Control
## ARENA DOS DOCES: batalhas de doces movidas a perguntas do quiz (regras em
## scripts/batalha.gd).
## - ARENA: o seu time e a escada de desafiantes (LUTAR / REVANCHE).
## - TROCAR TIME: escolha até 3 doces da sua coleção.
## - LUTA EM TEMPO REAL (como os jogos de futebol do celular): o JOYSTICK (ou
##   A/D, setas) anda para frente e para trás e os BOTÕES REDONDOS batem (SOCO,
##   VOADORA, PIRUETA; teclas J, K, L). De perto o golpe é certo; de longe o doce
##   dá um bote e pode errar (a chance aparece embaixo). O "!" em cima do doce
##   dele avisa que ele vai bater: afaste-se para ele errar. De vez em quando
##   vem a PERGUNTA RELÂMPAGO (acertou: energia e turbo; errou: apanha) e, com a
##   energia cheia, o GOLPE SUPREMO (tecla I) também pergunta.
## - FIM: vitória (prêmio) ou derrota (açúcar do esforço e tentar de novo).

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const BRILHO := preload("res://assets/doce_match/brilho.svg")
const RAIOS := preload("res://assets/itens/raios.svg")
## Palavra de história em quadrinhos no golpe (o SUPER tem a dele).
const PALAVRAS_GOLPE := ["POW!", "TUM!", "BAM!", "PAF!", "TOMA!"]
## Movimentos do desafiante, um por golpe, em rodízio (o seu SUPREMO é o "tornado").
const GOLPES := ["soco", "voadora", "pirueta", "cambalhota"]
const FOTOS := "res://assets/doces_3d/fotos/%s.png"
const VERDE := Color("#7BE07B")
const AMARELO := Color("#F4E038")
const VERMELHO := Color("#FF5A5A")
## Botões redondos: cor e tamanho (o SOCO, o mais usado, é o maior).
const BOTOES := {
	"soco": {"texto": "SOCO", "cor": Color("#4FA3FF"), "raio": 70.0},
	"voadora": {"texto": "VOA-\nDORA", "cor": Color("#FF8A3D"), "raio": 52.0},
	"pirueta": {"texto": "PIRU-\nETA", "cor": Color("#B05CFF"), "raio": 52.0},
	"supremo": {"texto": "SUPRE-\nMO", "cor": Color("#FF4FA0"), "raio": 56.0},
}

var luta: Batalha
var _painel: Control
var _palco: Control
var _topo_titulo: Label
var _visor_meu: Doce3D
var _visor_deles: Doce3D
var _lado := {}  # "meu"/"deles" -> {"nome": Label, "vida": ProgressBar, "texto": Label, "banco": HBoxContainer}
var _vagas := {}  # "meu"/"deles" -> Control que segue a posição da luta (o visor dentro faz os golpes)
## Posição mostrada de cada doce (metros): segue a da luta suave (o empurrão
## vira um deslize). Congelada no lado que vai apanhar até o golpe encostar.
var _x_tela := {"meu": 0.0, "deles": 0.0}
var _congelado := {}
var _atacando := {}  # visor -> true enquanto vai até o outro (não começa outro golpe)
var _voltas := {}  # visor -> tweens da volta para o lugar (o próximo golpe corta)
var _super: HBoxContainer
var _rotulo_turbo: Label
var _aviso_deles: Label
var _controles: Control
var _joystick: Joystick
var _botoes := {}  # "soco"/"voadora"/"pirueta"/"supremo" -> BotaoGolpe
var _rotulo_chance: Label
var _quadro_pergunta: PanelContainer
var _enunciado: Label
var _barra_tempo: ProgressBar
var _cor_tempo: StyleBoxFlat
var _alternativas: GridContainer
var _aviso_pergunta: Label
## A luta está rodando (depois da entrada dos doces; para no fim).
var em_luta := false
## Direção forçada do joystick (testes e capturas; NAN = joystick e teclado).
var direcao_forcada := NAN
var _esperando := false  # mostrando a resposta: a luta espera um instante
var _fila := ""  # golpe apertado no meio de outro: sai assim que der
var _terminou := false
var _tempo_resta := 0.0
var respondendo := false
## O último movimento de luta usado (para os testes).
var ultimo_golpe := ""
var _proximo_golpe := randi() % GOLPES.size()
var _escolha_time: Array = []


func _ready() -> void:
	_montar_fundo()
	_montar_topo()
	mostrar_arena()
	Telas.dica_primeira_vez("arena", "ARENA DOS DOCES",
		"Ande com o JOYSTICK e bata com os BOTÕES REDONDOS: de perto o golpe é certo, de longe pode errar. Apareceu o ! em cima dele? Afaste-se! Acerte as PERGUNTAS RELÂMPAGO para encher a energia e soltar o GOLPE SUPREMO!")


func ao_voltar() -> void:
	if is_instance_valid(_painel) and _painel.name == "Time":
		mostrar_arena()
		return
	if luta != null and not luta.acabou():
		desistir()
		return
	Telas.voltar()


func _process(delta: float) -> void:
	if respondendo:
		_tempo_resta = maxf(0.0, _tempo_resta - delta)
		_barra_tempo.value = _tempo_resta
		# o tempo vai do verde ao vermelho e pisca nos últimos segundos
		var fracao := _tempo_resta / Batalha.TEMPO
		_cor_tempo.bg_color = VERDE if fracao > 0.5 else (AMARELO if fracao > 0.25 else VERMELHO)
		_barra_tempo.modulate.a = 1.0 if _tempo_resta > 5.0 else 0.6 + 0.4 * absf(sin(_tempo_resta * 6.0))
		if _tempo_resta <= 0.0:
			responder(-1)
	if luta == null or not is_instance_valid(_palco):
		return
	if em_luta and not _esperando and luta.fase == "luta" and not luta.acabou():
		for evento in luta.avancar(delta, _direcao()):
			_evento(evento)
		if _fila != "" and luta.pode_golpear(_fila) and not _atacando.get(_visor_meu, false):
			var tipo := _fila
			_fila = ""
			usar_golpe(tipo)
	_posicionar(delta)
	_atualizar_controles()


func _unhandled_input(evento: InputEvent) -> void:
	if luta == null or not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if respondendo:
		var n: int = evento.keycode - KEY_1
		if n >= 0 and n < _alternativas.get_child_count():
			responder(n)
		return
	match evento.keycode:
		KEY_J, KEY_SPACE:
			usar_golpe("soco")
		KEY_K:
			usar_golpe("voadora")
		KEY_L:
			usar_golpe("pirueta")
		KEY_I:
			usar_supremo()


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
	chao.anchor_top = 0.45
	chao.anchor_bottom = 0.69
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


## Monta a luta: os doces no chão da arena, o placar em cima (plaquinhas, a
## energia e o turbo), o joystick e os botões redondos embaixo e o quadro da
## pergunta (escondido).
func _montar_palco() -> void:
	if is_instance_valid(_palco):
		_palco.queue_free()
	_palco = Control.new()
	_palco.name = "Palco"
	_palco.set_anchors_preset(PRESET_FULL_RECT)
	_palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_palco)
	move_child(_palco, get_node("Topo").get_index())  # o topo (voltar) fica por cima
	# os doces: cada um numa "vaga" que anda pela arena (o visor dentro dela faz
	# os botes, pulos e piruetas)
	var arena := Control.new()
	arena.name = "Arena"
	arena.set_anchors_preset(PRESET_FULL_RECT)
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palco.add_child(arena)
	_vagas.clear()
	_visor_meu = _montar_doce(arena, "meu")
	_visor_deles = _montar_doce(arena, "deles")
	# o "!" do aviso: o doce dele vai bater
	_aviso_deles = Label.new()
	_aviso_deles.name = "AvisoGolpe"
	_aviso_deles.theme_type_variation = &"TituloClaro"
	_aviso_deles.add_theme_font_size_override("font_size", 58)
	_aviso_deles.add_theme_color_override("font_color", Color.WHITE)
	_aviso_deles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_deles.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_aviso_deles.custom_minimum_size = Vector2(76, 76)
	var bolinha := StyleBoxFlat.new()
	bolinha.bg_color = Color("#FF3B5C")
	bolinha.set_corner_radius_all(999)
	bolinha.set_border_width_all(5)
	bolinha.border_color = Color.WHITE
	bolinha.shadow_color = Color(0, 0, 0, 0.35)
	bolinha.shadow_size = 6
	_aviso_deles.add_theme_stylebox_override("normal", bolinha)
	_aviso_deles.text = "!"
	_aviso_deles.visible = false
	_aviso_deles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# placar: as plaquinhas dos dois lados e, no meio, a energia e o turbo
	var placar := HBoxContainer.new()
	placar.name = "Placar"
	placar.set_anchors_preset(PRESET_TOP_WIDE)
	placar.offset_left = 20
	placar.offset_right = -20
	placar.offset_top = 84
	placar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placar.add_theme_constant_override("separation", 14)
	_palco.add_child(placar)
	_montar_lado(placar, "meu")
	var meio := VBoxContainer.new()
	meio.alignment = BoxContainer.ALIGNMENT_BEGIN
	meio.custom_minimum_size = Vector2(170, 0)
	meio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meio.add_theme_constant_override("separation", 0)
	placar.add_child(meio)
	var vs := Label.new()
	vs.name = "VS"
	vs.theme_type_variation = &"Numero"
	vs.add_theme_font_size_override("font_size", 46)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.text = "VS"
	meio.add_child(vs)
	var rotulo_super := Label.new()
	rotulo_super.theme_type_variation = &"SubtituloClaro"
	rotulo_super.add_theme_font_size_override("font_size", 18)
	rotulo_super.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_super.text = "ENERGIA"
	meio.add_child(rotulo_super)
	_super = HBoxContainer.new()
	_super.name = "Super"
	_super.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_child(_super)
	for i in Batalha.SUPER_COM:
		var estrela := TextureRect.new()
		estrela.texture = BRILHO
		estrela.custom_minimum_size = Vector2(32, 32)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_super.add_child(estrela)
	_rotulo_turbo = Label.new()
	_rotulo_turbo.name = "Turbo"
	_rotulo_turbo.theme_type_variation = &"TituloClaro"
	_rotulo_turbo.add_theme_font_size_override("font_size", 24)
	_rotulo_turbo.add_theme_color_override("font_color", Color("#FF9A3D"))
	_rotulo_turbo.add_theme_constant_override("outline_size", 8)
	_rotulo_turbo.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	_rotulo_turbo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_turbo.text = "TURBO!"
	_rotulo_turbo.visible = false
	meio.add_child(_rotulo_turbo)
	_montar_lado(placar, "deles")
	_palco.add_child(_aviso_deles)  # por cima do placar
	_montar_controles()
	_montar_pergunta()


## Um doce na arena: a vaga (posição na luta) com o visor 3D dentro.
func _montar_doce(arena: Control, quem: String) -> Doce3D:
	var vaga := Control.new()
	vaga.name = "Vaga_" + quem
	vaga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.add_child(vaga)
	_vagas[quem] = vaga
	var visor := Doce3D.new()
	visor.name = "Doce_" + quem
	visor.giravel = false
	visor.distancia = 6.3  # cabe a coroa dos doces de nível alto
	visor.angulo_inicial = 0.55 if quem == "meu" else -0.55  # um de frente para o outro
	visor.set_anchors_preset(PRESET_FULL_RECT)
	visor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vaga.add_child(visor)
	return visor


## Joystick (esquerda), a chance de acertar (meio) e os botões redondos (direita,
## em arco em volta do SOCO, como nos jogos de futebol).
func _montar_controles() -> void:
	_controles = Control.new()
	_controles.name = "Controles"
	_controles.set_anchors_preset(PRESET_FULL_RECT)
	_controles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palco.add_child(_controles)
	_joystick = Joystick.new()
	_joystick.name = "Joystick"
	_joystick.anchor_top = 1.0
	_joystick.anchor_bottom = 1.0
	_joystick.offset_left = 28
	_joystick.offset_right = 228
	_joystick.offset_top = -224
	_joystick.offset_bottom = -24
	_controles.add_child(_joystick)
	var direita := Control.new()  # um ponto no canto de baixo à direita
	direita.name = "Botoes"
	direita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	direita.anchor_left = 1.0
	direita.anchor_right = 1.0
	direita.anchor_top = 1.0
	direita.anchor_bottom = 1.0
	_controles.add_child(direita)
	# centros em relação ao canto de baixo à direita
	var lugares := {"soco": Vector2(-104, -100), "voadora": Vector2(-246, -74), "pirueta": Vector2(-224, -208),
		"supremo": Vector2(-96, -250)}
	_botoes.clear()
	for tipo in BOTOES:
		var dados: Dictionary = BOTOES[tipo]
		var botao := BotaoGolpe.new()
		botao.name = "Golpe_" + tipo
		botao.texto = dados["texto"]
		botao.cor = dados["cor"]
		var raio: float = dados["raio"]
		botao.size = Vector2.ONE * raio * 2.0
		botao.position = lugares[tipo] - Vector2.ONE * raio
		if tipo == "supremo":
			botao.apertado.connect(usar_supremo)
		else:
			botao.apertado.connect(usar_golpe.bind(tipo))
		direita.add_child(botao)
		_botoes[tipo] = botao
	_rotulo_chance = Label.new()
	_rotulo_chance.name = "Chance"
	_rotulo_chance.theme_type_variation = &"TituloClaro"
	_rotulo_chance.add_theme_font_size_override("font_size", 26)
	_rotulo_chance.add_theme_constant_override("outline_size", 10)
	_rotulo_chance.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
	_rotulo_chance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo_chance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo_chance.set_anchors_preset(PRESET_CENTER_BOTTOM)
	_rotulo_chance.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_rotulo_chance.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_rotulo_chance.offset_bottom = -40
	_controles.add_child(_rotulo_chance)


## O quadro da pergunta (relâmpago e supremo), embaixo, por cima dos controles.
func _montar_pergunta() -> void:
	_quadro_pergunta = PanelContainer.new()
	_quadro_pergunta.name = "QuadroPergunta"
	_quadro_pergunta.theme_type_variation = &"PainelRoxo"
	_quadro_pergunta.anchor_left = 0.5
	_quadro_pergunta.anchor_right = 0.5
	_quadro_pergunta.anchor_top = 1.0
	_quadro_pergunta.anchor_bottom = 1.0
	_quadro_pergunta.offset_left = -500
	_quadro_pergunta.offset_right = 500
	_quadro_pergunta.offset_bottom = -12
	_quadro_pergunta.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_quadro_pergunta.visible = false
	_palco.add_child(_quadro_pergunta)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 8)
	_quadro_pergunta.add_child(dentro)
	_aviso_pergunta = Label.new()
	_aviso_pergunta.name = "AvisoPergunta"
	_aviso_pergunta.theme_type_variation = &"SubtituloClaro"
	_aviso_pergunta.add_theme_font_size_override("font_size", 20)
	_aviso_pergunta.add_theme_color_override("font_color", AMARELO)
	_aviso_pergunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dentro.add_child(_aviso_pergunta)
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


## Um lado do placar: plaquinha (nome, estrelas do nível, raridade e a barra
## de vida com rastro) e o time embaixo.
func _montar_lado(pai: Control, quem: String) -> void:
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
	estilo.content_margin_top = 4
	estilo.content_margin_bottom = 6
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 6
	placa.add_theme_stylebox_override("panel", estilo)
	coluna.add_child(placa)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 0)
	placa.add_child(dentro)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	dentro.add_child(linha)
	var nome := Label.new()
	nome.theme_type_variation = &"TituloClaro"
	nome.add_theme_font_size_override("font_size", 24)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.clip_text = true
	linha.add_child(nome)
	var raridade := Label.new()
	raridade.theme_type_variation = &"TituloClaro"
	raridade.add_theme_font_size_override("font_size", 16)
	linha.add_child(raridade)
	var estrelas := Label.new()
	estrelas.theme_type_variation = &"TituloClaro"
	estrelas.add_theme_font_size_override("font_size", 17)
	estrelas.add_theme_color_override("font_color", Color("#FFC83D"))
	dentro.add_child(estrelas)
	# barra de vida: a de trás (branca) vai atrás da de cor, devagar (rastro do golpe)
	var barras := Control.new()
	barras.custom_minimum_size = Vector2(0, 22)
	dentro.add_child(barras)
	var rastro := _barra(Color(1, 1, 1, 0.85), Color(0, 0, 0, 0.4))
	barras.add_child(rastro)
	var vida := _barra(VERDE, Color(0, 0, 0, 0))
	vida.name = "Vida"
	barras.add_child(vida)
	var texto := Label.new()
	texto.theme_type_variation = &"TituloClaro"
	texto.add_theme_font_size_override("font_size", 16)
	texto.add_theme_constant_override("outline_size", 6)
	texto.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(PRESET_FULL_RECT)
	barras.add_child(texto)
	var banco := HBoxContainer.new()
	banco.name = "Banco"
	banco.alignment = BoxContainer.ALIGNMENT_BEGIN if quem == "meu" else BoxContainer.ALIGNMENT_END
	banco.add_theme_constant_override("separation", 6)
	coluna.add_child(banco)
	_lado[quem] = {"nome": nome, "vida": vida, "rastro": rastro, "texto": texto, "banco": banco,
		"cheio": vida.get_theme_stylebox("fill"), "estilo": estilo, "raridade": raridade, "estrelas": estrelas}


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
	em_luta = false
	respondendo = false
	_esperando = false
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
		forca_time += Batalha.minha_forca(id)
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
			var extra := Companheiros.forca_xp(doce["id"])
			maior_vida = maxi(maior_vida, Batalha.vida(doce["id"], Companheiros.nivel(doce["id"]), extra))
			maior_ataque = maxi(maior_ataque, Batalha.ataque(doce["id"], Companheiros.nivel(doce["id"]), extra))
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
	# nível de luta (XP do doce): quanto mais ele joga, mais forte fica
	var xp := Companheiros.nivel_xp_detalhe(id)
	var luta := Label.new()
	luta.name = "NivelLuta"
	luta.theme_type_variation = &"TituloClaro"
	luta.add_theme_font_size_override("font_size", 15)
	luta.add_theme_color_override("font_color", Color("#7BE07B"))
	luta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	luta.text = "LUTA NV %d" % xp["nivel"]
	luta.tooltip_text = "Nível de luta: o doce ganha XP jogando com você (falta %d XP)" % xp["falta"]
	coluna.add_child(luta)
	var extra := Companheiros.forca_xp(id)
	for par in [["♥", Batalha.vida(id, nivel, extra), maior_vida, Color("#FF6F8E")], ["⚔", Batalha.ataque(id, nivel, extra), maior_ataque, Color("#FFC83D")]]:
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
	var esta := luta
	em_luta = false
	_terminou = false
	_esperando = false
	respondendo = false
	_fila = ""
	_atacando.clear()
	_voltas.clear()
	_topo_titulo.text = "ARENA · " + str(luta.desafiante["nome"])
	_montar_palco()
	_mostrar_lutador("meu", true)
	_mostrar_lutador("deles", true)
	_atualizar_super()
	Audio.tocar("especial")
	# entrada: os doces entram andando, cada um do seu lado, o VS bate na tela e
	# o desafiante provoca num balão
	_congelado = {"meu": true, "deles": true}
	_x_tela = {"meu": -2.0, "deles": Batalha.ARENA + 2.0}
	var entrada := create_tween().set_parallel()
	entrada.tween_method(func(v: float): _x_tela["meu"] = v, -2.0, luta.x_meu, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entrada.tween_method(func(v: float): _x_tela["deles"] = v, Batalha.ARENA + 2.0, luta.x_deles, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entrada.chain().tween_callback(func(): if luta == esta: _congelado.clear())
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
	if luta == esta and not luta.acabou():
		em_luta = true
		Audio.tocar("largada")
		_texto_pulando("LUTEM!", Vector2(0.5, 0.42), 72, AMARELO)


## Joystick (só para os lados) e teclado (A/D e setas).
func _direcao() -> float:
	if not is_nan(direcao_forcada):
		return direcao_forcada
	var teclas := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) \
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var direcao := _joystick.vetor.x + teclas if is_instance_valid(_joystick) else teclas
	return 0.0 if absf(direcao) < 0.2 else clampf(direcao, -1.0, 1.0)


## Tamanho do doce na tela, a linha do chão e onde fica cada metro da arena.
func _tamanho_doce() -> float:
	return clampf(size.y * 0.5, 240.0, 420.0)


func _chao() -> float:
	return size.y * 0.6


func _na_tela(x: float) -> float:
	var margem := _tamanho_doce() * 0.42
	return margem + x / Batalha.ARENA * (size.x - 2.0 * margem)


## Os doces na tela seguem a posição da luta (suave: o empurrão vira um
## deslize) e mexem as pernas enquanto andam.
func _posicionar(delta: float) -> void:
	var lado := _tamanho_doce()
	for quem in ["meu", "deles"]:
		var antes: float = _x_tela[quem]
		if not _congelado.get(quem, false):
			var alvo: float = luta.x_meu if quem == "meu" else luta.x_deles
			_x_tela[quem] = lerpf(antes, alvo, 1.0 - exp(-14.0 * delta))
		var vaga: Control = _vagas[quem]
		vaga.size = Vector2.ONE * lado
		vaga.position = Vector2(_na_tela(_x_tela[quem]) - lado / 2.0, _chao() - lado * 0.8)
		var visor := _visor_meu if quem == "meu" else _visor_deles
		visor.andar(delta > 0.0 and absf(_x_tela[quem] - antes) / delta > 0.5 and not visor.segurar_pose)
	if is_instance_valid(_aviso_deles):
		# em cima da cabeça do doce dele
		var vaga_deles: Control = _vagas["deles"]
		_aviso_deles.position = vaga_deles.position + Vector2((lado - _aviso_deles.size.x) / 2.0, lado * 0.24 - _aviso_deles.size.y)


## Recarga dos botões, o supremo aceso, o turbo e a chance de acertar.
func _atualizar_controles() -> void:
	if not is_instance_valid(_controles):
		return
	var correndo := em_luta and luta.correndo()
	for tipo in ["soco", "voadora", "pirueta"]:
		var total := float(Batalha.GOLPES[tipo]["recarga"])
		_botoes[tipo].atualizar(clampf(luta.recarga(tipo) / total, 0.0, 1.0), correndo)
	_botoes["supremo"].atualizar(0.0, correndo and luta.pode_supremo(), correndo and luta.energia >= Batalha.SUPER_COM,
		"%d/%d" % [luta.energia, Batalha.SUPER_COM])
	_rotulo_turbo.visible = luta.turbo > 0.0
	if _rotulo_turbo.visible:
		_rotulo_turbo.modulate.a = 0.6 + 0.4 * absf(sin(luta.turbo * 8.0))
	var chance := Batalha.chance(luta.distancia())
	var texto := "PERTO: GOLPE CERTO!" if chance >= 1.0 else "LONGE: %d%% DE ACERTAR" % roundi(chance * 100.0)
	if texto != _rotulo_chance.text:
		_rotulo_chance.text = texto
		_rotulo_chance.add_theme_color_override("font_color",
			VERDE if chance >= 1.0 else (AMARELO if chance >= 0.5 else Color("#FFB36B")))


## O que a luta avisou: o desafiante vai bater, bateu, ou chegou a pergunta.
func _evento(e: Dictionary) -> void:
	match str(e["tipo"]):
		"prepara":
			_avisar_golpe_deles()
		"golpe":
			_executar(e)
		"pergunta":
			Audio.tocar("bip", 1.2)
			_mostrar_pergunta("PERGUNTA RELÂMPAGO! ACERTE: +1 ENERGIA E TURBO")


## O aviso: "!" em cima do doce dele, que se encolhe para o bote.
func _avisar_golpe_deles() -> void:
	Audio.tocar("bip", 0.8, -4.0)
	_visor_deles.preparar_golpe()
	_visor_deles.pose_luta("guarda", 0.1)
	_aviso_deles.visible = true
	_aviso_deles.pivot_offset = _aviso_deles.size / 2.0
	_aviso_deles.scale = Vector2.ONE * 0.2
	var pulo := _aviso_deles.create_tween()
	pulo.tween_property(_aviso_deles, "scale", Vector2.ONE * 1.25, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulo.tween_property(_aviso_deles, "scale", Vector2.ONE, 0.1)
	pulo.tween_interval(maxf(0.1, luta.telegrafo() - 0.22))
	pulo.tween_callback(func(): _aviso_deles.visible = false)


## Tocou num botão de golpe: bate na hora (se estiver no meio de outro golpe,
## sai logo depois).
func usar_golpe(tipo: String) -> void:
	if luta == null or not em_luta or _esperando:
		return
	if not luta.pode_golpear(tipo) or _atacando.get(_visor_meu, false):
		if luta.correndo() and luta.recarga(tipo) <= 0.3:
			_fila = tipo
		return
	_fila = ""
	_executar(luta.golpear(tipo))


## GOLPE SUPREMO: a luta para e a pergunta decide se acerta.
func usar_supremo() -> void:
	if luta == null or not em_luta or _esperando or not luta.pode_supremo():
		return
	Audio.tocar("especial")
	luta.pedir_supremo()
	_mostrar_pergunta("GOLPE SUPREMO: ACERTE PARA ACERTAR!")


## Anima um golpe e, se ele acabou com a luta, termina.
func _executar(r: Dictionary) -> void:
	if r.is_empty():
		return
	await _animar_golpe(r)
	if luta != null and r["fim"] != "" and not _terminou:
		_terminar()


func _mostrar_pergunta(aviso: String) -> void:
	var p := luta.pergunta
	_fila = ""
	_joystick.soltar()
	_controles.visible = false
	_aviso_deles.visible = false
	_quadro_pergunta.visible = true
	_aviso_pergunta.text = aviso
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


## Responde (k = -1: acabou o tempo). Mostra a certa e a luta volta: a
## relâmpago certa dá energia e turbo; errada, ele bate; o supremo acerta ou erra.
func responder(k: int) -> void:
	if not respondendo or luta == null:
		return
	respondendo = false
	_esperando = true
	var esta := luta
	var certa := int(luta.pergunta["resposta"])
	for i in _alternativas.get_child_count():
		var b: Button = _alternativas.get_child(i)
		b.disabled = true
		if i == certa:
			b.modulate = VERDE.lightened(0.3)
		elif i == k:
			b.modulate = VERMELHO.lightened(0.3)
	var r := luta.responder(k, Batalha.TEMPO - _tempo_resta)
	Audio.tocar("acerto" if r["acertou_pergunta"] else "erro")
	if k < 0:
		_texto_voando("ACABOU O TEMPO!", Vector2(0.5, 0.52), 34, 0.9)
	await get_tree().create_timer(0.55).timeout
	if luta != esta:
		return
	_esperando = false
	_quadro_pergunta.visible = false
	_controles.visible = not luta.acabou()
	if r["fase"] == "pergunta" and r["acertou_pergunta"]:
		Audio.tocar("turbo")
		_texto_pulando("TURBO! +1 ENERGIA", Vector2(0.5, 0.36), 50, Color("#FF9A3D"))
		_faiscas(_visor_meu.get_global_rect().get_center(), 26, true)
		_atualizar_super()
		return
	_executar(r)


## O golpe é um movimento de luta de verdade: o SOCO (um bote rápido), a
## VOADORA, a PIRUETA (alterna com a cambalhota) e o SUPREMO (o tornado com
## uppercut: a arena escurece e raios giram atrás do atacante); o desafiante
## usa os movimentos em rodízio. Quem vai apanhar fica parado até o golpe
## encostar; no contato o mundo para um instante (raios, POW!, faíscas e
## tremida) e o alvo desliza para trás (o empurrão da luta). Errou (de longe):
## o alvo pula para trás e o golpe pega no ar. Nocaute: sai voando girando e o
## próximo do time cai do alto.
func _animar_golpe(r: Dictionary) -> void:
	if r.is_empty() or r["atacante"] == "ninguem" or not is_instance_valid(_palco):
		return
	var meu_bate: bool = r["atacante"] == "meu"
	var atacante := _visor_meu if meu_bate else _visor_deles
	var alvo := _visor_deles if meu_bate else _visor_meu
	var quem_bate := "meu" if meu_bate else "deles"
	var quem_apanha := "deles" if meu_bate else "meu"
	var lado := 1.0 if meu_bate else -1.0  # para onde o atacante vai
	var forte: bool = r["super"] and not r["errou"]
	var errou_golpe: bool = r["esquivou"] or r["errou"]
	_congelado[quem_apanha] = true
	# até onde o atacante vai para encostar no outro (o doce ocupa ~40% da
	# altura do visor)
	var distancia: float = _vagas[quem_apanha].get_global_rect().get_center().x - _vagas[quem_bate].get_global_rect().get_center().x
	var alcance := distancia - signf(distancia) * alvo.size.y * 0.36
	if absf(alcance) < 4.0:
		alcance = 4.0 * lado
	for visor in [atacante, alvo]:
		visor.pivot_offset = Vector2(visor.size.x / 2.0, visor.size.y * 0.8)  # gira e achata pelos pés
	var golpe: String
	match str(r.get("golpe", "")):
		"soco":
			golpe = "soco"
		"voadora":
			golpe = "voadora"
		"pirueta":
			golpe = "pirueta" if _proximo_golpe % 2 == 0 else "cambalhota"
			_proximo_golpe += 1
		"supremo":
			golpe = "tornado"
		_:
			golpe = GOLPES[_proximo_golpe % GOLPES.size()]
			_proximo_golpe += 1
	ultimo_golpe = golpe
	_parar_volta(atacante)
	_atacando[atacante] = true
	var extras: Array[Node] = []
	if r["super"]:
		extras = _carregar_super(atacante)
		await get_tree().create_timer(0.5).timeout
		if luta == null:
			_sumir(extras)
			return
	# de perfil, olhando para o outro doce
	atacante.segurar_pose = true
	atacante.andar(false)
	create_tween().tween_property(atacante.pivo(), "rotation", Vector3(0, atacante.angulo_inicial * 2.3, 0), 0.1)
	match golpe:
		"soco":
			await _golpe_soco(atacante, alcance)
		"voadora":
			await _golpe_voadora(atacante, alcance)
		"pirueta":
			await _golpe_pirueta(atacante, alcance)
		"cambalhota":
			await _golpe_cambalhota(atacante, alcance)
		"tornado":
			await _golpe_tornado(atacante, alcance)
	_atacando[atacante] = false
	_congelado[quem_apanha] = false  # o alvo desliza: o empurrão do golpe
	if luta == null or not is_instance_valid(alvo):
		_sumir(extras)
		return
	if errou_golpe:
		await _golpe_no_ar(atacante, alvo, r, alcance, extras)
		return
	# contato: estouro, o alvo pisca branco e o mundo para um instante
	var centro_alvo := alvo.get_global_rect().get_center()
	var contato := centro_alvo - Vector2(alvo.size.x * 0.16 * signf(alcance), 0)
	var leve := golpe == "soco"
	Audio.tocar("explosao" if forte else "estouro", 1.25 if leve else 1.0, -5.0 if leve else 0.0)
	if forte:
		Audio.tocar("explosao", 0.7, -4.0)
	alvo.apanhar(forte or golpe == "cambalhota")
	alvo.modulate = Color(3, 3, 3)
	if leve:
		_faiscas(contato + Vector2(0, randf_range(-30, 20)), 10, false)
		_tremer(_palco, 4.0)
	else:
		_impacto(contato, forte)
		_faiscas(contato, 44 if forte else 22, forte)
		_tremer(_palco, 18.0 if forte else 9.0)
	await get_tree().create_timer(0.12 if forte else (0.03 if leve else 0.07)).timeout
	if luta == null or not is_instance_valid(alvo):
		_sumir(extras)
		return
	var reacao := create_tween()
	reacao.tween_property(alvo, "modulate", Color(1, 0.45, 0.45), 0.08)
	reacao.tween_property(alvo, "modulate", Color.WHITE, 0.3)
	match golpe:
		"cambalhota":
			# esmagado pela pisada: achata e volta como mola
			alvo.scale = Vector2(1.35, 0.55)
			var mola := create_tween()
			mola.tween_property(alvo, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		"tornado":
			# lançado para o alto pelo uppercut, gira e cai quicando
			alvo.pivot_offset = alvo.size / 2.0
			var voo := create_tween()
			voo.tween_property(alvo, "position:y", -260.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			voo.parallel().tween_property(alvo, "rotation", TAU * lado, 0.55)
			voo.tween_property(alvo, "position:y", 0.0, 0.42).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			voo.tween_callback(func():
				alvo.rotation = 0.0
				alvo.pivot_offset = Vector2(alvo.size.x / 2.0, alvo.size.y * 0.8))
			get_tree().create_timer(0.62).timeout.connect(func():
				if is_instance_valid(_palco):
					Audio.tocar("chape", 1.1, -4.0)
					_tremer(_palco, 8.0))
	if golpe != "tornado":
		# inclina para trás e volta balançando
		var inclina := create_tween()
		inclina.tween_property(alvo, "rotation", deg_to_rad((8.0 if leve else 16.0) * lado), 0.1)
		inclina.tween_property(alvo, "rotation", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# o atacante volta para o lugar num pulo para trás
	_voltar_para_o_lugar(atacante)
	_sumir(extras)
	var texto := "-%d" % r["dano"]
	var cor := Color.WHITE
	if r["super"]:
		texto = "SUPREMO! " + texto
		cor = Color("#FF6FAE")
	elif r["rapido"]:
		texto = "RÁPIDO! " + texto
		cor = AMARELO
	elif r["turbo"]:
		cor = Color("#FF9A3D")
	var onde := Vector2(centro_alvo.x / size.x, (centro_alvo.y - alvo.size.y * 0.12) / size.y)
	_texto_pulando(texto, onde, 56 if r["super"] else (34 if leve else 46), cor)
	_atualizar_vida(quem_apanha, false, 0 if r["nocaute"] else -1)
	_atualizar_super()
	if not r["nocaute"]:
		return
	# nocaute: tonto, sai voando girando e o próximo do time cai do alto
	await get_tree().create_timer(0.3 if golpe != "tornado" else 0.7).timeout
	if luta == null or not is_instance_valid(alvo):
		return
	Audio.tocar("caixa", 0.8)
	alvo.desmaiar()
	_texto_pulando("NOCAUTE!", onde + Vector2(0, 0.08), 48, Color.WHITE)
	_estrelas_tontas(alvo.get_global_rect().get_center() + Vector2(0, -70))
	await get_tree().create_timer(0.25).timeout
	if luta == null or not is_instance_valid(alvo):
		return
	alvo.pivot_offset = alvo.size / 2.0
	var voa := create_tween().set_parallel()
	voa.tween_property(alvo, "position", Vector2(420.0 * signf(alcance), -280.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	voa.tween_property(alvo, "rotation", TAU * 2.0 * lado, 0.45)
	voa.tween_property(alvo, "scale", Vector2.ONE * 0.4, 0.45)
	voa.tween_property(alvo, "modulate:a", 0.0, 0.25).set_delay(0.2)
	Audio.tocar("pulo", 0.7)
	await voa.finished
	if not is_instance_valid(alvo):
		return
	alvo.position = Vector2.ZERO
	alvo.rotation = 0.0
	alvo.scale = Vector2.ONE
	if luta == null:
		return
	if r["entrou"] != "":
		# o próximo do time cai do alto e quica
		_mostrar_lutador(quem_apanha, false)
		alvo.position.y = -600.0
		alvo.modulate.a = 1.0
		var cai := create_tween()
		cai.tween_property(alvo, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		get_tree().create_timer(0.18).timeout.connect(func():
			if is_instance_valid(_palco):
				Audio.tocar("chape", 1.2, -4.0)
				_tremer(_palco, 7.0))
		await cai.finished
	if luta != null:
		_atualizar_bancos()


## O golpe pega no ar: quem ia apanhar pula para trás e desvia (o dele, de
## longe ou no aviso), ou o seu passa raspando (de longe, ou o supremo com a
## pergunta errada).
func _golpe_no_ar(atacante: Doce3D, alvo: Doce3D, r: Dictionary, alcance: float, extras: Array[Node]) -> void:
	Audio.tocar("pulo", 1.3)
	var desvia := create_tween().set_parallel()
	desvia.tween_property(alvo, "position:x", 70.0 * signf(alcance), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	desvia.tween_property(alvo, "rotation", deg_to_rad(-10.0 * signf(alcance)), 0.14)
	_pulinho(alvo, 70.0, 0.28)
	desvia.chain().tween_property(alvo, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	desvia.parallel().tween_property(alvo, "rotation", 0.0, 0.3)
	_rastro(alvo)
	var em_cima := alvo.get_global_rect().get_center() - Vector2(0, alvo.size.y * 0.12)
	var onde := Vector2(em_cima.x / size.x, em_cima.y / size.y)
	if r["esquivou"]:
		_texto_pulando("DESVIOU!", onde, 40, VERDE)
	elif r["super"]:
		_texto_pulando("ERROU O SUPREMO!", Vector2(0.5, 0.3), 46, VERMELHO)
		_estrelas_tontas(atacante.get_global_rect().get_center() + Vector2(0, -70))
	else:
		_texto_pulando("ERROU!", onde, 36, Color("#FFB36B"))
	_voltar_para_o_lugar(atacante)
	_sumir(extras)
	await get_tree().create_timer(0.3).timeout


## SOCO: um bote até o outro (mais longo de longe) e o soco, alternando os braços.
func _golpe_soco(atacante: Doce3D, alcance: float) -> void:
	atacante.pose_luta("soco_d" if _proximo_golpe % 2 == 0 else "soco_e", 0.05)
	_proximo_golpe += 1
	Audio.tocar("pulo", 1.5, -9.0)
	var tempo := 0.08 + absf(alcance) / 4000.0
	var bote := create_tween()
	bote.tween_property(atacante, "position:x", alcance * 0.94, tempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pulinho(atacante, 10.0 + absf(alcance) * 0.05, tempo)
	await bote.finished


## VOADORA: se agacha, pula alto com uma perna esticada e o corpo para trás.
func _golpe_voadora(atacante: Doce3D, alcance: float) -> void:
	atacante.preparar_golpe()
	atacante.pose_luta("guarda", 0.08)
	await get_tree().create_timer(0.1).timeout
	if luta == null or not is_instance_valid(atacante):
		return
	atacante.pose_luta("voadora", 0.08)
	Audio.tocar("pulo", 1.0)
	var pivo := atacante.pivo()
	create_tween().tween_property(pivo, "rotation:x", -0.35, 0.1)
	var tempo := 0.22 + absf(alcance) / 6000.0
	var pulo := create_tween().set_parallel()
	pulo.tween_property(atacante, "position:x", alcance * 0.95, tempo).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulo.tween_property(atacante, "rotation", deg_to_rad(12.0 * signf(alcance)), tempo)
	var arco := create_tween()
	arco.tween_property(atacante, "position:y", -150.0, tempo / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arco.tween_property(atacante, "position:y", -30.0, tempo / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await pulo.finished


## PIRUETA: gira duas vezes com os braços abertos indo até o outro doce.
func _golpe_pirueta(atacante: Doce3D, alcance: float) -> void:
	atacante.pose_luta("aberto", 0.08)
	Audio.tocar("pulo", 1.5, -4.0)
	var pivo := atacante.pivo()
	var frente := atacante.angulo_inicial * 2.3
	var tempo := 0.26 + absf(alcance) / 6000.0
	var gira := create_tween().set_parallel()
	gira.tween_property(pivo, "rotation:y", frente + TAU * 2.0, tempo).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	gira.tween_property(atacante, "position:x", alcance * 0.95, tempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pulinho(atacante, 30.0, tempo)
	await gira.finished
	if is_instance_valid(pivo):
		pivo.rotation.y = frente  # (as voltas inteiras acabaram)


## CAMBALHOTA: se agacha, dá um mortal para a frente no ar e cai pisando.
func _golpe_cambalhota(atacante: Doce3D, alcance: float) -> void:
	atacante.preparar_golpe()
	await get_tree().create_timer(0.08).timeout
	if luta == null or not is_instance_valid(atacante):
		return
	atacante.pose_luta("encolhido", 0.08)
	Audio.tocar("pulo", 0.9)
	var pivo := atacante.pivo()
	var tempo := 0.3 + absf(alcance) / 6000.0
	var pulo := create_tween().set_parallel()
	pulo.tween_property(atacante, "position:x", alcance * 0.92, tempo).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulo.tween_property(pivo, "rotation:x", TAU, tempo).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var arco := create_tween()
	arco.tween_property(atacante, "position:y", -200.0, tempo / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arco.tween_property(atacante, "position:y", -40.0, tempo / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await pulo.finished
	if is_instance_valid(pivo):
		pivo.rotation.x = 0.0
	atacante.pose_luta("guarda", 0.06)


## TORNADO (SUPREMO): gira três vezes de braços abertos, deixando rastro, e
## termina num uppercut que lança o outro doce para o alto.
func _golpe_tornado(atacante: Doce3D, alcance: float) -> void:
	atacante.pose_luta("aberto", 0.08)
	Audio.tocar("pulo", 1.6, -4.0)
	var pivo := atacante.pivo()
	var frente := atacante.angulo_inicial * 2.3
	var gira := create_tween().set_parallel()
	gira.tween_property(pivo, "rotation:y", frente + TAU * 3.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	gira.tween_property(atacante, "position:x", alcance * 0.88, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for i in 4:
		get_tree().create_timer(0.07 * (i + 1)).timeout.connect(_rastro.bind(atacante))
	await gira.finished
	if luta == null or not is_instance_valid(atacante):
		return
	pivo.rotation.y = frente
	atacante.pose_luta("uppercut", 0.06)
	var sobe := create_tween()
	sobe.tween_property(atacante, "position:y", -90.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await sobe.finished


## Sobe e desce (um pulinho) em `segundos`.
func _pulinho(visor: Control, altura: float, segundos: float) -> void:
	var arco := create_tween()
	arco.tween_property(visor, "position:y", -altura, segundos / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arco.tween_property(visor, "position:y", 0.0, segundos / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Depois do golpe: pulo para trás até o lugar (na vaga), pose normal e de
## frente de novo. O próximo golpe corta a volta (ver _parar_volta).
func _voltar_para_o_lugar(visor: Doce3D) -> void:
	_parar_volta(visor)
	visor.pose_luta("normal", 0.2)
	var volta := create_tween().set_parallel()
	volta.tween_property(visor, "position:x", 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	volta.tween_property(visor, "rotation", 0.0, 0.26)
	volta.tween_property(visor, "modulate", Color.WHITE, 0.25)
	volta.tween_property(visor.pivo(), "rotation", Vector3(0, visor.angulo_inicial, 0), 0.26)
	var queda := create_tween()
	queda.tween_property(visor, "position:y", -30.0, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	queda.tween_property(visor, "position:y", 0.0, 0.14).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	volta.chain().tween_callback(func(): visor.segurar_pose = false)
	_voltas[visor] = [volta, queda]


func _parar_volta(visor: Doce3D) -> void:
	for tween: Tween in _voltas.get(visor, []):
		if tween.is_valid():
			tween.kill()
	_voltas.erase(visor)


## Vitória: mortal para trás e os braços para o alto.
func _vitoria(visor: Doce3D) -> void:
	visor.segurar_pose = true
	visor.pose_luta("encolhido", 0.1)
	_pulinho(visor, 170.0, 0.5)
	var mortal := create_tween()
	mortal.tween_property(visor.pivo(), "rotation:x", -TAU, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await mortal.finished
	if not is_instance_valid(visor):
		return
	visor.pivo().rotation.x = 0.0
	visor.pose_luta("vitoria", 0.12)
	visor.comemorar()
	await get_tree().create_timer(1.4).timeout
	if is_instance_valid(visor):
		visor.pose_luta("normal", 0.3)
		visor.segurar_pose = false


## SUPER: a arena escurece, raios dourados giram atrás do atacante e ele brilha
## carregando. Devolve os nós para sumir depois do golpe.
func _carregar_super(atacante: Doce3D) -> Array[Node]:
	var escuro := ColorRect.new()
	escuro.name = "EscuroSuper"
	escuro.color = Color(0.08, 0.03, 0.15, 0.0)
	escuro.set_anchors_preset(PRESET_FULL_RECT)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escuro)
	move_child(escuro, _palco.get_index())  # atrás dos doces
	create_tween().tween_property(escuro, "color:a", 0.6, 0.25)
	var raios := TextureRect.new()
	raios.name = "RaiosSuper"
	raios.texture = RAIOS
	raios.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	raios.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vaga := atacante.get_parent() as Control
	vaga.add_child(raios)
	vaga.move_child(raios, 0)
	var lado := minf(vaga.size.x, vaga.size.y) * 1.5
	raios.size = Vector2.ONE * lado
	raios.pivot_offset = raios.size / 2.0
	raios.position = vaga.size / 2.0 - raios.size / 2.0
	raios.modulate = Color(1, 0.85, 0.3, 0.0)
	raios.scale = Vector2.ONE * 0.4
	var giro := raios.create_tween().set_parallel()
	giro.tween_property(raios, "modulate:a", 0.95, 0.2)
	giro.tween_property(raios, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	giro.tween_property(raios, "rotation", TAU * 0.7, 1.6)
	Audio.tocar("especial", 0.8)
	var brilho := create_tween()
	brilho.tween_property(atacante, "modulate", Color(1.7, 1.5, 1.0), 0.3)
	_tremer(atacante, 4.0)
	_faiscas(atacante.get_global_rect().get_center(), 24, true)
	return [escuro, raios]


func _sumir(nos: Array[Node]) -> void:
	for no in nos:
		if is_instance_valid(no):
			var some := no.create_tween()
			some.tween_property(no, "modulate:a", 0.0, 0.3)
			some.tween_callback(no.queue_free)


## Estouro do golpe: raios, um anel que cresce e uma palavra de quadrinho (POW!).
func _impacto(onde: Vector2, forte: bool) -> void:
	var raios := TextureRect.new()
	raios.texture = RAIOS
	raios.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	raios.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raios.size = Vector2.ONE * (380.0 if forte else 250.0)
	raios.pivot_offset = raios.size / 2.0
	raios.position = onde - raios.size / 2.0
	raios.modulate = Color(1, 0.95, 0.6, 0.95)
	raios.scale = Vector2.ONE * 0.2
	add_child(raios)
	var t := raios.create_tween().set_parallel()
	t.tween_property(raios, "scale", Vector2.ONE * 1.3, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(raios, "rotation", 0.6, 0.3)
	t.tween_property(raios, "modulate:a", 0.0, 0.25).set_delay(0.08)
	t.chain().tween_callback(raios.queue_free)
	var anel := Panel.new()
	anel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0)
	estilo.border_color = Color(1, 1, 1, 0.9)
	estilo.set_border_width_all(10)
	estilo.set_corner_radius_all(999)
	anel.add_theme_stylebox_override("panel", estilo)
	anel.size = Vector2.ONE * (220.0 if forte else 150.0)
	anel.pivot_offset = anel.size / 2.0
	anel.position = onde - anel.size / 2.0
	anel.scale = Vector2.ONE * 0.2
	add_child(anel)
	var a := anel.create_tween().set_parallel()
	a.tween_property(anel, "scale", Vector2.ONE * 1.6, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	a.tween_property(anel, "modulate:a", 0.0, 0.28)
	a.chain().tween_callback(anel.queue_free)
	var palavra := Label.new()
	palavra.name = "PalavraGolpe"
	palavra.theme_type_variation = &"TituloClaro"
	palavra.add_theme_font_size_override("font_size", 92 if forte else 70)
	palavra.add_theme_color_override("font_color", Color("#FF6FAE") if forte else AMARELO)
	palavra.add_theme_constant_override("outline_size", 18)
	palavra.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	palavra.text = "SUPER!" if forte else PALAVRAS_GOLPE.pick_random()
	palavra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(palavra)
	palavra.size = palavra.get_combined_minimum_size()
	palavra.pivot_offset = palavra.size / 2.0
	palavra.position = onde + Vector2(0, -120) - palavra.size / 2.0
	palavra.rotation = randf_range(-0.28, 0.28)
	palavra.scale = Vector2.ONE * 0.2
	var p := palavra.create_tween()
	p.tween_property(palavra, "scale", Vector2.ONE * 1.25, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	p.tween_property(palavra, "scale", Vector2.ONE, 0.12)
	p.tween_interval(0.35)
	p.tween_property(palavra, "modulate:a", 0.0, 0.2)
	p.tween_callback(palavra.queue_free)


## Cópia apagada do doce no caminho do bote do SUPER (rastro).
func _rastro(visor: Doce3D) -> void:
	if not is_instance_valid(visor) or not is_instance_valid(visor._imagem):
		return
	var copia := TextureRect.new()
	copia.texture = visor._imagem.texture
	copia.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	copia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(copia)
	copia.size = visor._imagem.size
	copia.global_position = visor._imagem.global_position
	copia.modulate = Color(1, 0.6, 0.9, 0.5)
	var some := copia.create_tween()
	some.tween_property(copia, "modulate:a", 0.0, 0.25)
	some.tween_callback(copia.queue_free)


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


## `vida_forcada` >= 0: mostra essa vida (o nocauteado, que já saiu da vez, vai a zero).
func _atualizar_vida(quem: String, na_hora := false, vida_forcada := -1) -> void:
	var dados: Dictionary = luta.meu() if quem == "meu" else luta.deles()
	var l: Dictionary = _lado[quem]
	var vida := 0 if dados.is_empty() else int(dados["vida"])
	if vida_forcada >= 0:
		vida = vida_forcada
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


## A energia do GOLPE SUPREMO (uma estrela por pergunta relâmpago certa).
func _atualizar_super() -> void:
	if luta == null:
		return
	for i in _super.get_child_count():
		var estrela: TextureRect = _super.get_child(i)
		var cheia := i < luta.energia
		estrela.modulate = AMARELO if cheia else Color(1, 1, 1, 0.28)
		estrela.pivot_offset = estrela.size / 2.0
		estrela.scale = Vector2.ONE * (1.25 if cheia else 1.0)


## Sai da luta sem prêmio (voltar no meio).
func desistir() -> void:
	respondendo = false
	em_luta = false
	luta = null
	mostrar_arena()


func _terminar() -> void:
	_terminou = true
	em_luta = false
	respondendo = false
	_quadro_pergunta.visible = false
	_controles.visible = false
	_aviso_deles.visible = false
	var venceu := luta.venceu()
	var ganho := luta.concluir()
	if venceu:
		Audio.tocar("vitoria")
		_vitoria(_visor_meu)
		_confete()
	else:
		_vitoria(_visor_deles)
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
			premios.add_child(Itens.ficha(Itens.bau(ganho["bau"]), "+1", 44))
		if ganho.has("movel"):
			extras = "+ " + Casa.MOVEIS[ganho["movel"]]["nome"] + " PARA A MINHA CASA!"
		if extras != "":
			_texto(coluna, extras, 30)
		_texto(coluna, "%d ACERTOS EM %d PERGUNTAS" % [luta.acertos, luta.respondidas], 24)
	else:
		coluna.add_child(Itens.fichas_premio({"acucar": ganho["acucar"]}, 40))
		_texto(coluna, "PELO ESFORÇO", 26)
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


## Texto que pula na tela (cresce, passa do ponto e volta), sobe e some: o dano
## do golpe e o NOCAUTE (posição em fração da tela).
func _texto_pulando(texto: String, onde: Vector2, tamanho: int, cor: Color) -> Label:
	var rotulo := _texto_voando(texto, onde, tamanho, 1.0)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.pivot_offset = rotulo.get_combined_minimum_size() / 2.0
	rotulo.scale = Vector2.ONE * 0.3
	var pulo := rotulo.create_tween()
	pulo.tween_property(rotulo, "scale", Vector2.ONE * 1.3, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulo.tween_property(rotulo, "scale", Vector2.ONE, 0.15)
	return rotulo


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
