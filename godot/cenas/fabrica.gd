extends Control
## FÁBRICA DE CHOCOLATE: toque nos chocolates do pedido que passam na
## esteira (regras em scripts/fabrica.gd). Os queimados e quebrados não!
## A cada 3 pedidos, um pedido especial: uma pergunta do quiz.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const BRILHO := preload("res://assets/doce_match/brilho.svg")
const TEMPO_PERGUNTA := 12.0
const RAIO := 40.0  # tamanho de um chocolate na tela
const ESTEIRA_Y := 0.66  # altura da esteira (fração da tela)

var jogo: Fabrica
var _nos := {}  # id -> Node2D do chocolate
var _fundo: Control
var _esteira: Control
var _pedido_caixa: HBoxContainer
var _rotulo_tempo: Label
var _rotulo_pedidos: Label
var _barra_tempo: ProgressBar
var _caixa: Control
var _painel: Control
var _jogando := false
var _faixas := 0.0  # animação das listras da esteira


func _ready() -> void:
	_montar()
	mostrar_inicio()
	Telas.dica_primeira_vez("fabrica", "FÁBRICA DE CHOCOLATE",
		"Olhe o PEDIDO no alto e toque nos chocolates certos que passam na esteira: eles vão para a caixa. Os queimados e quebrados não! Errar tira tempo. A cada 3 pedidos vem uma pergunta do quiz.")


func ao_voltar() -> void:
	if _jogando and not jogo.acabou:
		_terminar()
		return
	Telas.voltar()


# --- Desenho dos chocolates ---------------------------------------------------------

## Desenha um chocolate `tipo` centrado em (0,0) no `alvo`. `defeito`:
## queimado (preto, com fumacinha) ou quebrado (rachado).
static func desenhar_chocolate(alvo: CanvasItem, tipo: String, r: float, defeito := false, quebrado := false) -> void:
	var choco := Color("#6B3A1F")
	var escuro := Color("#3E1F0E")
	if defeito and not quebrado:
		choco = Color("#2A1A12")
		escuro = Color("#140C08")
	match tipo:
		"bombom":
			# forminha dourada pregueada + bola de chocolate com fio
			for k in 12:
				var a := k * TAU / 12.0
				alvo.draw_circle(Vector2(cos(a), sin(a) * 0.5 + 0.55) * r * 0.85, r * 0.22, Color("#E8B23A"))
			alvo.draw_circle(Vector2(0, 0.35 * r), r * 0.8, Color("#F2C84B"))
			alvo.draw_circle(Vector2(0, -0.05 * r), r * 0.72, choco)
			alvo.draw_arc(Vector2(0, -0.1 * r), r * 0.45, PI * 1.15, PI * 1.85, 10, Color("#F3E3B5"), r * 0.08)
			alvo.draw_circle(Vector2(-0.25 * r, -0.35 * r), r * 0.12, Color(1, 1, 1, 0.35))
		"trufa":
			alvo.draw_circle(Vector2.ZERO, r * 0.78, escuro)
			for k in 18:
				var a := k * 2.4
				var d := (k % 5) * 0.13 + 0.1
				alvo.draw_circle(Vector2(cos(a), sin(a)) * r * d, r * 0.06, Color("#8A5A3A"))
			alvo.draw_circle(Vector2(-0.3 * r, -0.3 * r), r * 0.14, Color(1, 1, 1, 0.25))
		"barra":
			alvo.draw_rect(Rect2(-r, -0.55 * r, 2 * r, 1.1 * r), escuro)
			for cx in 3:
				for cy in 2:
					alvo.draw_rect(Rect2(-0.92 * r + cx * 0.64 * r, -0.48 * r + cy * 0.5 * r, 0.56 * r, 0.42 * r), choco)
			alvo.draw_rect(Rect2(0.4 * r, -0.58 * r, 0.62 * r, 1.16 * r), Color("#C9CED6"))  # papel laminado
			alvo.draw_rect(Rect2(0.4 * r, -0.58 * r, 0.1 * r, 1.16 * r), Color("#E8ECF2"))
		"coracao":
			var cor := Color("#D8263A") if not defeito else Color("#3A1A1A")
			alvo.draw_circle(Vector2(-0.35 * r, -0.2 * r), r * 0.45, cor)
			alvo.draw_circle(Vector2(0.35 * r, -0.2 * r), r * 0.45, cor)
			alvo.draw_colored_polygon(PackedVector2Array([Vector2(-0.78 * r, -0.05 * r), Vector2(0.78 * r, -0.05 * r),
				Vector2(0, 0.8 * r)]), cor)
			alvo.draw_circle(Vector2(-0.4 * r, -0.35 * r), r * 0.12, Color(1, 1, 1, 0.4))
	if quebrado:
		alvo.draw_polyline(PackedVector2Array([Vector2(-0.1 * r, -0.7 * r), Vector2(0.1 * r, -0.2 * r),
			Vector2(-0.15 * r, 0.15 * r), Vector2(0.1 * r, 0.7 * r)]), Color("#1A0E08"), r * 0.1)
	elif defeito:
		for k in 3:  # fumacinha de queimado
			alvo.draw_circle(Vector2((k - 1) * 0.3 * r, -0.95 * r - k * 0.12 * r), r * 0.14, Color(0.4, 0.4, 0.4, 0.55))


# --- Montagem ----------------------------------------------------------------------

func _montar() -> void:
	_fundo = Control.new()
	_fundo.set_anchors_preset(PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.draw.connect(_desenhar_fundo)
	add_child(_fundo)
	_esteira = Control.new()
	_esteira.set_anchors_preset(PRESET_FULL_RECT)
	_esteira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_esteira.draw.connect(_desenhar_esteira)
	add_child(_esteira)
	# caixa do pedido (no fim da esteira, à direita, em cima)
	_caixa = Control.new()
	_caixa.name = "Caixa"
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caixa.draw.connect(func():
		_caixa.draw_rect(Rect2(-70, -40, 140, 90), Color("#C98A5A"))
		_caixa.draw_rect(Rect2(-70, -40, 140, 18), Color("#E0A870"))
		_caixa.draw_rect(Rect2(-12, -40, 24, 90), Color("#E8364F"))
		_caixa.draw_rect(Rect2(-70, -2, 140, 14), Color("#E8364F")))
	add_child(_caixa)
	# topo: voltar, título, tempo e pedido
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_TOP_WIDE)
	for lado in ["left", "right", "top"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 10)
	margem.add_child(coluna)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)
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
	titulo.add_theme_font_size_override("font_size", 36)
	titulo.text = "FÁBRICA DE CHOCOLATE"
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	_rotulo_pedidos = _rotulo_contorno(34)
	topo.add_child(_rotulo_pedidos)
	_rotulo_tempo = _rotulo_contorno(44)
	_rotulo_tempo.custom_minimum_size = Vector2(110, 0)
	_rotulo_tempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	topo.add_child(_rotulo_tempo)
	_barra_tempo = ProgressBar.new()
	_barra_tempo.theme_type_variation = &"BarraClara"
	_barra_tempo.show_percentage = false
	_barra_tempo.custom_minimum_size = Vector2(0, 12)
	_barra_tempo.max_value = Fabrica.TEMPO_INICIAL
	_barra_tempo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_barra_tempo)
	# o pedido, num cartão no meio
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(centro)
	var cartao := PanelContainer.new()
	cartao.theme_type_variation = &"PainelRoxo"
	cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(cartao)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 18)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(linha)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 32)
	rotulo.text = "PEDIDO:"
	linha.add_child(rotulo)
	_pedido_caixa = HBoxContainer.new()
	_pedido_caixa.name = "Pedido"
	_pedido_caixa.add_theme_constant_override("separation", 22)
	_pedido_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(_pedido_caixa)


func _rotulo_contorno(tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	rotulo.add_theme_constant_override("outline_size", 10)
	rotulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rotulo


func _y_esteira() -> float:
	return get_viewport_rect().size.y * ESTEIRA_Y


func _x_esteira(fracao: float) -> float:
	var largura := get_viewport_rect().size.x
	return lerpf(60.0, largura - 220.0, fracao)


## Parede de tijolos de chocolate, canos e janelas redondas.
func _desenhar_fundo() -> void:
	var tela := get_viewport_rect().size
	_fundo.draw_rect(Rect2(Vector2.ZERO, tela), Color("#7A4A2E"))
	var tijolo := Color("#8C5836")
	for linha in int(tela.y / 38.0) + 1:
		var y := linha * 38.0
		var desvio := 0.0 if linha % 2 == 0 else 50.0
		var x := -desvio
		while x < tela.x:
			_fundo.draw_rect(Rect2(x + 3, y + 3, 94, 32), tijolo)
			x += 100.0
	for jx in [0.2, 0.5, 0.8]:  # janelas redondas com luz
		var c := Vector2(tela.x * jx, tela.y * 0.36)
		_fundo.draw_circle(c, 46, Color("#4A2A18"))
		_fundo.draw_circle(c, 38, Color("#FFE6A8"))
		_fundo.draw_line(c - Vector2(38, 0), c + Vector2(38, 0), Color("#4A2A18"), 6)
		_fundo.draw_line(c - Vector2(0, 38), c + Vector2(0, 38), Color("#4A2A18"), 6)
	# cano que despeja chocolate no começo da esteira
	var y := _y_esteira()
	_fundo.draw_rect(Rect2(20, y - 250, 70, 150), Color("#B8BEC8"))
	_fundo.draw_rect(Rect2(20, y - 250, 70, 14), Color("#DDE2EA"))
	_fundo.draw_rect(Rect2(40, y - 100, 30, 50), Color("#5A2E17"))
	_fundo.draw_rect(Rect2(0, y + 60, tela.x, tela.y), Color("#4A2A18"))  # chão


## Esteira: faixa escura com listras andando e roletes nas pontas.
func _desenhar_esteira() -> void:
	var y := _y_esteira()
	var inicio := _x_esteira(0.0) - 40.0
	var fim := _x_esteira(1.0) + 40.0
	_esteira.draw_rect(Rect2(inicio, y + RAIO * 0.7, fim - inicio, 34), Color("#3A3A48"))
	var x := inicio + fmod(_faixas, 40.0)
	while x < fim - 10:
		_esteira.draw_rect(Rect2(x, y + RAIO * 0.7 + 4, 18, 26), Color("#50505F"))
		x += 40.0
	for px in [inicio, fim]:
		_esteira.draw_circle(Vector2(px, y + RAIO * 0.7 + 17), 20, Color("#9AA0AE"))
		_esteira.draw_circle(Vector2(px, y + RAIO * 0.7 + 17), 7, Color("#5A5F6E"))
	for px in range(int(inicio) + 80, int(fim), 160):  # pernas
		_esteira.draw_rect(Rect2(px, y + RAIO * 0.7 + 34, 14, 60), Color("#5A5F6E"))


# --- Partida ----------------------------------------------------------------------

func comecar() -> void:
	_fechar_painel()
	if not Confeitaria.gastar_acucar(Fabrica.CUSTO_ACUCAR):
		_sem_acucar()
		return
	for no in _nos.values():
		no.queue_free()
	_nos.clear()
	jogo = Fabrica.new()
	_jogando = true
	_caixa.position = Vector2(get_viewport_rect().size.x - 110, _y_esteira() - 10)
	_montar_pedido()
	_atualizar_placar()


func _process(delta: float) -> void:
	if not _jogando or jogo == null or jogo.acabou:
		return
	var caidos := jogo.avancar(delta)
	_faixas += delta * jogo.velocidade() * 900.0
	_esteira.queue_redraw()
	for id in caidos:
		if _nos.has(id):
			var no: Node2D = _nos[id]
			_nos.erase(id)
			var tween := no.create_tween().set_parallel()
			tween.tween_property(no, "position", no.position + Vector2(60, 260), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(no, "rotation", 2.0, 0.5)
			tween.chain().tween_callback(no.queue_free)
	for item in jogo.esteira:
		if not _nos.has(item["id"]):
			_nos[item["id"]] = _criar_chocolate(item)
		_nos[item["id"]].position = Vector2(_x_esteira(item["x"]), _y_esteira())
	_atualizar_placar()
	if jogo.acabou:
		_terminar()


func _criar_chocolate(item: Dictionary) -> Node2D:
	var no := Node2D.new()
	no.name = "Chocolate"
	var quebrado: bool = item["defeito"] and int(item["id"]) % 2 == 0
	no.draw.connect(func(): desenhar_chocolate(no, item["tipo"], RAIO, item["defeito"], quebrado))
	no.scale = Vector2.ONE * 0.2
	no.create_tween().tween_property(no, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	add_child(no)
	move_child(no, _caixa.get_index())
	return no


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		tocar_em(evento.position)


## Toque na tela: pega o chocolate mais perto do dedo (se houver).
func tocar_em(ponto: Vector2) -> void:
	if not _jogando or jogo.acabou or jogo.pergunta_pendente or is_instance_valid(_painel):
		return
	var melhor := -1
	var distancia := RAIO * 1.5
	for id in _nos:
		var d: float = _nos[id].position.distance_to(ponto)
		if d < distancia:
			distancia = d
			melhor = id
	if melhor >= 0:
		tocar(melhor)


func tocar(id: int) -> void:
	var r := jogo.tocar(id)
	if r.is_empty():
		return
	var no: Node2D = _nos[id]
	_nos.erase(id)
	if r["certo"]:
		Audio.tocar("moeda", 1.0 + randf() * 0.2)
		var tween := no.create_tween().set_parallel()
		tween.tween_property(no, "position", _caixa.position + Vector2(0, -20), 0.35).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(no, "scale", Vector2.ONE * 0.5, 0.35)
		tween.chain().tween_callback(no.queue_free)
		_faiscas(no.position, Color("#FFE27A"))
	else:
		Audio.tocar("erro")
		_texto_voando("-%d s  %s" % [int(Fabrica.TEMPO_ERRO), "QUEIMADO!" if r["motivo"] == "defeito" else "NÃO ESTÁ NO PEDIDO!"],
			no.position, Cores.VERMELHO)
		var tween := no.create_tween().set_parallel()
		tween.tween_property(no, "modulate:a", 0.0, 0.3)
		tween.tween_property(no, "scale", Vector2.ONE * 1.4, 0.3)
		tween.chain().tween_callback(no.queue_free)
		_tremer()
	if r["pedido_completo"]:
		Audio.tocar("vitoria" if r["especial"] else "caixa")
		_texto_voando("PEDIDO PRONTO! +%d s" % int(Fabrica.TEMPO_POR_PEDIDO), _caixa.position + Vector2(-60, -80), Cores.AMARELO)
		var pulo := _caixa.create_tween()
		pulo.tween_property(_caixa, "scale", Vector2(1.2, 0.85), 0.1)
		pulo.tween_property(_caixa, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
		if r["especial"]:
			await get_tree().create_timer(0.4).timeout
			_perguntar()
	_montar_pedido()
	_atualizar_placar()
	if jogo.acabou:
		_terminar()


func _montar_pedido() -> void:
	for filho in _pedido_caixa.get_children():
		filho.queue_free()
	for tipo in jogo.pedido:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		var icone := Control.new()
		icone.custom_minimum_size = Vector2(56, 56)
		icone.draw.connect(func():
			icone.draw_set_transform(Vector2(28, 28))
			desenhar_chocolate(icone, tipo, 22.0))
		item.add_child(icone)
		var rotulo := Label.new()
		rotulo.theme_type_variation = &"TituloClaro"
		rotulo.add_theme_font_size_override("font_size", 34)
		var falta := int(jogo.pedido[tipo])
		rotulo.text = "x%d" % falta if falta > 0 else "OK"
		rotulo.add_theme_color_override("font_color", Color.WHITE if falta > 0 else Cores.AMARELO)
		item.add_child(rotulo)
		_pedido_caixa.add_child(item)


func _atualizar_placar() -> void:
	if jogo == null:
		_rotulo_tempo.text = ""
		_rotulo_pedidos.text = "RECORDE: %d PEDIDOS" % Fabrica.recorde()
		return
	_rotulo_tempo.text = "%d s" % ceili(jogo.tempo)
	_rotulo_tempo.add_theme_color_override("font_color", Cores.VERMELHO if jogo.tempo < 10 else Color.WHITE)
	_rotulo_pedidos.text = "%d PEDIDOS" % jogo.pedidos_feitos
	_barra_tempo.max_value = maxf(Fabrica.TEMPO_INICIAL, jogo.tempo)
	_barra_tempo.value = jogo.tempo


func _faiscas(ponto: Vector2, cor: Color) -> void:
	var faiscas := CPUParticles2D.new()
	faiscas.texture = BRILHO
	faiscas.amount = 10
	faiscas.lifetime = 0.5
	faiscas.one_shot = true
	faiscas.explosiveness = 1.0
	faiscas.spread = 180.0
	faiscas.initial_velocity_min = 100.0
	faiscas.initial_velocity_max = 220.0
	faiscas.gravity = Vector2(0, 250)
	faiscas.scale_amount_min = 0.4
	faiscas.scale_amount_max = 0.9
	faiscas.color = cor
	faiscas.position = ponto
	faiscas.emitting = true
	add_child(faiscas)
	faiscas.finished.connect(faiscas.queue_free)


func _texto_voando(texto: String, ponto: Vector2, cor: Color) -> void:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 34)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	rotulo.add_theme_constant_override("outline_size", 10)
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rotulo)
	rotulo.position = ponto - Vector2(rotulo.get_minimum_size().x / 2, 90)
	var tween := rotulo.create_tween()
	tween.tween_property(rotulo, "position:y", rotulo.position.y - 60, 0.8)
	tween.parallel().tween_property(rotulo, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.tween_callback(rotulo.queue_free)


func _tremer() -> void:
	var tween := create_tween()
	for i in 4:
		tween.tween_property(self, "position", Vector2(randf_range(-8, 8), randf_range(-5, 5)), 0.04)
	tween.tween_property(self, "position", Vector2.ZERO, 0.04)


# --- Pedido especial (pergunta do quiz) --------------------------------------------------

func _perguntar() -> void:
	var pergunta := Torre.sortear_pergunta()
	if pergunta.is_empty():
		jogo.responder(false)
		return
	var coluna := _abrir_painel("PEDIDO ESPECIAL!")
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
	var meio := get_viewport_rect().size / 2
	if acertou:
		Audio.tocar("acerto")
		_texto_voando("ACERTOU! +%d s" % int(Fabrica.TEMPO_PERGUNTA), meio, Cores.AMARELO)
	else:
		Audio.tocar("erro")
		_texto_voando("QUE PENA!", meio, Color.WHITE)
	_atualizar_placar()


# --- Início e fim ------------------------------------------------------------------------

func mostrar_inicio() -> void:
	_atualizar_placar()
	var coluna := _abrir_painel("FÁBRICA DE CHOCOLATE")
	_texto_painel(coluna, "Toque nos chocolates do PEDIDO que passam na esteira.\nOs queimados e quebrados NÃO! Errar tira %d segundos.\nPedido pronto dá mais tempo; a cada 3, uma pergunta do quiz." % int(Fabrica.TEMPO_ERRO), 22)
	_texto_painel(coluna, "RECORDE: %d PEDIDOS" % Fabrica.recorde(), 30)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR", &"BotaoSecundario", Telas.voltar))
	botoes.add_child(_botao("Jogar", "JOGAR (%d AÇÚCAR)" % Fabrica.CUSTO_ACUCAR, &"", comecar))


func _terminar() -> void:
	if not _jogando:
		return
	_jogando = false
	var premio := Fabrica.concluir(jogo)
	await get_tree().create_timer(0.6).timeout
	var coluna := _abrir_painel("FIM DO TURNO!")
	_texto_painel(coluna, "%d PEDIDOS" % jogo.pedidos_feitos, 56)
	if premio["recorde_novo"]:
		_texto_painel(coluna, "NOVO RECORDE!", 32).add_theme_color_override("font_color", Cores.AMARELO)
	_texto_painel(coluna, "+%d MOEDAS · %d PONTOS%s" % [premio["moedas"], jogo.pontos,
		"  ·  +1 BAÚ DE DOCE!" if premio["bau"] != "" else ""], 26)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR", &"BotaoSecundario", Telas.voltar))
	botoes.add_child(_botao("DeNovo", "DE NOVO (%d AÇÚCAR)" % Fabrica.CUSTO_ACUCAR, &"", comecar))
	if premio["recorde_novo"] or premio["bau"] != "":
		Audio.tocar("vitoria")


func _sem_acucar() -> void:
	var coluna := _abrir_painel("SEM AÇÚCAR!")
	_texto_painel(coluna, "Cada turno na fábrica custa %d de açúcar. Você tem %d.\nCada acerto no quiz dá %d!" % [
		Fabrica.CUSTO_ACUCAR, Confeitaria.acucar(), Confeitaria.ACUCAR_POR_ACERTO], 24)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR", &"BotaoSecundario", Telas.voltar))
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
		botao.theme_type_variation = &"BotaoComprar"  # o JOGAR (gasta açúcar) em menta
	return botao
