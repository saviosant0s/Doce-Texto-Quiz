extends Control
## Tela de carregamento antes da partida: um personagem sorteado e uma dica.

const DURACAO := 3.2

## Curiosidades sobre doces e dicas de Word/Excel (sem entregar respostas do quiz).
const DICAS := [
	["VOCÊ SABIA?", "O chocolate branco não é chocolate de verdade: ele não leva massa de cacau, só a manteiga."],
	["VOCÊ SABIA?", "O brigadeiro nasceu no Brasil, nos anos 1940."],
	["VOCÊ SABIA?", "A máquina de algodão-doce foi inventada por um dentista, em 1897."],
	["VOCÊ SABIA?", "O mel quase não estraga: já acharam mel comestível em tumbas egípcias."],
	["VOCÊ SABIA?", "A pipoca estoura porque a água dentro do grão vira vapor."],
	["VOCÊ SABIA?", "O Brasil é o maior produtor de cana-de-açúcar do mundo."],
	["VOCÊ SABIA?", "O fruto do cacau nasce direto no tronco do cacaueiro."],
	["VOCÊ SABIA?", "A Bahia é um dos maiores produtores de cacau do Brasil."],
	["VOCÊ SABIA?", "O pé de moleque é feito de amendoim com açúcar ou rapadura."],
	["VOCÊ SABIA?", "O pudim de leite condensado é um dos doces favoritos dos brasileiros."],
	["DICA", "Errou algo? Ctrl + Z desfaz a última ação no Word e no Excel."],
	["DICA", "No Excel, toda fórmula começa com o sinal de igual (=)."],
	["DICA", "No Excel, a célula B3 fica na coluna B, linha 3."],
	["DICA", "No Word, clicar três vezes em um parágrafo seleciona ele inteiro."],
	["DICA", "Ctrl + A seleciona tudo: o texto inteiro no Word ou a planilha no Excel."],
	["DICA", "Salve seu trabalho com frequência para não perder nada!"],
]

## Guarda o último sorteio para não repetir em seguida.
static var _ultimo_personagem := ""
static var _ultima_dica := -1


func _ready() -> void:
	var opcoes := Personagens.CARREGAMENTO.filter(func(p): return p != _ultimo_personagem)
	_ultimo_personagem = opcoes.pick_random()
	%Personagem.texture = Personagens.textura(_ultimo_personagem)

	var indice := randi() % DICAS.size()
	if indice == _ultima_dica:
		indice = (indice + 1) % DICAS.size()
	_ultima_dica = indice
	%Tipo.text = DICAS[indice][0]
	%Texto.text = DICAS[indice][1].to_upper()

	Animacoes.flutuar(%Personagem)
	var tween := create_tween()
	tween.tween_property(%Barra, "value", 100.0, DURACAO).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Jogo.ir_para.bind("partida"))
