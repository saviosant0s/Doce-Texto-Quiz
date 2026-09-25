extends Control
## Como jogar: uma aba para cada parte do jogo (vila, quiz, laboratório,
## confeitaria, Doce Match, baús e missões) e os títulos de doceiro.

## Abas do "Como jogar": cada uma com 4 cartões (ícone da pasta de ícones ou
## item 3D do jogo, título e texto curto).
const ABAS := [
	{"nome": "VILA", "passos": [
		{"icone": "casa", "titulo": "ANDE PELA VILA",
			"texto": "Use o joystick (ou WASD no computador). Empurre até o fim para correr; o botão de seta pula."},
		{"icone": "avancar", "titulo": "ENTRE NOS PRÉDIOS",
			"texto": "Chegue na porta e toque em ENTRAR: Escola, Laboratório, Confeitaria, Fliperama e Troféus."},
		{"icone": "camera", "titulo": "TROQUE A CÂMERA",
			"texto": "O botão da câmera muda entre de cima, de perto e 1ª pessoa. Arraste o dedo para olhar em volta."},
		{"icone": "lampada", "titulo": "SIGA OS AVISOS",
			"texto": "A seta amarela mostra o próximo passo. O \"!\" aparece nos prédios com algo esperando você."},
		{"icone": "confeitaria", "titulo": "COMPRE TERRENOS",
			"texto": "Atrás da Escola ficam os terrenos: construa um Moinho (açúcar), um Cofre (moedas), casas e jardins."},
		{"item": "BAU_DOCE", "titulo": "EXPLORE LONGE",
			"texto": "O Lago de Chocolate e o Mirante do Sorvete têm um presente por dia para quem anda até lá."},
	]},
	{"nome": "QUIZ", "passos": [
		{"icone": "camadas", "titulo": "ESCOLHA O NÍVEL",
			"texto": "Na Escola, comece pelo fácil. Passando nele, você libera o médio, e depois o difícil."},
		{"icone": "relogio", "titulo": "RESPONDA RÁPIDO",
			"texto": "10 perguntas, 30 segundos cada. Rapidez e acertos seguidos valem mais pontos!"},
		{"item": "ESTRELA", "titulo": "FAÇA 6 ACERTOS",
			"texto": "Com 6 acertos você passa no nível. Com 8 e 10, ganha mais estrelas, moedas e açúcar."},
		{"icone": "trofeu", "titulo": "GANHE SEU TÍTULO",
			"texto": "Cada nível vencido dá um título de doceiro. Revise seus erros para aprender de vez!"},
	]},
	{"nome": "LABORATÓRIO", "passos": [
		{"icone": "laboratorio", "titulo": "FASES PRÁTICAS",
			"texto": "Use o Excel e o Word de verdade: fórmulas, negrito, listas, títulos... São 40 fases em 5 capítulos."},
		{"icone": "grafico", "titulo": "EXCEL",
			"texto": "Toque nas células e nos botões para montar a fórmula e aperte CONFERIR. Toda fórmula começa com =."},
		{"icone": "camadas", "titulo": "WORD",
			"texto": "Toque numa palavra para selecionar (duas vezes = parágrafo) e use a barra: N, cores, listas, títulos."},
		{"item": "BAU_CHEFE", "titulo": "ESTRELAS E CHEFES",
			"texto": "Sem erro e sem dica = 3 estrelas. No fim de cada capítulo tem um chefe e, no caminho, baús."},
	]},
	{"nome": "CONFEITARIA", "passos": [
		{"item": "ACUCAR", "titulo": "AÇÚCAR",
			"texto": "Cada acerto no quiz e cada fase nova do laboratório dá açúcar para a sua confeitaria."},
		{"icone": "confeitaria", "titulo": "MÁQUINAS",
			"texto": "As máquinas transformam o açúcar em doces sozinhas. Construa e melhore nos círculos do chão."},
		{"icone": "pessoas", "titulo": "ATENDA",
			"texto": "Pegue os doces nas bandejas e leve ao balcão: os clientes pagam em moedas."},
		{"item": "MOEDA", "titulo": "RECOLHA",
			"texto": "As moedas ficam no caixa. Passe por lá para guardar e use para construir e comprar doces."},
	]},
	{"nome": "DOCE MATCH", "passos": [
		{"icone": "controle", "titulo": "30 NÍVEIS",
			"texto": "No Fliperama, cada nível tem um objetivo: pontos, juntar peças ou limpar a gelatina rosa."},
		{"icone": "estrela", "titulo": "PEÇAS ESPECIAIS",
			"texto": "Fila de 4 vira LISTRADA, L ou T vira EMBRULHADA e fila de 5 vira a BOMBA de confeito!"},
		{"item": "ESTRELA", "titulo": "ESTRELAS E BAÚS",
			"texto": "Jogadas que sobram viram pontos. Mais pontos, mais estrelas; a cada 5 níveis, um baú."},
		{"item": "ACUCAR", "titulo": "CUSTA AÇÚCAR",
			"texto": "Cada tentativa custa 30 de açúcar. Faltou? Jogue o quiz ou o Laboratório."},
	]},
	{"nome": "TORRE", "passos": [
		{"icone": "controle", "titulo": "EMPILHE O BOLO",
			"texto": "Na Torre de Doces, um andar passa de um lado para o outro: toque para soltar em cima da torre."},
		{"icone": "estrela", "titulo": "PERFEITO!",
			"texto": "O que sobra para fora cai. Solte certinho para um PERFEITO; 3 seguidos alargam o andar."},
		{"icone": "lampada", "titulo": "PERGUNTA BÔNUS",
			"texto": "A cada 10 andares vem uma pergunta do quiz: acertou, ganha pontos e o andar volta a ficar largo."},
		{"item": "ACUCAR", "titulo": "CUSTA AÇÚCAR",
			"texto": "Cada torre custa 20 de açúcar e dá moedas por andar. Bateu o recorde de 10 em 10? Baú!"},
	]},
	{"nome": "FÁBRICA", "passos": [
		{"icone": "controle", "titulo": "OLHE O PEDIDO",
			"texto": "Na Fábrica de Chocolate, o pedido fica no alto: quantos bombons, trufas, barras e corações."},
		{"icone": "doce", "titulo": "TOQUE NOS CERTOS",
			"texto": "Toque nos chocolates do pedido que passam na esteira. Queimados e quebrados NÃO: tiram 3 segundos."},
		{"icone": "lampada", "titulo": "PEDIDO ESPECIAL",
			"texto": "Pedido pronto dá mais tempo e a esteira acelera. A cada 3, uma pergunta do quiz vale bônus."},
		{"item": "ACUCAR", "titulo": "CUSTA AÇÚCAR",
			"texto": "Cada turno custa 20 de açúcar e dá moedas por pedido. Recorde de 5 em 5 pedidos? Baú!"},
	]},
	{"nome": "BAÚS E DOCES", "passos": [
		{"item": "BAU_DOCE", "titulo": "BAÚS SURPRESA",
			"texto": "Ganhe baús passando no quiz, nas missões, no laboratório e subindo de nível."},
		{"icone": "doce", "titulo": "PEDAÇOS",
			"texto": "Dentro vêm pedaços de doces: junte 10 e o doce é seu. Com mais, ele sobe de nível."},
		{"item": "BAU_OURO", "titulo": "RARIDADE",
			"texto": "Comum, raro, épico e lendário (a cor da borda). A cada 10 baús vem um épico ou lendário."},
		{"icone": "coracao", "titulo": "COMPANHEIRO",
			"texto": "Escolha um doce na coleção: o bônus dele (mais açúcar, mais tempo...) vale no jogo todo."},
	]},
	{"nome": "MISSÕES", "passos": [
		{"icone": "missoes", "titulo": "DO DIA",
			"texto": "3 missões novas todo dia. Cumpriu? Toque em RESGATAR. As 3 juntas dão um baú de prata."},
		{"item": "BAU_OURO", "titulo": "DA SEMANA",
			"texto": "3 missões maiores por semana. As 3 juntas dão um baú de ouro."},
		{"icone": "relogio", "titulo": "VOLTE TODO DIA",
			"texto": "O prêmio por entrar cresce a cada dia seguido. O 7º dia dá um baú de ouro!"},
		{"item": "XP", "titulo": "SUBA DE NÍVEL",
			"texto": "Tudo o que você faz dá experiência (XP). Cada nível novo dá um baú."},
	]},
]
const ITENS := {"ESTRELA": Itens.ESTRELA, "ACUCAR": Itens.ACUCAR, "MOEDA": Itens.MOEDA, "XP": Itens.XP,
	"BAU_DOCE": Itens.BAU_DOCE, "BAU_OURO": Itens.BAU_OURO, "BAU_CHEFE": Itens.BAU_CHEFE}
const FAIXAS := [
	{"personagem": "brigadeiro_triste", "faixa": "MENOS DE 6", "nome": "AINDA NÃO É DOCEIRO"},
	{"personagem": "maca_noob", "faixa": "PASSOU NO FÁCIL", "nome": "DOCEIRO NOOB"},
	{"personagem": "cupcake_pro", "faixa": "PASSOU NO MÉDIO", "nome": "DOCEIRO PRO"},
	{"personagem": "chocolate_mestre", "faixa": "PASSOU NO DIFÍCIL", "nome": "DOCEIRO MESTRE"},
]


var _abas: HBoxContainer
var aba_atual := -1


func _ready() -> void:
	%Voltar.pressed.connect(Telas.voltar)
	%Jogar.pressed.connect(Telas.ir_para_casa)
	for faixa in FAIXAS:
		%Faixas.add_child(_criar_faixa(faixa))
	# abas logo abaixo do topo
	_abas = HBoxContainer.new()
	_abas.name = "Abas"
	_abas.add_theme_constant_override("separation", 8)
	%Coluna.add_child(_abas)
	%Coluna.move_child(_abas, 1)
	for i in ABAS.size():
		var b := Button.new()
		b.name = "Aba%d" % i
		b.text = ABAS[i]["nome"]
		b.custom_minimum_size = Vector2(0, 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 20)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(mostrar_aba.bind(i))
		_abas.add_child(b)
	mostrar_aba(0)


## Mostra os 4 cartões de uma aba (os títulos de doceiro só na aba QUIZ).
func mostrar_aba(indice: int) -> void:
	if indice == aba_atual:
		return
	aba_atual = indice
	for i in _abas.get_child_count():
		var aba: Button = _abas.get_child(i)
		aba.theme_type_variation = &"BotaoRoxo" if i == indice else &"Alternativa"
		aba.add_theme_font_size_override("font_size", 26 if i == indice else 20)  # a fonte do roxo é mais estreita
	for filho in %Passos.get_children():
		%Passos.remove_child(filho)
		filho.queue_free()
	var passos: Array = ABAS[indice]["passos"]
	for i in passos.size():
		var cartao := _criar_passo(i + 1, passos[i])
		%Passos.add_child(cartao)
		Animacoes.entrar(cartao, Vector2(0, 30), 0.05 * i)
	%Coluna.get_node("Titulos").visible = ABAS[indice]["nome"] == "QUIZ"


func _criar_passo(numero: int, passo: Dictionary) -> PanelContainer:
	var cartao := PanelContainer.new()
	cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	cartao.add_child(coluna)

	var topo := HBoxContainer.new()
	coluna.add_child(topo)
	var bolinha := PanelContainer.new()
	bolinha.theme_type_variation = &"PainelRoxo"
	bolinha.custom_minimum_size = Vector2(60, 60)
	var num := Label.new()
	num.theme_type_variation = &"TituloClaro"
	num.text = str(numero)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bolinha.add_child(num)
	bolinha.add_theme_stylebox_override("panel", _circulo(Cores.ROXO))
	topo.add_child(bolinha)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(espaco)
	var icone := TextureRect.new()
	if passo.has("item"):
		icone.texture = ITENS[passo["item"]]  # item 3D do jogo, com as cores dele
	else:
		icone.texture = load("res://assets/icones/%s.svg" % passo["icone"])
		icone.modulate = Cores.ROXO
	icone.custom_minimum_size = Vector2(60, 60)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	topo.add_child(icone)

	var titulo := Label.new()
	titulo.theme_type_variation = &"Subtitulo"
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.text = passo["titulo"]
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	coluna.add_child(titulo)
	var texto := Label.new()
	texto.theme_type_variation = &"Texto"
	texto.add_theme_font_size_override("font_size", 22)
	texto.text = passo["texto"]
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(100, 0)
	coluna.add_child(texto)
	return cartao


func _criar_faixa(faixa: Dictionary) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_theme_constant_override("separation", 8)
	var imagem := TextureRect.new()
	imagem.texture = Personagens.textura(faixa["personagem"])
	imagem.custom_minimum_size = Vector2(72, 84)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(imagem)
	var textos := VBoxContainer.new()
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", -2)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(textos)
	var porcentagem := Label.new()
	porcentagem.theme_type_variation = &"TituloClaro"
	porcentagem.add_theme_font_size_override("font_size", 26)
	porcentagem.text = faixa["faixa"]
	textos.add_child(porcentagem)
	var nome := Label.new()
	nome.theme_type_variation = &"TextoClaro"
	nome.add_theme_font_size_override("font_size", 15)
	nome.text = faixa["nome"]
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size = Vector2(90, 0)
	textos.add_child(nome)
	return linha


func _circulo(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(999)
	return estilo
