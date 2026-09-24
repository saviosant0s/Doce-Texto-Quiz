extends Control
## Escolha do nível (fácil, médio, difícil) e menu lateral.

const CARTAO := preload("res://componentes/cartao_nivel.tscn")


func _ready() -> void:
	%Inicio.pressed.connect(Jogo.ir_para.bind("inicio"))
	%Titulos.pressed.connect(Jogo.abrir.bind("titulos"))
	%ComoJogar.pressed.connect(Jogo.abrir.bind("como_jogar"))
	%Creditos.pressed.connect(Jogo.abrir.bind("creditos"))
	for i in Jogo.niveis.size():
		var cartao := CARTAO.instantiate()
		%Cartoes.add_child(cartao)
		cartao.configurar(i, Jogo.niveis[i], Jogo.acertos_por_nivel[i])
		Animacoes.entrar(cartao, Vector2(0, 50), 0.08 * i)
