extends Control
## Tela inicial: logo, mascote e botões de jogar, como jogar e créditos.


func _ready() -> void:
	%Versao.text = Jogo.versao()
	%Jogar.pressed.connect(Jogo.ir_para.bind("niveis"))
	%ComoJogar.pressed.connect(Jogo.abrir.bind("como_jogar"))
	%Creditos.pressed.connect(Jogo.abrir.bind("creditos"))
	Animacoes.pular(%Mascote)
	Animacoes.entrar(%Logo, Vector2(-60, 0))
	Animacoes.entrar(%Mascote, Vector2(60, 0), 0.1)
