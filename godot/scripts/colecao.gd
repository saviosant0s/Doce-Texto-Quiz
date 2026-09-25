class_name Colecao
## Coleção de doces 3D: catálogo, preços e compras. O que o jogador tem fica em
## Progresso.colecao ({"doces": [ids comprados], "companheiro": id}).
##
## - O primeiro doce (inicial) já vem na coleção.
## - Os doces de título (Noob, Pro, Mestre) não são vendidos: vêm ao passar
##   no nível correspondente.
## - O companheiro escolhido aparece na tela de carregamento.

## Na ordem da vitrine. Preço em moedas (uma boa partida rende 80 a 150).
const LISTA := [
	{"id": "brigadeiro", "nome": "BRIGADEIRO", "preco": 0, "inicial": true,
		"curiosidade": "Criado no Brasil nos anos 1940, é presença garantida em toda festa de aniversário."},
	{"id": "maca", "nome": "MAÇÃ", "titulo": "noob",
		"curiosidade": "Existem mais de 7 mil tipos de maçã no mundo. E a do amor é doce de festa junina!"},
	{"id": "cupcake", "nome": "CUPCAKE", "titulo": "pro",
		"curiosidade": "O nome vem de \"bolo de xícara\": as receitas antigas mediam tudo em xícaras."},
	{"id": "chocolate", "nome": "CHOCOLATE", "titulo": "mestre",
		"curiosidade": "O chocolate é feito das sementes do cacau, fruto nativo da Amazônia."},
	{"id": "bala", "nome": "BALA DE MENTA", "preco": 100,
		"curiosidade": "As listras vermelhas e brancas deixam a bala de menta famosa no mundo todo."},
	{"id": "pirulito", "nome": "PIRULITO", "preco": 150,
		"curiosidade": "O pirulito com palito foi inventado para dar para comer sem melar os dedos."},
	{"id": "rosquinha", "nome": "ROSQUINHA", "preco": 200,
		"curiosidade": "O furo no meio faz a massa assar (ou fritar) por igual, sem ficar crua no centro."},
	{"id": "macaron", "nome": "MACARON", "preco": 250,
		"curiosidade": "Doce francês feito com farinha de amêndoas e clara de ovo, bem crocante por fora."},
	{"id": "picole", "nome": "PICOLÉ", "preco": 300,
		"curiosidade": "O picolé foi inventado por acaso por um menino que esqueceu suco com um palito no frio."},
	{"id": "cupcake_morango", "nome": "CUPCAKE DE MORANGO", "preco": 350,
		"curiosidade": "Cada morango tem cerca de 200 sementinhas, todas do lado de fora."},
	{"id": "bombom", "nome": "BOMBOM", "preco": 400,
		"curiosidade": "\"Bombom\" vem do francês bonbon, algo como \"bom-bom\": gostoso duas vezes."},
	{"id": "pudim", "nome": "PUDIM", "preco": 500,
		"curiosidade": "O pudim de leite condensado é um dos doces mais queridos do Brasil."},
	{"id": "algodao_doce", "nome": "ALGODÃO-DOCE", "preco": 600,
		"curiosidade": "É só açúcar derretido e girado bem rápido até virar fios finíssimos."},
	{"id": "jujuba", "nome": "JUJUBA", "preco": 120,
		"curiosidade": "A jujuba leva gelatina ou amido, por isso é molinha e \"borrachuda\"."},
	{"id": "beijinho", "nome": "BEIJINHO", "preco": 150,
		"curiosidade": "Primo do brigadeiro, o beijinho troca o chocolate pelo coco e ganha um cravo em cima."},
	{"id": "marshmallow", "nome": "MARSHMALLOW", "preco": 180,
		"curiosidade": "O nome vem de uma planta, a malva-do-pântano, que era usada na receita antiga."},
	{"id": "pacoca", "nome": "PAÇOCA", "preco": 200,
		"curiosidade": "\"Paçoca\" vem do tupi e quer dizer algo como \"coisa esmigalhada\"."},
	{"id": "cocada", "nome": "COCADA", "preco": 250,
		"curiosidade": "A cocada é doce de praia e de feira no Nordeste, feita de coco e açúcar."},
	{"id": "pe_de_moleque", "nome": "PÉ DE MOLEQUE", "preco": 300,
		"curiosidade": "Dizem que o nome veio de quem pedia: \"pede, moleque!\" para ganhar um pedaço."},
	{"id": "sorvete", "nome": "SORVETE", "preco": 350,
		"curiosidade": "A casquinha de sorvete ficou famosa numa feira nos Estados Unidos, em 1904."},
	{"id": "pao_de_mel", "nome": "PÃO DE MEL", "preco": 400,
		"curiosidade": "O pão de mel leva mel, canela e cravo na massa, e é coberto de chocolate."},
	{"id": "quindim", "nome": "QUINDIM", "preco": 450,
		"curiosidade": "O quindim tem origem portuguesa, com coco adicionado aqui no Brasil."},
	{"id": "churros", "nome": "CHURROS", "preco": 500,
		"curiosidade": "O churros veio da Espanha; no Brasil ganhou recheio de doce de leite."},
	{"id": "brownie", "nome": "BROWNIE", "preco": 550,
		"curiosidade": "\"Brown\" é marrom em inglês: o nome vem da cor do chocolate."},
	{"id": "bolo", "nome": "BOLO DE ANIVERSÁRIO", "preco": 800,
		"curiosidade": "O costume de pôr velinhas no bolo começou na Alemanha, há mais de 200 anos."},
]

const NOMES_TITULOS := {"noob": "NOOB", "pro": "PRO", "mestre": "MESTRE"}
const NIVEL_DO_TITULO := {"noob": "FÁCIL", "pro": "MÉDIO", "mestre": "DIFÍCIL"}


static func dados(id: String) -> Dictionary:
	for doce in LISTA:
		if doce["id"] == id:
			return doce
	return {}


## Se o jogador já tem o doce (comprado, inicial ou ganho por título).
static func tem(id: String) -> bool:
	var doce := dados(id)
	if doce.is_empty():
		return false
	if doce.get("inicial", false) or id in Progresso.colecao["doces"]:
		return true  # comprado ou ganho com fragmentos dos baús
	if doce.has("titulo"):
		return Progresso.titulos.get(doce["titulo"], 0) > 0
	return false


static func a_venda(id: String) -> bool:
	var doce := dados(id)
	return not doce.is_empty() and not doce.has("titulo") and not doce.get("inicial", false)


static func quantidade() -> int:
	return LISTA.filter(func(d): return tem(d["id"])).size()


## Compra o doce: retorna falso se não está à venda, já tem ou faltam moedas.
static func comprar(id: String) -> bool:
	if not a_venda(id) or tem(id) or Progresso.moedas < dados(id)["preco"]:
		return false
	Progresso.colecao["doces"].append(id)
	Progresso.gastar_moedas(dados(id)["preco"])  # também salva
	return true


## Doce que aparece no carregamento ("" = nenhum; aparece o fantasma).
static func companheiro() -> String:
	var id: String = Progresso.colecao.get("companheiro", "")
	return id if tem(id) else ""


## Pódio dos títulos (tela de Troféus): cada degrau (noob, pro, mestre) mostra
## um doce. Começa com os doces de 2023 (maçã, cupcake e chocolate, que vêm
## com os títulos); depois de ganhar o título, o jogador pode pôr ali qualquer
## doce da coleção. Fica em Progresso.colecao["podio"] = {título: id}.
const DOCE_DO_TITULO := {"noob": "maca", "pro": "cupcake", "mestre": "chocolate"}


static func doce_do_podio(titulo: String) -> String:
	var id: String = Progresso.colecao.get("podio", {}).get(titulo, "")
	return id if tem(id) else DOCE_DO_TITULO[titulo]


static func escolher_do_podio(titulo: String, id: String) -> bool:
	if not DOCE_DO_TITULO.has(titulo) or not tem(id) or Progresso.titulos.get(titulo, 0) == 0:
		return false
	if not Progresso.colecao.has("podio"):
		Progresso.colecao["podio"] = {}
	Progresso.colecao["podio"][titulo] = id
	Progresso.salvar()
	return true


static func escolher_companheiro(id: String) -> bool:
	if not tem(id):
		return false
	Progresso.colecao["companheiro"] = id
	Progresso.salvar()
	return true
