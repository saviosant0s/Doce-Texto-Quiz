extends Node
## Regras do quiz e estado da partida atual. Disponível como `Jogo` (autoload).
##
## Regras:
## - Cada partida sorteia PERGUNTAS_POR_PARTIDA perguntas do nível (primeiro as
##   nunca vistas e as erradas da última vez; evita repetir a partida anterior).
## - Com NOTA_PARA_PASSAR% ou mais, o jogador passa no nível: ganha o título do
##   nível (Noob, Pro, Mestre) e libera o próximo.
## - Estrelas: 60% = 1, 80% = 2, 100% = 3. Moedas por acerto e por estrela.
## - Pontos: cada acerto vale PONTOS_BASE + até PONTOS_RAPIDEZ pela rapidez;
##   sequências de acertos multiplicam os pontos (combo).

const CAMINHO_PERGUNTAS := "res://dados/perguntas.json"
const TEMPO_POR_PERGUNTA := 30.0
const PERGUNTAS_POR_PARTIDA := 10
const NOTA_PARA_PASSAR := 60
const NOTAS_ESTRELAS := [60, 80, 100]
## Título ganho ao passar em cada nível (fácil, médio, difícil).
const TITULOS := ["noob", "pro", "mestre"]
const MOEDAS_POR_ACERTO := [5, 8, 12]
const MOEDAS_POR_ESTRELA := 10
const PONTOS_BASE := 100
const PONTOS_RAPIDEZ := 100
## Multiplicador de pontos por sequência de acertos: [acertos seguidos, multiplicador].
const COMBOS := [[5, 2.0], [3, 1.5]]
## Ajudas pagas com moedas (uma de cada por pergunta).
const CUSTO_ELIMINAR := 30  # tira duas alternativas erradas
const CUSTO_MAIS_TEMPO := 20  # +SEGUNDOS_EXTRAS no cronômetro
const SEGUNDOS_EXTRAS := 10.0

## Níveis e perguntas, lidos de dados/perguntas.json.
var niveis: Array = []

# --- Partida atual ---
var nivel_atual := 0
## Perguntas sorteadas, com as alternativas já embaralhadas.
var perguntas_partida: Array = []
var resultados: Array[bool] = []  # acertou/errou em cada pergunta
var respostas: Array[int] = []  # alternativa escolhida (-1 = tempo esgotado)
var tempos: Array[float] = []  # segundos gastos em cada pergunta
var pontos := 0
var sequencia := 0  # acertos seguidos até agora
var ajudas_usadas := 0
## Pontos ganhos na última resposta e o multiplicador usado (para a tela animar).
var ultimo_ganho := {"pontos": 0, "multiplicador": 1.0}
## Resumo da partida terminada (ver finalizar_partida).
var resumo := {}


func _ready() -> void:
	niveis = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_PERGUNTAS))["niveis"]


# --- Regras ------------------------------------------------------------------

func estrelas_para(nota: int) -> int:
	return NOTAS_ESTRELAS.filter(func(minimo): return nota >= minimo).size()


func acertos_para_passar() -> int:
	return ceili(PERGUNTAS_POR_PARTIDA * NOTA_PARA_PASSAR / 100.0)


func aproveitamento() -> int:
	if resultados.is_empty():
		return 0
	return roundi(100.0 * resultados.count(true) / resultados.size())


# --- Partida -----------------------------------------------------------------

## Começa uma partida no nível (se estiver liberado) e vai para o carregamento.
func iniciar_nivel(indice: int) -> void:
	if not Progresso.nivel_liberado(indice):
		return
	preparar_partida(indice)
	Telas.ir_para("carregamento")


## Zera a partida e sorteia as perguntas, sem trocar de tela.
func preparar_partida(indice: int) -> void:
	nivel_atual = indice
	resultados.clear()
	respostas.clear()
	tempos.clear()
	pontos = 0
	sequencia = 0
	ajudas_usadas = 0
	ultimo_ganho = {"pontos": 0, "multiplicador": 1.0}
	resumo = {}
	_sortear_perguntas()


## Registra a resposta da pergunta atual; `escolha` = -1 quando o tempo acaba.
func registrar_resposta(escolha: int, tempo: float) -> bool:
	var pergunta: Dictionary = perguntas_partida[respostas.size()]
	var acertou: bool = escolha == pergunta["resposta"]
	resultados.append(acertou)
	respostas.append(escolha)
	tempos.append(tempo)
	sequencia = sequencia + 1 if acertou else 0
	var ganho := pontos_da_resposta(acertou, tempo, sequencia)
	pontos += ganho
	ultimo_ganho = {"pontos": ganho, "multiplicador": multiplicador(sequencia)}
	return acertou


## Paga e registra uma ajuda. Retorna falso se não houver moedas.
func usar_ajuda(custo: int) -> bool:
	if not Progresso.gastar_moedas(custo):
		return false
	ajudas_usadas += 1
	return true


## Duas alternativas erradas (índices) da pergunta atual, para a ajuda "eliminar".
func alternativas_para_eliminar() -> Array:
	var correta: int = perguntas_partida[respostas.size()]["resposta"]
	var erradas := [0, 1, 2, 3].filter(func(i): return i != correta)
	erradas.shuffle()
	return erradas.slice(0, 2)


## Formata números com ponto de milhar: 2198 -> "2.198".
static func formatar(numero: int) -> String:
	var texto := str(absi(numero))
	var partes := []
	while texto.length() > 3:
		partes.push_front(texto.right(3))
		texto = texto.left(texto.length() - 3)
	partes.push_front(texto)
	return ("-" if numero < 0 else "") + ".".join(partes)


func multiplicador(acertos_seguidos: int) -> float:
	for combo in COMBOS:
		if acertos_seguidos >= combo[0]:
			return combo[1]
	return 1.0


## Acerto vale a base mais um bônus que cai conforme o tempo gasto (responder
## na hora = bônus cheio; no fim do tempo = sem bônus), vezes o combo.
func pontos_da_resposta(acertou: bool, tempo: float, acertos_seguidos: int) -> int:
	if not acertou:
		return 0
	var rapidez := clampf(1.0 - tempo / TEMPO_POR_PERGUNTA, 0.0, 1.0)
	return roundi((PONTOS_BASE + PONTOS_RAPIDEZ * rapidez) * multiplicador(acertos_seguidos))


## Calcula nota, estrelas, título e moedas, e salva no Progresso.
func finalizar_partida() -> void:
	var nota := aproveitamento()
	var estrelas := estrelas_para(nota)
	var acertos := resultados.count(true)
	var moedas: int = acertos * MOEDAS_POR_ACERTO[nivel_atual] + estrelas * MOEDAS_POR_ESTRELA
	var titulo: String = TITULOS[nivel_atual]
	var lista := []
	for i in resultados.size():
		lista.append({"id": perguntas_partida[i]["id"], "acertou": resultados[i], "tempo": tempos[i]})
	var mudancas := Progresso.registrar_partida(nivel_atual, lista, titulo, estrelas, moedas, pontos)
	resumo = {
		"nivel": nivel_atual,
		"acertos": acertos,
		"total": resultados.size(),
		"nota": nota,
		"estrelas": estrelas,
		"aprovado": estrelas > 0,
		"titulo": titulo,
		"moedas": moedas,
		"pontos": pontos,
		"ajudas": ajudas_usadas,
	}
	resumo.merge(mudancas)


## Escolhe as perguntas: primeiro as nunca vistas, depois as erradas da última
## vez, depois as menos vistas; as da partida anterior vão para o fim da fila.
func _sortear_perguntas() -> void:
	var anteriores: Array = Progresso.niveis[nivel_atual]["ultimas_perguntas"]
	var banco: Array = niveis[nivel_atual]["perguntas"].duplicate()
	var prioridade := {}
	for pergunta in banco:
		var h := Progresso.historico(pergunta["id"])
		var p := randf()  # desempate aleatório
		if h["vistas"] > 0:
			p += 1.0 if not h["ultima_certa"] else 2.0 + h["vistas"] * 0.5
		if pergunta["id"] in anteriores:
			p += 10.0
		prioridade[pergunta["id"]] = p
	banco.sort_custom(func(a, b): return prioridade[a["id"]] < prioridade[b["id"]])
	var escolhidas := banco.slice(0, PERGUNTAS_POR_PARTIDA)
	escolhidas.shuffle()  # para as "nunca vistas" não virem sempre primeiro
	perguntas_partida.clear()
	for original in escolhidas:
		var alternativas: Array = original["alternativas"].duplicate()
		var correta: String = alternativas[int(original["resposta"])]
		alternativas.shuffle()
		perguntas_partida.append({
			"id": original["id"],
			"enunciado": original["enunciado"],
			"alternativas": alternativas,
			"resposta": alternativas.find(correta),
			"explicacao": original.get("explicacao", ""),
		})
