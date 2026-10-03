class_name LutaChefao
extends CanvasLayer
## A luta contra o chefão na praça (regras em scripts/chefao.gd; o gigante em
## componentes/vila/chefao_vila.gd). A câmera enquadra o doce do jogador e o
## chefão; em cima, a vida do chefão e os corações; embaixo, a pergunta.
## Acertou: o seu doce joga balas nele (mais balas com combo). Errou: ele joga
## chocolate no seu doce (que fica sujo) e você perde um coração.

signal terminou(venceu: bool)

const CORACAO := preload("res://assets/icones/coracao.svg")
const VERDE := Color("#7BE07B")
const AMARELO := Color("#F4E038")
const VERMELHO := Color("#FF5A5A")
const LUGAR_JOGADOR := Vector3(0, 0, 5.2)
const CAMERA := Vector3(-7.0, 4.0, 17.0)  # (em frente à Minha Casa, sem tapar)
const OLHAR := Vector3(0.0, 4.5, 1.5)
## Lente deslocada: a imagem sobe um pouco (o quadro da pergunta tapa a parte
## de baixo da tela), sem entortar a perspectiva.
const DESLOCAMENTO_LENTE := 0.1  # fração da altura da tela
const ANGULO := 65.0

var luta: Chefao
var respondendo := false
var _vila: Node
var _chefao: ChefaoVila
var _vida: ProgressBar
var _rastro: ProgressBar
var _texto_vida: Label
var _coracoes: HBoxContainer
var _combo: Label
var _bravo: Label
var _quadro: PanelContainer
var _enunciado: Label
var _tempo: ProgressBar
var _cor_tempo: StyleBoxFlat
var _alternativas: GridContainer
var _tempo_resta := 0.0
var _painel: Control


func _init(vila: Node, chefao: ChefaoVila) -> void:
	_vila = vila
	_chefao = chefao
	layer = 5
	name = "LutaChefao"


func _ready() -> void:
	_montar()
	comecar()


func _process(delta: float) -> void:
	if not respondendo:
		return
	_tempo_resta = maxf(0.0, _tempo_resta - delta)
	_tempo.value = _tempo_resta
	var fracao := _tempo_resta / luta.tempo()
	_cor_tempo.bg_color = VERDE if fracao > 0.5 else (AMARELO if fracao > 0.25 else VERMELHO)
	if _tempo_resta <= 0.0:
		responder(-1)


# --- Montagem ------------------------------------------------------------------------

func _montar() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_FULL_RECT)
	coluna.offset_left = 20
	coluna.offset_right = -20
	coluna.offset_top = 14
	coluna.offset_bottom = -14
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(coluna)
	# topo: fugir, nome e vida do chefão
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)
	var fugir := Button.new()
	fugir.name = "Fugir"
	fugir.text = "FUGIR"
	fugir.theme_type_variation = &"BotaoSecundario"
	fugir.custom_minimum_size = Vector2(130, 56)
	fugir.focus_mode = Control.FOCUS_NONE
	fugir.pressed.connect(sair)
	topo.add_child(fugir)
	var placa := PanelContainer.new()
	placa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#2E1D4A", 0.9)
	estilo.set_corner_radius_all(16)
	estilo.set_border_width_all(4)
	estilo.border_color = Color("#E8364F")
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 4
	estilo.content_margin_bottom = 8
	placa.add_theme_stylebox_override("panel", estilo)
	topo.add_child(placa)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 2)
	placa.add_child(dentro)
	var linha := HBoxContainer.new()
	dentro.add_child(linha)
	var nome := Label.new()
	nome.name = "NomeChefao"
	nome.theme_type_variation = &"TituloClaro"
	nome.add_theme_font_size_override("font_size", 30)
	nome.text = Chefao.nome()
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(nome)
	_bravo = Label.new()
	_bravo.theme_type_variation = &"TituloClaro"
	_bravo.add_theme_font_size_override("font_size", 24)
	_bravo.add_theme_color_override("font_color", VERMELHO)
	_bravo.text = "BRAVO!"
	_bravo.visible = false
	linha.add_child(_bravo)
	var barras := Control.new()
	barras.custom_minimum_size = Vector2(0, 26)
	dentro.add_child(barras)
	_rastro = _barra(Color(1, 1, 1, 0.85), Color(0, 0, 0, 0.45))
	barras.add_child(_rastro)
	_vida = _barra(Color("#E8364F"), Color(0, 0, 0, 0))
	_vida.name = "VidaChefao"
	barras.add_child(_vida)
	_texto_vida = Label.new()
	_texto_vida.theme_type_variation = &"TituloClaro"
	_texto_vida.add_theme_font_size_override("font_size", 18)
	_texto_vida.add_theme_constant_override("outline_size", 6)
	_texto_vida.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
	_texto_vida.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto_vida.set_anchors_preset(Control.PRESET_FULL_RECT)
	barras.add_child(_texto_vida)
	# corações e combo
	var meio := HBoxContainer.new()
	meio.add_theme_constant_override("separation", 6)
	meio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(meio)
	_coracoes = HBoxContainer.new()
	_coracoes.name = "Coracoes"
	_coracoes.add_theme_constant_override("separation", 4)
	meio.add_child(_coracoes)
	for i in Chefao.CORACOES:
		var c := TextureRect.new()
		c.texture = CORACAO
		c.custom_minimum_size = Vector2(40, 40)
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.modulate = Color("#FF5A7A")
		_coracoes.add_child(c)
	_combo = Label.new()
	_combo.name = "Combo"
	_combo.theme_type_variation = &"TituloClaro"
	_combo.add_theme_font_size_override("font_size", 30)
	_combo.add_theme_constant_override("outline_size", 10)
	_combo.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	meio.add_child(_combo)
	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(espaco)
	# pergunta
	_quadro = PanelContainer.new()
	_quadro.name = "QuadroPergunta"
	_quadro.theme_type_variation = &"PainelRoxo"
	_quadro.visible = false
	coluna.add_child(_quadro)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 8)
	_quadro.add_child(caixa)
	_enunciado = Label.new()
	_enunciado.theme_type_variation = &"TituloClaro"
	_enunciado.add_theme_font_size_override("font_size", 26)
	_enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enunciado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(_enunciado)
	_tempo = _barra(VERDE, Color(0, 0, 0, 0.3))
	_tempo.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_tempo.custom_minimum_size = Vector2(0, 14)
	_cor_tempo = _tempo.get_theme_stylebox("fill")
	caixa.add_child(_tempo)
	_alternativas = GridContainer.new()
	_alternativas.name = "Alternativas"
	_alternativas.columns = 2
	_alternativas.add_theme_constant_override("h_separation", 10)
	_alternativas.add_theme_constant_override("v_separation", 8)
	caixa.add_child(_alternativas)
	_atualizar()


func _barra(cor: Color, fundo: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.set_anchors_preset(Control.PRESET_FULL_RECT)
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


# --- Fluxo ----------------------------------------------------------------------------

func comecar() -> void:
	luta = Chefao.new()
	_vida.max_value = luta.vida_max
	_rastro.max_value = luta.vida_max
	_vida.value = luta.vida
	_rastro.value = luta.vida
	_atualizar()
	var jogador: DoceAndante = _vila.jogador
	jogador.global_position = LUGAR_JOGADOR
	jogador.olhar_para(_chefao.alvo())
	var camera: Camera3D = _vila._camera
	var ate := Transform3D(Basis.looking_at(OLHAR - CAMERA), CAMERA)
	usar_lente(camera, true)
	var voo := create_tween()
	voo.tween_method(func(t: float): camera.global_transform = camera.global_transform.interpolate_with(ate, t),
		0.0, 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	Audio.tocar("explosao", 0.6)
	_chefao.preparar_ataque()
	_texto_voando('%s: "ESTA VILA AGORA É MINHA!"' % Chefao.nome(), Vector2(0.5, 0.42), 34, 1.8)
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(_quadro) and not luta.acabou():
		_nova_pergunta()


func _nova_pergunta() -> void:
	var p := luta.proxima_pergunta()
	_quadro.visible = true
	_enunciado.text = str(p["enunciado"])
	for filho in _alternativas.get_children():
		_alternativas.remove_child(filho)
		filho.queue_free()
	for k in p["alternativas"].size():
		var b := Button.new()
		b.name = "Alternativa%d" % k
		b.theme_type_variation = &"Alternativa"
		b.text = str(p["alternativas"][k])
		b.custom_minimum_size = Vector2(0, 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 21)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(responder.bind(k))
		_alternativas.add_child(b)
	_tempo_resta = luta.tempo()
	_tempo.max_value = luta.tempo()
	_tempo.value = _tempo_resta
	respondendo = true


## Responde (-1 = acabou o tempo).
func responder(k: int) -> void:
	if not respondendo:
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
	var r := luta.responder(k, luta.tempo() - _tempo_resta)
	Audio.tocar("acerto" if r["acertou"] else "erro")
	await get_tree().create_timer(0.45).timeout
	_quadro.visible = false
	if r["acertou"]:
		await _jogador_ataca(r)
	else:
		await _chefao_ataca()
	_atualizar()
	if r["ficou_bravo"]:
		_chefao.ficar_bravo()
		Audio.tocar("explosao", 0.5)
		_texto_voando("ELE FICOU BRAVO! MENOS TEMPO PARA RESPONDER!", Vector2(0.5, 0.42), 32, 1.6)
		await get_tree().create_timer(1.2).timeout
	if r["fim"] != "":
		_terminar(r["fim"] == "venceu")
	else:
		_nova_pergunta()


## O doce do jogador joga balas no chefão (uma por nível de combo, até 3).
func _jogador_ataca(r: Dictionary) -> void:
	var jogador: DoceAndante = _vila.jogador
	jogador.comemorar()
	var quantas := clampi(int(r["combo"]), 1, 3)
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F"]
	for i in quantas:
		var de := jogador.global_position + Vector3(0, 1.3, 0)
		_arremesso(de, _chefao.alvo() + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0), cores[i], 0.45, 3.0)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(0.35).timeout
	Audio.tocar("explosao" if quantas >= 3 else "estouro")
	_chefao.receber_golpe(quantas >= 3)
	_faiscas(_chefao.alvo(), 30 + 15 * quantas)
	var texto := "-%d" % r["dano"]
	if quantas >= 2:
		texto = "COMBO x%d! %s" % [r["combo"], texto]
	if r["rapido"]:
		texto = "RÁPIDO! " + texto
	_texto_voando(texto, Vector2(0.5, 0.3), 46 if quantas >= 3 else 38, 1.0)
	_atualizar_vida()
	await get_tree().create_timer(0.5).timeout


## O chefão joga chocolate no doce do jogador (que fica sujo) e tira um coração.
func _chefao_ataca() -> void:
	var jogador: DoceAndante = _vila.jogador
	_chefao.preparar_ataque()
	await get_tree().create_timer(0.18).timeout
	_arremesso(_chefao.mao(), jogador.global_position + Vector3(0, 1.0, 0), "#5A2E17", 0.7, 5.0)
	await get_tree().create_timer(0.55).timeout
	Audio.tocar("chape")
	jogador.sujar(jogador.altura_no_modelo(1.6))
	_faiscas(jogador.global_position + Vector3(0, 1.0, 0), 24, Color("#5A2E17"))
	_tremer_camera()
	var coracao: TextureRect = _coracoes.get_child(luta.coracoes) if luta.coracoes < _coracoes.get_child_count() else null
	if coracao:
		coracao.pivot_offset = coracao.size / 2.0
		var tween := coracao.create_tween()
		tween.tween_property(coracao, "scale", Vector2.ONE * 1.5, 0.12)
		tween.tween_property(coracao, "scale", Vector2.ONE, 0.2)
	_texto_voando("-1 CORAÇÃO", Vector2(0.3, 0.62), 34, 0.9)
	await get_tree().create_timer(0.6).timeout


func _terminar(venceu: bool) -> void:
	var ganho := luta.concluir()
	if venceu:
		Audio.tocar("vitoria")
		await _chefao.explodir()
		_vila.jogador.comemorar()
		await get_tree().create_timer(1.2).timeout
	var coluna := _abrir_painel("A VILA ESTÁ SALVA!" if venceu else "O CHEFÃO VENCEU DESTA VEZ...")
	if venceu:
		var premios := HBoxContainer.new()
		premios.alignment = BoxContainer.ALIGNMENT_CENTER
		premios.add_theme_constant_override("separation", 22)
		coluna.add_child(premios)
		for par in [[Itens.MOEDA, int(ganho["moedas"])], [Itens.ACUCAR, int(ganho["acucar"])]]:
			var icone := TextureRect.new()
			icone.texture = par[0]
			icone.custom_minimum_size = Vector2(54, 54)
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			premios.add_child(icone)
			var numero := _texto(premios, "+0", 44)
			var total: int = par[1]
			numero.create_tween().tween_method(func(v: float): numero.text = "+%d" % roundi(v), 0.0, float(total), 0.9)
		_texto(coluna, "+ BAÚ %s  + %d DE EXPERIÊNCIA" % ["DE OURO" if ganho["bau"] == "ouro" else "DE DOCE", ganho["xp"]], 28)
		_texto(coluna, "%d ACERTOS EM %d PERGUNTAS" % [luta.acertos, luta.rodadas], 22)
	else:
		_texto(coluna, "+%d AÇÚCAR PELO ESFORÇO. ELE CONTINUA NA PRAÇA: TENTE DE NOVO!" % ganho.get("acucar", 0), 24)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("VoltarVila", "VOLTAR PARA A VILA", &"BotaoComprar" if venceu else &"BotaoSecundario", sair))
	if not venceu:
		botoes.add_child(_botao("TentarDeNovo", "TENTAR DE NOVO", &"BotaoComprar", func():
			_painel.queue_free()
			comecar()))
	terminou.emit(venceu)


## Liga a lente deslocada (projeção de "frustum" com ângulo de ANGULO graus).
static func usar_lente(camera: Camera3D, ligada: bool) -> void:
	if not ligada:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		return
	var tamanho := 2.0 * camera.near * tan(deg_to_rad(ANGULO) / 2.0)
	camera.projection = Camera3D.PROJECTION_FRUSTUM
	camera.size = tamanho
	camera.frustum_offset = Vector2(0, -DESLOCAMENTO_LENTE * tamanho)


## Sai da luta (fugindo ou no fim): a vila volta ao normal.
func sair() -> void:
	usar_lente(_vila._camera, false)
	respondendo = false
	_vila.sair_da_luta_chefao()
	queue_free()


func _atualizar() -> void:
	if luta == null:
		return
	for i in _coracoes.get_child_count():
		(_coracoes.get_child(i) as TextureRect).modulate = Color("#FF5A7A") if i < luta.coracoes else Color(0.3, 0.25, 0.35, 0.6)
	_combo.text = "COMBO x%d" % luta.combo if luta.combo >= 2 else ""
	_bravo.visible = luta.bravo() and not luta.venceu()
	_texto_vida.text = "%d / %d" % [luta.vida, luta.vida_max]


func _atualizar_vida() -> void:
	create_tween().tween_property(_vida, "value", float(luta.vida), 0.2)
	create_tween().tween_property(_rastro, "value", float(luta.vida), 0.6).set_delay(0.35).set_trans(Tween.TRANS_SINE)
	_texto_vida.text = "%d / %d" % [luta.vida, luta.vida_max]


# --- Efeitos --------------------------------------------------------------------------

## Uma bola (bala ou chocolate) voando em arco de `de` até `ate`.
func _arremesso(de: Vector3, ate: Vector3, cor: String, raio: float, altura: float) -> void:
	var bola := MeshInstance3D.new()
	var malha := SphereMesh.new()
	malha.radius = raio
	malha.height = raio * 2.0
	bola.mesh = malha
	var mat := Pecas3D.material(Color(cor), 0.15)
	mat.emission_enabled = true
	mat.emission = Color(cor)
	mat.emission_energy_multiplier = 0.4
	bola.material_override = mat
	_vila.add_child(bola)
	bola.global_position = de
	var meio := (de + ate) / 2.0 + Vector3(0, altura, 0)
	var voo := bola.create_tween()
	voo.tween_method(func(t: float):
		bola.global_position = de.lerp(meio, t).lerp(meio.lerp(ate, t), t)
		bola.rotation.x += 0.3, 0.0, 1.0, 0.5)
	voo.tween_callback(bola.queue_free)


## Faíscas coloridas (ou respingos de chocolate) num ponto do mundo.
func _faiscas(onde: Vector3, quantas: int, cor := Color("#FFFFFF")) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = quantas
	p.lifetime = 0.8
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 7.0
	p.gravity = Vector3(0, -9.0, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.color = cor
	if cor == Color("#FFFFFF"):
		p.hue_variation_min = -1.0
		p.hue_variation_max = 1.0
		p.color = Color("#FF6FAE")
	var bolinha := SphereMesh.new()
	bolinha.radius = 0.1
	bolinha.height = 0.2
	bolinha.radial_segments = 6
	bolinha.rings = 3
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolinha.material = mat
	p.mesh = bolinha
	_vila.add_child(p)
	p.global_position = onde
	p.emitting = true
	p.finished.connect(p.queue_free)


func _tremer_camera() -> void:
	var camera: Camera3D = _vila._camera
	var base := camera.global_position
	var tween := camera.create_tween()
	for i in 6:
		tween.tween_property(camera, "global_position", base + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.2), 0) * (1.0 - i / 6.0), 0.04)
	tween.tween_property(camera, "global_position", base, 0.05)


func _abrir_painel(titulo: String) -> VBoxContainer:
	_painel = Control.new()
	_painel.name = "FimLuta"
	_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_painel)
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.55)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel.add_child(centro)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)
	var rotulo := _texto(coluna, titulo, 54)
	rotulo.name = "TituloFim"
	rotulo.pivot_offset = Vector2(250, 30)
	rotulo.scale = Vector2.ONE * 0.4
	rotulo.create_tween().tween_property(rotulo, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return coluna


func _texto(pai: Control, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 30 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.custom_minimum_size.x = 0 if tamanho >= 40 else 700
	rotulo.text = texto
	pai.add_child(rotulo)
	return rotulo


func _botao(nome: String, texto: String, estilo: StringName, acao: Callable) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.text = texto
	botao.theme_type_variation = estilo
	botao.custom_minimum_size = Vector2(300, 68)
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(acao)
	return botao


func _texto_voando(texto: String, onde: Vector2, tamanho: int, duracao: float) -> void:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_constant_override("outline_size", 12)
	rotulo.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rotulo)
	var tela := rotulo.get_viewport().get_visible_rect().size
	rotulo.position = tela * onde - rotulo.get_combined_minimum_size() / 2.0
	var tween := rotulo.create_tween().set_parallel()
	tween.tween_property(rotulo, "position:y", rotulo.position.y - 60.0, duracao)
	tween.tween_property(rotulo, "modulate:a", 0.0, duracao).set_delay(duracao * 0.5)
	tween.chain().tween_callback(rotulo.queue_free)
