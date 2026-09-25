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
## - Revisão: uma partida só com as perguntas que o jogador errou da última vez
##   (de qualquer nível). Não conta para os níveis, mas corrige o histórico.
## - Cada acerto (partida ou revisão) também dá açúcar para a Minha
##   Confeitaria (Confeitaria.ACUCAR_POR_ACERTO).

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
const MOEDAS_POR_ACERTO_REVISAO := 3

## Níveis e perguntas, lidos de dados/perguntas.json.
var niveis: Array = []

# --- Partida atual ---
var nivel_atual := 0
## Verdadeiro durante uma partida de revisão (perguntas erradas de todos os níveis).
var revisao := false
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


## Começa uma revisão das perguntas erradas (se houver alguma).
func iniciar_revisao() -> void:
	if perguntas_para_revisar().is_empty():
		return
	preparar_revisao()
	Telas.ir_para("carregamento")


## Zera a partida e sorteia as perguntas, sem trocar de tela.
func preparar_partida(indice: int) -> void:
	_zerar_partida()
	nivel_atual = indice
	_sortear_perguntas()


## Zera a partida e escolhe até PERGUNTAS_POR_PARTIDA perguntas erradas.
func preparar_revisao() -> void:
	_zerar_partida()
	revisao = true
	var erradas := perguntas_para_revisar()
	erradas.shuffle()
	perguntas_partida.clear()
	for original in erradas.slice(0, PERGUNTAS_POR_PARTIDA):
		perguntas_partida.append(_embaralhar(original))


## Perguntas (de todos os níveis) que o jogador errou na última vez que viu.
## Cada uma vem com "nivel" (índice do nível de onde veio).
func perguntas_para_revisar() -> Array:
	var lista := []
	for i in niveis.size():
		for pergunta in niveis[i]["perguntas"]:
			var h := Progresso.historico(pergunta["id"])
			if h["vistas"] > 0 and not h["ultima_certa"]:
				var copia: Dictionary = pergunta.duplicate()
				copia["nivel"] = i
				lista.append(copia)
	return lista


## Pergunta original pelo id (com "nivel"), ou vazio se não existir.
func pergunta_por_id(id: String) -> Dictionary:
	for i in niveis.size():
		for pergunta in niveis[i]["perguntas"]:
			if pergunta["id"] == id:
				var copia: Dictionary = pergunta.duplicate()
				copia["nivel"] = i
				return copia
	return {}


func total_de_perguntas() -> int:
	var total := 0
	for nivel in niveis:
		total += nivel["perguntas"].size()
	return total


# --- Estatísticas --------------------------------------------------------------

## Respostas e acertos por assunto ("word", "excel", "geral"), somando o
## histórico de todas as perguntas: {"word": {"respostas": n, "acertos": n}, ...}.
func acerto_por_assunto() -> Dictionary:
	var totais := {}
	for assunto in ["word", "excel", "geral"]:
		totais[assunto] = {"respostas": 0, "acertos": 0}
	for nivel in niveis:
		for pergunta in nivel["perguntas"]:
			var h := Progresso.historico(pergunta["id"])
			var t: Dictionary = totais[pergunta.get("assunto", "geral")]
			t["respostas"] += h["acertos"] + h["erros"]
			t["acertos"] += h["acertos"]
	return totais


## As `quantidade` perguntas que o jogador mais errou (só as que errou alguma
## vez), com "erros" e "vistas" do histórico.
func mais_erradas(quantidade: int) -> Array:
	var lista := []
	for nivel in niveis:
		for pergunta in nivel["perguntas"]:
			var h := Progresso.historico(pergunta["id"])
			if h["erros"] > 0:
				var copia: Dictionary = pergunta.duplicate()
				copia["erros"] = h["erros"]
				copia["vistas"] = h["vistas"]
				lista.append(copia)
	# Mais erros primeiro; no empate, a que tem a maior proporção de erros
	lista.sort_custom(func(a, b):
		if a["erros"] != b["erros"]:
			return a["erros"] > b["erros"]
		return float(a["erros"]) / a["vistas"] > float(b["erros"]) / b["vistas"])
	return lista.slice(0, quantidade)


func _zerar_partida() -> void:
	revisao = false
	resultados.clear()
	respostas.clear()
	tempos.clear()
	pontos = 0
	sequencia = 0
	ajudas_usadas = 0
	ultimo_ganho = {"pontos": 0, "multiplicador": 1.0}
	resumo = {}


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


## Calcula nota, estrelas, título e moedas, salva no Progresso e verifica as
## conquistas. O resultado fica em `resumo` para as telas seguintes.
func finalizar_partida() -> void:
	var nota := aproveitamento()
	var acertos := resultados.count(true)
	var lista := []
	var sequencia_maxima := 0
	var seguidos := 0
	for i in resultados.size():
		lista.append({"id": perguntas_partida[i]["id"], "acertou": resultados[i], "tempo": tempos[i]})
		seguidos = seguidos + 1 if resultados[i] else 0
		sequencia_maxima = maxi(sequencia_maxima, seguidos)
	resumo = {
		"revisao": revisao,
		"nivel": nivel_atual,
		"acertos": acertos,
		"total": resultados.size(),
		"nota": nota,
		"pontos": pontos,
		"ajudas": ajudas_usadas,
		"sequencia_maxima": sequencia_maxima,
		"tempos": tempos.duplicate(),
		"resultados": resultados.duplicate(),
	}
	if revisao:
		var moedas := acertos * MOEDAS_POR_ACERTO_REVISAO
		Progresso.registrar_revisao(lista, moedas)
		resumo.merge({"estrelas": 0, "aprovado": false, "titulo": "", "moedas": moedas,
			"restantes": perguntas_para_revisar().size()})
	else:
		var estrelas := estrelas_para(nota)
		var moedas: int = acertos * MOEDAS_POR_ACERTO[nivel_atual] + estrelas * MOEDAS_POR_ESTRELA
		var titulo: String = TITULOS[nivel_atual]
		resumo.merge({"estrelas": estrelas, "aprovado": estrelas > 0, "titulo": titulo, "moedas": moedas})
		resumo.merge(Progresso.registrar_partida(nivel_atual, lista, titulo, estrelas, moedas, pontos))
	resumo["acucar"] = acertos * Confeitaria.ACUCAR_POR_ACERTO
	Confeitaria.ganhar_acucar(resumo["acucar"])
	resumo["conquistas"] = Conquistas.verificar(resumo)


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
		perguntas_partida.append(_embaralhar(original))


## Cópia da pergunta com as alternativas em ordem aleatória.
func _embaralhar(original: Dictionary) -> Dictionary:
	var alternativas: Array = original["alternativas"].duplicate()
	var correta: String = alternativas[int(original["resposta"])]
	alternativas.shuffle()
	return {
		"id": original["id"],
		"assunto": original.get("assunto", "geral"),
		"nivel": original.get("nivel", nivel_atual),
		"enunciado": original["enunciado"],
		"alternativas": alternativas,
		"resposta": alternativas.find(correta),
		"explicacao": original.get("explicacao", ""),
	}
