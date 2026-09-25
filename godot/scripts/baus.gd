class_name Baus
## Baús surpresa: o jogador ganha baús fechados e abre quando quiser (tela
## cenas/baus.*). Dentro vêm fragmentos de doces (ver Companheiros), moedas
## e açúcar.
##
## - Tipos: DOCE (partida do quiz aprovada, até QUIZ_POR_DIA por dia), PRATA
##   (missões do dia completas, subir de nível) e OURO (missões da semana,
##   prêmio do 7º dia seguido, a cada 5 níveis).
## - Quanto melhor o baú, mais itens e mais chance de doce raro.
## - Garantia: se passar GARANTIA_EPICO baús sem vir um ÉPICO ou LENDÁRIO, o
##   próximo traz um com certeza (ninguém fica frustrado).
##
## Estado em Progresso.baus.

const TIPOS := ["doce", "prata", "ouro"]
const NOMES := {"doce": "BAÚ DE DOCE", "prata": "BAÚ DE PRATA", "ouro": "BAÚ DE OURO"}
const ITENS := {"doce": 2, "prata": 3, "ouro": 4}
## Chance (peso) de cada raridade de fragmento: comum, raro, épico, lendário.
const PESOS := {
	"doce": [70.0, 25.0, 4.5, 0.5],
	"prata": [50.0, 35.0, 13.0, 2.0],
	"ouro": [30.0, 40.0, 24.0, 6.0],
}
## Fragmentos por item, por raridade: [mín, máx] (vezes o FATOR do baú).
const FRAGMENTOS := [[3, 5], [2, 4], [1, 3], [1, 2]]
const FATOR := {"doce": 1.0, "prata": 1.5, "ouro": 2.0}
const MOEDAS := {"doce": [10, 25], "prata": [25, 50], "ouro": [50, 100]}
const ACUCAR := {"doce": [10, 20], "prata": [20, 40], "ouro": [40, 80]}
const GARANTIA_EPICO := 10
const QUIZ_POR_DIA := 5


static func padrao() -> Dictionary:
	return {"fechados": {"doce": 0, "prata": 0, "ouro": 0}, "sem_epico": 0, "abertos": 0,
		"quiz_dia": "", "quiz_hoje": 0}


static func _estado() -> Dictionary:
	return Progresso.baus


static func quantos(tipo: String) -> int:
	return int(_estado()["fechados"].get(tipo, 0))


static func total_fechados() -> int:
	var n := 0
	for t in TIPOS:
		n += quantos(t)
	return n


static func ganhar(tipo: String, quantidade := 1) -> void:
	_estado()["fechados"][tipo] = quantos(tipo) + quantidade
	Progresso.salvar()


## Baú de doce por uma partida do quiz aprovada (até QUIZ_POR_DIA por dia).
## Retorna true se ganhou.
static func ganhar_do_quiz() -> bool:
	var e := _estado()
	var hoje := Missoes.hoje()
	if e["quiz_dia"] != hoje:
		e["quiz_dia"] = hoje
		e["quiz_hoje"] = 0
	if int(e["quiz_hoje"]) >= QUIZ_POR_DIA:
		return false
	e["quiz_hoje"] = int(e["quiz_hoje"]) + 1
	ganhar("doce")
	return true


## Quantos baús faltam para a garantia de épico.
static func faltam_para_garantia() -> int:
	return maxi(1, GARANTIA_EPICO - int(_estado()["sem_epico"]))


static func _raridade(tipo: String, sorteio: RandomNumberGenerator) -> int:
	var pesos: Array = PESOS[tipo]
	var total := 0.0
	for p in pesos:
		total += p
	var r := sorteio.randf() * total
	for i in pesos.size():
		r -= pesos[i]
		if r <= 0.0:
			return i
	return 0


## Abre um baú do tipo. Retorna a lista de itens (na ordem de mostrar):
## {"tipo": "fragmentos", "doce", "quantidade", "raridade", "ganhou_doce"}
## ou {"tipo": "moedas"/"acucar", "quantidade"}. [] se não tinha baú.
static func abrir(tipo: String, sorteio: RandomNumberGenerator = null) -> Array:
	if quantos(tipo) <= 0:
		return []
	if sorteio == null:
		sorteio = RandomNumberGenerator.new()
		sorteio.randomize()
	var e := _estado()
	e["fechados"][tipo] = quantos(tipo) - 1
	e["abertos"] = int(e["abertos"]) + 1
	var itens := []
	var veio_epico := false
	var garantia := int(e["sem_epico"]) + 1 >= GARANTIA_EPICO
	for i in ITENS[tipo]:
		# o primeiro item é sempre fragmento; os outros podem ser moedas/açúcar
		var sorte := sorteio.randf()
		if i == 0 or sorte < 0.6 or (garantia and not veio_epico and i == ITENS[tipo] - 1):
			var r := _raridade(tipo, sorteio)
			if garantia and not veio_epico and i == ITENS[tipo] - 1:
				r = Companheiros.Raridade.LENDARIO if sorteio.randf() < 0.2 else Companheiros.Raridade.EPICO
			veio_epico = veio_epico or r >= Companheiros.Raridade.EPICO
			var opcoes := Companheiros.de_raridade(r)
			var doce: String = opcoes[sorteio.randi() % opcoes.size()]
			var faixa: Array = FRAGMENTOS[r]
			var n := roundi(sorteio.randi_range(faixa[0], faixa[1]) * FATOR[tipo])
			var ganhou := Companheiros.receber_fragmentos(doce, n)
			itens.append({"tipo": "fragmentos", "doce": doce, "quantidade": n, "raridade": r, "ganhou_doce": ganhou})
		elif sorte < 0.85:
			var m := sorteio.randi_range(MOEDAS[tipo][0], MOEDAS[tipo][1])
			Progresso.moedas += m
			Progresso.estatisticas["moedas_ganhas"] = int(Progresso.estatisticas.get("moedas_ganhas", 0)) + m
			itens.append({"tipo": "moedas", "quantidade": m})
		else:
			var a := sorteio.randi_range(ACUCAR[tipo][0], ACUCAR[tipo][1])
			Confeitaria.ganhar_acucar(a)
			itens.append({"tipo": "acucar", "quantidade": a})
	e["sem_epico"] = 0 if veio_epico else int(e["sem_epico"]) + 1
	Missoes.registrar("baus", 1)
	Progresso.salvar()
	return itens
