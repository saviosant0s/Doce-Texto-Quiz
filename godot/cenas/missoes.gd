extends Control
## Missões: prêmio por entrar (7 dias seguidos), missões do dia e da semana
## (com RESGATAR) e o nível do jogador. Regras em scripts/missoes.gd e
## scripts/experiencia.gd.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_MOEDA := Itens.MOEDA
const ICONE_ACUCAR := Itens.ACUCAR
const ICONE_CERTO := preload("res://assets/icones/certo.svg")
const ICONE_IR := preload("res://assets/icones/avancar.svg")
const ICONE_XP := Itens.XP
## Ícone do jogo de cada tipo de missão.
const ICONES_TIPO := {
	"acertos": preload("res://assets/icones/interrogacao.svg"), "partidas": preload("res://assets/icones/interrogacao.svg"),
	"estrelas": preload("res://assets/icones/estrela.svg"), "lab_fases": preload("res://assets/icones/laboratorio.svg"),
	"clientes": preload("res://assets/icones/confeitaria.svg"), "match": preload("res://assets/icones/controle.svg"),
	"baus": Itens.BAU_PRATA, "torre": preload("res://assets/icones/torre.svg"),
	"fabrica": preload("res://assets/icones/fabrica.svg"), "corrida": preload("res://assets/icones/bandeira.svg"),
}
const TEXTURAS_BAU := {
	"doce": Itens.BAU_DOCE,
	"prata": Itens.BAU_PRATA,
	"ouro": Itens.BAU_OURO,
}

var _nivel: Label
var _barra_xp: ProgressBar
var _texto_xp: Label
var _botao_baus: Button
var _entrada: HBoxContainer
var _colunas := {}  # "dia"/"semana" -> VBoxContainer


func _ready() -> void:
	_montar()
	_atualizar()
	Telas.dica_primeira_vez("missoes", "MISSÕES",
		"3 missões por dia e 3 por semana. IR leva ao jogo; cumpriu, toque em PEGAR. As 3 dão um baú!")


func ao_voltar() -> void:
	Telas.voltar()


func _atualizar() -> void:
	_nivel.text = "NÍVEL %d" % Experiencia.nivel()
	_barra_xp.max_value = Experiencia.xp_para(Experiencia.nivel())
	_barra_xp.value = Experiencia.xp()
	_texto_xp.text = "%d/%d XP" % [Experiencia.xp(), Experiencia.xp_para(Experiencia.nivel())]
	_botao_baus.text = "BAÚS (%d)" % Baus.total_fechados()
	_montar_entrada()
	_montar_lista("dia")
	_montar_lista("semana")


# --- Montagem -------------------------------------------------------------------------

func _montar() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_preset(PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	margem.add_child(coluna)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	coluna.add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(60, 60)
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
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.text = "MISSÕES"
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	# nível e barra de experiência
	var nivel := VBoxContainer.new()
	nivel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nivel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nivel.add_theme_constant_override("separation", 2)
	topo.add_child(nivel)
	var linha := HBoxContainer.new()
	nivel.add_child(linha)
	_nivel = Label.new()
	_nivel.theme_type_variation = &"TituloClaro"
	_nivel.add_theme_font_size_override("font_size", 30)
	linha.add_theme_constant_override("separation", 12)
	linha.add_child(_nivel)
	_texto_xp = Label.new()
	_texto_xp.theme_type_variation = &"TextoClaro"
	_texto_xp.add_theme_font_size_override("font_size", 18)
	linha.add_child(_texto_xp)
	_barra_xp = ProgressBar.new()
	_barra_xp.theme_type_variation = &"BarraClara"
	_barra_xp.show_percentage = false
	_barra_xp.custom_minimum_size = Vector2(0, 18)
	nivel.add_child(_barra_xp)
	_botao_baus = Button.new()
	_botao_baus.name = "Baus"
	_botao_baus.theme_type_variation = &"Alternativa"
	_botao_baus.icon = TEXTURAS_BAU["doce"]
	_botao_baus.add_theme_constant_override("icon_max_width", 44)
	Itens.sem_tinta(_botao_baus)
	_botao_baus.custom_minimum_size = Vector2(0, 72)
	_botao_baus.pressed.connect(Telas.abrir.bind("baus"))
	topo.add_child(_botao_baus)
	# prêmio por entrar
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelEscuro"
	coluna.add_child(painel)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 6)
	painel.add_child(dentro)
	var titulo_entrada := Label.new()
	titulo_entrada.theme_type_variation = &"SubtituloClaro"
	titulo_entrada.add_theme_font_size_override("font_size", 22)
	titulo_entrada.text = "PRÊMIO POR ENTRAR (VOLTE TODO DIA)"
	dentro.add_child(titulo_entrada)
	_entrada = HBoxContainer.new()
	_entrada.name = "Entrada"
	_entrada.add_theme_constant_override("separation", 10)
	dentro.add_child(_entrada)
	# missões
	var listas := HBoxContainer.new()
	listas.add_theme_constant_override("separation", 20)
	listas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(listas)
	for periodo in ["dia", "semana"]:
		var caixa := PanelContainer.new()
		caixa.theme_type_variation = &"PainelEscuro"
		caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caixa.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # em tablet não estica vazio
		listas.add_child(caixa)
		var lista := VBoxContainer.new()
		lista.name = "Lista_" + periodo
		lista.add_theme_constant_override("separation", 8)
		caixa.add_child(lista)
		_colunas[periodo] = lista


func _limpar(no: Control) -> void:
	for filho in no.get_children():
		no.remove_child(filho)
		filho.queue_free()


func _montar_entrada() -> void:
	_limpar(_entrada)
	var hoje := Missoes.dia_da_sequencia()
	var disponivel := Missoes.entrada_disponivel()
	for i in Missoes.ENTRADA.size():
		var premio: Dictionary = Missoes.ENTRADA[i]
		var numero := i + 1
		var feito := numero < hoje or (numero == hoje and not disponivel)
		var cartao := Button.new()
		cartao.name = "Dia%d" % numero
		cartao.custom_minimum_size = Vector2(150, 96)
		cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cartao.focus_mode = Control.FOCUS_NONE
		var agora := numero == hoje and disponivel
		cartao.theme_type_variation = &"Alternativa" if agora else &"BotaoRoxo"
		cartao.disabled = not agora
		if agora and Telas.animacoes_continuas:
			_pulsar(cartao)
		var texto := "DIA %d\n" % numero
		if premio.has("moedas"):
			texto += "%d MOEDAS" % premio["moedas"]
			cartao.icon = ICONE_MOEDA
			Itens.sem_tinta(cartao)
		elif premio.has("acucar"):
			texto += "%d AÇÚCAR" % premio["acucar"]
			cartao.icon = ICONE_ACUCAR
			Itens.sem_tinta(cartao)
		else:
			texto += Baus.NOMES[premio["bau"]].replace("BAÚ DE ", "BAÚ ")
			cartao.icon = TEXTURAS_BAU[premio["bau"]]
			Itens.sem_tinta(cartao)
		if feito:
			texto = "DIA %d\nPEGO!" % numero
			cartao.icon = ICONE_CERTO
		cartao.text = texto
		cartao.add_theme_font_size_override("font_size", 18)
		cartao.add_theme_constant_override("icon_max_width", 34)
		cartao.pressed.connect(resgatar_entrada)
		_entrada.add_child(cartao)


func _montar_lista(periodo: String) -> void:
	var lista: VBoxContainer = _colunas[periodo]
	_limpar(lista)
	var cabecalho := Label.new()
	cabecalho.theme_type_variation = &"TituloClaro"
	cabecalho.add_theme_font_size_override("font_size", 28)
	cabecalho.text = "MISSÕES DO DIA" if periodo == "dia" else "MISSÕES DA SEMANA"
	lista.add_child(cabecalho)
	var missoes: Array = Missoes.diarias() if periodo == "dia" else Missoes.semanais()
	var premio: Dictionary = Missoes.PREMIO_DIA if periodo == "dia" else Missoes.PREMIO_SEMANA
	for i in missoes.size():
		var m: Dictionary = missoes[i]
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 10)
		lista.add_child(linha)
		var icone := TextureRect.new()
		icone.texture = ICONES_TIPO.get(m["tipo"], ICONE_MOEDA)
		icone.custom_minimum_size = Vector2(52, 52)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(icone)
		var textos := VBoxContainer.new()
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.add_theme_constant_override("separation", 4)
		linha.add_child(textos)
		var nome := Label.new()
		nome.theme_type_variation = &"TituloClaro"
		nome.add_theme_font_size_override("font_size", 22)
		nome.text = Missoes.texto_curto(m)
		nome.tooltip_text = Missoes.texto(m)
		textos.add_child(nome)
		# barra com o número dentro e o prêmio em ícones
		var baixo := HBoxContainer.new()
		baixo.add_theme_constant_override("separation", 8)
		textos.add_child(baixo)
		var barra := ProgressBar.new()
		barra.theme_type_variation = &"BarraClara"
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 24)
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barra.max_value = int(m["meta"])
		barra.value = mini(int(m["progresso"]), int(m["meta"]))
		baixo.add_child(barra)
		var numero := Label.new()
		numero.theme_type_variation = &"TituloClaro"
		numero.add_theme_font_size_override("font_size", 17)
		numero.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
		numero.add_theme_constant_override("outline_size", 6)
		numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		numero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		numero.text = "%d/%d" % [mini(int(m["progresso"]), int(m["meta"])), int(m["meta"])]
		barra.add_child(numero)
		baixo.add_child(Itens.ficha(ICONE_MOEDA, str(premio["moedas"]), 20))
		baixo.add_child(Itens.ficha(ICONE_XP, str(premio["xp"]), 20))
		var botao := Button.new()
		botao.name = "Resgatar_%s_%d" % [periodo, i]
		botao.custom_minimum_size = Vector2(120, 60)
		botao.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		botao.add_theme_font_size_override("font_size", 22)
		botao.focus_mode = Control.FOCUS_NONE
		if m["resgatada"]:
			botao.text = "FEITO!"
			botao.icon = ICONE_CERTO
			botao.add_theme_constant_override("icon_max_width", 26)
			botao.theme_type_variation = &"BotaoRoxo"
			botao.disabled = true
		elif Missoes.cumprida(m):
			botao.text = "PEGAR!"
			botao.theme_type_variation = &"BotaoPremio"
			botao.pressed.connect(resgatar.bind(periodo, i))
			if Telas.animacoes_continuas:
				_pulsar(botao)
		else:
			# ainda fazendo: IR leva direto para o jogo da missão
			botao.text = "IR"
			botao.icon = ICONE_IR
			botao.add_theme_constant_override("icon_max_width", 22)
			botao.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			botao.theme_type_variation = &"BotaoAzul"
			botao.tooltip_text = "Ir jogar: " + Missoes.texto(m)
			botao.pressed.connect(ir_para_missao.bind(m))
		linha.add_child(botao)
	var bonus := HBoxContainer.new()
	bonus.add_theme_constant_override("separation", 8)
	lista.add_child(bonus)
	var bau := TextureRect.new()
	bau.texture = TEXTURAS_BAU["prata" if periodo == "dia" else "ouro"]
	bau.custom_minimum_size = Vector2(48, 42)
	bau.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bau.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bonus.add_child(bau)
	var ganho: bool = Progresso.missoes.get("bonus_dia" if periodo == "dia" else "bonus_semana", false)
	var texto_bonus := Label.new()
	texto_bonus.theme_type_variation = &"SubtituloClaro"
	texto_bonus.add_theme_font_size_override("font_size", 18)
	texto_bonus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texto_bonus.text = ("BAÚ GANHO!" if ganho else "AS 3 = 1 %s" % Baus.NOMES["prata" if periodo == "dia" else "ouro"])
	bonus.add_child(texto_bonus)


# --- Ações ---------------------------------------------------------------------------

func resgatar(periodo: String, indice: int) -> void:
	var premio := Missoes.resgatar(periodo, indice)
	if premio.is_empty():
		return
	Audio.tocar("moeda")
	if premio.has("bau"):
		Audio.tocar("construir")
	Telas.mostrar_premio(premio, "MISSÃO CUMPRIDA!")
	Experiencia.anunciar()
	_atualizar()


## Botão IR: abre o jogo da missão (na vila, a tela de missões está por cima).
func ir_para_missao(m: Dictionary) -> void:
	Audio.tocar("estouro", 1.1, -4.0)
	Telas.abrir(Missoes.cena(m))


func resgatar_entrada() -> void:
	var premio := Missoes.resgatar_entrada()
	if premio.is_empty():
		return
	Audio.tocar("moeda")
	if premio.has("bau"):
		Audio.tocar("construir")
	Telas.mostrar_premio(premio, "PRÊMIO DO DIA %d!" % premio["dia"])
	_atualizar()


func _pulsar(botao: Control) -> void:
	botao.resized.connect(func(): botao.pivot_offset = botao.size / 2)
	var tween := botao.create_tween().set_loops()
	tween.tween_property(botao, "scale", Vector2.ONE * 1.06, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(botao, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
