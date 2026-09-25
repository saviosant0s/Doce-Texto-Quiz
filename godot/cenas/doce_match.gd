extends Control
## Doce Match: jogo de combinar 3 (no Fliperama da Vila dos Doces). Arraste
## uma peça para a vizinha (ou toque numa e depois na vizinha) para trocar;
## filas de 3 ou mais somem. Regras em scripts/doce_match.gd; aqui só o
## desenho e as animações.

const TEXTURAS := {
	"folha": preload("res://assets/doce_match/folha.svg"),
	"planilha": preload("res://assets/doce_match/planilha.svg"),
	"grafico": preload("res://assets/doce_match/grafico.svg"),
	"celula": preload("res://assets/doce_match/celula.svg"),
	"tecla": preload("res://assets/doce_match/tecla.svg"),
	"disquete": preload("res://assets/doce_match/disquete.svg"),
}
const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const TAMANHO := 76.0  # lado de cada casa do tabuleiro, em pixels
const ARRASTO_MINIMO := 24.0
const ESPERA_DICA := 6.0

var jogo: DoceMatch
var _pecas: Array = []  # [y][x] -> TextureRect (ou null)
var _tabuleiro: Control
var _ocupado := false
var _selecionada := Vector2i(-1, -1)
var _toque_inicio := Vector2.ZERO
var _toque_casa := Vector2i(-1, -1)
var _parado_ha := 0.0
var _rotulo_pontos: Label
var _rotulo_jogadas: Label
var _rotulo_recorde: Label
var _barra: ProgressBar
var _estrelas: Array[TextureRect] = []
var _fim: Control


func _ready() -> void:
	jogo = DoceMatch.new()
	_montar_tela()
	_comecar()


## Nova partida: paga o açúcar e monta o tabuleiro; sem açúcar, mostra o
## aviso com o atalho para o quiz.
func _comecar() -> void:
	if is_instance_valid(_fim):
		_fim.queue_free()
	if not Confeitaria.gastar_acucar(DoceMatch.CUSTO_ACUCAR):
		jogo.jogadas = 0
		_criar_pecas()
		_atualizar_placar()
		_mostrar_sem_acucar()
		return
	jogo = DoceMatch.new()
	_criar_pecas()
	_atualizar_placar()


## Botão "voltar" do celular.
func ao_voltar() -> void:
	Telas.voltar()


func _process(delta: float) -> void:
	if _ocupado or jogo.acabou():
		return
	_parado_ha += delta
	if _parado_ha > ESPERA_DICA:
		_parado_ha = 0.0
		var dica := jogo.jogada_possivel()
		for p in dica:
			_pulinho(_pecas[p.y][p.x])


# --- Toques ------------------------------------------------------------------------

func _casa_em(ponto: Vector2) -> Vector2i:
	return Vector2i(floori(ponto.x / TAMANHO), floori(ponto.y / TAMANHO))


func _toque_no_tabuleiro(evento: InputEvent) -> void:
	if _ocupado or jogo.acabou():
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_toque_inicio = evento.position
			_toque_casa = _casa_em(evento.position)
		elif _toque_casa != Vector2i(-1, -1):
			# soltou sem arrastar: toque para escolher (ou trocar com a escolhida)
			var casa := _toque_casa
			_toque_casa = Vector2i(-1, -1)
			if not jogo.dentro(casa):
				return
			if _selecionada != Vector2i(-1, -1) and jogo.vizinhas(_selecionada, casa):
				var a := _selecionada
				_marcar(Vector2i(-1, -1))
				jogar(a, casa)
			else:
				_marcar(casa if casa != _selecionada else Vector2i(-1, -1))
	elif evento is InputEventMouseMotion and _toque_casa != Vector2i(-1, -1):
		var arrasto: Vector2 = evento.position - _toque_inicio
		if arrasto.length() >= ARRASTO_MINIMO:
			var direcao := Vector2i(signi(roundi(arrasto.x)), 0) if absf(arrasto.x) > absf(arrasto.y) \
				else Vector2i(0, signi(roundi(arrasto.y)))
			var a := _toque_casa
			_toque_casa = Vector2i(-1, -1)
			_marcar(Vector2i(-1, -1))
			if jogo.dentro(a) and jogo.dentro(a + direcao):
				jogar(a, a + direcao)


func _marcar(casa: Vector2i) -> void:
	if _selecionada != Vector2i(-1, -1):
		var antiga: Control = _pecas[_selecionada.y][_selecionada.x]
		if antiga:
			antiga.create_tween().tween_property(antiga, "scale", Vector2.ONE, 0.1)
	_selecionada = casa
	if casa != Vector2i(-1, -1):
		var peca: Control = _pecas[casa.y][casa.x]
		peca.create_tween().tween_property(peca, "scale", Vector2.ONE * 1.15, 0.1)


# --- Jogada e cascata ------------------------------------------------------------------

## Troca `a` e `b` com animação; se valer, resolve a cascata toda.
func jogar(a: Vector2i, b: Vector2i) -> void:
	if _ocupado:
		return
	_ocupado = true
	_parado_ha = 0.0
	var pa: Control = _pecas[a.y][a.x]
	var pb: Control = _pecas[b.y][b.x]
	await _animar_troca(pa, pb, a, b)
	if not jogo.trocar(a, b):
		Audio.tocar("erro")
		await _animar_troca(pa, pb, b, a)  # volta
		_ocupado = false
		return
	_pecas[a.y][a.x] = pb
	_pecas[b.y][b.x] = pa
	var combo := 1
	while true:
		var passo := jogo.passo(combo)
		if passo.is_empty():
			break
		await _animar_passo(passo)
		combo += 1
	if jogo.jogada_possivel().is_empty():
		jogo.embaralhar()
		Telas.mostrar_aviso("SEM JOGADAS: EMBARALHANDO!")
		_criar_pecas()
	_atualizar_placar()
	_ocupado = false
	if jogo.acabou():
		_mostrar_fim()


func _animar_troca(pa: Control, pb: Control, a: Vector2i, b: Vector2i) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(pa, "position", _posicao(b), 0.14)
	tween.tween_property(pb, "position", _posicao(a), 0.14)
	await tween.finished


func _animar_passo(passo: Dictionary) -> void:
	Audio.tocar("estouro", 0.9 + 0.15 * (passo["combo"] - 1))  # combo: cada vez mais agudo
	# somem
	var centro := Vector2.ZERO
	for p: Vector2i in passo["somem"]:
		var peca: Control = _pecas[p.y][p.x]
		_pecas[p.y][p.x] = null
		centro += _posicao(p)
		var tween := peca.create_tween().set_parallel()
		tween.tween_property(peca, "scale", Vector2.ONE * 0.1, 0.16)
		tween.tween_property(peca, "modulate:a", 0.0, 0.16)
		tween.chain().tween_callback(peca.queue_free)
	centro /= maxf(1.0, passo["somem"].size())
	var texto := "+%d" % passo["ganho"]
	if passo["combo"] > 1:
		texto = "COMBO x%d!  %s" % [passo["combo"], texto]
	_mostrar_ganho(texto, centro + Vector2(TAMANHO / 2, TAMANHO / 2))
	_atualizar_placar()
	await get_tree().create_timer(0.17).timeout
	# caem (na mesma ordem em que a regra moveu)
	var tween := create_tween().set_parallel()
	var algum := false
	for movimento in passo["caem"]:
		var de: Vector2i = movimento[0]
		var para: Vector2i = movimento[1]
		var peca: Control = _pecas[de.y][de.x]
		_pecas[para.y][para.x] = peca
		_pecas[de.y][de.x] = null
		tween.tween_property(peca, "position", _posicao(para), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		algum = true
	# novas entram por cima
	var por_coluna := {}
	for nova in passo["novas"]:
		var p: Vector2i = nova[0]
		por_coluna[p.x] = por_coluna.get(p.x, 0) + 1
		var peca := _criar_peca(p, nova[1])
		peca.position = _posicao(Vector2i(p.x, p.y - _altura_entrada(p, passo)))
		tween.tween_property(peca, "position", _posicao(p), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		algum = true
	if algum:
		await tween.finished
	else:
		tween.kill()


## Quantas casas acima do tabuleiro a peça nova começa (as de cima mais alto).
func _altura_entrada(p: Vector2i, passo: Dictionary) -> int:
	var novas_na_coluna := 0
	for nova in passo["novas"]:
		if nova[0].x == p.x:
			novas_na_coluna += 1
	return novas_na_coluna


func _mostrar_ganho(texto: String, ponto: Vector2) -> void:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 40)
	rotulo.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	rotulo.add_theme_constant_override("outline_size", 10)
	rotulo.text = texto
	rotulo.z_index = 10
	_tabuleiro.add_child(rotulo)
	rotulo.position = ponto - rotulo.get_minimum_size() / 2
	var tween := rotulo.create_tween()
	tween.tween_property(rotulo, "position:y", rotulo.position.y - 60, 0.7)
	tween.parallel().tween_property(rotulo, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(rotulo.queue_free)


func _pulinho(peca: Control) -> void:
	if peca == null:
		return
	var tween := peca.create_tween()
	tween.tween_property(peca, "scale", Vector2.ONE * 1.2, 0.15)
	tween.tween_property(peca, "scale", Vector2.ONE, 0.15)
	tween.tween_property(peca, "scale", Vector2.ONE * 1.2, 0.15)
	tween.tween_property(peca, "scale", Vector2.ONE, 0.15)


# --- Fim da partida ----------------------------------------------------------------------

func _mostrar_fim() -> void:
	var estrelas := jogo.estrelas()
	var moedas := jogo.moedas()
	var recorde: int = Progresso.estatisticas.get("match_recorde", 0)
	var novo_recorde := jogo.pontos > recorde
	Progresso.estatisticas["match_recorde"] = maxi(recorde, jogo.pontos)
	Progresso.estatisticas["match_partidas"] = int(Progresso.estatisticas.get("match_partidas", 0)) + 1
	Progresso.ganhar_moedas(moedas)  # também salva
	Audio.tocar("construir" if estrelas > 0 else "moeda")
	var painel := _painel_central()
	_fim = painel.get_parent().get_parent()
	var coluna: VBoxContainer = painel.get_child(0)
	var titulo := Label.new()
	titulo.theme_type_variation = &"TituloClaro"
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.text = "FIM DE JOGO!" if estrelas == 0 else "MUITO BEM!"
	coluna.add_child(titulo)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var estrela := TextureRect.new()
		estrela.texture = ICONE_ESTRELA
		estrela.custom_minimum_size = Vector2(70, 70)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrela.modulate = Cores.OURO if i < estrelas else Color(1, 1, 1, 0.25)
		linha.add_child(estrela)
	coluna.add_child(linha)
	var resumo := Label.new()
	resumo.theme_type_variation = &"SubtituloClaro"
	resumo.add_theme_font_size_override("font_size", 32)
	resumo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resumo.text = "%s PONTOS%s\n+%d MOEDAS" % [Jogo.formatar(jogo.pontos), "  ·  NOVO RECORDE!" if novo_recorde else "", moedas]
	coluna.add_child(resumo)
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	var sair := Button.new()
	sair.name = "Sair"
	sair.theme_type_variation = &"BotaoRoxo"
	sair.text = "SAIR"
	sair.custom_minimum_size = Vector2(220, 70)
	sair.pressed.connect(Telas.voltar)
	botoes.add_child(sair)
	var denovo := Button.new()
	denovo.name = "JogarDeNovo"
	denovo.text = "DE NOVO (%d AÇÚCAR)" % DoceMatch.CUSTO_ACUCAR
	denovo.custom_minimum_size = Vector2(300, 70)
	denovo.pressed.connect(recomecar)
	botoes.add_child(denovo)
	_abrir_painel(painel)


func recomecar() -> void:
	_comecar()


## Sem açúcar para jogar: explica e leva ao quiz.
func _mostrar_sem_acucar() -> void:
	var painel := _painel_central()
	_fim = painel.get_parent().get_parent()
	var coluna: VBoxContainer = painel.get_child(0)
	_rotulo_central(coluna, "SEM AÇÚCAR!", 60)
	_rotulo_central(coluna, "Cada partida do Doce Match custa %d de açúcar.\nVocê tem %d. Cada acerto no quiz dá %d!" % [
		DoceMatch.CUSTO_ACUCAR, Confeitaria.acucar(), Confeitaria.ACUCAR_POR_ACERTO], 26)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	var sair := Button.new()
	sair.name = "Sair"
	sair.theme_type_variation = &"BotaoRoxo"
	sair.text = "SAIR"
	sair.custom_minimum_size = Vector2(200, 70)
	sair.pressed.connect(Telas.voltar)
	botoes.add_child(sair)
	var quiz := Button.new()
	quiz.name = "JogarQuiz"
	quiz.text = "JOGAR O QUIZ"
	quiz.custom_minimum_size = Vector2(300, 70)
	quiz.pressed.connect(Telas.abrir.bind("niveis"))
	botoes.add_child(quiz)
	_abrir_painel(painel)


## Painel no meio da tela, com o fundo escurecido (o nó "Fim" é a camada toda).
func _painel_central() -> PanelContainer:
	var camada := Control.new()
	camada.name = "Fim"
	camada.set_anchors_preset(PRESET_FULL_RECT)
	add_child(camada)
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
	return painel


func _rotulo_central(pai: Control, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 40 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.text = texto
	pai.add_child(rotulo)
	return rotulo


func _abrir_painel(painel: Control) -> void:
	await get_tree().process_frame  # espera o CenterContainer posicionar
	if not is_instance_valid(painel):
		return
	painel.pivot_offset = painel.size / 2
	painel.scale = Vector2.ONE * 0.6
	painel.create_tween().tween_property(painel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Montagem ----------------------------------------------------------------------------

func _posicao(p: Vector2i) -> Vector2:
	return Vector2(p.x * TAMANHO, p.y * TAMANHO)


func _criar_peca(p: Vector2i, tipo: int) -> TextureRect:
	var peca := TextureRect.new()
	peca.texture = TEXTURAS[DoceMatch.TIPOS[tipo]]
	peca.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	peca.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	peca.size = Vector2(TAMANHO, TAMANHO)
	peca.pivot_offset = peca.size / 2
	peca.position = _posicao(p)
	peca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tabuleiro.add_child(peca)
	_pecas[p.y][p.x] = peca
	return peca


func _criar_pecas() -> void:
	for filho in _tabuleiro.get_children():
		filho.queue_free()
	_pecas.clear()
	for y in DoceMatch.ALTURA:
		var linha := []
		linha.resize(DoceMatch.LARGURA)
		_pecas.append(linha)
	for y in DoceMatch.ALTURA:
		for x in DoceMatch.LARGURA:
			var peca := _criar_peca(Vector2i(x, y), jogo.grade[y][x])
			peca.scale = Vector2.ONE * 0.2
			peca.create_tween().tween_property(peca, "scale", Vector2.ONE, 0.2).set_delay(0.02 * (x + y))


func _atualizar_placar() -> void:
	_rotulo_pontos.text = Jogo.formatar(jogo.pontos)
	_rotulo_jogadas.text = "%d" % jogo.jogadas
	_rotulo_recorde.text = "RECORDE: %s   ·   AÇÚCAR: %d" % [Jogo.formatar(maxi(Progresso.estatisticas.get("match_recorde", 0), jogo.pontos)), Confeitaria.acucar()]
	var meta: int = DoceMatch.METAS[mini(jogo.estrelas(), DoceMatch.METAS.size() - 1)]
	_barra.max_value = DoceMatch.METAS[-1]
	_barra.value = jogo.pontos
	for i in _estrelas.size():
		_estrelas[i].modulate = Cores.OURO if jogo.pontos >= DoceMatch.METAS[i] else Color(1, 1, 1, 0.3)
	_barra.tooltip_text = "Próxima estrela: %d pontos" % meta


func _montar_tela() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 28)
	add_child(margem)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 28)
	margem.add_child(linha)
	# lado esquerdo: título e placar
	var esquerda := VBoxContainer.new()
	esquerda.custom_minimum_size = Vector2(360, 0)
	esquerda.add_theme_constant_override("separation", 16)
	linha.add_child(esquerda)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	esquerda.add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(72, 72)
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
	titulo.text = "DOCE MATCH"
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelEscuro"
	painel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esquerda.add_child(painel)
	var placar := VBoxContainer.new()
	placar.alignment = BoxContainer.ALIGNMENT_CENTER
	placar.add_theme_constant_override("separation", 6)
	painel.add_child(placar)
	_rotulo_pontos = _item_placar(placar, "PONTOS", 72)
	_rotulo_jogadas = _item_placar(placar, "JOGADAS", 56)
	var estrelas := HBoxContainer.new()
	estrelas.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var estrela := TextureRect.new()
		estrela.texture = ICONE_ESTRELA
		estrela.custom_minimum_size = Vector2(48, 48)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrelas.add_child(estrela)
		_estrelas.append(estrela)
	placar.add_child(estrelas)
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(0, 22)
	placar.add_child(_barra)
	_rotulo_recorde = Label.new()
	_rotulo_recorde.theme_type_variation = &"TextoClaro"
	_rotulo_recorde.add_theme_font_size_override("font_size", 22)
	_rotulo_recorde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placar.add_child(_rotulo_recorde)
	var ajuda := Label.new()
	ajuda.theme_type_variation = &"TextoClaro"
	ajuda.add_theme_font_size_override("font_size", 17)
	ajuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ajuda.text = "Arraste uma peça para a vizinha e forme filas de 3 ou mais iguais! Cada partida: %d de açúcar." % DoceMatch.CUSTO_ACUCAR
	placar.add_child(ajuda)
	# lado direito: o tabuleiro
	var moldura := PanelContainer.new()
	moldura.theme_type_variation = &"PainelRoxo"
	moldura.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	moldura.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(moldura)
	_tabuleiro = Control.new()
	_tabuleiro.name = "Tabuleiro"
	_tabuleiro.custom_minimum_size = Vector2(DoceMatch.LARGURA, DoceMatch.ALTURA) * TAMANHO
	_tabuleiro.clip_contents = true
	_tabuleiro.mouse_filter = Control.MOUSE_FILTER_STOP
	_tabuleiro.gui_input.connect(_toque_no_tabuleiro)
	moldura.add_child(_tabuleiro)


func _item_placar(pai: Control, nome: String, tamanho: int) -> Label:
	var titulo := Label.new()
	titulo.theme_type_variation = &"SubtituloClaro"
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.text = nome
	pai.add_child(titulo)
	var valor := Label.new()
	valor.theme_type_variation = &"TituloClaro"
	valor.add_theme_font_size_override("font_size", tamanho)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pai.add_child(valor)
	return valor
