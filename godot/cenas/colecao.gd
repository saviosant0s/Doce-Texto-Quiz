extends Control
## Minha Coleção: vitrine dos doces 3D. À esquerda, o doce escolhido em 3D
## (gira com o dedo, pula quando tocado) com o botão de comprar ou de escolher
## como companheiro; à direita, a grade com todos os doces.
## Regras e catálogo em scripts/colecao.gd.

const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")
const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")
const ICONE_CORACAO := preload("res://assets/icones/coracao.svg")
const COLUNAS := 4
const TAMANHO_MINIATURA := 200

## Miniaturas já desenhadas (continuam valendo ao voltar para a tela).
static var _miniaturas := {}

var _selecionado := ""
var _visor: Doce3D
var _nome: Label
var _texto: Label
var _acao: Button
var _cartoes := {}  # id -> Button


func _ready() -> void:
	%Voltar.pressed.connect(Telas.voltar)
	_criar_painel()
	_criar_grade()
	_atualizar_topo()
	var inicial := Colecao.companheiro()
	selecionar(inicial if not inicial.is_empty() else Colecao.LISTA[0]["id"])
	Animacoes.entrar(%Corpo, Vector2(0, 40))
	_desenhar_miniaturas()


## Mostra o doce `id` no visor 3D e ajusta o botão de ação.
func selecionar(id: String) -> void:
	_selecionado = id
	var doce := Colecao.dados(id)
	_visor.mostrar(id)
	_nome.text = doce["nome"]
	_texto.text = doce["curiosidade"]
	for outro in _cartoes:
		_marcar_cartao(_cartoes[outro], outro == id)
	_atualizar_acao()


func _atualizar_topo() -> void:
	%Quantidade.text = "%s MOEDAS" % Jogo.formatar(Progresso.moedas)
	%Titulo.text = "MINHA COLEÇÃO · %d/%d" % [Colecao.quantidade(), Colecao.LISTA.size()]


func _atualizar_acao() -> void:
	var id := _selecionado
	var doce := Colecao.dados(id)
	_acao.disabled = false
	_acao.icon = null
	if Colecao.tem(id):
		if Colecao.companheiro() == id:
			_acao.text = "SEU COMPANHEIRO"
			_acao.icon = ICONE_CORACAO
			_acao.disabled = true
		else:
			_acao.text = "ESCOLHER COMO COMPANHEIRO"
	elif doce.has("titulo"):
		_acao.text = "PASSE NO NÍVEL %s" % Colecao.NIVEL_DO_TITULO[doce["titulo"]]
		_acao.icon = ICONE_CADEADO
		_acao.disabled = true
	else:
		var preco: int = doce["preco"]
		_acao.icon = ICONE_MOEDA
		if Progresso.moedas >= preco:
			_acao.text = "COMPRAR POR %s" % Jogo.formatar(preco)
		else:
			_acao.text = "FALTAM %s MOEDAS" % Jogo.formatar(preco - Progresso.moedas)
			_acao.disabled = true


func _ao_tocar_acao() -> void:
	var id := _selecionado
	if Colecao.tem(id):
		Colecao.escolher_companheiro(id)
		_visor.comemorar()
		Telas.mostrar_aviso("%s VAI TE ACOMPANHAR!" % Colecao.dados(id)["nome"])
		_atualizar_acao()
		_atualizar_cartao(id)
		for outro in _cartoes:
			_atualizar_cartao(outro)
		return
	var doce := Colecao.dados(id)
	var sim := await Telas.confirmar("COMPRAR %s?" % doce["nome"],
		"Custa %s moedas. Você tem %s." % [Jogo.formatar(doce["preco"]), Jogo.formatar(Progresso.moedas)],
		"COMPRAR", "AGORA NÃO")
	if not sim or not Colecao.comprar(id):
		return
	Audio.tocar("acerto")
	_visor.comemorar()
	if Colecao.companheiro().is_empty():
		Colecao.escolher_companheiro(id)  # o primeiro doce comprado já vira companheiro
	_atualizar_topo()
	_atualizar_acao()
	for outro in _cartoes:
		_atualizar_cartao(outro)
	for conquista in Conquistas.verificar({}):
		Telas.mostrar_aviso("CONQUISTA: %s  +%d MOEDAS" % [conquista["nome"], conquista["moedas"]])
		_atualizar_topo()


# --- Painel do doce escolhido ----------------------------------------------------

func _criar_painel() -> void:
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelEscuro"
	painel.custom_minimum_size = Vector2(430, 0)
	%Corpo.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 6)
	painel.add_child(coluna)
	_visor = Doce3D.new()
	_visor.name = "Visor"
	_visor.custom_minimum_size = Vector2(0, 300)
	_visor.size_flags_vertical = SIZE_EXPAND_FILL
	coluna.add_child(_visor)
	_nome = Label.new()
	_nome.theme_type_variation = &"TituloClaro"
	_nome.add_theme_font_size_override("font_size", 44)
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_nome)
	_texto = Label.new()
	_texto.theme_type_variation = &"TextoClaro"
	_texto.add_theme_font_size_override("font_size", 18)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(200, 52)
	coluna.add_child(_texto)
	_acao = Button.new()
	_acao.name = "Acao"
	_acao.custom_minimum_size = Vector2(0, 64)
	_acao.add_theme_font_size_override("font_size", 32)
	_acao.expand_icon = true
	_acao.add_theme_constant_override("icon_max_width", 30)
	_acao.pressed.connect(_ao_tocar_acao)
	coluna.add_child(_acao)


# --- Grade de doces ----------------------------------------------------------------

func _criar_grade() -> void:
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_horizontal = SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	%Corpo.add_child(rolagem)
	var grade := GridContainer.new()
	grade.columns = COLUNAS
	grade.size_flags_horizontal = SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	rolagem.add_child(grade)
	for doce in Colecao.LISTA:
		var cartao := _criar_cartao(doce)
		grade.add_child(cartao)
		_cartoes[doce["id"]] = cartao
		_atualizar_cartao(doce["id"])


func _criar_cartao(doce: Dictionary) -> Button:
	var cartao := Button.new()
	cartao.name = doce["id"]
	cartao.theme_type_variation = &"CartaoNivel"
	cartao.custom_minimum_size = Vector2(0, 176)
	cartao.size_flags_horizontal = SIZE_EXPAND_FILL
	cartao.pressed.connect(selecionar.bind(doce["id"]))
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(PRESET_FULL_RECT)
	coluna.offset_left = 6
	coluna.offset_right = -6
	coluna.offset_top = 6
	coluna.offset_bottom = -8
	coluna.add_theme_constant_override("separation", 0)
	coluna.mouse_filter = MOUSE_FILTER_IGNORE
	cartao.add_child(coluna)
	var imagem := TextureRect.new()
	imagem.name = "Imagem"
	imagem.size_flags_vertical = SIZE_EXPAND_FILL
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.mouse_filter = MOUSE_FILTER_IGNORE
	imagem.texture = _miniaturas.get(doce["id"])
	coluna.add_child(imagem)
	var nome := Label.new()
	nome.theme_type_variation = &"Subtitulo"
	nome.add_theme_font_size_override("font_size", 20)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.text = doce["nome"]
	nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nome.mouse_filter = MOUSE_FILTER_IGNORE
	coluna.add_child(nome)
	var situacao := HBoxContainer.new()
	situacao.name = "Situacao"
	situacao.alignment = BoxContainer.ALIGNMENT_CENTER
	situacao.add_theme_constant_override("separation", 4)
	situacao.mouse_filter = MOUSE_FILTER_IGNORE
	coluna.add_child(situacao)
	var icone := TextureRect.new()
	icone.name = "Icone"
	icone.custom_minimum_size = Vector2(18, 18)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size_flags_vertical = SIZE_SHRINK_CENTER
	icone.modulate = Cores.ROXO
	icone.mouse_filter = MOUSE_FILTER_IGNORE
	situacao.add_child(icone)
	var texto := Label.new()
	texto.name = "Texto"
	texto.theme_type_variation = &"Subtitulo"
	texto.add_theme_font_size_override("font_size", 18)
	texto.mouse_filter = MOUSE_FILTER_IGNORE
	situacao.add_child(texto)
	return cartao


## Situação do doce no cartão: preço, "passe no nível X", "seu" ou companheiro.
func _atualizar_cartao(id: String) -> void:
	var cartao: Button = _cartoes[id]
	var doce := Colecao.dados(id)
	var icone: TextureRect = cartao.find_child("Icone", true, false)
	var texto: Label = cartao.find_child("Texto", true, false)
	var imagem: TextureRect = cartao.find_child("Imagem", true, false)
	var tem := Colecao.tem(id)
	imagem.material = null if tem else Personagens.material_silhueta()
	icone.visible = true
	if Colecao.companheiro() == id:
		icone.texture = ICONE_CORACAO
		texto.text = "COMPANHEIRO"
	elif tem:
		icone.visible = false
		texto.text = "NA COLEÇÃO"
	elif doce.has("titulo"):
		icone.texture = ICONE_CADEADO
		texto.text = "NÍVEL " + Colecao.NIVEL_DO_TITULO[doce["titulo"]]
	else:
		icone.texture = ICONE_MOEDA
		texto.text = Jogo.formatar(doce["preco"])


func _marcar_cartao(cartao: Button, marcado: bool) -> void:
	if marcado:
		var estilo: StyleBoxFlat = cartao.get_theme_stylebox("normal", &"CartaoNivel").duplicate()
		estilo.border_color = Cores.CREME
		estilo.set_border_width_all(5)
		for estado in ["normal", "hover", "pressed", "focus"]:
			cartao.add_theme_stylebox_override(estado, estilo)
	else:
		for estado in ["normal", "hover", "pressed", "focus"]:
			cartao.remove_theme_stylebox_override(estado)


# --- Miniaturas --------------------------------------------------------------------

## Desenha a foto de cada doce uma vez (num visor escondido) para a grade.
## Em aparelhos sem desenho (testes), fica sem foto.
func _desenhar_miniaturas() -> void:
	var faltam := Colecao.LISTA.filter(func(d): return not _miniaturas.has(d["id"]))
	if faltam.is_empty() or DisplayServer.get_name() == "headless":
		return
	var fotografo := Doce3D.new()
	fotografo.giravel = false
	fotografo.distancia = 4.4  # mais perto: o doce ocupa a foto toda
	fotografo.angulo_inicial = -0.25
	fotografo.custom_minimum_size = Vector2(TAMANHO_MINIATURA, TAMANHO_MINIATURA)
	fotografo.size = fotografo.custom_minimum_size
	fotografo.position = Vector2(-TAMANHO_MINIATURA * 3, 0)  # fora da tela
	add_child(fotografo)
	fotografo.set_process(false)  # parado, sem piscar
	fotografo._viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for doce in faltam:
		fotografo.mostrar(doce["id"])
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if not is_inside_tree():
			return
		var foto := fotografo._viewport.get_texture().get_image()
		if foto == null or foto.is_empty():
			continue
		_miniaturas[doce["id"]] = ImageTexture.create_from_image(foto)
		var imagem: TextureRect = _cartoes[doce["id"]].find_child("Imagem", true, false)
		imagem.texture = _miniaturas[doce["id"]]
	fotografo.queue_free()
