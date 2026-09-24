extends Control
## Créditos: equipe, orientadores e instituição.


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	%Sobre.pressed.connect(Jogo.abrir.bind("sobre"))
	%Apoie.pressed.connect(Jogo.mostrar_aviso.bind("DISPONÍVEL EM BREVE"))
	Animacoes.entrar(%Coluna)
