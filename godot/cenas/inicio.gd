extends Control
## Tela inicial: logo, mascote e botões de jogar, como jogar e créditos.


func _ready() -> void:
	%Versao.text = Telas.versao()
	%Jogar.pressed.connect(Telas.ir_para_casa)  # a Vila dos Doces
	%ComoJogar.pressed.connect(Telas.abrir.bind("como_jogar"))
	%Creditos.pressed.connect(Telas.abrir.bind("creditos"))
	%Configuracoes.pressed.connect(Telas.abrir.bind("configuracoes"))
	# nível, missões e baús no canto de cima
	var progresso := BotoesProgresso.new()
	progresso.name = "Progresso"
	progresso.position = Vector2(28, 28)
	add_child(progresso)
	var mascote := _preparar_mascote()
	Animacoes.entrar(%Logo, Vector2(-60, 0))
	Animacoes.entrar(mascote, Vector2(60, 0), 0.1)


## Se o mascote 3D estiver disponível (ver Mascote3D), troca a imagem por ele,
## que gira com o dedo. Senão, o mascote 2D só flutua.
func _preparar_mascote() -> Control:
	if not Mascote3D.disponivel():
		Animacoes.flutuar(%Mascote)
		return %Mascote
	# o 3D entra por cima do desenho; o desenho só some quando o 3D já
	# apareceu (assim não fica um espaço roxo vazio ao abrir o jogo)
	var mascote_3d := Mascote3D.new()
	mascote_3d.set_anchors_preset(Control.PRESET_FULL_RECT)
	%Mascote.add_child(mascote_3d)
	mascote_3d.pronto.connect(func(): %Mascote.texture = null, CONNECT_ONE_SHOT)
	%Mascote.custom_minimum_size = Vector2(520, 500)
	%Mascote.mouse_filter = Control.MOUSE_FILTER_PASS
	return %Mascote
