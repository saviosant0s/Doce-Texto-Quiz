extends Control
## Tela inicial: logo, mascote e botões de jogar, como jogar e créditos.


func _ready() -> void:
	%Versao.text = Jogo.versao()
	%Jogar.pressed.connect(Jogo.ir_para.bind("niveis"))
	%ComoJogar.pressed.connect(Jogo.abrir.bind("como_jogar"))
	%Creditos.pressed.connect(Jogo.abrir.bind("creditos"))
	var mascote := _preparar_mascote()
	Animacoes.entrar(%Logo, Vector2(-60, 0))
	Animacoes.entrar(mascote, Vector2(60, 0), 0.1)


## Se houver um modelo 3D do mascote (assets/mascote_3d/mascote.glb), troca a
## imagem por ele, que gira com o dedo. Senão, o mascote 2D só flutua.
func _preparar_mascote() -> Control:
	if not ResourceLoader.exists(Mascote3D.MODELO):
		Animacoes.flutuar(%Mascote)
		return %Mascote
	var mascote_3d := Mascote3D.new()
	mascote_3d.custom_minimum_size = Vector2(520, 500)
	mascote_3d.tooltip_text = "Arraste para girar"
	%Mascote.add_sibling(mascote_3d)
	%Mascote.queue_free()
	return mascote_3d
