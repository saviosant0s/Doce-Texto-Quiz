extends Control
## Tela de carregamento antes da partida: um personagem sorteado e uma dica.
## Também é usada (em "modo cortina") pelo Telas enquanto monta as telas 3D
## (vila e cozinha), com o nome do lugar no lugar de "QUIZ".

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

## Nome grande de cada lugar no modo cortina: [linha de cima, palavra na caixa, tamanho].
const LUGARES := {
	"vila": ["VILA DOS", "DOCES", 200],
	"cozinha": ["MINHA", "COZINHA", 150],
}

## No modo cortina a tela não vai sozinha para a partida (o Telas cuida).
var modo_cortina := false


## Uma curiosidade ou dica do Office, sem repetir a última: [tipo, texto].
static func sortear_dica() -> Array:
	var e_curiosidade := randf() < 0.5
	var lista: Array = CURIOSIDADES if e_curiosidade else DICAS
	var dica: String = lista.filter(func(d): return d != _ultima_dica).pick_random()
	_ultima_dica = dica
	return ["VOCÊ SABIA?" if e_curiosidade else "DICA", dica.to_upper()]


## Modo cortina: nome do lugar, doce companheiro (foto) e dica nova.
func preparar(lugar: String) -> void:
	var nomes: Array = LUGARES.get(lugar, ["DOCE TEXTO", "QUIZ", 240])
	%DoceTexto.text = nomes[0]
	%Quiz.text = nomes[1]
	%Quiz.add_theme_font_size_override("font_size", nomes[2])
	var id := Colecao.companheiro()
	%Personagem.texture = Personagens.textura(id if not id.is_empty() else PERSONAGEM)
	var dica := sortear_dica()
	%Tipo.text = dica[0]
	%Texto.text = dica[1]
	%Barra.value = 0.0


func barra(valor: float) -> void:
	%Barra.value = valor


func _ready() -> void:
	if modo_cortina:
		return
	%Personagem.texture = Personagens.textura(PERSONAGEM)
	_mostrar_companheiro()
	var dica := sortear_dica()
	%Tipo.text = dica[0]
	%Texto.text = dica[1]

	if %Personagem.visible:
		Animacoes.flutuar(%Personagem)
	var tween := create_tween()
	tween.tween_property(%Barra, "value", 100.0, DURACAO).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(Telas.ir_para.bind("partida"))


## Botão "voltar" do celular: ignorado enquanto carrega (a partida já vai começar).
func ao_voltar() -> void:
	pass


## Se o jogador escolheu um companheiro na coleção, ele aparece em 3D no lugar
## do fantasma.
func _mostrar_companheiro() -> void:
	var id := Colecao.companheiro()
	if id.is_empty():
		return
	var doce := Doce3D.new()
	doce.name = "Companheiro"
	doce.id = id
	doce.nivel = Companheiros.nivel(id)
	doce.giravel = false
	doce.distancia = 4.6  # do tamanho do fantasma
	doce.custom_minimum_size = %Personagem.custom_minimum_size
	doce.size_flags_horizontal = %Personagem.size_flags_horizontal
	doce.size_flags_vertical = %Personagem.size_flags_vertical
	%Personagem.add_sibling(doce)
	%Personagem.visible = false
