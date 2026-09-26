extends Control
## Doce Match: jogo de combinar 3 (no Fliperama da Vila dos Doces), com
## NÍVEIS como no Candy Crush. Primeiro aparece o mapa dos níveis; tocando num
## nível liberado, o jogador vê o objetivo e paga o açúcar para tentar.
##
## No tabuleiro: arraste uma peça para a vizinha (ou toque numa e depois na
## vizinha) para trocar. Filas de 4, L/T e 5 viram peças especiais que
## explodem linhas, colunas, as casas em volta ou todas as peças de um tipo.
## Regras em scripts/doce_match.gd; aqui só o desenho e as animações.

const TEXTURAS := {
	"folha": preload("res://assets/doce_match/folha.svg"),
	"planilha": preload("res://assets/doce_match/planilha.svg"),
	"grafico": preload("res://assets/doce_match/grafico.svg"),
	"celula": preload("res://assets/doce_match/celula.svg"),
	"tecla": preload("res://assets/doce_match/tecla.svg"),
	"disquete": preload("res://assets/doce_match/disquete.svg"),
}
const CORES_TIPOS := {
	"folha": Color("#4F8DF5"), "planilha": Color("#2FC46A"), "grafico": Color("#FFB23E"),
	"celula": Color("#A87DFA"), "tecla": Color("#F25CAB"), "disquete": Color("#2CCFBC"),
}
const LISTRAS := preload("res://assets/doce_match/listras.svg")
const EMBRULHO := preload("res://assets/doce_match/embrulho.svg")
const BOMBA := preload("res://assets/doce_match/bomba.svg")
const BRILHO := preload("res://assets/doce_match/brilho.svg")
const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")
const ICONE_ESTRELA := Itens.ESTRELA
const COR_GELATINA := Color("#FF6FB5")
const TAMANHO := 76.0  # lado de cada casa do tabuleiro, em pixels
const MARGEM_PECA := 5.0  # a peça é menor que a casa (a gelatina aparece em volta)
const ARRASTO_MINIMO := 24.0
const ESPERA_DICA := 6.0
const PASSO_MAPA := 150.0
const ALTURA_MAPA := 560.0
const PALAVRAS_COMBO := ["", "", "DOCE!", "DELICIOSO!", "INCRÍVEL!", "DIVINO!"]

## Nível que acabou de ser vencido (o mapa anima o próximo ao voltar).
static var recem_vencido := 0

var jogo: DoceMatch
var numero_nivel := 0
var _pecas: Array = []  # [y][x] -> TextureRect (ou null)
var _tabuleiro: Control
var _mesa: Control  # tudo o que fica dentro do tabuleiro (treme nas explosões)
var _gelatina: Control
var _efeitos: Control
var _ocupado := false
var _selecionada := Vector2i(-1, -1)
var _toque_inicio := Vector2.ZERO
var _toque_casa := Vector2i(-1, -1)
var _parado_ha := 0.0
var _rotulo_pontos: Label
var _rotulo_jogadas: Label
var _barra: ProgressBar
var _estrelas: Array[TextureRect] = []
var _objetivos: Array = []  # [{"obj", "rotulo", "icone", "certo"}]
var _camada_mapa: Control
var _camada_jogo: Control
var _camada_topo: Control  # textos de combo e peças voando até o objetivo
var _rolagem: ScrollContainer
var _botoes_nivel := {}  # número -> Button
var _rotulo_estrelas: Label
var _rotulo_acucar: Label
var _rotulo_moedas: Label
var _painel: Control
var _arrastando := false
var _arrasto_inicio := 0.0
var _rolagem_inicio := 0
var _fim_registrado := false


func _ready() -> void:
	_camada_topo = Control.new()
	_camada_topo.name = "Efeitos"
	_camada_topo.set_anchors_preset(PRESET_FULL_RECT)
	_camada_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_topo.z_index = 20
	add_child(_camada_topo)
	mostrar_mapa()
	Telas.dica_primeira_vez("doce_match", "DOCE MATCH",
		"Cada nível tem um objetivo: fazer pontos, juntar peças ou limpar a gelatina rosa. Fila de 4 vira peça LISTRADA, L ou T vira EMBRULHADA e fila de 5 vira a BOMBA de confeito!")


## Botão "voltar" do celular.
func ao_voltar() -> void:
	if is_instance_valid(_painel):
		_fechar_painel()
		return
	if is_instance_valid(_camada_jogo):
		_perguntar_sair()
		return
	Telas.voltar()


func _process(delta: float) -> void:
	if not is_instance_valid(_camada_jogo) or _ocupado or jogo.acabou() or is_instance_valid(_painel):
		return
	_parado_ha += delta
	if _parado_ha > ESPERA_DICA:
		_parado_ha = 0.0
		for p in jogo.jogada_possivel():
			_pulinho(_pecas[p.y][p.x])


# === MAPA DOS NÍVEIS =============================================================

func mostrar_mapa() -> void:
	if is_instance_valid(_camada_jogo):
		_camada_jogo.queue_free()
		_camada_jogo = null
	if is_instance_valid(_camada_mapa):
		_camada_mapa.queue_free()
	_botoes_nivel.clear()
	_camada_mapa = Control.new()
	_camada_mapa.name = "MapaNiveis"
	_camada_mapa.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_camada_mapa)
	move_child(_camada_mapa, _camada_topo.get_index())
	_montar_mapa()
	_montar_topo_mapa()
	_atualizar_contadores()
	_centralizar_mapa.call_deferred()


func _montar_topo_mapa() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_TOP_WIDE)
	for lado in ["left", "right", "top"]:
		margem.add_theme_constant_override("margin_" + lado, 28)
	_camada_mapa.add_child(margem)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	margem.add_child(topo)
	topo.add_child(_botao_voltar(Telas.voltar))
	topo.add_child(_etiqueta_titulo("DOCE MATCH"))
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(espaco)
	_rotulo_estrelas = _contador(topo, ICONE_ESTRELA)
	_rotulo_acucar = _contador(topo, Itens.ACUCAR)
	_rotulo_moedas = _contador(topo, Itens.MOEDA)


func _atualizar_contadores() -> void:
	if is_instance_valid(_rotulo_estrelas):
		_rotulo_estrelas.text = "%d/%d" % [DoceMatch.total_estrelas(), DoceMatch.niveis().size() * 3]
		_rotulo_acucar.text = str(Confeitaria.acucar())
		_rotulo_moedas.text = Jogo.formatar(Progresso.moedas)


func _altura_mapa() -> float:
	return maxf(ALTURA_MAPA, get_viewport_rect().size.y - 130.0)


## Onde fica o nível `n` (1..30) no mapa: um caminho que sobe e desce.
func _ponto_nivel(n: int) -> Vector2:
	var altura := _altura_mapa()
	var meio := altura * 0.55
	var onda := sin((n - 1) * 0.9) * (altura * 0.26)
	return Vector2(130.0 + (n - 1) * PASSO_MAPA, meio + onda)


func _montar_mapa() -> void:
	_rolagem = ScrollContainer.new()
	_rolagem.name = "Rolagem"
	_rolagem.set_anchors_preset(PRESET_FULL_RECT)
	_rolagem.offset_top = 120
	_rolagem.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_camada_mapa.add_child(_rolagem)
	var mapa := Control.new()
	mapa.name = "Caminho"
	mapa.gui_input.connect(_arrastar_mapa)
	_rolagem.add_child(mapa)
	var total := DoceMatch.niveis().size()
	mapa.custom_minimum_size = Vector2(_ponto_nivel(total).x + 150.0, _altura_mapa())
	var caminho: Array[Vector2] = []
	var feito_ate := 0
	for n in range(1, total + 1):
		caminho.append(_ponto_nivel(n))
		if DoceMatch.estrelas_do_nivel(n) > 0:
			feito_ate = n + 1
	var linha := Line2D.new()
	linha.points = caminho
	linha.width = 22
	linha.default_color = Color(1, 1, 1, 0.35)
	linha.joint_mode = Line2D.LINE_JOINT_ROUND
	linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
	linha.end_cap_mode = Line2D.LINE_CAP_ROUND
	mapa.add_child(linha)
	if feito_ate > 1:
		var feita := linha.duplicate()
		feita.points = caminho.slice(0, mini(feito_ate, total))
		feita.default_color = Cores.AMARELO
		feita.width = 14
		mapa.add_child(feita)
	for n in range(1, total + 1):
		_criar_botao_nivel(mapa, n)


func _criar_botao_nivel(mapa: Control, n: int) -> void:
	var dados := DoceMatch.dados_nivel(n)
	var liberado := DoceMatch.liberado(n)
	var atual := n == DoceMatch.proximo_nivel() and DoceMatch.estrelas_do_nivel(n) == 0
	var lado := 92.0
	var botao := Button.new()
	botao.name = "Nivel_%d" % n
	botao.focus_mode = Control.FOCUS_NONE
	botao.custom_minimum_size = Vector2(lado, lado)
	botao.size = Vector2(lado, lado)
	botao.position = _ponto_nivel(n) - botao.size / 2
	botao.pivot_offset = botao.size / 2
	var cor := Cores.ROXO
	if _tem_gelatina(dados):
		cor = Color("#D9468F")
	elif dados["objetivos"].any(func(o): return o["tipo"] == "coletar"):
		cor = Color("#2F7DD1")
	if atual:
		cor = Cores.AMARELO_ESCURO
	if not liberado:
		cor = Color("#8C8499")
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(int(lado / 2))
	estilo.set_border_width_all(6)
	estilo.border_color = Color.WHITE if liberado else Color("#D9D4E2")
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 6
	estilo.shadow_offset = Vector2(0, 5)
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		botao.add_theme_stylebox_override(estado, estilo)
	if liberado:
		botao.text = str(n)
	else:
		botao.icon = ICONE_CADEADO
		botao.expand_icon = true
		botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		botao.add_theme_constant_override("icon_max_width", int(lado * 0.5))
	botao.add_theme_font_size_override("font_size", 42)
	botao.add_theme_color_override("font_color", Color.WHITE)
	botao.pressed.connect(abrir_nivel.bind(n))
	mapa.add_child(botao)
	_botoes_nivel[n] = botao
	if liberado:
		var estrelas := HBoxContainer.new()
		estrelas.add_theme_constant_override("separation", 0)
		estrelas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 3:
			var e := TextureRect.new()
			e.texture = ICONE_ESTRELA
			e.custom_minimum_size = Vector2(28, 28)
			e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			e.modulate = Color.WHITE if i < DoceMatch.estrelas_do_nivel(n) else Itens.ESTRELA_APAGADA
			e.mouse_filter = Control.MOUSE_FILTER_IGNORE
			estrelas.add_child(e)
		estrelas.position = Vector2(lado / 2 - 42, lado + 2)
		botao.add_child(estrelas)
	# baú de prêmio nos níveis 5, 10, 15...
	var bau := DoceMatch.bau_do_nivel(n)
	if bau != "":
		var foto := TextureRect.new()
		foto.name = "Bau"
		foto.texture = Itens.bau_aberto(bau) if DoceMatch.estrelas_do_nivel(n) > 0 else Itens.bau(bau)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		foto.custom_minimum_size = Vector2(64, 56)
		foto.size = Vector2(64, 56)
		foto.position = Vector2(lado - 20, -40)
		foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(foto)
	if atual:
		_marcar_atual(botao, lado)


func _tem_gelatina(dados: Dictionary) -> bool:
	return dados["objetivos"].any(func(o): return o["tipo"] == "gelatina")


## Doce do jogador em cima do nível atual, pulando.
func _marcar_atual(botao: Control, lado: float) -> void:
	var id_doce := Colecao.companheiro()
	if id_doce == "":
		id_doce = "brigadeiro"
	var foto := TextureRect.new()
	foto.name = "Jogador"
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foto.texture = Personagens.textura(id_doce)
	foto.custom_minimum_size = Vector2(80, 80)
	foto.size = Vector2(80, 80)
	foto.position = Vector2(lado / 2 - 40, -88)
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao.add_child(foto)
	if Telas.animacoes_continuas:
		var tween := foto.create_tween().set_loops()
		tween.tween_property(foto, "position:y", -102.0, 0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_property(foto, "position:y", -88.0, 0.45).set_trans(Tween.TRANS_SINE)


func _centralizar_mapa() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_rolagem):
		return
	var alvo := DoceMatch.proximo_nivel()
	_rolagem.scroll_horizontal = int(_ponto_nivel(alvo).x - _rolagem.size.x / 2)
	if recem_vencido > 0 and _botoes_nivel.has(recem_vencido + 1) and DoceMatch.liberado(recem_vencido + 1):
		var novo: Control = _botoes_nivel[recem_vencido + 1]
		novo.scale = Vector2.ZERO
		novo.create_tween().tween_property(novo, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(0.3)
		Audio.tocar("estouro", 1.2)
	recem_vencido = 0


func _arrastar_mapa(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_arrastando = evento.pressed
		_arrasto_inicio = evento.global_position.x
		_rolagem_inicio = _rolagem.scroll_horizontal
	elif evento is InputEventMouseMotion and _arrastando:
		_rolagem.scroll_horizontal = _rolagem_inicio - int(evento.global_position.x - _arrasto_inicio)


## Toque num nível do mapa: mostra o objetivo e o botão de jogar.
func abrir_nivel(n: int) -> void:
	if not DoceMatch.liberado(n):
		Telas.mostrar_aviso("PASSE NO NÍVEL %d PRIMEIRO!" % (n - 1))
		return
	var dados := DoceMatch.dados_nivel(n)
	var painel := _painel_central()
	var coluna: VBoxContainer = painel.get_child(0)
	_rotulo(coluna, "NÍVEL %d" % n, 56)
	coluna.add_child(_linha_estrelas(DoceMatch.estrelas_do_nivel(n), 56))
	_rotulo(coluna, "OBJETIVO", 24)
	for obj in dados["objetivos"]:
		coluna.add_child(_linha_objetivo(obj, dados))
	_rotulo(coluna, "%d JOGADAS" % int(dados["jogadas"]), 24)
	if DoceMatch.estrelas_do_nivel(n) == 0:
		var premio := "PRÊMIO: %d MOEDAS" % (DoceMatch.MOEDAS_NIVEL + DoceMatch.MOEDAS_POR_ESTRELA)
		var bau := DoceMatch.bau_do_nivel(n)
		if bau != "":
			premio += " + " + Baus.NOMES[bau]
		_rotulo(coluna, premio, 22).add_theme_color_override("font_color", Cores.AMARELO)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Fechar", "VOLTAR", &"BotaoSecundario", 200, _fechar_painel))
	botoes.add_child(_botao("Jogar", "JOGAR (%d AÇÚCAR)" % DoceMatch.CUSTO_ACUCAR, &"", 330, comecar_nivel.bind(n)))
	_abrir_painel(painel)


## Uma linha do objetivo: ícone (peça, gelatina ou estrela) + texto.
func _linha_objetivo(obj: Dictionary, dados: Dictionary) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 12)
	linha.add_child(_icone_objetivo(obj, 44))
	var texto := DoceMatch.descrever(obj)
	if obj["tipo"] == "gelatina":
		texto = "LIMPE AS %d GELATINAS" % _contar_gelatina(dados)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 28)
	rotulo.text = texto
	linha.add_child(rotulo)
	return linha


func _contar_gelatina(dados: Dictionary) -> int:
	var n := 0
	for linha in dados.get("gelatina", []):
		n += str(linha).count("g")
	return n


func _icone_objetivo(obj: Dictionary, lado: float) -> Control:
	if obj["tipo"] == "gelatina":
		var quadro := Panel.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = COR_GELATINA
		estilo.set_corner_radius_all(int(lado * 0.25))
		estilo.set_border_width_all(3)
		estilo.border_color = Color("#FFD1E8")
		quadro.add_theme_stylebox_override("panel", estilo)
		quadro.custom_minimum_size = Vector2(lado, lado)
		quadro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return quadro
	var icone := TextureRect.new()
	icone.texture = TEXTURAS[obj["peca"]] if obj["tipo"] == "coletar" else ICONE_ESTRELA
	icone.custom_minimum_size = Vector2(lado, lado)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icone


# === PARTIDA ====================================================================

## Paga o açúcar e começa o nível `n`; sem açúcar, mostra o aviso.
func comecar_nivel(n: int) -> void:
	_fechar_painel()
	if not Confeitaria.gastar_acucar(DoceMatch.CUSTO_ACUCAR):
		_mostrar_sem_acucar()
		return
	numero_nivel = n
	jogo = DoceMatch.new(DoceMatch.dados_nivel(n))
	_fim_registrado = false
	_ocupado = false
	_selecionada = Vector2i(-1, -1)
	if is_instance_valid(_camada_mapa):
		_camada_mapa.queue_free()
		_camada_mapa = null
	if is_instance_valid(_camada_jogo):
		_camada_jogo.queue_free()
	_montar_tela()
	_criar_pecas()
	_atualizar_placar()
	_anunciar(DoceMatch.descrever(jogo.nivel["objetivos"][0]) if jogo.nivel["objetivos"][0]["tipo"] != "gelatina" \
		else "LIMPE A GELATINA!", 44)


func _montar_tela() -> void:
	_camada_jogo = Control.new()
	_camada_jogo.name = "Partida"
	_camada_jogo.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_camada_jogo)
	move_child(_camada_jogo, _camada_topo.get_index())
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 28)
	_camada_jogo.add_child(margem)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 28)
	margem.add_child(linha)
	# lado esquerdo: nível, jogadas, objetivos e pontos
	var esquerda := VBoxContainer.new()
	esquerda.custom_minimum_size = Vector2(360, 0)
	esquerda.add_theme_constant_override("separation", 14)
	linha.add_child(esquerda)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	esquerda.add_child(topo)
	topo.add_child(_botao_voltar(_perguntar_sair))
	topo.add_child(_etiqueta_titulo("NÍVEL %d" % numero_nivel))
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelEscuro"
	painel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esquerda.add_child(painel)
	var placar := VBoxContainer.new()
	placar.alignment = BoxContainer.ALIGNMENT_CENTER
	placar.add_theme_constant_override("separation", 8)
	painel.add_child(placar)
	_rotulo_jogadas = _item_placar(placar, "JOGADAS", 64)
	_rotulo(placar, "OBJETIVO", 22)
	_objetivos.clear()
	for obj in jogo.nivel["objetivos"]:
		var caixa := HBoxContainer.new()
		caixa.alignment = BoxContainer.ALIGNMENT_CENTER
		caixa.add_theme_constant_override("separation", 12)
		var icone := _icone_objetivo(obj, 52)
		icone.pivot_offset = Vector2(26, 26)
		caixa.add_child(icone)
		var rotulo := Label.new()
		rotulo.theme_type_variation = &"TituloClaro"
		rotulo.add_theme_font_size_override("font_size", 38)
		caixa.add_child(rotulo)
		placar.add_child(caixa)
		_objetivos.append({"obj": obj, "rotulo": rotulo, "icone": icone, "certo": false})
	_rotulo_pontos = _item_placar(placar, "PONTOS", 40)
	_barra = ProgressBar.new()
	_barra.theme_type_variation = &"BarraClara"
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(0, 20)
	placar.add_child(_barra)
	var estrelas := HBoxContainer.new()
	estrelas.alignment = BoxContainer.ALIGNMENT_CENTER
	_estrelas.clear()
	for i in 3:
		var estrela := TextureRect.new()
		estrela.texture = ICONE_ESTRELA
		estrela.custom_minimum_size = Vector2(44, 44)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrela.pivot_offset = Vector2(22, 22)
		estrelas.add_child(estrela)
		_estrelas.append(estrela)
	placar.add_child(estrelas)
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
	_mesa = Control.new()
	_mesa.name = "Mesa"
	_mesa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mesa.size = _tabuleiro.custom_minimum_size
	_tabuleiro.add_child(_mesa)
	var casas := Control.new()
	casas.name = "Casas"
	casas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	casas.size = _mesa.size
	casas.draw.connect(_desenhar_casas.bind(casas))
	_mesa.add_child(casas)
	_gelatina = Control.new()
	_gelatina.name = "Gelatina"
	_gelatina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gelatina.size = _mesa.size
	_gelatina.draw.connect(_desenhar_gelatina)
	_mesa.add_child(_gelatina)
	_efeitos = Control.new()
	_efeitos.name = "Explosoes"
	_efeitos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_efeitos.size = _mesa.size
	_efeitos.z_index = 5
	_mesa.add_child(_efeitos)


func _desenhar_casas(casas: Control) -> void:
	casas.draw_rect(Rect2(Vector2.ZERO, casas.size), Color(0.16, 0.08, 0.3, 0.45))
	for y in DoceMatch.ALTURA:
		for x in DoceMatch.LARGURA:
			var cor := Color(1, 1, 1, 0.10 if (x + y) % 2 == 0 else 0.04)
			casas.draw_rect(Rect2(Vector2(x, y) * TAMANHO, Vector2.ONE * TAMANHO), cor)


func _desenhar_gelatina() -> void:
	if jogo == null:
		return
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_GELATINA
	estilo.set_corner_radius_all(14)
	estilo.set_border_width_all(3)
	estilo.border_color = Color("#FFC2E0")
	for y in DoceMatch.ALTURA:
		for x in DoceMatch.LARGURA:
			if jogo.gelatina[y][x]:
				_gelatina.draw_style_box(estilo, Rect2(Vector2(x, y) * TAMANHO + Vector2(2, 2), Vector2.ONE * (TAMANHO - 4)))


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
	if _ocupado or jogo.acabou():
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
	_atualizar_placar()
	var combo := 1
	while true:
		var passo := jogo.passo(combo)
		if passo.is_empty():
			break
		await _animar_passo(passo)
		combo += 1
	if not jogo.acabou() and jogo.jogada_possivel().is_empty():
		jogo.embaralhar()
		Telas.mostrar_aviso("SEM JOGADAS: EMBARALHANDO!")
		_criar_pecas()
	_atualizar_placar()
	if jogo.acabou():
		await _terminar()
	_ocupado = false


func _animar_troca(pa: Control, pb: Control, a: Vector2i, b: Vector2i) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(pa, "position", _posicao(b), 0.14)
	tween.tween_property(pb, "position", _posicao(a), 0.14)
	await tween.finished


func _animar_passo(passo: Dictionary) -> void:
	var combo: int = passo["combo"]
	var efeitos: Array = passo["efeitos"]
	Audio.tocar("estouro", 0.9 + 0.12 * (combo - 1))  # combo: cada vez mais agudo
	# 1) explosões das peças especiais
	if not efeitos.is_empty():
		Audio.tocar("explosao", randf_range(0.9, 1.1))
		for efeito in efeitos:
			_animar_efeito(efeito)
		_tremer(4.0 + 3.0 * mini(efeitos.size(), 4))
		await get_tree().create_timer(0.16).timeout
	# 2) as peças somem, com confete da cor delas
	var centro := Vector2.ZERO
	var voando := {}  # tipo -> quantas já voaram até o objetivo
	for p: Vector2i in passo["somem"]:
		var peca: Control = _pecas[p.y][p.x]
		_pecas[p.y][p.x] = null
		centro += _centro(p)
		if peca == null:
			continue
		var tipo: String = peca.get_meta("tipo", "")
		if tipo != "":
			_confete(_centro(p), CORES_TIPOS[tipo])
			if voando.get(tipo, 0) < 6 and _objetivo_de_coleta(tipo) != null:
				voando[tipo] = voando.get(tipo, 0) + 1
				_voar_ate_objetivo(peca, tipo)
		var tween := peca.create_tween()
		tween.tween_property(peca, "scale", Vector2.ONE * 1.25, 0.06)
		tween.tween_property(peca, "scale", Vector2.ONE * 0.1, 0.14)
		tween.parallel().tween_property(peca, "modulate:a", 0.0, 0.14)
		tween.tween_callback(peca.queue_free)
	centro /= maxf(1.0, passo["somem"].size())
	# 3) gelatina limpa
	for p: Vector2i in passo["gelatinas"]:
		_respingo_gelatina(p)
	if not passo["gelatinas"].is_empty():
		_gelatina.queue_redraw()
	# 4) peças especiais que nasceram
	for criada in passo["criadas"]:
		_virar_especial(criada[0], criada[1], criada[2])
	if not passo["criadas"].is_empty():
		Audio.tocar("especial")
	# 5) pontos e palavra de combo
	_mostrar_ganho("+%d" % passo["ganho"], centro)
	var forca := combo + (1 if not efeitos.is_empty() else 0)
	if forca >= 2:
		_anunciar(PALAVRAS_COMBO[mini(forca, PALAVRAS_COMBO.size() - 1)], 64 + 6 * mini(forca, 5))
	_atualizar_placar()
	await get_tree().create_timer(0.2).timeout
	# 6) as peças caem (na mesma ordem em que a regra moveu) e novas entram
	var tween := create_tween().set_parallel()
	var algum := false
	for movimento in passo["caem"]:
		var de: Vector2i = movimento[0]
		var para: Vector2i = movimento[1]
		var peca: Control = _pecas[de.y][de.x]
		_pecas[para.y][para.x] = peca
		_pecas[de.y][de.x] = null
		if peca:
			tween.tween_property(peca, "position", _posicao(para), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			algum = true
	var por_coluna := {}
	for nova in passo["novas"]:
		var p: Vector2i = nova[0]
		por_coluna[p.x] = por_coluna.get(p.x, 0) + 1
	for nova in passo["novas"]:
		var p: Vector2i = nova[0]
		var peca := _criar_peca(p, nova[1], DoceMatch.Especial.NENHUM)
		peca.position = _posicao(Vector2i(p.x, p.y - por_coluna[p.x]))
		tween.tween_property(peca, "position", _posicao(p), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		algum = true
	if algum:
		await tween.finished
	else:
		tween.kill()


# --- Efeitos -------------------------------------------------------------------------

func _animar_efeito(efeito: Dictionary) -> void:
	var pos: Vector2i = efeito["pos"]
	match efeito["tipo"]:
		"linha":
			_raio(Rect2(0, pos.y * TAMANHO, DoceMatch.LARGURA * TAMANHO, TAMANHO), true)
		"coluna":
			_raio(Rect2(pos.x * TAMANHO, 0, TAMANHO, DoceMatch.ALTURA * TAMANHO), false)
		"embrulho":
			_anel(_centro(pos), TAMANHO * 1.6)
		"bomba":
			for alvo: Vector2i in efeito["alvos"]:
				var raio := Line2D.new()
				raio.points = [_centro(pos), _centro(alvo)]
				raio.width = 6
				raio.default_color = Color(1, 1, 1, 0.9)
				raio.begin_cap_mode = Line2D.LINE_CAP_ROUND
				raio.end_cap_mode = Line2D.LINE_CAP_ROUND
				_efeitos.add_child(raio)
				var tween := raio.create_tween()
				tween.tween_property(raio, "width", 14.0, 0.12)
				tween.tween_property(raio, "modulate:a", 0.0, 0.25)
				tween.tween_callback(raio.queue_free)
			_anel(_centro(pos), TAMANHO * 2.2)


## Faixa de luz atravessando a linha (ou a coluna) da peça listrada.
func _raio(area: Rect2, deitado: bool) -> void:
	var faixa := ColorRect.new()
	faixa.color = Color(1, 1, 0.85, 0.95)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.position = area.position
	faixa.size = area.size
	faixa.pivot_offset = area.size / 2
	faixa.scale = Vector2(1, 0.1) if deitado else Vector2(0.1, 1)
	_efeitos.add_child(faixa)
	var tween := faixa.create_tween()
	tween.tween_property(faixa, "scale", Vector2.ONE, 0.1)
	tween.tween_property(faixa, "scale", Vector2(1, 0.05) if deitado else Vector2(0.05, 1), 0.28)
	tween.parallel().tween_property(faixa, "modulate:a", 0.0, 0.28)
	tween.tween_callback(faixa.queue_free)
	for i in 5:
		var ponto := area.position + Vector2(area.size.x * (i + 0.5) / 5.0, area.size.y / 2) if deitado \
			else area.position + Vector2(area.size.x / 2, area.size.y * (i + 0.5) / 5.0)
		_confete(ponto, Cores.AMARELO_CLARO)


## Onda redonda que cresce (peça embrulhada e bomba).
func _anel(centro: Vector2, raio: float) -> void:
	var anel := Control.new()
	anel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anel.position = centro
	anel.scale = Vector2.ONE * 0.2
	anel.draw.connect(func():
		anel.draw_arc(Vector2.ZERO, raio, 0, TAU, 48, Color(1, 0.95, 0.6), 12.0, true)
		anel.draw_circle(Vector2.ZERO, raio * 0.8, Color(1, 1, 1, 0.35)))
	_efeitos.add_child(anel)
	var tween := anel.create_tween()
	tween.tween_property(anel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(anel, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.tween_callback(anel.queue_free)


## Pedacinhos brilhantes voando da peça que estourou.
func _confete(ponto: Vector2, cor: Color) -> void:
	var particulas := CPUParticles2D.new()
	particulas.position = ponto
	particulas.texture = BRILHO
	particulas.amount = 8
	particulas.lifetime = 0.55
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.spread = 180.0
	particulas.direction = Vector2.UP
	particulas.initial_velocity_min = 120.0
	particulas.initial_velocity_max = 260.0
	particulas.gravity = Vector2(0, 500)
	particulas.scale_amount_min = 0.5
	particulas.scale_amount_max = 1.1
	particulas.angular_velocity_min = -360.0
	particulas.angular_velocity_max = 360.0
	particulas.color = cor.lightened(0.25)
	var sumir := Gradient.new()
	sumir.set_color(0, Color.WHITE)
	sumir.set_color(1, Color(1, 1, 1, 0))
	particulas.color_ramp = sumir
	particulas.emitting = true
	_efeitos.add_child(particulas)
	particulas.finished.connect(particulas.queue_free)


func _respingo_gelatina(p: Vector2i) -> void:
	var mancha := ColorRect.new()
	mancha.color = Color(COR_GELATINA, 0.6)
	mancha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mancha.size = Vector2.ONE * TAMANHO
	mancha.pivot_offset = mancha.size / 2
	mancha.position = Vector2(p) * TAMANHO
	_efeitos.add_child(mancha)
	var tween := mancha.create_tween().set_parallel()
	tween.tween_property(mancha, "scale", Vector2.ONE * 1.5, 0.3)
	tween.tween_property(mancha, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(mancha.queue_free)


## O tabuleiro treme (mais forte quanto maior a explosão).
func _tremer(forca: float) -> void:
	if not Telas.animacoes_continuas:
		return
	var tween := _mesa.create_tween()
	for i in 6:
		var lado := forca * (1.0 - i / 6.0)
		tween.tween_property(_mesa, "position", Vector2(randf_range(-lado, lado), randf_range(-lado, lado)), 0.035)
	tween.tween_property(_mesa, "position", Vector2.ZERO, 0.035)


## A peça em `p` vira especial (listrada, embrulhada ou bomba), com um brilho.
func _virar_especial(p: Vector2i, esp: int, tipo: int) -> void:
	var peca: TextureRect = _pecas[p.y][p.x]
	if peca == null:
		peca = _criar_peca(p, tipo, esp)
	else:
		_vestir(peca, tipo, esp)
	peca.modulate = Color(2, 2, 2)
	peca.scale = Vector2.ONE * 0.4
	var tween := peca.create_tween().set_parallel()
	tween.tween_property(peca, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(peca, "modulate", Color.WHITE, 0.35)
	_anel(_centro(p), TAMANHO * 0.7)


## Uma cópia pequena da peça voa até o ícone do objetivo de juntar peças.
func _voar_ate_objetivo(peca: Control, tipo: String) -> void:
	var alvo: Control = _objetivo_de_coleta(tipo)
	var copia := TextureRect.new()
	copia.texture = TEXTURAS[tipo]
	copia.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	copia.size = Vector2.ONE * (TAMANHO - 2 * MARGEM_PECA)
	copia.pivot_offset = copia.size / 2
	copia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_topo.add_child(copia)
	copia.global_position = peca.global_position
	var destino := alvo.global_position + alvo.size / 2 - copia.size / 2
	var tween := copia.create_tween().set_parallel()
	tween.tween_property(copia, "global_position", destino, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(copia, "scale", Vector2.ONE * 0.6, 0.5)
	tween.chain().tween_callback(func():
		copia.queue_free()
		if is_instance_valid(alvo):
			var pulo := alvo.create_tween()
			pulo.tween_property(alvo, "scale", Vector2.ONE * 1.25, 0.06)
			pulo.tween_property(alvo, "scale", Vector2.ONE, 0.1))


func _objetivo_de_coleta(tipo: String) -> Control:
	for o in _objetivos:
		if o["obj"]["tipo"] == "coletar" and o["obj"]["peca"] == tipo and not o["certo"]:
			return o["icone"]
	return null


func _mostrar_ganho(texto: String, ponto: Vector2) -> void:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 36)
	rotulo.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	rotulo.add_theme_constant_override("outline_size", 10)
	rotulo.text = texto
	_efeitos.add_child(rotulo)
	rotulo.position = ponto - rotulo.get_minimum_size() / 2
	var tween := rotulo.create_tween()
	tween.tween_property(rotulo, "position:y", rotulo.position.y - 60, 0.7)
	tween.parallel().tween_property(rotulo, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(rotulo.queue_free)


## Palavra grande no meio do tabuleiro ("DELICIOSO!", objetivo do nível...).
func _anunciar(texto: String, tamanho: int) -> void:
	if not is_instance_valid(_tabuleiro):
		return
	for antigo in _camada_topo.get_children():
		if antigo.name.begins_with("Anuncio"):
			antigo.queue_free()
	var rotulo := Label.new()
	rotulo.name = "Anuncio"
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", Cores.AMARELO)
	rotulo.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	rotulo.add_theme_constant_override("outline_size", 18)
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_topo.add_child(rotulo)
	await get_tree().process_frame  # o tabuleiro precisa estar no lugar
	if not is_instance_valid(rotulo) or not is_instance_valid(_tabuleiro):
		return
	rotulo.size = rotulo.get_minimum_size()
	rotulo.pivot_offset = rotulo.size / 2
	rotulo.global_position = _tabuleiro.global_position + _tabuleiro.size / 2 - rotulo.size / 2
	rotulo.rotation = randf_range(-0.12, 0.12)
	rotulo.scale = Vector2.ONE * 0.3
	var tween := rotulo.create_tween()
	tween.tween_property(rotulo, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.45)
	tween.tween_property(rotulo, "modulate:a", 0.0, 0.3)
	tween.tween_callback(rotulo.queue_free)


func _pulinho(peca: Control) -> void:
	if peca == null:
		return
	var tween := peca.create_tween()
	tween.tween_property(peca, "scale", Vector2.ONE * 1.2, 0.15)
	tween.tween_property(peca, "scale", Vector2.ONE, 0.15)
	tween.tween_property(peca, "scale", Vector2.ONE * 1.2, 0.15)
	tween.tween_property(peca, "scale", Vector2.ONE, 0.15)


# --- Fim do nível ----------------------------------------------------------------------

func _terminar() -> void:
	if _fim_registrado:
		return
	_fim_registrado = true
	var venceu := jogo.venceu()
	if venceu:
		await _jogadas_extras()
	Missoes.registrar("match", 1)
	Experiencia.ganhar(Experiencia.XP_MATCH)
	var recorde: int = Progresso.estatisticas.get("match_recorde", 0)
	Progresso.estatisticas["match_recorde"] = maxi(recorde, jogo.pontos)
	Progresso.estatisticas["match_partidas"] = int(Progresso.estatisticas.get("match_partidas", 0)) + 1
	if venceu:
		var estrelas := jogo.estrelas()
		var premio := DoceMatch.concluir(numero_nivel, estrelas)
		recem_vencido = numero_nivel if premio["primeira"] else 0
		_mostrar_vitoria(estrelas, premio)
	else:
		Progresso.salvar()
		_mostrar_derrota()


## Venceu com jogadas sobrando: cada uma vira uma explosãozinha de pontos.
func _jogadas_extras() -> void:
	var sobrando := jogo.jogadas
	if sobrando > 0:
		_anunciar("JOGADAS EXTRAS!", 60)
		Audio.tocar("vitoria")
		await get_tree().create_timer(0.6).timeout
		for i in mini(sobrando, 12):
			var p := Vector2i(randi() % DoceMatch.LARGURA, randi() % DoceMatch.ALTURA)
			_confete(_centro(p), Cores.AMARELO)
			_anel(_centro(p), TAMANHO * 0.8)
			_mostrar_ganho("+%d" % DoceMatch.BONUS_JOGADA, _centro(p))
			Audio.tocar("estouro", 1.0 + 0.05 * i)
			jogo.jogadas -= 1
			jogo.pontos += DoceMatch.BONUS_JOGADA
			_atualizar_placar()
			await get_tree().create_timer(0.12).timeout
		# o que passou de 12 entra de uma vez
		jogo.bonus_de_jogadas()
		_atualizar_placar()
		await get_tree().create_timer(0.4).timeout
	else:
		Audio.tocar("vitoria")


func _mostrar_vitoria(estrelas: int, premio: Dictionary) -> void:
	var painel := _painel_central()
	var coluna: VBoxContainer = painel.get_child(0)
	_rotulo(coluna, "NÍVEL %d COMPLETO!" % numero_nivel, 56)
	var linha := _linha_estrelas(0, 80)
	coluna.add_child(linha)
	_rotulo(coluna, "%s PONTOS" % Jogo.formatar(jogo.pontos), 34)
	if premio["moedas"] > 0:
		coluna.add_child(_linha_premio(Itens.MOEDA, "+%d MOEDAS" % premio["moedas"]))
	if premio["bau"] != "":
		coluna.add_child(_linha_premio(Itens.bau(premio["bau"]), "+1 %s!" % Baus.NOMES[premio["bau"]]))
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Mapa", "MAPA", &"BotaoAzul", 180, _voltar_ao_mapa))
	if numero_nivel < DoceMatch.niveis().size():
		botoes.add_child(_botao("Proximo", "PRÓXIMO (%d AÇÚCAR)" % DoceMatch.CUSTO_ACUCAR, &"", 340,
			comecar_nivel.bind(numero_nivel + 1)))
	await _abrir_painel(painel)
	# as estrelas acendem uma por uma
	for i in estrelas:
		if not is_instance_valid(linha):
			return
		var e: TextureRect = linha.get_child(i)
		e.pivot_offset = e.size / 2
		e.modulate = Color.WHITE
		e.scale = Vector2.ONE * 1.8
		e.create_tween().tween_property(e, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Audio.tocar("moeda", 1.0 + 0.15 * i)
		await get_tree().create_timer(0.3).timeout


func _mostrar_derrota() -> void:
	Audio.tocar("erro")
	var painel := _painel_central()
	var coluna: VBoxContainer = painel.get_child(0)
	_rotulo(coluna, "ACABARAM AS JOGADAS!", 52)
	for obj in jogo.nivel["objetivos"]:
		var p := jogo.progresso_objetivo(obj)
		var linha := HBoxContainer.new()
		linha.alignment = BoxContainer.ALIGNMENT_CENTER
		linha.add_theme_constant_override("separation", 12)
		linha.add_child(_icone_objetivo(obj, 44))
		var rotulo := Label.new()
		rotulo.theme_type_variation = &"TituloClaro"
		rotulo.add_theme_font_size_override("font_size", 30)
		rotulo.text = "%s / %s" % [Jogo.formatar(p[0]), Jogo.formatar(p[1])]
		rotulo.add_theme_color_override("font_color", Cores.AMARELO if p[0] >= p[1] else Color.WHITE)
		linha.add_child(rotulo)
		coluna.add_child(linha)
	_rotulo(coluna, "Quase! Tente de novo: as peças caem diferente a cada vez.", 22)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Mapa", "MAPA", &"BotaoAzul", 180, _voltar_ao_mapa))
	botoes.add_child(_botao("TentarDeNovo", "DE NOVO (%d AÇÚCAR)" % DoceMatch.CUSTO_ACUCAR, &"", 340,
		comecar_nivel.bind(numero_nivel)))
	_abrir_painel(painel)


func _voltar_ao_mapa() -> void:
	_fechar_painel()
	mostrar_mapa()


func _perguntar_sair() -> void:
	if is_instance_valid(_painel):
		return
	if jogo.acabou():
		_voltar_ao_mapa()
		return
	var painel := _painel_central()
	var coluna: VBoxContainer = painel.get_child(0)
	_rotulo(coluna, "SAIR DO NÍVEL?", 52)
	_rotulo(coluna, "O açúcar desta tentativa não volta.", 24)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "SAIR", &"BotaoSecundario", 200, _voltar_ao_mapa))
	botoes.add_child(_botao("Continuar", "CONTINUAR", &"", 260, _fechar_painel))
	_abrir_painel(painel)


## Sem açúcar para jogar: explica e leva ao quiz.
func _mostrar_sem_acucar() -> void:
	var painel := _painel_central()
	var coluna: VBoxContainer = painel.get_child(0)
	_rotulo(coluna, "SEM AÇÚCAR!", 60)
	_rotulo(coluna, "Cada tentativa custa %d de açúcar. Você tem %d.\nCada acerto no quiz dá %d, e o Laboratório também dá açúcar!" % [
		DoceMatch.CUSTO_ACUCAR, Confeitaria.acucar(), Confeitaria.ACUCAR_POR_ACERTO], 24)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "MAPA", &"BotaoAzul", 200, _voltar_ao_mapa))
	botoes.add_child(_botao("JogarQuiz", "JOGAR O QUIZ", &"", 300, Telas.abrir.bind("niveis")))
	_abrir_painel(painel)


# --- Painéis e peças de interface ---------------------------------------------------------

## Painel no meio da tela, com o fundo escurecido (o nó "Fim" é a camada toda).
func _painel_central() -> PanelContainer:
	_fechar_painel()
	var camada := Control.new()
	camada.name = "Fim"
	camada.set_anchors_preset(PRESET_FULL_RECT)
	add_child(camada)
	move_child(camada, _camada_topo.get_index())
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
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)
	_painel = camada
	return painel


func _fechar_painel() -> void:
	if is_instance_valid(_painel):
		_painel.queue_free()
		_painel.name = "FimFechando"  # para não ser achado de novo
	_painel = null
	_atualizar_contadores()


func _abrir_painel(painel: Control) -> void:
	await get_tree().process_frame  # espera o CenterContainer posicionar
	if not is_instance_valid(painel):
		return
	painel.pivot_offset = painel.size / 2
	painel.scale = Vector2.ONE * 0.6
	var tween := painel.create_tween()
	tween.tween_property(painel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func _rotulo(pai: Control, texto: String, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 40 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.text = texto
	pai.add_child(rotulo)
	return rotulo


func _botao(nome: String, texto: String, estilo: StringName, largura: float, acao: Callable) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.text = texto
	botao.theme_type_variation = estilo
	botao.custom_minimum_size = Vector2(largura, 76)
	botao.pressed.connect(acao)
	if estilo == &"":
		botao.theme_type_variation = &"BotaoComprar"  # ação principal em menta
	return botao


func _botao_voltar(acao: Callable) -> Button:
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(60, 60)
	voltar.icon = ICONE_VOLTAR
	voltar.expand_icon = true
	voltar.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltar.pressed.connect(acao)
	return voltar


func _etiqueta_titulo(texto: String) -> PanelContainer:
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"EtiquetaAmarela"
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var titulo := Label.new()
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.text = texto
	etiqueta.add_child(titulo)
	return etiqueta


func _contador(pai: Control, icone_textura: Texture2D) -> Label:
	var caixa := PanelContainer.new()
	caixa.theme_type_variation = &"Etiqueta"
	caixa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	caixa.add_child(linha)
	var icone := TextureRect.new()
	icone.texture = icone_textura
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


func _linha_estrelas(acesas: int, lado: float) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var e := TextureRect.new()
		e.texture = ICONE_ESTRELA
		e.custom_minimum_size = Vector2(lado, lado)
		e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		e.modulate = Color.WHITE if i < acesas else Itens.ESTRELA_APAGADA
		linha.add_child(e)
	return linha


func _linha_premio(textura: Texture2D, texto: String) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 10)
	var icone := TextureRect.new()
	icone.texture = textura
	icone.custom_minimum_size = Vector2(48, 48)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(icone)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 30)
	rotulo.text = texto
	linha.add_child(rotulo)
	return linha


func _item_placar(pai: Control, nome: String, tamanho: int) -> Label:
	_rotulo(pai, nome, 22)
	var valor := Label.new()
	valor.theme_type_variation = &"TituloClaro"
	valor.add_theme_font_size_override("font_size", tamanho)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pai.add_child(valor)
	return valor


# --- Tabuleiro ---------------------------------------------------------------------------

## Canto de cima/esquerda da peça na casa `p` (a peça é menor que a casa).
func _posicao(p: Vector2i) -> Vector2:
	return Vector2(p) * TAMANHO + Vector2.ONE * MARGEM_PECA


func _centro(p: Vector2i) -> Vector2:
	return (Vector2(p) + Vector2(0.5, 0.5)) * TAMANHO


func _criar_peca(p: Vector2i, tipo: int, esp: int) -> TextureRect:
	var peca := TextureRect.new()
	peca.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	peca.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	peca.size = Vector2.ONE * (TAMANHO - 2 * MARGEM_PECA)
	peca.pivot_offset = peca.size / 2
	peca.position = _posicao(p)
	peca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vestir(peca, tipo, esp)
	_mesa.add_child(peca)
	_mesa.move_child(_efeitos, -1)
	_pecas[p.y][p.x] = peca
	return peca


## Põe a figura da peça e, se for especial, as listras ou o embrulho por cima.
func _vestir(peca: TextureRect, tipo: int, esp: int) -> void:
	for filho in peca.get_children():
		filho.queue_free()
	if tipo == DoceMatch.BOMBA or esp == DoceMatch.Especial.BOMBA:
		peca.texture = BOMBA
		peca.set_meta("tipo", "")
		peca.set_meta("especial", DoceMatch.Especial.BOMBA)
		if Telas.animacoes_continuas:
			var giro := peca.create_tween().set_loops()
			giro.tween_property(peca, "rotation", TAU, 4.0).from(0.0)
		return
	peca.texture = TEXTURAS[DoceMatch.TIPOS[tipo]]
	peca.set_meta("tipo", DoceMatch.TIPOS[tipo])
	peca.set_meta("especial", esp)
	if esp == DoceMatch.Especial.NENHUM:
		return
	var capa := TextureRect.new()
	capa.name = "Especial"
	capa.texture = EMBRULHO if esp == DoceMatch.Especial.EMBRULHO else LISTRAS
	capa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	capa.size = peca.size
	capa.pivot_offset = peca.size / 2
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if esp == DoceMatch.Especial.COLUNA:
		capa.rotation = PI / 2
	peca.add_child(capa)
	if Telas.animacoes_continuas:
		var brilho := capa.create_tween().set_loops()
		brilho.tween_property(capa, "modulate:a", 0.55, 0.6).set_trans(Tween.TRANS_SINE)
		brilho.tween_property(capa, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)


func _criar_pecas() -> void:
	for filho in _mesa.get_children():
		if filho is TextureRect:
			filho.queue_free()
	_pecas.clear()
	for y in DoceMatch.ALTURA:
		var linha := []
		linha.resize(DoceMatch.LARGURA)
		_pecas.append(linha)
	for y in DoceMatch.ALTURA:
		for x in DoceMatch.LARGURA:
			var peca := _criar_peca(Vector2i(x, y), jogo.grade[y][x], jogo.especial[y][x])
			peca.scale = Vector2.ONE * 0.2
			peca.create_tween().tween_property(peca, "scale", Vector2.ONE, 0.2).set_delay(0.02 * (x + y))
	_gelatina.queue_redraw()


func _atualizar_placar() -> void:
	if not is_instance_valid(_rotulo_jogadas):
		return
	_rotulo_pontos.text = Jogo.formatar(jogo.pontos)
	_rotulo_jogadas.text = "%d" % jogo.jogadas
	_rotulo_jogadas.add_theme_color_override("font_color", Cores.VERMELHO if jogo.jogadas <= 3 and not jogo.venceu() else Color.WHITE)
	for o in _objetivos:
		var p := jogo.progresso_objetivo(o["obj"])
		var feito: bool = p[0] >= p[1]
		o["rotulo"].text = "OK!" if feito else ("%d" % (p[1] - p[0]) if o["obj"]["tipo"] != "pontos" else Jogo.formatar(p[1] - p[0]))
		o["rotulo"].add_theme_color_override("font_color", Cores.AMARELO if feito else Color.WHITE)
		if feito and not o["certo"]:
			o["certo"] = true
			var icone: Control = o["icone"]
			var tween := icone.create_tween()
			tween.tween_property(icone, "scale", Vector2.ONE * 1.4, 0.12)
			tween.tween_property(icone, "scale", Vector2.ONE, 0.2)
	var metas: Array = jogo.nivel["estrelas"]
	_barra.max_value = maxf(1.0, float(metas[-1]))
	_barra.value = jogo.pontos
	for i in _estrelas.size():
		var acesa := jogo.pontos >= int(metas[i]) and int(metas[i]) > 0
		var era := _estrelas[i].modulate == Color.WHITE
		_estrelas[i].modulate = Color.WHITE if acesa else Itens.ESTRELA_APAGADA
		if acesa and not era:
			var tween := _estrelas[i].create_tween()
			tween.tween_property(_estrelas[i], "scale", Vector2.ONE * 1.5, 0.12)
			tween.tween_property(_estrelas[i], "scale", Vector2.ONE, 0.2)
