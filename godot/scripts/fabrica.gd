class_name Fabrica
extends RefCounted
## Regras da FÁBRICA DE CHOCOLATE (minigame da vila).
##
## Chocolates passam numa esteira (da esquerda para a direita). No alto fica
## o PEDIDO (ex.: 3 trufas + 2 bombons): toque nos chocolates do pedido para
## eles irem para a caixa. Cuidado com os DEFEITUOSOS (queimados ou
## quebrados): tocar neles, ou num chocolate que o pedido não quer, tira
## tempo. Completou o pedido: pontos, mais tempo, e a esteira acelera.
## A cada PEDIDOS_POR_ESPECIAL pedidos vem um PEDIDO ESPECIAL: uma pergunta
## do quiz (acertou: pontos e tempo extra).
## A partida começa com TEMPO_INICIAL segundos e acaba quando o tempo zera.
##
## A esteira vai de 0.0 (entrada) a 1.0 (fim); o que chega ao fim cai.

const TIPOS := ["bombom", "trufa", "barra", "coracao"]
const NOMES := {"bombom": "BOMBONS", "trufa": "TRUFAS", "barra": "BARRAS", "coracao": "CORAÇÕES"}
const TEMPO_INICIAL := 60.0
const TEMPO_POR_PEDIDO := 6.0
const TEMPO_ERRO := 3.0
const TEMPO_PERGUNTA := 8.0
const VELOCIDADE_INICIAL := 0.16  # fração da esteira por segundo
const ACELERACAO := 0.012  # a cada pedido
const VELOCIDADE_MAXIMA := 0.42
const INTERVALO_INICIAL := 0.9  # segundos entre um chocolate e outro
const INTERVALO_MINIMO := 0.45
const CHANCE_DEFEITO := 0.14
const PONTOS_CHOCOLATE := 10
const PONTOS_PEDIDO := 50
const PONTOS_PERGUNTA := 80
const PEDIDOS_POR_ESPECIAL := 3
const CUSTO_ACUCAR := 20

## Chocolates na esteira: [{"id", "tipo", "x", "defeito": bool}]
var esteira: Array = []
## Pedido atual: {tipo: quantos faltam}; e o total dele (para a barra).
var pedido := {}
var pedido_total := 0
var pedidos_feitos := 0
var pontos := 0
var tempo := TEMPO_INICIAL
var acabou := false
var pergunta_pendente := false
var erros := 0
var _proximo_id := 0
var _espera := 0.0
var _sorteio := RandomNumberGenerator.new()


func _init(semente := -1) -> void:
	if semente >= 0:
		_sorteio.seed = semente
	else:
		_sorteio.randomize()
	_novo_pedido()


func velocidade() -> float:
	return minf(VELOCIDADE_MAXIMA, VELOCIDADE_INICIAL + ACELERACAO * pedidos_feitos)


func intervalo() -> float:
	return maxf(INTERVALO_MINIMO, INTERVALO_INICIAL - 0.04 * pedidos_feitos)


## Pedido novo: 2 tipos (3 no começo é demais), cada vez mais chocolates.
func _novo_pedido() -> void:
	pedido.clear()
	var tipos := TIPOS.duplicate()
	for i in tipos.size():  # embaralha com o sorteio da partida
		var j := _sorteio.randi_range(i, tipos.size() - 1)
		var t: String = tipos[i]
		tipos[i] = tipos[j]
		tipos[j] = t
	var quantos_tipos := 1 if pedidos_feitos == 0 else (2 if pedidos_feitos < 6 else 3)
	pedido_total = 0
	for i in quantos_tipos:
		var n := _sorteio.randi_range(1, 2 + mini(pedidos_feitos / 2, 3))
		pedido[tipos[i]] = n
		pedido_total += n


func faltam() -> int:
	var n := 0
	for t in pedido:
		n += int(pedido[t])
	return n


## Passa o tempo: chocolates andam, novos entram, o que chega ao fim cai.
## Retorna os ids que caíram.
func avancar(delta: float) -> Array:
	if acabou or pergunta_pendente:
		return []
	tempo -= delta
	if tempo <= 0.0:
		tempo = 0.0
		acabou = true
		return []
	var caidos := []
	for item in esteira:
		item["x"] += velocidade() * delta
		if item["x"] >= 1.0:
			caidos.append(item["id"])
	esteira = esteira.filter(func(i): return i["x"] < 1.0)
	_espera -= delta
	if _espera <= 0.0:
		_espera = intervalo()
		_colocar_na_esteira()
	return caidos


func _colocar_na_esteira() -> void:
	# metade das vezes vem um chocolate que o pedido quer (o jogo não trava)
	var tipo: String
	if not pedido.is_empty() and _sorteio.randf() < 0.55:
		var quer: Array = pedido.keys().filter(func(t): return int(pedido[t]) > 0)
		tipo = quer[_sorteio.randi() % quer.size()] if not quer.is_empty() else TIPOS[_sorteio.randi() % TIPOS.size()]
	else:
		tipo = TIPOS[_sorteio.randi() % TIPOS.size()]
	esteira.append({"id": _proximo_id, "tipo": tipo, "x": 0.0, "defeito": _sorteio.randf() < CHANCE_DEFEITO})
	_proximo_id += 1


func item(id: int) -> Dictionary:
	for i in esteira:
		if i["id"] == id:
			return i
	return {}


## Toque num chocolate. Retorna {"certo": bool, "motivo": "ok"/"defeito"/
## "nao_pediu", "pedido_completo": bool, "especial": bool} ou {} se não achou.
func tocar(id: int) -> Dictionary:
	if acabou or pergunta_pendente:
		return {}
	var i := item(id)
	if i.is_empty():
		return {}
	esteira.erase(i)
	if i["defeito"] or int(pedido.get(i["tipo"], 0)) <= 0:
		erros += 1
		tempo = maxf(0.0, tempo - TEMPO_ERRO)
		if tempo <= 0.0:
			acabou = true
		return {"certo": false, "motivo": "defeito" if i["defeito"] else "nao_pediu", "pedido_completo": false, "especial": false}
	pedido[i["tipo"]] = int(pedido[i["tipo"]]) - 1
	pontos += PONTOS_CHOCOLATE
	var completo := faltam() == 0
	var especial := false
	if completo:
		pedidos_feitos += 1
		pontos += PONTOS_PEDIDO
		tempo += TEMPO_POR_PEDIDO
		especial = pedidos_feitos % PEDIDOS_POR_ESPECIAL == 0
		pergunta_pendente = especial
		_novo_pedido()
	return {"certo": true, "motivo": "ok", "pedido_completo": completo, "especial": especial}


## Resposta do pedido especial (pergunta do quiz).
func responder(acertou: bool) -> void:
	if not pergunta_pendente:
		return
	pergunta_pendente = false
	if acertou:
		pontos += PONTOS_PERGUNTA
		tempo += TEMPO_PERGUNTA


# --- Progresso ---------------------------------------------------------------------

static func recorde() -> int:
	return int(Progresso.estatisticas.get("fabrica_recorde", 0))


## Fim: moedas (3 por pedido + pontos/40), recorde de pedidos, missão e XP.
## Um baú de doce a cada nova marca de 5 pedidos acima do recorde.
static func concluir(jogo: Fabrica) -> Dictionary:
	var antes := recorde()
	var feitos := jogo.pedidos_feitos
	var moedas := feitos * 3 + jogo.pontos / 40
	var bau := ""
	if feitos / 5 > antes / 5 and feitos >= 5:
		bau = "doce"
		Baus.ganhar(bau)
	if feitos > antes:
		Progresso.estatisticas["fabrica_recorde"] = feitos
	Progresso.estatisticas["fabrica_partidas"] = int(Progresso.estatisticas.get("fabrica_partidas", 0)) + 1
	Missoes.registrar("fabrica", feitos)
	Experiencia.ganhar(Experiencia.XP_MATCH)
	if moedas > 0:
		Progresso.ganhar_moedas(moedas)  # também salva
	else:
		Progresso.salvar()
	return {"moedas": moedas, "bau": bau, "recorde_novo": feitos > antes}
