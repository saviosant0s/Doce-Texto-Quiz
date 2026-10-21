class_name PainelAmigos
extends Control
## Painel AMIGOS da vila (regras em scripts/amigos.gd):
## - esquerda: o seu nome, o CÓDIGO DA VILA (COPIAR / ENVIAR PELO WHATSAPP) e
##   ADICIONAR AMIGO (colar o código que ele mandou);
## - direita: RANKING DA SEMANA (você e os amigos), com VISITAR e remover.

const FOTOS := "res://assets/doces_3d/fotos/%s.png"
const OURO := Color("#FFD23F")

var _nome: LineEdit
var _codigo: Label
var _colar: LineEdit
var _ranking: VBoxContainer
var _semana: Label


func _ready() -> void:
	name = "PainelAmigos"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.55)
	escuro.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(escuro)
	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, 40)
	for lado in ["top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 22)
	add_child(margem)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	painel.add_child(coluna)
	var topo := HBoxContainer.new()
	coluna.add_child(topo)
	var titulo := _texto(topo, "AMIGOS", 44, OURO)
	titulo.size_flags_horizontal = SIZE_EXPAND_FILL
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var fechar_botao := _botao("Fechar", "FECHAR", &"BotaoSecundario", fechar)
	fechar_botao.custom_minimum_size = Vector2(150, 54)
	topo.add_child(fechar_botao)
	var lados := HBoxContainer.new()
	lados.add_theme_constant_override("separation", 22)
	lados.size_flags_vertical = SIZE_EXPAND_FILL
	coluna.add_child(lados)
	_montar_meu_codigo(lados)
	_montar_ranking(lados)
	atualizar()


func _montar_meu_codigo(pai: Control) -> void:
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 8)
	lado.size_flags_horizontal = SIZE_EXPAND_FILL
	pai.add_child(lado)
	_texto(lado, "SEU NOME", 22, OURO, true)
	var linha_nome := HBoxContainer.new()
	linha_nome.add_theme_constant_override("separation", 8)
	lado.add_child(linha_nome)
	_nome = LineEdit.new()
	_nome.name = "Nome"
	_nome.placeholder_text = "COMO OS AMIGOS VÃO TE VER"
	_nome.max_length = Amigos.NOME_MAXIMO
	_nome.text = Amigos.nome()
	_nome.size_flags_horizontal = SIZE_EXPAND_FILL
	_nome.custom_minimum_size = Vector2(0, 50)
	_nome.add_theme_font_size_override("font_size", 22)
	_nome.text_submitted.connect(func(_t: String): _salvar_nome())
	linha_nome.add_child(_nome)
	linha_nome.add_child(_botao("SalvarNome", "SALVAR", &"Button", _salvar_nome))
	_texto(lado, "CÓDIGO DA SUA VILA", 22, OURO, true)
	var caixa := PanelContainer.new()
	caixa.theme_type_variation = &"PainelEscuro"
	lado.add_child(caixa)
	_codigo = Label.new()
	_codigo.name = "Codigo"
	_codigo.theme_type_variation = &"TextoClaro"
	_codigo.add_theme_font_size_override("font_size", 15)
	_codigo.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_codigo.max_lines_visible = 3
	_codigo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caixa.add_child(_codigo)
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 8)
	lado.add_child(botoes)
	botoes.add_child(_botao("Copiar", "COPIAR CÓDIGO", &"Button", copiar))
	botoes.add_child(_botao("WhatsApp", "ENVIAR PELO WHATSAPP", &"BotaoComprar", enviar_whatsapp))
	_texto(lado, "ADICIONAR AMIGO", 22, OURO, true)
	var linha_colar := HBoxContainer.new()
	linha_colar.add_theme_constant_override("separation", 8)
	lado.add_child(linha_colar)
	_colar = LineEdit.new()
	_colar.name = "CodigoAmigo"
	_colar.placeholder_text = "COLE AQUI O CÓDIGO DO AMIGO"
	_colar.size_flags_horizontal = SIZE_EXPAND_FILL
	_colar.custom_minimum_size = Vector2(0, 50)
	_colar.add_theme_font_size_override("font_size", 18)
	_colar.text_submitted.connect(func(_t: String): adicionar())
	linha_colar.add_child(_colar)
	linha_colar.add_child(_botao("Colar", "COLAR", &"Button", func(): _colar.text = DisplayServer.clipboard_get()))
	var adicionar_botao := _botao("Adicionar", "ADICIONAR AMIGO", &"BotaoComprar", adicionar)
	lado.add_child(adicionar_botao)
	var explica := _texto(lado, "Mande o seu código para os amigos e cole o deles aqui. Visitar um amigo dá +%d açúcar e +%d moedas (uma vez por dia)." % [
		Amigos.PREMIO_VISITA["acucar"], Amigos.PREMIO_VISITA["moedas"]], 17, Color.WHITE, true)
	explica.modulate.a = 0.85


func _montar_ranking(pai: Control) -> void:
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 6)
	lado.size_flags_horizontal = SIZE_EXPAND_FILL
	pai.add_child(lado)
	_texto(lado, "RANKING DA SEMANA", 26, OURO, true)
	_semana = _texto(lado, "", 17, Color.WHITE, true)
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lado.add_child(rolagem)
	_ranking = VBoxContainer.new()
	_ranking.name = "Ranking"
	_ranking.size_flags_horizontal = SIZE_EXPAND_FILL
	_ranking.add_theme_constant_override("separation", 6)
	rolagem.add_child(_ranking)
	var pontos := []
	for evento in ["acertos", "lab_fases", "corrida", "chefao"]:
		pontos.append("%s %d" % [{"acertos": "acerto no quiz", "lab_fases": "fase do laboratório",
			"corrida": "corrida", "chefao": "chefão"}[evento], Amigos.PONTOS[evento]])
	var regra := _texto(lado, "Pontos: " + ", ".join(pontos) + "... Zeram toda segunda.", 16, Color.WHITE, true)
	regra.modulate.a = 0.8


func atualizar() -> void:
	_codigo.text = Amigos.meu_codigo()
	_semana.text = "SEMANA DE %s" % Amigos.texto_semana()
	for filho in _ranking.get_children():
		filho.queue_free()
	var linhas := Amigos.ranking()
	for posicao in linhas.size():
		_linha_ranking(posicao, linhas[posicao])
	if linhas.size() == 1:
		var vazio := _texto(_ranking, "Ainda sem amigos: mande o seu código e cole o deles do lado esquerdo!", 18, Color.WHITE, true)
		vazio.modulate.a = 0.85


func _linha_ranking(posicao: int, l: Dictionary) -> void:
	var fundo := PanelContainer.new()
	fundo.name = "Linha%d" % posicao
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#FFD23F", 0.28) if l["eu"] else Color(1, 1, 1, 0.1)
	estilo.set_corner_radius_all(14)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 8
	estilo.content_margin_top = 2
	estilo.content_margin_bottom = 2
	fundo.add_theme_stylebox_override("panel", estilo)
	_ranking.add_child(fundo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	fundo.add_child(linha)
	var lugar := _texto(linha, "%dº" % (posicao + 1), 26, [OURO, Color("#E4E4F0"), Color("#E0A95E")][posicao] if posicao < 3 else Color.WHITE)
	lugar.custom_minimum_size.x = 44
	var foto := TextureRect.new()
	if ResourceLoader.exists(FOTOS % l["doce"]):
		foto.texture = load(FOTOS % l["doce"])
	foto.custom_minimum_size = Vector2(44, 44)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(foto)
	var nome := _texto(linha, ("%s (VOCÊ)" % l["nome"]) if l["eu"] and l["nome"] != "VOCÊ" else str(l["nome"]), 22, Color.WHITE)
	nome.size_flags_horizontal = SIZE_EXPAND_FILL
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nome.clip_text = true
	var pontos := _texto(linha, "%d PTS" % l["pontos"] if l["atual"] else "CÓDIGO ANTIGO", 20 if l["atual"] else 15, OURO if l["atual"] else Color(1, 1, 1, 0.6))
	pontos.tooltip_text = "" if l["atual"] else "O código é de outra semana: peça o código novo"
	if not l["eu"]:
		var visitar := _botao("Visitar_" + l["i"], "VISITAR", &"BotaoComprar", func(): visitar_amigo(l["i"]))
		visitar.custom_minimum_size = Vector2(120, 46)
		visitar.add_theme_font_size_override("font_size", 20)
		linha.add_child(visitar)
		var tirar := _botao("Remover_" + l["i"], "X", &"BotaoSecundario", func(): remover_amigo(l["i"]))
		tirar.custom_minimum_size = Vector2(46, 46)
		tirar.tooltip_text = "Remover amigo"
		linha.add_child(tirar)


# --- Ações --------------------------------------------------------------------------

func _salvar_nome() -> void:
	_nome.text = Amigos.escolher_nome(_nome.text)
	Telas.mostrar_aviso("NOME SALVO: " + _nome.text if _nome.text != "" else "ESCREVA UM NOME")
	atualizar()


func _conferir_nome() -> bool:
	if Amigos.nome() == "" and _nome.text.strip_edges() != "":
		Amigos.escolher_nome(_nome.text)
	if Amigos.nome() == "":
		Telas.mostrar_aviso("ESCREVA O SEU NOME PRIMEIRO (É ASSIM QUE OS AMIGOS VÃO TE VER)")
		_nome.grab_focus()
		return false
	return true


func copiar() -> void:
	if not _conferir_nome():
		return
	DisplayServer.clipboard_set(Amigos.mensagem())
	Telas.mostrar_aviso("CÓDIGO COPIADO! COLE NA CONVERSA COM OS SEUS AMIGOS")


func enviar_whatsapp() -> void:
	if not _conferir_nome():
		return
	OS.shell_open("https://wa.me/?text=" + Amigos.mensagem().uri_encode())


func adicionar() -> void:
	var r := Amigos.adicionar(_colar.text)
	Telas.mostrar_aviso(r["texto"])
	if r["ok"]:
		_colar.text = ""
		Audio.tocar("construir")
		atualizar()
	else:
		Audio.tocar("erro")


func visitar_amigo(id: String) -> void:
	var a := Amigos.amigo(id)
	if a.is_empty():
		return
	Audio.tocar("porta")
	Vila.visitar(a)


func remover_amigo(id: String) -> void:
	var a := Amigos.amigo(id)
	if a.is_empty():
		return
	if await Telas.confirmar("REMOVER %s?" % a["n"], "Ele sai do seu ranking. Para adicionar de novo, é só colar o código dele.", "REMOVER", "CANCELAR"):
		Amigos.remover(id)
		atualizar()


func fechar() -> void:
	queue_free()


# --- Peças --------------------------------------------------------------------------

func _texto(pai: Control, texto: String, tamanho: int, cor: Color, quebra := false) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 24 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.text = texto
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if quebra:
		rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rotulo.custom_minimum_size.x = 200
	pai.add_child(rotulo)
	return rotulo


func _botao(nome: String, texto: String, estilo: StringName, acao: Callable) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.text = texto
	botao.theme_type_variation = estilo
	botao.custom_minimum_size = Vector2(0, 50)
	botao.add_theme_font_size_override("font_size", 20)
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(acao)
	return botao
