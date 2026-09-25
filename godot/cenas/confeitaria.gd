extends Control
## Minha Confeitaria, painel simples (aparelhos sem placa de vídeo; com placa,
## a confeitaria é a cozinha 3D em cenas/cozinha.*): as máquinas de doces
## (construir, melhorar, vender a bandeja). O açúcar vem dos acertos no quiz.
## Regras em scripts/confeitaria.gd.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")
const ICONE_ACUCAR := preload("res://assets/icones/acucar.svg")
const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const ICONE_COLECAO := preload("res://assets/icones/doce.svg")
const ICONE_AJUDA := preload("res://assets/icones/interrogacao.svg")
const NOMES_NIVEIS := ["FÁCIL", "MÉDIO", "DIFÍCIL"]
const INTERVALO := 0.2  # segundos entre uma conta e outra das máquinas

var _rotulo_acucar: Label
var _rotulo_moedas: Label
var _cartoes := {}  # id da máquina -> {cartao, imagem, barra, ...}
var _relogio := 0.0


func _ready() -> void:
	var prontos := Confeitaria.atualizar()
	if prontos > 0:
		Progresso.salvar()
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, 40)
	margem.add_theme_constant_override("margin_top", 28)
	margem.add_theme_constant_override("margin_bottom", 22)
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 16)
	margem.add_child(coluna)
	coluna.add_child(_criar_topo())
	var maquinas := HBoxContainer.new()
	maquinas.name = "Maquinas"
	maquinas.size_flags_vertical = SIZE_EXPAND_FILL
	maquinas.add_theme_constant_override("separation", 16)
	coluna.add_child(maquinas)
	for i in Confeitaria.MAQUINAS.size():
		var m: Dictionary = Confeitaria.MAQUINAS[i]
		maquinas.add_child(_criar_cartao(m))
		Animacoes.entrar(_cartoes[m["id"]]["cartao"], Vector2(0, 40), 0.07 * i)
	coluna.add_child(_criar_baixo())
	_atualizar_tudo()
	if not Progresso.config.get("viu_confeitaria", false):
		_explicar.call_deferred()


func _process(delta: float) -> void:
	_relogio += delta
	if _relogio < INTERVALO:
		return
	_relogio = 0.0
	var prontos := Confeitaria.atualizar()
	if prontos > 0:
		Progresso.salvar()
		Audio.tocar("acerto")
		_atualizar_tudo()
		return
	for m in Confeitaria.MAQUINAS:  # só as barrinhas andando
		_cartoes[m["id"]]["barra"].value = Confeitaria.andamento(m["id"])


func _exit_tree() -> void:
	Confeitaria.atualizar()
	Progresso.salvar()


## Primeira visita: como funciona a confeitaria.
func _explicar() -> void:
	Progresso.config["viu_confeitaria"] = true
	Progresso.salvar()
	var jogar := await Telas.confirmar("MINHA CONFEITARIA",
		"Cada acerto no quiz dá %d de açúcar. As máquinas transformam açúcar em doces " % Confeitaria.ACUCAR_POR_ACERTO
		+ "sozinhas e põem na bandeja. Venda as bandejas para ganhar moedas e use as moedas "
		+ "para melhorar as máquinas.",
		"JOGAR O QUIZ", "ENTENDI")
	if jogar:
		Telas.abrir("niveis")


# --- Montagem ---------------------------------------------------------------------

func _criar_topo() -> HBoxContainer:
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	var voltar := _botao_icone("Voltar", ICONE_VOLTAR)
	voltar.pressed.connect(Telas.voltar)
	topo.add_child(voltar)
	var titulo := PanelContainer.new()
	titulo.theme_type_variation = &"EtiquetaAmarela"
	titulo.size_flags_vertical = SIZE_SHRINK_CENTER
	var texto := Label.new()
	texto.theme_type_variation = &"Titulo"
	texto.text = "MINHA CONFEITARIA"
	titulo.add_child(texto)
	topo.add_child(titulo)
	var espaco := Control.new()
	espaco.size_flags_horizontal = SIZE_EXPAND_FILL
	topo.add_child(espaco)
	_rotulo_acucar = _etiqueta(topo, "Acucar", ICONE_ACUCAR, Color.WHITE)
	_rotulo_moedas = _etiqueta(topo, "Moedas", ICONE_MOEDA, Cores.AMARELO)
	var ajuda := _botao_icone("Ajuda", ICONE_AJUDA)
	ajuda.pressed.connect(_explicar)
	topo.add_child(ajuda)
	var colecao := _botao_icone("Colecao", ICONE_COLECAO)
	colecao.pressed.connect(Telas.abrir.bind("colecao"))
	topo.add_child(colecao)
	return topo


func _botao_icone(nome: String, icone: Texture2D) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.theme_type_variation = &"BotaoIconeAmarelo"
	botao.custom_minimum_size = Vector2(68, 68)
	botao.icon = icone
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return botao


## Etiqueta roxa com ícone e número (açúcar, estoque, moedas). Retorna o texto.
func _etiqueta(pai: Control, nome: String, icone: Texture2D, cor: Color) -> Label:
	var etiqueta := PanelContainer.new()
	etiqueta.name = nome
	etiqueta.theme_type_variation = &"Etiqueta"
	etiqueta.size_flags_vertical = SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	etiqueta.add_child(linha)
	var imagem := TextureRect.new()
	imagem.texture = icone
	imagem.modulate = cor
	imagem.custom_minimum_size = Vector2(30, 30)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.size_flags_vertical = SIZE_SHRINK_CENTER
	linha.add_child(imagem)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 34)
	linha.add_child(rotulo)
	pai.add_child(etiqueta)
	return rotulo


## Cartão de uma máquina: nome, nível (estrelas), o doce que ela faz, barra do
## próximo doce, situação, estoque e os botões.
func _criar_cartao(m: Dictionary) -> PanelContainer:
	var cartao := PanelContainer.new()
	cartao.name = m["id"]
	cartao.size_flags_horizontal = SIZE_EXPAND_FILL
	cartao.add_theme_stylebox_override("panel", get_theme_stylebox("normal", &"CartaoNivel"))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	cartao.add_child(coluna)
	var nome := Label.new()
	nome.theme_type_variation = &"Subtitulo"
	nome.add_theme_font_size_override("font_size", 26)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.text = m["nome"]
	coluna.add_child(nome)
	var estrelas := HBoxContainer.new()
	estrelas.alignment = BoxContainer.ALIGNMENT_CENTER
	estrelas.add_theme_constant_override("separation", 2)
	for i in Confeitaria.NIVEL_MAXIMO:
		var estrela := TextureRect.new()
		estrela.texture = ICONE_ESTRELA
		estrela.custom_minimum_size = Vector2(24, 24)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrela.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		estrelas.add_child(estrela)
	coluna.add_child(estrelas)
	var imagem := TextureRect.new()
	imagem.name = "Imagem"
	imagem.custom_minimum_size = Vector2(0, 96)
	imagem.size_flags_vertical = SIZE_EXPAND_FILL
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.texture = Personagens.textura(m["doce"])
	coluna.add_child(imagem)
	var barra := ProgressBar.new()
	barra.name = "Barra"
	barra.max_value = 1.0
	barra.step = 0.0
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 18)
	coluna.add_child(barra)
	var situacao := Label.new()
	situacao.name = "Situacao"
	situacao.theme_type_variation = &"Texto"
	situacao.add_theme_font_size_override("font_size", 17)
	situacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	situacao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	coluna.add_child(situacao)
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 8)
	coluna.add_child(botoes)
	var vender := _botao_acao("Vender", &"BotaoRoxo")
	vender.pressed.connect(_vender.bind(m))
	botoes.add_child(vender)
	var principal := _botao_acao("Principal")
	principal.pressed.connect(_acao_principal.bind(m))
	botoes.add_child(principal)
	_cartoes[m["id"]] = {"cartao": cartao, "imagem": imagem, "barra": barra, "situacao": situacao,
		"estrelas": estrelas, "vender": vender, "principal": principal}
	return cartao


func _botao_acao(nome: String, variacao := &"") -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.theme_type_variation = variacao
	botao.custom_minimum_size = Vector2(0, 52)
	botao.size_flags_horizontal = SIZE_EXPAND_FILL
	botao.add_theme_font_size_override("font_size", 24)
	botao.clip_text = true
	return botao


## Parte de baixo: dica de como ganhar açúcar e o aumento do "carregar".
func _criar_baixo() -> HBoxContainer:
	var baixo := HBoxContainer.new()
	baixo.add_theme_constant_override("separation", 16)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelEscuro"
	painel.size_flags_horizontal = SIZE_EXPAND_FILL
	baixo.add_child(painel)
	var dica := Label.new()
	dica.theme_type_variation = &"TextoClaro"
	dica.add_theme_font_size_override("font_size", 20)
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dica.text = "CADA ACERTO NO QUIZ DÁ %d DE AÇÚCAR. AS MÁQUINAS FAZEM OS DOCES SOZINHAS; VENDA A BANDEJA PARA GANHAR MOEDAS." % Confeitaria.ACUCAR_POR_ACERTO
	painel.add_child(dica)
	return baixo


# --- Atualização da tela ------------------------------------------------------------

func _atualizar_tudo() -> void:
	_rotulo_acucar.text = Jogo.formatar(Confeitaria.acucar())
	_rotulo_moedas.text = Jogo.formatar(Progresso.moedas)
	for m in Confeitaria.MAQUINAS:
		_atualizar_cartao(m)


func _atualizar_cartao(m: Dictionary) -> void:
	var id: String = m["id"]
	var c: Dictionary = _cartoes[id]
	var nivel := Confeitaria.nivel(id)
	for i in c["estrelas"].get_child_count():
		c["estrelas"].get_child(i).modulate = Cores.OURO if i < nivel else Color(Cores.ROXO, 0.18)
	var imagem: TextureRect = c["imagem"]
	var vender: Button = c["vender"]
	var principal: Button = c["principal"]
	var situacao: Label = c["situacao"]
	var barra: ProgressBar = c["barra"]
	barra.value = Confeitaria.andamento(id)
	if not Confeitaria.liberada(id):
		imagem.material = Personagens.material_silhueta()
		barra.visible = false
		situacao.text = "PASSE NO NÍVEL %s" % NOMES_NIVEIS[m["nivel_quiz"]]
		vender.visible = false
		principal.text = "BLOQUEADA"
		principal.disabled = true
		return
	imagem.material = null
	vender.visible = Confeitaria.construida(id)
	barra.visible = Confeitaria.construida(id)
	if not Confeitaria.construida(id):
		imagem.modulate = Color(1, 1, 1, 0.55)
		situacao.text = "%d DE AÇÚCAR POR DOCE" % m["acucar"]
		principal.text = "CONSTRUIR GRÁTIS" if m["construir"] == 0 else "CONSTRUIR · %s" % Jogo.formatar(m["construir"])
		principal.disabled = Progresso.moedas < m["construir"]
		return
	imagem.modulate = Color.WHITE
	var parada := Confeitaria.parada(id)
	if parada == "SEM AÇÚCAR":
		situacao.text = "SEM AÇÚCAR: JOGUE O QUIZ"
	elif not parada.is_empty():
		situacao.text = "BANDEJA CHEIA: VENDA"
	else:
		situacao.text = "1 A CADA %ss · %d DE AÇÚCAR" % [String.num(Confeitaria.tempo(id), 1).trim_suffix(".0"), m["acucar"]]
	situacao.add_theme_color_override("font_color", Cores.VERMELHO if not parada.is_empty() else Cores.ROXO)
	var quantos := Confeitaria.bandeja(id)
	vender.text = "VENDER %d/%d · +%d" % [quantos, Confeitaria.capacidade_bandeja(id), quantos * Confeitaria.valor(id)]
	vender.disabled = quantos == 0
	var preco := Confeitaria.preco(id)
	if preco < 0:
		principal.text = "NÍVEL MÁXIMO"
		principal.disabled = true
	else:
		principal.text = "MELHORAR · %s" % Jogo.formatar(preco)
		principal.disabled = Progresso.moedas < preco


# --- Ações ------------------------------------------------------------------------------

func _acao_principal(m: Dictionary) -> void:
	var id: String = m["id"]
	var nova := not Confeitaria.construida(id)
	if Confeitaria.construir_ou_melhorar(id):
		Audio.tocar("acerto")
		Telas.mostrar_aviso(("%s CONSTRUÍDA!" % m["nome"]) if nova else ("%s: NÍVEL %d!" % [m["nome"], Confeitaria.nivel(id)]))
		Animacoes.pular(_cartoes[id]["imagem"], 18.0, 0.0)
	_atualizar_tudo()


func _vender(m: Dictionary) -> void:
	var ganho := Confeitaria.vender_bandeja(m["id"])
	if ganho > 0:
		Audio.tocar("acerto")
		Telas.mostrar_aviso("+%d MOEDAS" % ganho)
	_atualizar_tudo()
