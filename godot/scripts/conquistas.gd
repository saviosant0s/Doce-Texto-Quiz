class_name Conquistas
## Conquistas: metas especiais que dão moedas de recompensa. São verificadas ao
## fim de cada partida (ver Jogo.finalizar_partida) e ficam salvas em
## Progresso.conquistas.

## Na ordem em que aparecem na tela de troféus.
const LISTA := [
	{"id": "primeira_partida", "nome": "PRIMEIRA MORDIDA", "descricao": "Jogue sua primeira partida.",
		"moedas": 10, "icone": "coracao"},
	{"id": "primeira_aprovacao", "nome": "DOCEIRO APRENDIZ", "descricao": "Passe em um nível pela primeira vez.",
		"moedas": 20, "icone": "certo"},
	{"id": "todos_niveis", "nome": "CONFEITARIA COMPLETA", "descricao": "Passe nos três níveis.",
		"moedas": 50, "icone": "trofeu"},
	{"id": "gabarito", "nome": "GABARITO", "descricao": "Acerte 10 de 10 em uma partida.",
		"moedas": 30, "icone": "estrela"},
	{"id": "ceu_estrelado", "nome": "CÉU ESTRELADO", "descricao": "Consiga 3 estrelas em todos os níveis.",
		"moedas": 100, "icone": "estrela"},
	{"id": "embalado", "nome": "EMBALADO", "descricao": "Acerte 5 perguntas seguidas.",
		"moedas": 15, "icone": "grafico"},
	{"id": "relampago", "nome": "RELÂMPAGO", "descricao": "Acerte uma pergunta em menos de 3 segundos.",
		"moedas": 15, "icone": "relogio"},
	{"id": "pontuador", "nome": "CHUVA DE PONTOS", "descricao": "Faça 2.000 pontos em uma partida.",
		"moedas": 20, "icone": "grafico"},
	{"id": "sem_rodinhas", "nome": "SEM RODINHAS", "descricao": "Passe no nível difícil sem usar ajudas.",
		"moedas": 40, "icone": "trofeu"},
	{"id": "revisor", "nome": "APRENDI COM O ERRO", "descricao": "Acerte todas as perguntas de uma revisão.",
		"moedas": 25, "icone": "lampada"},
	{"id": "persistente", "nome": "PERSISTENTE", "descricao": "Jogue 10 partidas.",
		"moedas": 20, "icone": "camadas"},
	{"id": "dedicado", "nome": "DEDICADO", "descricao": "Jogue 25 partidas.",
		"moedas": 40, "icone": "camadas"},
	{"id": "colecionador", "nome": "COFRINHO CHEIO", "descricao": "Ganhe 500 moedas no total.",
		"moedas": 30, "icone": "cofrinho"},
	{"id": "primeira_compra", "nome": "DOCE NOVO", "descricao": "Compre um doce na sua coleção.",
		"moedas": 20, "icone": "doce"},
	{"id": "colecao_completa", "nome": "CONFEITARIA DOS SONHOS", "descricao": "Tenha todos os doces da coleção.",
		"moedas": 150, "icone": "doce"},
	{"id": "enciclopedia", "nome": "ENCICLOPÉDIA", "descricao": "Veja todas as perguntas do jogo.",
		"moedas": 50, "icone": "interrogacao"},
]

const PONTOS_CHUVA := 2000
const SEGUNDOS_RELAMPAGO := 3.0


static func dados(id: String) -> Dictionary:
	for conquista in LISTA:
		if conquista["id"] == id:
			return conquista
	return {}


static func icone(conquista: Dictionary) -> Texture2D:
	return load("res://assets/icones/%s.svg" % conquista["icone"])


static func quantidade_desbloqueada() -> int:
	return LISTA.filter(func(c): return Progresso.conquistas.has(c["id"])).size()


## Desbloqueia as conquistas alcançadas agora e retorna as novas (na ordem da
## LISTA). `partida` é o Jogo.resumo da partida que acabou de terminar.
static func verificar(partida: Dictionary) -> Array:
	var novas := []
	# Repete porque a recompensa de uma conquista pode completar o "cofrinho"
	var mudou := true
	while mudou:
		mudou = false
		for conquista in LISTA:
			if not Progresso.conquistas.has(conquista["id"]) and alcancou(conquista["id"], partida):
				Progresso.desbloquear_conquista(conquista["id"], conquista["moedas"])
				novas.append(conquista)
				mudou = true
	novas.sort_custom(func(a, b): return LISTA.find(a) < LISTA.find(b))
	return novas


## Se a condição da conquista `id` é verdadeira agora.
static func alcancou(id: String, partida: Dictionary) -> bool:
	var niveis := Progresso.niveis
	var estatisticas := Progresso.estatisticas
	var revisao: bool = partida.get("revisao", false)
	match id:
		"primeira_partida":
			return estatisticas["partidas"] + estatisticas["revisoes"] >= 1
		"primeira_aprovacao":
			return niveis.any(func(n): return n["aprovado"])
		"todos_niveis":
			return niveis.all(func(n): return n["aprovado"])
		"gabarito":
			return not revisao and partida.get("total", 0) == Jogo.PERGUNTAS_POR_PARTIDA \
				and partida.get("acertos", 0) == partida.get("total", 0)
		"ceu_estrelado":
			return niveis.all(func(n): return n["estrelas"] >= 3)
		"embalado":
			return partida.get("sequencia_maxima", 0) >= 5
		"relampago":
			var tempos: Array = partida.get("tempos", [])
			var resultados: Array = partida.get("resultados", [])
			for i in resultados.size():
				if resultados[i] and tempos[i] < SEGUNDOS_RELAMPAGO:
					return true
			return false
		"pontuador":
			return not revisao and partida.get("pontos", 0) >= PONTOS_CHUVA
		"sem_rodinhas":
			return not revisao and partida.get("nivel", 0) == 2 and partida.get("aprovado", false) \
				and partida.get("ajudas", 0) == 0
		"revisor":
			return revisao and partida.get("total", 0) > 0 and partida.get("acertos", 0) == partida.get("total", 0)
		"persistente":
			return estatisticas["partidas"] >= 10
		"dedicado":
			return estatisticas["partidas"] >= 25
		"colecionador":
			return estatisticas["moedas_ganhas"] >= 500
		"primeira_compra":
			return not Progresso.colecao["doces"].is_empty()
		"colecao_completa":
			# os doces dos eventos da temporada não contam (só saem em certas épocas)
			var normais := Colecao.LISTA.filter(func(d): return not d.has("evento"))
			return normais.all(func(d): return Colecao.tem(d["id"]))
		"enciclopedia":
			return Progresso.perguntas.size() >= Jogo.total_de_perguntas()
	return false
