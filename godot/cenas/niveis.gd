extends Control
## Escolha do nível (fácil, médio, difícil) e menu lateral.

const CARTAO := preload("res://componentes/cartao_nivel.tscn")


func _ready() -> void:
	%Inicio.pressed.connect(Telas.ir_para.bind("inicio"))
	%Titulos.pressed.connect(Telas.abrir.bind("titulos"))
	%ComoJogar.pressed.connect(Telas.abrir.bind("como_jogar"))
	%Creditos.pressed.connect(Telas.abrir.bind("creditos"))
	for i in Jogo.niveis.size():
		var cartao := CARTAO.instantiate()
		%Cartoes.add_child(cartao)
		cartao.configurar(i, Jogo.niveis[i])
		Animacoes.entrar(cartao, Vector2(0, 50), 0.08 * i)
