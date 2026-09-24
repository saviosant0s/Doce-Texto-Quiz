extends Control
## Sobre o projeto e redes sociais da equipe.


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	Animacoes.entrar(%Linha)
