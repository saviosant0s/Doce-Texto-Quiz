extends Control
## Resultado final: título de doceiro conquistado (ou "tente novamente").

const TEXTOS := {
	"nodoc": {"chamada": "QUE PENA!", "titulo": "VOCÊ NÃO É UM DOCEIRO!", "personagem": "brigadeiro_triste"},
	"noob": {"chamada": "PARABÉNS!", "titulo": "VOCÊ É UM DOCEIRO NOOB!", "personagem": "maca_noob"},
	"pro": {"chamada": "PARABÉNS!", "titulo": "VOCÊ É UM DOCEIRO PRO!", "personagem": "cupcake_pro"},
	"mestre": {"chamada": "PARABÉNS!", "titulo": "VOCÊ É UM DOCEIRO MESTRE!", "personagem": "chocolate_mestre"},
}


func _ready() -> void:
	var dados: Dictionary = TEXTOS[Jogo.resultado]
	var venceu := Jogo.resultado != "nodoc"
	%Chamada.text = dados["chamada"]
	%Titulo.text = dados["titulo"]
	%Personagem.texture = load("res://assets/personagens/%s.png" % dados["personagem"])
	var acertos := Jogo.resultados.count(true)
	if venceu:
		var moedas: int = Jogo.FAIXAS.filter(func(f): return f["id"] == Jogo.resultado)[0]["moedas"]
		%Detalhe.text = "Você acertou %d de %d perguntas e ganhou %d moedas." % [acertos, Jogo.resultados.size(), moedas]
	else:
		%Detalhe.text = "Você acertou %d de %d perguntas. Revise o conteúdo e tente de novo!" % [acertos, Jogo.resultados.size()]
		%JogarDeNovo.text = "TENTE NOVAMENTE"
		%Fundo.decoracao = Fundo.Decoracao.NENHUMA
	%Inicio.pressed.connect(Jogo.ir_para.bind("inicio"))
	%JogarDeNovo.pressed.connect(Jogo.iniciar_nivel.bind(Jogo.nivel_atual))
	Animacoes.entrar(%Personagem, Vector2(-60, 0))
	Animacoes.entrar(%Cartao, Vector2(60, 0), 0.1)
	if venceu:
		Animacoes.pular(%Personagem)
