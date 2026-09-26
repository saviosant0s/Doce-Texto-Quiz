class_name Casa
## MINHA CASA (estilo Animal Crossing): a casa do jogador na vila, com a sala
## para decorar. Compra móveis, papel de parede e piso na LOJA com moedas;
## alguns móveis especiais não se compram: vêm de conquistas (título de
## Mestre, recorde na Torre...). No modo DECORAR, põe os móveis na grade do
## chão, gira, muda de lugar ou guarda.
## CONFORTO: soma dos móveis colocados + parede + piso. Cada faixa nova de
## conforto dá um prêmio (uma vez).
##
## Estado em Progresso.vila["casa"] = {"moveis": {id: quantos tem},
## "colocados": [{"id", "x", "z", "giro"}], "parede", "piso",
## "paredes": [ids], "pisos": [ids], "premio_conforto": faixa já premiada}.

const LARGURA := 8  # casas da grade (x)
const FUNDO := 6  # casas da grade (z)

## "tam": [largura, fundo] em casas; "tapete": fica no chão, outros móveis
## podem ficar em cima; "libera": como ganhar (só os especiais).
const MOVEIS := {
	"tapete_glace": {"nome": "TAPETE DE GLACÊ", "preco": 60, "tam": [2, 2], "conforto": 10, "tapete": true},
	"sofa_marshmallow": {"nome": "SOFÁ DE MARSHMALLOW", "preco": 180, "tam": [2, 1], "conforto": 25},
	"poltrona_pudim": {"nome": "POLTRONA DE PUDIM", "preco": 120, "tam": [1, 1], "conforto": 15},
	"mesa_biscoito": {"nome": "MESA DE BISCOITO", "preco": 100, "tam": [1, 1], "conforto": 12},
	"cadeira_pirulito": {"nome": "CADEIRA DE PIRULITO", "preco": 50, "tam": [1, 1], "conforto": 6},
	"cama_bolo": {"nome": "CAMA DE BOLO", "preco": 250, "tam": [1, 2], "conforto": 30},
	"estante_chocolate": {"nome": "ESTANTE DE CHOCOLATE", "preco": 160, "tam": [2, 1], "conforto": 18},
	"luminaria_bala": {"nome": "LUMINÁRIA DE BALA", "preco": 70, "tam": [1, 1], "conforto": 8},
	"planta_cupcake": {"nome": "PLANTA NO CUPCAKE", "preco": 45, "tam": [1, 1], "conforto": 6},
	"tv_wafer": {"nome": "TV DE WAFER", "preco": 220, "tam": [2, 1], "conforto": 22},
	"geladeira_sorvete": {"nome": "GELADEIRA DE SORVETE", "preco": 200, "tam": [1, 1], "conforto": 20},
	"piano_chocolate": {"nome": "PIANO DE CHOCOLATE", "preco": 400, "tam": [2, 1], "conforto": 40},
	"aquario_gelatina": {"nome": "AQUÁRIO DE GELATINA", "preco": 300, "tam": [2, 1], "conforto": 32},
	"relogio_cuco": {"nome": "RELÓGIO DE CUCO", "preco": 150, "tam": [1, 1], "conforto": 15},
	"bau_brinquedos": {"nome": "BAÚ DE BRINQUEDOS", "preco": 90, "tam": [1, 1], "conforto": 10},
	# especiais (não estão à venda)
	"trofeu_gigante": {"nome": "TROFÉU GIGANTE", "preco": 0, "tam": [1, 1], "conforto": 50,
		"libera": "titulo_mestre", "como": "Ganhe o título de DOCEIRO MESTRE (passe no difícil)."},
	"bolo_torre": {"nome": "MINI TORRE DE BOLO", "preco": 0, "tam": [1, 1], "conforto": 45,
		"libera": "torre_20", "como": "Empilhe 20 andares na TORRE DE DOCES."},
	"fliperama_mini": {"nome": "FLIPERAMA DE CASA", "preco": 0, "tam": [1, 1], "conforto": 45,
		"libera": "match_10", "como": "Passe 10 níveis do DOCE MATCH."},
	"robo_office": {"nome": "ROBÔ DO OFFICE", "preco": 0, "tam": [1, 1], "conforto": 45,
		"libera": "lab_30", "como": "Junte 30 estrelas no LABORATÓRIO."},
	"banco_praca": {"nome": "BANCO DA PRAÇA", "preco": 0, "tam": [2, 1], "conforto": 35,
		"libera": "historia", "como": "Termine o capítulo FESTA NA PRAÇA das histórias da vila."},
	"retrato_vila": {"nome": "RETRATO DA VILA", "preco": 0, "tam": [1, 1], "conforto": 55,
		"libera": "historia", "como": "Termine o capítulo O SEGREDO DA FÁBRICA das histórias da vila."},
	# móveis dos eventos da temporada (prêmio da trilha do evento)
	"vaso_primavera": {"nome": "VASO DA PRIMAVERA", "preco": 0, "tam": [1, 1], "conforto": 40,
		"libera": "evento", "como": "Prêmio do evento FESTIVAL DAS FLORES."},
	"abobora_luminosa": {"nome": "ABÓBORA LUMINOSA", "preco": 0, "tam": [1, 1], "conforto": 40,
		"libera": "evento", "como": "Prêmio do evento NOITE DAS ABÓBORAS."},
	"arvore_natal": {"nome": "ÁRVORE DE NATAL", "preco": 0, "tam": [1, 1], "conforto": 45,
		"libera": "evento", "como": "Prêmio do evento NATAL DOCE."},
	"mascara_carnaval": {"nome": "MÁSCARA DE CARNAVAL", "preco": 0, "tam": [1, 1], "conforto": 40,
		"libera": "evento", "como": "Prêmio do evento CARNAVAL DE CONFEITOS."},
	"cesta_pascoa": {"nome": "CESTA DE PÁSCOA", "preco": 0, "tam": [1, 1], "conforto": 40,
		"libera": "evento", "como": "Prêmio do evento CAÇA AOS OVOS."},
	"fogueira_junina": {"nome": "FOGUEIRA JUNINA", "preco": 0, "tam": [1, 1], "conforto": 40,
		"libera": "evento", "como": "Prêmio do evento ARRAIÁ DOCE."},
}

## Papéis de parede e pisos: {id: {"nome", "preco", "conforto"}}; o primeiro
## de cada já vem com a casa.
const PAREDES := {
	"creme": {"nome": "CREME", "preco": 0, "conforto": 0},
	"listras_rosa": {"nome": "LISTRAS DE MORANGO", "preco": 80, "conforto": 10},
	"bolinhas_menta": {"nome": "BOLINHAS DE MENTA", "preco": 80, "conforto": 10},
	"xadrez_lilas": {"nome": "XADREZ DE UVA", "preco": 100, "conforto": 12},
	"chocolate": {"nome": "CHOCOLATE AO LEITE", "preco": 120, "conforto": 15},
	"ceu_estrelado": {"nome": "CÉU ESTRELADO", "preco": 150, "conforto": 20},
}
const PISOS := {
	"madeira": {"nome": "MADEIRA", "preco": 0, "conforto": 0},
	"biscoito": {"nome": "BISCOITO", "preco": 80, "conforto": 10},
	"carpete_rosa": {"nome": "CARPETE DE ALGODÃO-DOCE", "preco": 90, "conforto": 12},
	"xadrez_choco": {"nome": "XADREZ DE CHOCOLATE", "preco": 120, "conforto": 15},
	"marmore": {"nome": "MÁRMORE DE AÇÚCAR", "preco": 150, "conforto": 20},
}

## Faixas de conforto: [mínimo, nome, prêmio].
const FAIXAS := [
	[0, "SIMPLES", {}],
	[60, "ACONCHEGANTE", {"moedas": 50}],
	[150, "CHARMOSA", {"moedas": 100}],
	[280, "LINDA", {"bau": "doce"}],
	[450, "DOS SONHOS", {"moedas": 250}],
	[700, "DE REVISTA", {"bau": "ouro"}],
]


## A casa já vem com alguns móveis de presente, arrumados.
static func padrao() -> Dictionary:
	return {"moveis": {"tapete_glace": 1, "poltrona_pudim": 1, "mesa_biscoito": 1, "planta_cupcake": 1},
		"colocados": [{"id": "tapete_glace", "x": 3, "z": 2, "giro": 0}, {"id": "poltrona_pudim", "x": 3, "z": 2, "giro": 0},
			{"id": "mesa_biscoito", "x": 4, "z": 3, "giro": 0}, {"id": "planta_cupcake", "x": 0, "z": 0, "giro": 0}],
		"parede": "creme", "piso": "madeira",
		"paredes": ["creme"], "pisos": ["madeira"], "premio_conforto": 0}


static func _estado() -> Dictionary:
	if not Progresso.vila.has("casa"):
		Progresso.vila["casa"] = padrao()
	var e: Dictionary = Progresso.vila["casa"]
	for chave in padrao():
		if not e.has(chave):
			e[chave] = padrao()[chave]
	return e


# --- Móveis ------------------------------------------------------------------------

static func a_venda(id: String) -> bool:
	return MOVEIS.has(id) and not MOVEIS[id].has("libera")


static func quantos(id: String) -> int:
	return int(_estado()["moveis"].get(id, 0))


## Quantos desse móvel estão guardados (tem, mas não estão na sala).
static func guardados(id: String) -> int:
	return quantos(id) - _estado()["colocados"].filter(func(c): return c["id"] == id).size()


static func comprar(id: String) -> bool:
	if not a_venda(id) or Progresso.moedas < int(MOVEIS[id]["preco"]):
		return false
	_estado()["moveis"][id] = quantos(id) + 1
	Progresso.gastar_moedas(int(MOVEIS[id]["preco"]))  # também salva
	return true


## Se o jogador já cumpriu o que libera o móvel especial.
static func cumpriu(condicao: String) -> bool:
	match condicao:
		"titulo_mestre":
			return int(Progresso.titulos.get("mestre", 0)) > 0
		"torre_20":
			return Torre.recorde() >= 20
		"match_10":
			return Progresso.doce_match.get("estrelas", {}).size() >= 10
		"lab_30":
			return Laboratorio.total_estrelas() >= 30
	return false


## Dá um móvel (prêmio das histórias da vila).
static func ganhar_movel(id: String) -> void:
	if MOVEIS.has(id):
		_estado()["moveis"][id] = quantos(id) + 1
		Progresso.salvar()


## Dá os móveis especiais já conquistados (uma vez cada). Retorna os ids novos.
static func liberar_especiais() -> Array:
	var novos := []
	for id in MOVEIS:
		if MOVEIS[id].has("libera") and quantos(id) == 0 and cumpriu(MOVEIS[id]["libera"]):
			_estado()["moveis"][id] = 1
			novos.append(id)
	if not novos.is_empty():
		Progresso.salvar()
	return novos


# --- Grade da sala -----------------------------------------------------------------

## Tamanho no chão com o giro (0 a 3, de 90 em 90 graus).
static func tamanho(id: String, giro: int) -> Vector2i:
	var t: Array = MOVEIS[id]["tam"]
	return Vector2i(t[1], t[0]) if giro % 2 == 1 else Vector2i(t[0], t[1])


static func colocados() -> Array:
	return _estado()["colocados"]


## Se cabe o móvel com canto em (x, z) e esse giro (sem sair da sala nem
## ficar em cima de outro; tapetes só não podem ficar em cima de tapetes).
## `ignorar`: índice de um colocado que está sendo mudado de lugar.
static func cabe(id: String, x: int, z: int, giro: int, ignorar := -1) -> bool:
	var t := tamanho(id, giro)
	if x < 0 or z < 0 or x + t.x > LARGURA or z + t.y > FUNDO:
		return false
	var tapete := bool(MOVEIS[id].get("tapete", false))
	var lista := colocados()
	for i in lista.size():
		var c: Dictionary = lista[i]
		if i == ignorar or bool(MOVEIS[c["id"]].get("tapete", false)) != tapete:
			continue
		var ct := tamanho(c["id"], int(c["giro"]))
		if x < int(c["x"]) + ct.x and int(c["x"]) < x + t.x and z < int(c["z"]) + ct.y and int(c["z"]) < z + t.y:
			return false
	return true


static func colocar(id: String, x: int, z: int, giro := 0) -> bool:
	if guardados(id) <= 0 or not cabe(id, x, z, giro):
		return false
	colocados().append({"id": id, "x": x, "z": z, "giro": giro})
	Progresso.salvar()
	return true


static func mover(indice: int, x: int, z: int) -> bool:
	var c: Dictionary = colocados()[indice]
	if not cabe(c["id"], x, z, int(c["giro"]), indice):
		return false
	c["x"] = x
	c["z"] = z
	Progresso.salvar()
	return true


## Gira 90 graus (se couber girado no mesmo canto).
static func girar(indice: int) -> bool:
	var c: Dictionary = colocados()[indice]
	var novo := (int(c["giro"]) + 1) % 4
	if not cabe(c["id"], int(c["x"]), int(c["z"]), novo, indice):
		return false
	c["giro"] = novo
	Progresso.salvar()
	return true


static func guardar(indice: int) -> void:
	colocados().remove_at(indice)
	Progresso.salvar()


## Índice do colocado que ocupa a casa (x, z); móveis antes de tapetes. -1 = nenhum.
static func no_lugar(x: int, z: int) -> int:
	var achado := -1
	var lista := colocados()
	for i in lista.size():
		var c: Dictionary = lista[i]
		var t := tamanho(c["id"], int(c["giro"]))
		if x >= int(c["x"]) and x < int(c["x"]) + t.x and z >= int(c["z"]) and z < int(c["z"]) + t.y:
			if not bool(MOVEIS[c["id"]].get("tapete", false)):
				return i
			achado = i
	return achado


# --- Parede e piso -----------------------------------------------------------------

static func tem_parede(id: String) -> bool:
	return id in _estado()["paredes"]


static func tem_piso(id: String) -> bool:
	return id in _estado()["pisos"]


## Compra (se ainda não tem) e usa. Falso se faltam moedas.
static func usar_parede(id: String) -> bool:
	if not PAREDES.has(id):
		return false
	if not tem_parede(id):
		if Progresso.moedas < int(PAREDES[id]["preco"]):
			return false
		_estado()["paredes"].append(id)
		Progresso.gastar_moedas(int(PAREDES[id]["preco"]))
	_estado()["parede"] = id
	Progresso.salvar()
	return true


static func usar_piso(id: String) -> bool:
	if not PISOS.has(id):
		return false
	if not tem_piso(id):
		if Progresso.moedas < int(PISOS[id]["preco"]):
			return false
		_estado()["pisos"].append(id)
		Progresso.gastar_moedas(int(PISOS[id]["preco"]))
	_estado()["piso"] = id
	Progresso.salvar()
	return true


static func parede() -> String:
	return str(_estado()["parede"])


static func piso() -> String:
	return str(_estado()["piso"])


# --- Conforto ----------------------------------------------------------------------

static func conforto() -> int:
	var soma := int(PAREDES.get(parede(), {}).get("conforto", 0)) + int(PISOS.get(piso(), {}).get("conforto", 0))
	var tipos := {}
	for c in colocados():
		# o mesmo móvel repetido vale menos (metade a partir do segundo)
		var valor := int(MOVEIS[c["id"]]["conforto"])
		soma += valor if not tipos.has(c["id"]) else valor / 2
		tipos[c["id"]] = true
	return soma


## Índice da faixa de conforto (0 = SIMPLES).
static func faixa(pontos := -1) -> int:
	if pontos < 0:
		pontos = conforto()
	var f := 0
	for i in FAIXAS.size():
		if pontos >= int(FAIXAS[i][0]):
			f = i
	return f


static func nome_faixa(indice := -1) -> String:
	return FAIXAS[faixa() if indice < 0 else indice][1]


## Quanto falta para a próxima faixa (-1 = já está na última).
static func falta_proxima() -> int:
	var f := faixa()
	return -1 if f >= FAIXAS.size() - 1 else int(FAIXAS[f + 1][0]) - conforto()


## Dá os prêmios das faixas novas alcançadas. Retorna [{"faixa", "moedas"|"bau"}].
static func premiar() -> Array:
	var ganhos := []
	var ja := int(_estado()["premio_conforto"])
	var agora := faixa()
	for i in range(ja + 1, agora + 1):
		var premio: Dictionary = FAIXAS[i][2]
		if premio.has("moedas"):
			Progresso.ganhar_moedas(int(premio["moedas"]))
		if premio.has("bau"):
			Baus.ganhar(premio["bau"])
		var ganho := premio.duplicate()
		ganho["faixa"] = i
		ganhos.append(ganho)
	if agora > ja:
		_estado()["premio_conforto"] = agora
		Progresso.salvar()
	return ganhos
