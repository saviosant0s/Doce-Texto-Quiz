extends Control
## Minha Coleção: vitrine dos doces 3D. À esquerda, o doce escolhido em 3D
## (gira com o dedo, pula quando tocado) com o botão de comprar ou de escolher
## como companheiro; à direita, a grade com todos os doces.
## Regras e catálogo em scripts/colecao.gd.

const ICONE_MOEDA := Itens.MOEDA
const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")
const ICONE_CORACAO := preload("res://assets/icones/coracao.svg")
const COLUNAS := 4
## Movimento máximo (px) para um toque contar como toque e não como arrasto.
const LIMITE_TOQUE := 14.0


var _selecionado := ""
var _visor: Doce3D
var _nome: Label
var _texto: Label
var _acao: Button
var _raridade: Label
var _bonus: Label
var _pedacos: ProgressBar
var _pedacos_texto: Label
var _melhorar: Button
var _cartoes := {}  # id -> PanelContainer
var _toque_inicio := Vector2.ZERO


func _ready() -> void:
	%Voltar.pressed.connect(Telas.voltar)
	_criar_painel()
	_criar_grade()
	_atualizar_topo()
	var inicial := Colecao.companheiro()
	selecionar(inicial if not inicial.is_empty() else Colecao.LISTA[0]["id"])
	Animacoes.entrar(%Corpo, Vector2(0, 40))
	Telas.dica_primeira_vez("companheiros", "COMPANHEIROS",
		"Cada doce tem uma raridade (a cor da borda) e um BÔNUS, como mais açúcar ou mais tempo no quiz. Escolha um como companheiro: só o bônus dele vale. Com pedaços dos baús, você melhora o nível dele.")


## Mostra o doce `id` no visor 3D e ajusta o botão de ação.
func selecionar(id: String) -> void:
	_selecionado = id
	var doce := Colecao.dados(id)
	_visor.nivel = Companheiros.nivel(id)
	_visor.mostrar(id, not Colecao.tem(id))
	_nome.text = doce["nome"]
	_texto.text = doce["curiosidade"]
	_atualizar_companheiro()
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
	for estado in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color",
			"icon_hover_pressed_color", "icon_disabled_color"]:
		_acao.remove_theme_color_override(estado)  # a moeda (abaixo) tira a tinta
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
		Itens.sem_tinta(_acao)
		if Progresso.moedas >= preco:
			_acao.text = "COMPRAR POR %s" % Jogo.formatar(preco)
		else:
			_acao.text = "FALTAM %s MOEDAS" % Jogo.formatar(preco - Progresso.moedas)
			_acao.disabled = true
	_atualizar_companheiro()


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
	Audio.tocar("moeda")
	_visor.mostrar(id)  # sai da silhueta: agora é seu
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
	painel.custom_minimum_size = Vector2(400, 0)
	%Corpo.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 6)
	painel.add_child(coluna)
	_visor = Doce3D.new()
	_visor.name = "Visor"
	_visor.custom_minimum_size = Vector2(0, 150)
	_visor.size_flags_vertical = SIZE_EXPAND_FILL
	coluna.add_child(_visor)
	_nome = Label.new()
	_nome.theme_type_variation = &"TituloClaro"
	_nome.add_theme_font_size_override("font_size", 38)
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_nome)
	_texto = Label.new()
	_texto.theme_type_variation = &"TextoClaro"
	_texto.add_theme_font_size_override("font_size", 16)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(200, 44)
	_texto.max_lines_visible = 2
	coluna.add_child(_texto)
	_acao = Button.new()
	_acao.name = "Acao"
	_acao.custom_minimum_size = Vector2(0, 56)
	_acao.add_theme_font_size_override("font_size", 28)
	_acao.expand_icon = true
	_acao.add_theme_constant_override("icon_max_width", 30)
	_acao.pressed.connect(_ao_tocar_acao)
	coluna.add_child(_acao)
	_melhorar = Button.new()
	_melhorar.name = "Melhorar"
	_melhorar.theme_type_variation = &"BotaoRoxo"
	_melhorar.custom_minimum_size = Vector2(0, 50)
	_melhorar.add_theme_font_size_override("font_size", 22)
	_melhorar.pressed.connect(_ao_melhorar)
	coluna.add_child(_melhorar)
	# raridade, bônus e pedaços (fragmentos dos baús surpresa), logo abaixo do nome
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	coluna.add_child(info)
	coluna.move_child(info, _nome.get_index() + 1)
	_raridade = Label.new()
	_raridade.name = "Raridade"
	_raridade.theme_type_variation = &"TituloClaro"
	_raridade.add_theme_font_size_override("font_size", 22)
	_raridade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(_raridade)
	_bonus = Label.new()
	_bonus.name = "Bonus"
	_bonus.theme_type_variation = &"SubtituloClaro"
	_bonus.add_theme_font_size_override("font_size", 19)
	_bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_bonus)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	info.add_child(linha)
	_pedacos = ProgressBar.new()
	_pedacos.theme_type_variation = &"BarraClara"
	_pedacos.show_percentage = false
	_pedacos.custom_minimum_size = Vector2(0, 18)
	_pedacos.size_flags_horizontal = SIZE_EXPAND_FILL
	_pedacos.size_flags_vertical = SIZE_SHRINK_CENTER
	linha.add_child(_pedacos)
	_pedacos_texto = Label.new()
	_pedacos_texto.theme_type_variation = &"TextoClaro"
	_pedacos_texto.add_theme_font_size_override("font_size", 17)
	linha.add_child(_pedacos_texto)


## Raridade, nível, bônus e pedaços do doce escolhido; botão de melhorar.
func _atualizar_companheiro() -> void:
	var id := _selecionado
	var n := Companheiros.nivel(id)
	_raridade.text = Companheiros.nome_raridade(id) + ("  ·  NÍVEL %d" % n if n > 0 else "")
	_raridade.add_theme_color_override("font_color", Companheiros.cor(id))
	_bonus.text = "BÔNUS: " + Companheiros.descrever_bonus(id)
	var precisa := Companheiros.fragmentos_precisos(id)
	_pedacos.max_value = maxi(precisa, 1)
	_pedacos.value = mini(Companheiros.fragmentos(id), maxi(precisa, 1))
	if precisa == 0:
		_pedacos_texto.text = "NÍVEL MÁXIMO"
	else:
		_pedacos_texto.text = "%d/%d PEDAÇOS" % [Companheiros.fragmentos(id), precisa]
	_melhorar.visible = n >= 1 and n < Companheiros.NIVEL_MAXIMO
	if _melhorar.visible:
		_melhorar.text = "MELHORAR (%d PEDAÇOS + %d MOEDAS)" % [precisa, Companheiros.preco_melhoria(id)]
		_melhorar.disabled = not Companheiros.pode_melhorar(id)


func _ao_melhorar() -> void:
	if not Companheiros.melhorar(_selecionado):
		return
	Audio.tocar("construir")
	var nivel := Companheiros.nivel(_selecionado)
	_visor.nivel = nivel
	_visor.remontar()  # o visual novo do nível (brilhos, laço, coroa...)
	_visor.comemorar()
	var enfeite: String = Doces3D.NOMES_ENFEITES[nivel]
	Telas.mostrar_aviso("%s AGORA É NÍVEL %d!%s" % [Colecao.dados(_selecionado)["nome"], nivel,
		"  GANHOU: " + enfeite if enfeite != "" else ""])
	_atualizar_topo()
	_atualizar_companheiro()
	_atualizar_cartao(_selecionado)


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


## Cartão da grade. Não é um botão: um toque curto seleciona, e arrastar rola
## a lista (botões "prendem" o dedo e a lista não rolava no celular).
func _criar_cartao(doce: Dictionary) -> PanelContainer:
	var cartao := PanelContainer.new()
	cartao.name = doce["id"]
	cartao.custom_minimum_size = Vector2(0, 176)
	cartao.size_flags_horizontal = SIZE_EXPAND_FILL
	cartao.mouse_filter = MOUSE_FILTER_PASS
	cartao.add_theme_stylebox_override("panel", get_theme_stylebox("normal", &"CartaoNivel"))
	cartao.gui_input.connect(_toque_no_cartao.bind(doce["id"]))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 0)
	coluna.mouse_filter = MOUSE_FILTER_IGNORE
	cartao.add_child(coluna)
	var imagem := TextureRect.new()
	imagem.name = "Imagem"
	imagem.size_flags_vertical = SIZE_EXPAND_FILL
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.mouse_filter = MOUSE_FILTER_IGNORE
	imagem.texture = Personagens.textura(doce["id"])
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
func _toque_no_cartao(evento: InputEvent, id: String) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_toque_inicio = evento.global_position
		elif evento.global_position.distance_to(_toque_inicio) < LIMITE_TOQUE:
			selecionar(id)


func _atualizar_cartao(id: String) -> void:
	var cartao: PanelContainer = _cartoes[id]
	var doce := Colecao.dados(id)
	var icone: TextureRect = cartao.find_child("Icone", true, false)
	var texto: Label = cartao.find_child("Texto", true, false)
	var imagem: TextureRect = cartao.find_child("Imagem", true, false)
	var tem := Colecao.tem(id)
	imagem.material = null if tem else Personagens.material_silhueta()
	icone.visible = true
	icone.modulate = Cores.ROXO
	if Colecao.companheiro() == id:
		icone.texture = ICONE_CORACAO
		texto.text = "COMPANHEIRO"
	elif tem:
		icone.visible = false
		texto.text = "NÍVEL %d" % Companheiros.nivel(id)
	elif Companheiros.fragmentos(id) > 0:
		icone.visible = false
		texto.text = "%d/%d PEDAÇOS" % [Companheiros.fragmentos(id), Companheiros.FRAGMENTOS_PARA_GANHAR]
	elif doce.has("titulo"):
		icone.texture = ICONE_CADEADO
		texto.text = "NÍVEL " + Colecao.NIVEL_DO_TITULO[doce["titulo"]]
	else:
		icone.texture = ICONE_MOEDA
		icone.modulate = Color.WHITE  # a moeda tem as cores dela
		texto.text = Jogo.formatar(doce["preco"])


func _marcar_cartao(cartao: PanelContainer, marcado: bool) -> void:
	var estilo: StyleBoxFlat = get_theme_stylebox("normal", &"CartaoNivel").duplicate()
	# borda na cor da raridade (comum, raro, épico, lendário)
	estilo.border_color = Companheiros.cor(cartao.name)
	estilo.set_border_width_all(4)
	if marcado:
		estilo.border_color = Cores.CREME
		estilo.set_border_width_all(5)
	cartao.add_theme_stylebox_override("panel", estilo)
