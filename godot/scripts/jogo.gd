extends Node
## Regras do quiz e estado da partida atual. Disponível como `Jogo` (autoload).
##
## Regras:
## - Cada partida sorteia PERGUNTAS_POR_PARTIDA perguntas do nível (primeiro as
##   nunca vistas e as erradas da última vez; evita repetir a partida anterior).
## - Com NOTA_PARA_PASSAR% ou mais, o jogador passa no nível: ganha o título do
##   nível (Noob, Pro, Mestre) e libera o próximo.
## - Estrelas: 60% = 1, 80% = 2, 100% = 3. Moedas por acerto e por estrela.

const CAMINHO_PERGUNTAS := "res://dados/perguntas.json"
const TEMPO_POR_PERGUNTA := 30.0
const PERGUNTAS_POR_PARTIDA := 10
const NOTA_PARA_PASSAR := 60
const NOTAS_ESTRELAS := [60, 80, 100]
## Título ganho ao passar em cada nível (fácil, médio, difícil).
const TITULOS := ["noob", "pro", "mestre"]
const MOEDAS_POR_ACERTO := [5, 8, 12]
const MOEDAS_POR_ESTRELA := 10

## Níveis e perguntas, lidos de dados/perguntas.json.
var niveis: Array = []

# --- Partida atual ---
var nivel_atual := 0
## Perguntas sorteadas, com as alternativas já embaralhadas.
var perguntas_partida: Array = []
var resultados: Array[bool] = []  # acertou/errou em cada pergunta
var respostas: Array[int] = []  # alternativa escolhida (-1 = tempo esgotado)
var tempos: Array[float] = []  # segundos gastos em cada pergunta
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
	resumo = {}
	_sortear_perguntas()


## Registra a resposta da pergunta atual; `escolha` = -1 quando o tempo acaba.
func registrar_resposta(escolha: int, tempo: float) -> bool:
	var pergunta: Dictionary = perguntas_partida[respostas.size()]
	var acertou: bool = escolha == pergunta["resposta"]
	resultados.append(acertou)
	respostas.append(escolha)
	tempos.append(tempo)
	return acertou


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
	var mudancas := Progresso.registrar_partida(nivel_atual, lista, titulo, estrelas, moedas)
	resumo = {
		"nivel": nivel_atual,
		"acertos": acertos,
		"total": resultados.size(),
		"nota": nota,
		"estrelas": estrelas,
		"aprovado": estrelas > 0,
		"titulo": titulo,
		"moedas": moedas,
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
