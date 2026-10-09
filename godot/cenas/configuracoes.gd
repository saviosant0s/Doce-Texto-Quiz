extends Control
## Configurações: volume da música e dos efeitos, animações e apagar progresso.

const ICONE_SOM := preload("res://assets/icones/som.svg")
const ICONE_ESTRELA := Itens.ESTRELA


func _ready() -> void:
	%Voltar.pressed.connect(_voltar)
	%Versao.text = Telas.versao()
	%Apagar.pressed.connect(_apagar_progresso)
	_criar_volume("MÚSICA", "volume_musica", false)
	_criar_volume("EFEITOS SONOROS", "volume_efeitos", true)
	_criar_chave_animacoes()
	_criar_qualidade()
	_criar_chave_dia()
	_criar_chave_desempenho()
	_criar_botao_abertura()
	# os textos das chaves quebram a linha (inteiros, deixavam a tela mais
	# larga que o celular: a versão e as bordas ficavam cortadas)
	for chave in %Linhas.find_children("*", "CheckButton", true, false):
		chave.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		chave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_atualizar_resumo()
	Animacoes.entrar(%Coluna, Vector2(0, 30))


## Linha com nome, controle deslizante (0 a 100%) e o valor atual.
func _criar_volume(nome: String, chave: String, tocar_exemplo: bool) -> void:
	var linha := VBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	var topo := HBoxContainer.new()
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Texto"
	rotulo.text = nome
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var valor := Label.new()
	valor.theme_type_variation = &"Subtitulo"
	topo.add_child(rotulo)
	topo.add_child(valor)
	linha.add_child(topo)

	var controle := HSlider.new()
	controle.min_value = 0
	controle.max_value = 100
	controle.step = 5
	controle.custom_minimum_size = Vector2(0, 32)
	controle.value = roundf(Progresso.config.get(chave, 1.0) * 100)
	valor.text = "%d%%" % controle.value
	controle.value_changed.connect(func(v: float):
		Progresso.config[chave] = v / 100.0
		valor.text = "%d%%" % v
		Audio.aplicar_volumes())
	controle.drag_ended.connect(func(_mudou):
		Progresso.salvar()
		if tocar_exemplo:
			Audio.tocar("acerto"))
	linha.add_child(controle)
	%Linhas.add_child(linha)


func _criar_chave_animacoes() -> void:
	var chave := CheckButton.new()
	chave.text = "Animações de fundo (mascote, estrelas, confete)"
	chave.button_pressed = Progresso.config.get("animacoes", true)
	chave.toggled.connect(func(ligado: bool):
		Progresso.config["animacoes"] = ligado
		Progresso.salvar())
	%Linhas.add_child(chave)
	if not Telas.placa_rapida:
		# (sem placa de vídeo as animações ficam desligadas para não travar;
		# o aviso vai no próprio texto, sem ocupar outra linha)
		chave.text = "Animações de fundo (desligadas: aparelho sem aceleração de vídeo)"
		chave.disabled = true


## Gráficos: BAIXA / MÉDIA / ALTA (grama, sombras, nitidez do 3D).
func _criar_qualidade() -> void:
	var linha := HBoxContainer.new()
	linha.name = "Qualidade"
	linha.add_theme_constant_override("separation", 8)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Texto"
	rotulo.text = "GRÁFICOS"
	rotulo.tooltip_text = "Se a vila ou a cozinha ficarem lentas, use MÉDIA ou BAIXA."
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	var grupo := ButtonGroup.new()
	var niveis := Qualidade.NOMES.size() if Qualidade.tem_ultra() else Qualidade.ULTRA
	for i in niveis:
		var botao := Button.new()
		botao.name = "Qualidade%d" % i
		botao.text = Qualidade.NOMES[i]
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.button_pressed = i == Qualidade.escolhida()
		botao.custom_minimum_size = Vector2(110, 46)
		botao.add_theme_font_size_override("font_size", 24)
		botao.theme_type_variation = &"BotaoRoxo" if i == Qualidade.escolhida() else &"BotaoSecundario"
		if i == Qualidade.ULTRA:
			botao.tooltip_text = "Super realista: sombras de contato, reflexo na água e raios de sol. Para placa de vídeo forte; o jogo reinicia."
		botao.pressed.connect(func():
			if i == Qualidade.ULTRA and not Qualidade.ultra_ativo():
				if not await Telas.confirmar("GRÁFICOS ULTRA", "Super realista: sombra de contato, reflexo dos prédios na água e raios de sol na névoa. Precisa de placa de vídeo forte (se ficar lento, ele volta sozinho para ALTA). O jogo vai reiniciar.", "REINICIAR", "CANCELAR"):
					_marcar_qualidade(linha, Qualidade.escolhida())
					return
				Qualidade.escolher(i)
				Qualidade.reiniciar_se_precisar(get_tree())
				return
			Qualidade.escolher(i)
			Telas._ajustar_fisica()
			_marcar_qualidade(linha, i))
		linha.add_child(botao)
	%Linhas.add_child(linha)


func _marcar_qualidade(linha: Control, nivel: int) -> void:
	for outro in linha.get_children():
		if outro is Button:
			var escolhido: bool = outro.name == "Qualidade%d" % nivel
			outro.button_pressed = escolhido
			outro.theme_type_variation = &"BotaoRoxo" if escolhido else &"BotaoSecundario"


## Dia e noite na vila: pelo relógio do aparelho ou sempre de dia.
func _criar_chave_dia() -> void:
	var chave := CheckButton.new()
	chave.name = "DiaENoite"
	chave.text = "Dia e noite na vila (desligado: sempre de dia)"
	chave.button_pressed = not CicloDia.sempre_dia()
	chave.toggled.connect(func(ligado: bool): CicloDia.escolher_sempre_dia(not ligado))
	%Linhas.add_child(chave)


func _criar_chave_desempenho() -> void:
	var chave := CheckButton.new()
	chave.name = "Desempenho"
	chave.text = "Mostrar desempenho (FPS e memória, para testes)"
	chave.button_pressed = bool(Progresso.config.get("desempenho", false))
	chave.toggled.connect(func(ligado: bool):
		Progresso.config["desempenho"] = ligado
		Progresso.salvar()
		Telas.mostrar_desempenho(ligado))
	%Linhas.add_child(chave)


## Ver de novo a abertura animada da vila (AberturaVila).
func _criar_botao_abertura() -> void:
	var botao := Button.new()
	botao.name = "VerAbertura"
	botao.text = "VER A ABERTURA DO JOGO"
	botao.theme_type_variation = &"BotaoSecundario"
	botao.custom_minimum_size = Vector2(0, 56)
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(func():
		Progresso.salvar()
		Vila.abrir_com_abertura = true
		Telas.ir_para("vila"))
	# no painel do progresso, embaixo do resumo (a coluna do som já está cheia)
	%Resumo.add_sibling(botao)


func _atualizar_resumo() -> void:
	var estrelas := 0
	for nivel in Progresso.niveis:
		estrelas += nivel["estrelas"]
	var titulos := 0
	for quantidade in Progresso.titulos.values():
		titulos += int(quantidade > 0)
	%Resumo.text = "%d partidas jogadas\n%d de 9 estrelas\n%d de 3 títulos\n%d moedas" % [
		Progresso.estatisticas["partidas"], estrelas, titulos, Progresso.moedas]


func _apagar_progresso() -> void:
	var apagar := await Telas.confirmar(
		"APAGAR TODO O PROGRESSO?",
		"Estrelas, recordes, títulos, moedas e o histórico das perguntas serão apagados. Isso não pode ser desfeito.",
		"APAGAR", "CANCELAR")
	if apagar:
		Progresso.apagar()
		_atualizar_resumo()
		Telas.mostrar_aviso("PROGRESSO APAGADO")


func _voltar() -> void:
	Progresso.salvar()
	Telas.voltar()
