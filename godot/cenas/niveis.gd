extends Control
## Escolha do nível (fácil, médio, difícil), revisão das perguntas erradas e
## menu lateral.

const CARTAO := preload("res://componentes/cartao_nivel.tscn")


func _ready() -> void:
	if not Telas.placa_rapida:
		# sem a vila (aparelho sem placa de vídeo): nível, missões e baús aqui
		var progresso := BotoesProgresso.new()
		progresso.name = "Progresso"
		progresso.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
		progresso.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		add_child(progresso)
	%Inicio.pressed.connect(Telas.voltar)  # volta para a vila (ou o início)
	%Titulos.pressed.connect(Telas.abrir.bind("titulos"))
	%Colecao.pressed.connect(Telas.abrir.bind("colecao"))
	%Confeitaria.pressed.connect(Telas.abrir_confeitaria)
	%DoceMatch.pressed.connect(Telas.abrir.bind("doce_match"))
	%Laboratorio.pressed.connect(Telas.abrir.bind("laboratorio"))
	%ComoJogar.pressed.connect(Telas.abrir.bind("como_jogar"))
	%Creditos.pressed.connect(Telas.abrir.bind("creditos"))
	%Configuracoes.pressed.connect(Telas.abrir.bind("configuracoes"))
	if Telas.placa_rapida:
		# com a vila, o menu do lado fica só com a volta e os OUTROS JOGOS
		# (acabou o quiz, já vai para outro sem passar pela vila). Troféus e
		# coleção ficam na vila; como jogar, créditos e ajustes, no início.
		for botao in [%Titulos, %Colecao, %ComoJogar, %Creditos, %Configuracoes]:
			botao.visible = false
		%Inicio.tooltip_text = "Voltar para a vila"
	for i in Jogo.niveis.size():
		var cartao := CARTAO.instantiate()
		%Cartoes.add_child(cartao)
		cartao.configurar(i, Jogo.niveis[i])
		Animacoes.entrar(cartao, Vector2(0, 50), 0.08 * i)
	_criar_botao_revisao()


## "REVISAR ERROS (n)": aparece quando há perguntas erradas para rever.
func _criar_botao_revisao() -> void:
	var erradas := Jogo.perguntas_para_revisar().size()
	if erradas == 0:
		return
	var botao := Button.new()
	botao.name = "Revisar"
	botao.theme_type_variation = &"BotaoRoxo"
	botao.text = "REVISAR ERROS (%d)" % erradas
	botao.icon = preload("res://assets/icones/lampada.svg")
	botao.add_theme_constant_override("icon_max_width", 34)
	botao.add_theme_color_override("icon_normal_color", Cores.AMARELO)
	botao.add_theme_color_override("icon_hover_color", Cores.AMARELO)
	botao.add_theme_color_override("icon_pressed_color", Cores.AMARELO)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.pressed.connect(Jogo.iniciar_revisao)
	Animacoes.destacar_ao_passar(botao)
	%Cartoes.get_parent().add_child(botao)
	Animacoes.entrar(botao, Vector2(0, 30), 0.3)
