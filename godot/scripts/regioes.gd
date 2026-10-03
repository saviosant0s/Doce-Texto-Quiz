class_name Regioes
## REGIÕES DO MAPA: em volta da vila (o quadrado do meio) ficam lugares
## novos para explorar, cada um atrás de um PORTÃO que abre com o progresso
## do jogador (nível do jogador ou título do quiz):
## - ILHA DO ALGODÃO-DOCE (oeste): o Lago de Morango e a ponte comprida até a
##   ilha, com o farol de pirulito.
## - BOSQUE DE PIRULITOS (sul): o Rio de Calda com a ponte e o bosque.
## - MONTANHA DE SORVETE (leste): o vale entre as montanhas de sorvete.
## Entrar numa região pela primeira vez = DESCOBRIR (prêmio, e no mapa ela
## sai da névoa). Cada região tem coisinhas para pegar (conchas, morangos,
## cristais) que voltam a cada dia do jogo.
##
## Estado em Progresso.vila["regioes"] = {"exploradas": [ids],
## "coletados": {"dia": dia do jogo, "ids": ["ilha-0", ...]}}.
##
## Coordenadas: x e z do chão da vila (o mapa 2D usa as mesmas).

## A vila (o quadrado do meio) e os limites do mundo inteiro.
const VILA := Rect2(-38, -38, 76, 76)
const MUNDO := Rect2(-96, -40, 192, 128)
const LARGURA_ENTRADA := 7.0

## "area": o retângulo da região; "entrada": o meio da abertura na cerca da
## vila (onde fica o portão); "requisito": ["nivel", n] (nível do jogador) ou
## ["titulo", "noob"|"pro"|"mestre"] (passar no nível do quiz).
const LISTA := [
	{"id": "ilha", "nome": "ILHA DO ALGODÃO-DOCE", "area": Rect2(-96, -40, 58, 128), "entrada": Vector3(-38, 0, 2),
		"requisito": ["nivel", 2], "cor": "#FF9EC7", "item": "CONCHA DE AÇÚCAR", "cor_item": "#FFE3EE"},
	{"id": "bosque", "nome": "BOSQUE DE PIRULITOS", "area": Rect2(-38, 38, 76, 50), "entrada": Vector3(-8, 0, 38),
		"requisito": ["titulo", "noob"], "cor": "#7BE07B", "item": "MORANGO SILVESTRE", "cor_item": "#E8364F"},
	{"id": "montanha", "nome": "MONTANHA DE SORVETE", "area": Rect2(38, -40, 58, 128), "entrada": Vector3(38, 0, 2),
		"requisito": ["titulo", "pro"], "cor": "#9FD4F7", "item": "CRISTAL DE AÇÚCAR", "cor_item": "#BFE6FF"},
]
## Prêmio de descobrir uma região (uma vez).
const PREMIO_DESCOBRIR := {"moedas": 40, "acucar": 30}
## Coisinhas para pegar em cada região por dia e o que cada uma dá.
const ITENS_POR_DIA := 5
const PREMIO_ITEM := {"acucar": 6, "moedas": 3}

## Onde ficam as coisinhas de cada região (fixo; o dia só sorteia quais
## aparecem, então elas nunca caem no lago nem em cima de nada).
const LUGARES_ITENS := {
	"ilha": [Vector3(-64, 0, -2), Vector3(-70, 0, 6), Vector3(-76, 0, -2), Vector3(-70, 0, -6), Vector3(-64, 0, 5),
		Vector3(-77, 0, 6), Vector3(-68, 0, 0)],
	"bosque": [Vector3(-26, 0, 60), Vector3(-12, 0, 72), Vector3(4, 0, 58), Vector3(20, 0, 66), Vector3(28, 0, 80),
		Vector3(-30, 0, 80), Vector3(10, 0, 82)],
	"montanha": [Vector3(52, 0, 4), Vector3(60, 0, -8), Vector3(66, 0, 14), Vector3(78, 0, -2), Vector3(64, 0, 22),
		Vector3(56, 0, -20), Vector3(84, 0, 16)],
}


static func regiao(id: String) -> Dictionary:
	for r in LISTA:
		if r["id"] == id:
			return r
	return {}


static func _estado() -> Dictionary:
	if not Progresso.vila.has("regioes"):
		Progresso.vila["regioes"] = {"exploradas": [], "coletados": {"dia": -1, "ids": []}}
	return Progresso.vila["regioes"]


## Se o portão da região já abre.
static func liberada(id: String) -> bool:
	var r := regiao(id)
	if r.is_empty():
		return false
	var req: Array = r["requisito"]
	if req[0] == "nivel":
		return Experiencia.nivel() >= int(req[1])
	return Quiz.tem_titulo(str(req[1]))


## O que falta para abrir ("" = já abre).
static func texto_requisito(id: String) -> String:
	if liberada(id):
		return ""
	var req: Array = regiao(id)["requisito"]
	if req[0] == "nivel":
		return "CHEGUE AO NÍVEL %d" % int(req[1])
	return Quiz.como_ganhar(str(req[1]))


static func explorada(id: String) -> bool:
	return id in _estado()["exploradas"]


## Região onde fica esse ponto ("" = dentro da vila ou fora de todas).
static func regiao_em(ponto: Vector3) -> String:
	var p := Vector2(ponto.x, ponto.z)
	if VILA.has_point(p):
		return ""
	for r in LISTA:
		if (r["area"] as Rect2).has_point(p):
			return r["id"]
	return ""


## Primeira vez na região: marca como explorada e dá o prêmio. Retorna o
## prêmio ({} se já tinha explorado ou se ainda está trancada).
static func descobrir(id: String) -> Dictionary:
	if regiao(id).is_empty() or explorada(id) or not liberada(id):
		return {}
	_estado()["exploradas"].append(id)
	Confeitaria.ganhar_acucar(int(PREMIO_DESCOBRIR["acucar"]))
	Progresso.ganhar_moedas(int(PREMIO_DESCOBRIR["moedas"]))  # também salva
	return PREMIO_DESCOBRIR.duplicate()


# --- Coisinhas para pegar ------------------------------------------------------------

## As coisinhas da região hoje: [{"id": "ilha-3", "posicao"}], sem as já pegas.
static func itens_de_hoje(id: String) -> Array:
	var lugares: Array = LUGARES_ITENS.get(id, [])
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = hash("itens-%s-%d" % [id, CicloDia.dia_jogo()])
	var indices := range(lugares.size())
	for i in range(indices.size() - 1, 0, -1):
		var j := sorteio.randi() % (i + 1)
		var troca = indices[i]
		indices[i] = indices[j]
		indices[j] = troca
	var lista := []
	for i in indices.slice(0, ITENS_POR_DIA):
		var chave := "%s-%d" % [id, i]
		if not _pego(chave):
			lista.append({"id": chave, "posicao": lugares[i]})
	return lista


static func _coletados() -> Dictionary:
	var c: Dictionary = _estado()["coletados"]
	if int(c.get("dia", -1)) != CicloDia.dia_jogo():
		c["dia"] = CicloDia.dia_jogo()
		c["ids"] = []
	return c


static func _pego(chave: String) -> bool:
	return chave in _coletados()["ids"]


## Pega a coisinha (uma vez por dia). Retorna o prêmio ({} se já pegou).
static func pegar(chave: String) -> Dictionary:
	if _pego(chave) or regiao(chave.get_slice("-", 0)).is_empty():
		return {}
	_coletados()["ids"].append(chave)
	Confeitaria.ganhar_acucar(int(PREMIO_ITEM["acucar"]))
	Progresso.ganhar_moedas(int(PREMIO_ITEM["moedas"]))  # também salva
	return PREMIO_ITEM.duplicate()
