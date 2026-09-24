extends Control
## Tela de carregamento antes da partida, com uma curiosidade sobre doces.

const DURACAO := 2.5
const CURIOSIDADES := [
	"Você sabia que o chocolate branco não é chocolate?",
	"Você sabia que o brigadeiro foi criado no Brasil, nos anos 1940?",
	"Você sabia que o algodão-doce foi inventado por um dentista?",
	"Você sabia que o mel nunca estraga?",
]


func _ready() -> void:
	%Curiosidade.text = CURIOSIDADES.pick_random().to_upper()
	Animacoes.pular(%Fantasma)
	var tween := create_tween()
	tween.tween_property(%Barra, "value", 100.0, DURACAO).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Jogo.ir_para.bind("partida"))
