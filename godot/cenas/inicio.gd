extends Control
## Tela inicial: logo, mascote e botões de jogar, como jogar e créditos.


func _ready() -> void:
	%Versao.text = Telas.versao()
	%Jogar.pressed.connect(Telas.ir_para_casa)  # a Vila dos Doces
	%ComoJogar.pressed.connect(Telas.abrir.bind("como_jogar"))
	%Creditos.pressed.connect(Telas.abrir.bind("creditos"))
	%Configuracoes.pressed.connect(Telas.abrir.bind("configuracoes"))
	# a tela inicial é só para começar a jogar: nível, missões e baús ficam na
	# vila (ou na tela dos níveis, em aparelhos sem a vila)
	var mascote := _preparar_mascote()
	Animacoes.entrar(%Logo, Vector2(-60, 0))
	Animacoes.entrar(mascote, Vector2(60, 0), 0.1)


## Se o mascote 3D estiver disponível (ver Mascote3D), troca a imagem por ele,
## que gira com o dedo. Senão, o mascote 2D só flutua.
## O 3D só é montado DEPOIS da animação de entrada: a primeira imagem 3D faz o
## celular travar um instante, e no meio da entrada (tela ainda transparente)
## o boneco aparecia apagado. Assim a entrada fica lisa com a imagem, e o 3D
## aparece por cima com um esmaecer suave quando já está desenhado.
func _preparar_mascote() -> Control:
	if not Mascote3D.disponivel():
		Animacoes.flutuar(%Mascote)
		return %Mascote
	%Mascote.custom_minimum_size = Vector2(520, 500)
	%Mascote.mouse_filter = Control.MOUSE_FILTER_PASS
	_trocar_por_3d.call_deferred()
	return %Mascote


func _trocar_por_3d() -> void:
	await get_tree().create_timer(0.7).timeout  # espera a entrada terminar
	if not is_inside_tree():
		return
	var mascote_3d := Mascote3D.new()
	mascote_3d.name = "Mascote3D"
	mascote_3d.set_anchors_preset(Control.PRESET_FULL_RECT)
	mascote_3d.modulate.a = 0.0
	%Mascote.add_child(mascote_3d)
	await mascote_3d.pronto
	if not is_instance_valid(mascote_3d):
		return
	var tween := mascote_3d.create_tween()
	tween.tween_property(mascote_3d, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(%Mascote, "self_modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		%Mascote.texture = null
		%Mascote.self_modulate.a = 1.0)
