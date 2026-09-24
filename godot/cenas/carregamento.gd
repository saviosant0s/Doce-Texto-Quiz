extends Control
## Tela de carregamento antes da partida: um personagem sorteado e uma dica.

const DURACAO := 3.2

## O fantasma de chocolate branco combina com a cor do cartão: é o personagem fixo desta tela.
const PERSONAGEM := "fantasma_chocolate"

## Curiosidades sobre doces e dicas de Word/Excel (atalhos do Office em português).
## Evite dicas que entreguem respostas do quiz.
const CURIOSIDADES := [
	"O chocolate branco não leva massa de cacau, só a manteiga de cacau.",
	"O brigadeiro surgiu no Brasil, nos anos 1940.",
	"A máquina de algodão-doce foi criada por um dentista e um confeiteiro, em 1897.",
	"O mel pode durar séculos: já acharam mel comestível em tumbas egípcias.",
	"A pipoca estoura porque a água dentro do grão vira vapor.",
	"O Brasil é o maior produtor de cana-de-açúcar do mundo.",
	"O fruto do cacau nasce direto no tronco do cacaueiro.",
	"A Bahia é um dos maiores produtores de cacau do Brasil.",
	"O pé de moleque é feito de amendoim com açúcar ou rapadura.",
	"A rapadura é feita do caldo da cana, fervido até endurecer.",
	"O beijinho é o primo do brigadeiro, feito com coco.",
	"O sorvete de casquinha ficou famoso em uma feira nos Estados Unidos, em 1904.",
	"Os astecas usavam sementes de cacau como dinheiro.",
	"A paçoca é feita de amendoim moído com açúcar.",
	"O quindim leva gema de ovo, açúcar e coco.",
	"O leite condensado foi criado para o leite durar mais tempo sem estragar.",
	"A palavra \"chocolate\" vem de línguas indígenas do México.",
	"Goiabada com queijo tem apelido: Romeu e Julieta.",
	"O açaí é uma fruta da Amazônia.",
	"O pudim de leite é um dos doces mais queridos do Brasil.",
]
const DICAS := [
	"Ctrl + Z desfaz a última ação no Word e no Excel.",
	"No Office em português, Ctrl + T seleciona tudo.",
	"No Office em português, Ctrl + B salva o arquivo.",
	"No Office em português, Ctrl + N deixa o texto em negrito.",
	"Ctrl + I deixa o texto em itálico.",
	"No Word em português, Ctrl + S sublinha o texto.",
	"Ctrl + P abre a janela de impressão.",
	"F12 abre o \"Salvar como\" no Word e no Excel.",
	"No Office em português, Ctrl + L abre a busca (Localizar).",
	"Clique duas vezes numa palavra do Word para selecionar só ela.",
	"Clique três vezes num parágrafo do Word para selecionar ele inteiro.",
	"No Word, Shift + Enter quebra a linha sem começar um novo parágrafo.",
	"No Excel, Alt + Enter quebra a linha dentro da mesma célula.",
	"No Excel, Ctrl + ; (ponto e vírgula) escreve a data de hoje na célula.",
	"No Excel, arraste o quadradinho no canto da célula para copiar a fórmula para as vizinhas.",
	"No Excel, o botão AutoSoma (Σ) soma uma coluna com um clique.",
	"No Excel, clique duas vezes na aba de uma planilha para renomeá-la.",
	"No Excel, a Formatação Condicional pinta as células conforme o valor.",
	"No Word, o Painel de Navegação (guia Exibir) ajuda a pular entre partes do texto.",
	"Salve seu trabalho com frequência para não perder nada!",
]

## Guarda o último sorteio para não repetir em seguida.
static var _ultima_dica := ""


func _ready() -> void:
	%Personagem.texture = Personagens.textura(PERSONAGEM)
	var e_curiosidade := randf() < 0.5
	var lista: Array = CURIOSIDADES if e_curiosidade else DICAS
	var dica: String = lista.filter(func(d): return d != _ultima_dica).pick_random()
	_ultima_dica = dica
	%Tipo.text = "VOCÊ SABIA?" if e_curiosidade else "DICA"
	%Texto.text = dica.to_upper()

	Animacoes.flutuar(%Personagem)
	var tween := create_tween()
	tween.tween_property(%Barra, "value", 100.0, DURACAO).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Telas.ir_para.bind("partida"))


## Botão "voltar" do celular: ignorado enquanto carrega (a partida já vai começar).
func ao_voltar() -> void:
	pass
