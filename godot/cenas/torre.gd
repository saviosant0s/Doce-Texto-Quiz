extends Control
## TORRE DE DOCES: empilhe andares de bolo o mais alto que der (regras em
## scripts/torre.gd). Toque em qualquer lugar para soltar o andar que passa.
## O céu vai escurecendo e aparecem estrelas conforme a torre sobe; a cada
## 10 andares, uma pergunta rápida do quiz vale bônus.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const BRILHO := preload("res://assets/doce_match/brilho.svg")
const ALTURA_ANDAR := 44.0
const TOPO_NA_TELA := 0.42  # o topo da torre fica a 42% da altura da tela
const TEMPO_PERGUNTA := 12.0
const SABORES := [
	["#FF8FB8", "#FFE3EE"], ["#7A4322", "#C98A5A"], ["#FFF1D8", "#FFFFFF"], ["#E8364F", "#FFD1DC"],
	["#8FE3C0", "#E9FFF6"], ["#FFD23F", "#FFF6C8"], ["#8B7CF6", "#E4DEFF"],
]
const CEU := [Color("#9FD4F7"), Color("#FFB3D1"), Color("#7E57B1"), Color("#1E1440")]

var jogo: Torre
var _mundo: Node2D
var _andares_nos: Array = []
var _andar_movel: Node2D
var _ceu: TextureRect
var _degrade: Gradient
var _nuvens: Array[Control] = []
var _estrelas: Node2D
var _rotulo_andares: Label
var _rotulo_recorde: Label
var _painel: Control
var _jogando := false
var _deslocamento := 0.0  # quanto o mundo já desceu (a câmera "sobe")


func _ready() -> void:
	_montar()
	mostrar_inicio()
	Telas.dica_primeira_vez("torre", "TORRE DE DOCES",
		"Um andar de bolo passa de um lado para o outro: toque para soltar em cima da torre. O que sobrar para fora cai! Solte certinho para um PERFEITO. A cada 10 andares, uma pergunta do quiz vale bônus.")


func ao_voltar() -> void:
	if _jogando and not jogo.acabou:
		_terminar()
		return
	Telas.voltar()


# --- Montagem ------------------------------------------------------------------

func _montar() -> void:
	_ceu = TextureRect.new()
	_ceu.set_anchors_preset(PRESET_FULL_RECT)
	_ceu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ceu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ceu.stretch_mode = TextureRect.STRETCH_SCALE
	_degrade = Gradient.new()
	var textura := GradientTexture2D.new()
	textura.gradient = _degrade
	textura.fill_from = Vector2(0, 0)
	textura.fill_to = Vector2(0, 1)
	textura.width = 4
	textura.height = 256
	_ceu.texture = textura
	add_child(_ceu)
	_pintar_ceu(0.0)
	_estrelas = Node2D.new()
	_estrelas.modulate.a = 0.0
	add_child(_estrelas)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 9
	for i in 60:
		var estrela := Sprite2D.new()
		estrela.texture = BRILHO
		estrela.scale = Vector2.ONE * sorteio.randf_range(0.2, 0.6)
		estrela.position = Vector2(sorteio.randf_range(0, 1600), sorteio.randf_range(0, 900))
		_estrelas.add_child(estrela)
	# nuvens de algodão-doce (andam devagar; sobem mais devagar que a torre)
	for i in 6:
		var nuvem := Panel.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(1, 1, 1, 0.75)
		estilo.set_corner_radius_all(60)
		nuvem.add_theme_stylebox_override("panel", estilo)
		nuvem.size = Vector2(sorteio.randf_range(140, 260), sorteio.randf_range(46, 70))
		nuvem.position = Vector2(sorteio.randf_range(0, 1400), sorteio.randf_range(80, 520))
		nuvem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nuvem.set_meta("y", nuvem.position.y)
		nuvem.set_meta("velocidade", sorteio.randf_range(12, 30))
		add_child(nuvem)
		_nuvens.append(nuvem)
	_mundo = Node2D.new()
	_mundo.name = "Mundo"
	add_child(_mundo)
	# morros de sorvete atrás da torre
	var morros := Node2D.new()
	morros.name = "Morros"
	morros.draw.connect(func():
		var cores := [Color("#FFC2DA"), Color("#C9B3EC"), Color("#A8E6C1"), Color("#FFE08A")]
		for k in 7:
			var cx := -200.0 + k * 300.0
			morros.draw_circle(Vector2(cx, 60), 190.0 + (k % 3) * 40.0, cores[k % cores.size()])
			morros.draw_circle(Vector2(cx, -60 - (k % 3) * 40.0), 70.0, Color(1, 1, 1, 0.85)))
	_mundo.add_child(morros)
	# chão de biscoito
	var chao := ColorRect.new()
	chao.color = Color("#D9A05B")
	chao.size = Vector2(4000, 600)
	chao.position = Vector2(-2000, 0)
	_mundo.add_child(chao)
	var grama := ColorRect.new()
	grama.color = Color("#6FC45A")
	grama.size = Vector2(4000, 14)
	grama.position = Vector2(-2000, 0)
	_mundo.add_child(grama)
	_posicionar_chao()
	# topo: voltar, título, andares e recorde
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_TOP_WIDE)
	for lado in ["left", "right", "top"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margem)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(topo)
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
	var titulo := Label.new()
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 38)
	titulo.text = "TORRE DE DOCES"
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	var placar := VBoxContainer.new()
	placar.add_theme_constant_override("separation", -6)
	placar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(placar)
	_rotulo_andares = Label.new()
	_rotulo_andares.theme_type_variation = &"TituloClaro"
	_rotulo_andares.add_theme_font_size_override("font_size", 64)
	_rotulo_andares.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	_rotulo_andares.add_theme_constant_override("outline_size", 12)
	_rotulo_andares.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	placar.add_child(_rotulo_andares)
	_rotulo_recorde = Label.new()
	_rotulo_recorde.theme_type_variation = &"SubtituloClaro"
	_rotulo_recorde.add_theme_font_size_override("font_size", 22)
	_rotulo_recorde.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	_rotulo_recorde.add_theme_constant_override("outline_size", 8)
	_rotulo_recorde.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	placar.add_child(_rotulo_recorde)


func _posicionar_chao() -> void:
	var chao := _chao()
	_mundo.get_node("Morros").position = Vector2(_meio() - 700, chao)
	for no in _mundo.get_children():
		if no is ColorRect:
			no.position.y = chao


func _meio() -> float:
	return get_viewport_rect().size.x / 2.0


## Altura (na tela, sem o deslocamento) do chão / da base da torre.
func _chao() -> float:
	return get_viewport_rect().size.y - 90.0


func _y_do_andar(i: int) -> float:
	return _chao() - (i + 1) * ALTURA_ANDAR


# --- Partida -------------------------------------------------------------------

func comecar() -> void:
	_fechar_painel()
	if not Confeitaria.gastar_acucar(Torre.CUSTO_ACUCAR):
		_sem_acucar()
		return
	for no in _andares_nos:
		no.queue_free()
	_andares_nos.clear()
	if is_instance_valid(_andar_movel):
		_andar_movel.queue_free()
	jogo = Torre.new()
	_deslocamento = 0.0
	_mundo.position = Vector2(0, 0)
	_posicionar_chao()
	_andares_nos.append(_criar_andar(jogo.andares[0], 0))
	_andar_movel = _criar_andar(jogo.atual, 1)
	_jogando = true
	_atualizar_placar()


func _process(delta: float) -> void:
	if not _jogando or jogo == null or jogo.acabou:
		return
	jogo.avancar(delta)
	if is_instance_valid(_andar_movel):
		_andar_movel.position.x = _meio() + jogo.atual["x"]
	# a câmera sobe junto com a torre, devagar
	var alvo := maxf(0.0, (jogo.altura() + 1) * ALTURA_ANDAR - get_viewport_rect().size.y * (1.0 - TOPO_NA_TELA) + 90.0)
	_deslocamento = lerpf(_deslocamento, alvo, minf(1.0, 4.0 * delta))
	_mundo.position.y = _deslocamento
	_atualizar_ceu()
	for nuvem in _nuvens:
		nuvem.position.x = wrapf(nuvem.position.x + nuvem.get_meta("velocidade") * delta, -300, get_viewport_rect().size.x + 50)
		nuvem.position.y = float(nuvem.get_meta("y")) + _deslocamento * 0.35


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		soltar()


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and evento.keycode == KEY_SPACE:
		soltar()


## Solta o andar que está passando (toque na tela ou espaço).
func soltar() -> void:
	if not _jogando or jogo.acabou or jogo.pergunta_pendente or is_instance_valid(_painel):
		return
	var r := jogo.soltar()
	if r.is_empty():
		return
	var i := jogo.altura()
	if is_instance_valid(_andar_movel):
		_andar_movel.queue_free()
	if not r["ficou"]:
		_pedaco_caindo(r["sobra_x"], r["sobra_largura"], _y_do_andar(i), i + 1)
		Audio.tocar("erro")
		_terminar()
		return
	var andar := _criar_andar({"x": r["x"], "largura": r["largura"]}, i)
	_andares_nos.append(andar)
	if r["sobra_largura"] > 0.5:
		_pedaco_caindo(r["sobra_x"], r["sobra_largura"], _y_do_andar(i), i)
		Audio.tocar("estouro", 0.9 + minf(i, 30) * 0.01)
	if r["perfeito"]:
		Audio.tocar("especial", 1.0 + minf(jogo.perfeitos_seguidos, 6) * 0.08)
		_texto_voando("PERFEITO!" if not r["cresceu"] else "PERFEITO! +LARGO", Vector2(_meio() + r["x"], _y_do_andar(i)))
		_brilho_do_andar(andar)
	andar.scale = Vector2(1.08, 0.8)
	andar.create_tween().tween_property(andar, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	_atualizar_placar()
	if jogo.pergunta_pendente:
		_andar_movel = null
		await get_tree().create_timer(0.35).timeout
		_perguntar()
		return
	_andar_movel = _criar_andar(jogo.atual, i + 1)


## Um andar de bolo desenhado: massa, recheio e cobertura escorrendo.
func _criar_andar(dados: Dictionary, indice: int) -> Node2D:
	var andar := Node2D.new()
	andar.name = "Andar"
	andar.position = Vector2(_meio() + float(dados["x"]), _y_do_andar(indice))
	var sabor: Array = SABORES[indice % SABORES.size()]
	var largura: float = dados["largura"]
	andar.draw.connect(_desenhar_andar.bind(andar, largura, sabor, indice))
	_mundo.add_child(andar)
	return andar


func _desenhar_andar(andar: Node2D, largura: float, sabor: Array, indice: int) -> void:
	var massa := Color(sabor[0])
	var cobertura := Color(sabor[1])
	var meia := largura / 2.0
	var h := ALTURA_ANDAR
	# sombra embaixo, massa e uma faixa de recheio
	andar.draw_rect(Rect2(-meia, 2, largura, h), Color(0, 0, 0, 0.18))
	andar.draw_rect(Rect2(-meia, 0, largura, h), massa)
	andar.draw_rect(Rect2(-meia, h * 0.55, largura, h * 0.14), massa.lightened(0.35))
	andar.draw_rect(Rect2(-meia, h - 5, largura, 5), massa.darkened(0.2))
	# cobertura em cima com pingos escorrendo
	andar.draw_rect(Rect2(-meia, 0, largura, h * 0.28), cobertura)
	var passo := 22.0
	var x := -meia + 8.0
	var k := indice * 7
	while x < meia - 6.0:
		var comprimento := 6.0 + float((k * 13) % 10)
		andar.draw_circle(Vector2(x, h * 0.28 + comprimento * 0.5), 6.0, cobertura)
		andar.draw_rect(Rect2(x - 6, h * 0.2, 12, comprimento * 0.5 + 2), cobertura)
		x += passo
		k += 1
	# confeitos
	var cores := [Color("#FF4F8B"), Color("#3E8EF0"), Color("#3DDC97"), Color("#FFD23F"), Color("#B36BFF")]
	for c in int(largura / 26.0):
		var px := -meia + 10.0 + c * 26.0 + float((c * 7 + indice) % 9)
		andar.draw_rect(Rect2(px, 4 + (c % 2) * 3, 7, 3), cores[(c + indice) % cores.size()])
	# volume: luz do lado esquerdo e sombra do direito (parece redondo)
	var faixa := minf(largura * 0.14, 26.0)
	andar.draw_rect(Rect2(-meia, 0, faixa, h), Color(1, 1, 1, 0.18))
	andar.draw_rect(Rect2(-meia + faixa, 0, faixa * 0.6, h), Color(1, 1, 1, 0.08))
	andar.draw_rect(Rect2(meia - faixa, 0, faixa, h), Color(0, 0, 0, 0.16))
	andar.draw_rect(Rect2(meia - faixa * 1.6, 0, faixa * 0.6, h), Color(0, 0, 0, 0.07))
	# brilho de cima
	andar.draw_rect(Rect2(-meia + 6, 3, largura * 0.35, 3), Color(1, 1, 1, 0.45))


func _pedaco_caindo(x: float, largura: float, y: float, indice: int) -> void:
	var pedaco := _criar_andar({"x": x, "largura": largura}, indice)
	pedaco.position.y = y
	var lado := 1.0 if x > (jogo.topo()["x"] if jogo.andares.size() > 0 else 0.0) else -1.0
	var tween := pedaco.create_tween().set_parallel()
	tween.tween_property(pedaco, "position", pedaco.position + Vector2(lado * 120, 700), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(pedaco, "rotation", lado * 1.6, 1.1)
	tween.chain().tween_callback(pedaco.queue_free)


func _brilho_do_andar(andar: Node2D) -> void:
	var faiscas := CPUParticles2D.new()
	faiscas.texture = BRILHO
	faiscas.amount = 16
	faiscas.lifetime = 0.6
	faiscas.one_shot = true
	faiscas.explosiveness = 1.0
	faiscas.spread = 180.0
	faiscas.initial_velocity_min = 120.0
	faiscas.initial_velocity_max = 260.0
	faiscas.gravity = Vector2(0, 200)
	faiscas.scale_amount_min = 0.4
	faiscas.scale_amount_max = 0.9
	faiscas.color = Color("#FFF3B0")
	faiscas.position = Vector2(0, ALTURA_ANDAR / 2)
	faiscas.emitting = true
	andar.add_child(faiscas)


func _texto_voando(texto: String, ponto_mundo: Vector2) -> void:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 48)
	rotulo.add_theme_color_override("font_color", Cores.AMARELO)
	rotulo.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	rotulo.add_theme_constant_override("outline_size", 12)
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rotulo)
	rotulo.position = ponto_mundo + _mundo.position - Vector2(rotulo.get_minimum_size().x / 2, 70)
	var tween := rotulo.create_tween()
	tween.tween_property(rotulo, "position:y", rotulo.position.y - 70, 0.7)
	tween.parallel().tween_property(rotulo, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(rotulo.queue_free)


## O céu muda com a altura: azul, pôr do sol rosa, roxo e noite com estrelas.
func _atualizar_ceu() -> void:
	_pintar_ceu(clampf(jogo.altura() / 45.0, 0.0, 1.0))
	_estrelas.modulate.a = clampf((jogo.altura() - 20) / 20.0, 0.0, 1.0)


func _pintar_ceu(fracao: float) -> void:
	var t := fracao * (CEU.size() - 1)
	var i := mini(int(t), CEU.size() - 2)
	var cor: Color = CEU[i].lerp(CEU[i + 1], t - i)
	_degrade.set_color(0, cor.darkened(0.08))
	_degrade.set_color(1, cor.lightened(0.35))


func _atualizar_placar() -> void:
	_rotulo_andares.text = "%d ANDARES" % (jogo.altura() if jogo else 0)
	_rotulo_recorde.text = "RECORDE: %d" % maxi(Torre.recorde(), jogo.altura() if jogo else 0)


# --- Pergunta dos 10 andares ------------------------------------------------------

func _perguntar() -> void:
	var pergunta := Torre.sortear_pergunta()
	if pergunta.is_empty():
		jogo.responder(false)
		_andar_movel = _criar_andar(jogo.atual, jogo.altura() + 1)
		return
	var coluna := _abrir_painel("%d ANDARES! PERGUNTA BÔNUS" % jogo.altura())
	var texto := Label.new()
	texto.theme_type_variation = &"TituloClaro"
	texto.add_theme_font_size_override("font_size", 28)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(760, 0)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.text = str(pergunta["enunciado"])
	coluna.add_child(texto)
	var barra := ProgressBar.new()
	barra.theme_type_variation = &"BarraClara"
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 14)
	barra.max_value = TEMPO_PERGUNTA
	barra.value = TEMPO_PERGUNTA
	coluna.add_child(barra)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	coluna.add_child(grade)
	var respondeu := [false]
	for k in pergunta["alternativas"].size():
		var botao := Button.new()
		botao.name = "Alternativa%d" % k
		botao.text = str(pergunta["alternativas"][k])
		botao.custom_minimum_size = Vector2(370, 64)
		botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		botao.add_theme_font_size_override("font_size", 22)
		botao.focus_mode = Control.FOCUS_NONE
		botao.pressed.connect(func():
			if respondeu[0]:
				return
			respondeu[0] = true
			_resultado_pergunta(k == int(pergunta["resposta"])))
		grade.add_child(botao)
	var tempo := barra.create_tween()
	tempo.tween_property(barra, "value", 0.0, TEMPO_PERGUNTA)
	tempo.tween_callback(func():
		if not respondeu[0]:
			respondeu[0] = true
			_resultado_pergunta(false))


func _resultado_pergunta(acertou: bool) -> void:
	jogo.responder(acertou)
	_fechar_painel()
	if acertou:
		Audio.tocar("acerto")
		_texto_voando("ACERTOU! +%d E ANDAR LARGO" % Torre.PONTOS_PERGUNTA, Vector2(_meio(), _y_do_andar(jogo.altura())))
		var topo: Node2D = _andares_nos[-1]
		topo.queue_free()
		_andares_nos[-1] = _criar_andar(jogo.topo(), jogo.altura())
	else:
		Audio.tocar("erro")
		_texto_voando("QUE PENA!", Vector2(_meio(), _y_do_andar(jogo.altura())))
	_andar_movel = _criar_andar(jogo.atual, jogo.altura() + 1)


# --- Início e fim ------------------------------------------------------------------

func mostrar_inicio() -> void:
	var coluna := _abrir_painel("TORRE DE DOCES")
	_texto_painel(coluna, "Toque na tela para soltar o andar em cima da torre.\nO que sobrar para fora cai! Solte certinho para um PERFEITO.\nA cada 10 andares, uma pergunta do quiz vale bônus.", 22)
	_texto_painel(coluna, "RECORDE: %d ANDARES" % Torre.recorde(), 30)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR", &"Alternativa", Telas.voltar))
	botoes.add_child(_botao("Jogar", "JOGAR (%d AÇÚCAR)" % Torre.CUSTO_ACUCAR, &"", comecar))


func _terminar() -> void:
	_jogando = false
	var premio := Torre.concluir(jogo)
	await get_tree().create_timer(0.9).timeout
	var coluna := _abrir_painel("A TORRE CAIU!" if jogo.acabou else "FIM DA TORRE")
	_texto_painel(coluna, "%d ANDARES" % jogo.altura(), 56)
	if premio["recorde_novo"]:
		_texto_painel(coluna, "NOVO RECORDE!", 32).add_theme_color_override("font_color", Cores.AMARELO)
	_texto_painel(coluna, "+%d MOEDAS · %d PERFEITOS%s" % [premio["moedas"], jogo.perfeitos,
		"  ·  +1 BAÚ DE DOCE!" if premio["bau"] != "" else ""], 26)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR", &"Alternativa", Telas.voltar))
	botoes.add_child(_botao("DeNovo", "DE NOVO (%d AÇÚCAR)" % Torre.CUSTO_ACUCAR, &"", comecar))
	if premio["recorde_novo"] or premio["bau"] != "":
		Audio.tocar("vitoria")


func _sem_acucar() -> void:
	var coluna := _abrir_painel("SEM AÇÚCAR!")
	_texto_painel(coluna, "Cada torre custa %d de açúcar. Você tem %d.\nCada acerto no quiz dá %d!" % [
		Torre.CUSTO_ACUCAR, Confeitaria.acucar(), Confeitaria.ACUCAR_POR_ACERTO], 24)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR", &"Alternativa", Telas.voltar))
	botoes.add_child(_botao("JogarQuiz", "JOGAR O QUIZ", &"", Telas.abrir.bind("niveis")))


func _abrir_painel(titulo: String) -> VBoxContainer:
	_fechar_painel()
	var camada := Control.new()
	camada.name = "Painel"
	camada.set_anchors_preset(PRESET_FULL_RECT)
	add_child(camada)
	_painel = camada
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.55)
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
	_texto_painel(coluna, titulo, 50)
	return coluna


func _fechar_painel() -> void:
	if is_instance_valid(_painel):
		_painel.queue_free()
	_painel = null


func _texto_painel(pai: Control, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 40 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.text = texto
	pai.add_child(rotulo)
	return rotulo


func _botao(nome: String, texto: String, estilo: StringName, acao: Callable) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.text = texto
	botao.theme_type_variation = estilo
	botao.custom_minimum_size = Vector2(260 if estilo != &"" else 330, 72)
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(acao)
	if estilo == &"":
		for estado in ["normal", "hover", "pressed", "focus"]:
			var caixa := botao.get_theme_stylebox(estado)
			if caixa is StyleBoxFlat:
				var verde: StyleBoxFlat = caixa.duplicate()
				verde.bg_color = Cores.VERDE if estado != "pressed" else Cores.VERDE_ESCURO
				verde.border_color = Cores.VERDE_ESCURO
				botao.add_theme_stylebox_override(estado, verde)
		for cor in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			botao.add_theme_color_override(cor, Color.WHITE)
	return botao
