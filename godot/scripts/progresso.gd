extends Node
## Progresso do jogador salvo em disco: níveis, títulos, moedas, configurações
## e histórico de cada pergunta. Disponível como `Progresso` (autoload).
##
## O arquivo tem um número de versão; saves antigos são convertidos ao carregar
## (ver _migrar), então ninguém perde o progresso quando o formato muda.

signal alterado

const CAMINHO := "user://salvamento.json"
const VERSAO := 2
const QUANTIDADE_NIVEIS := 3

## Por nível: melhor e última quantidade de acertos, estrelas (0 a 3), se já
## passou (e liberou o próximo), partidas jogadas e as perguntas da última partida.
var niveis: Array[Dictionary] = []
## Quantas vezes cada título foi conquistado ("noob", "pro", "mestre").
var titulos := {}
var moedas := 0
## volume_musica e volume_efeitos vão de 0 a 1.
var config := {}
## Histórico por id de pergunta: {"vistas", "acertos", "erros", "ultima_certa"}.
var perguntas := {}
## Totais gerais: partidas, revisoes, respostas, acertos, tempo_total (s),
## melhor_sequencia e moedas_ganhas (tudo que já ganhou, mesmo o que gastou).
var estatisticas := {}
## Conquistas desbloqueadas: {id: data "AAAA-MM-DD"}.
var conquistas := {}
## Coleção de doces 3D: {"doces": [ids comprados], "companheiro": id} (ver Colecao).
var colecao := {}
## Minha Confeitaria: açúcar, máquinas, estoque e encomendas (ver Confeitaria).
var confeitaria := {}
## Laboratório do Office: {"estrelas": {id_fase: 1..3}, "baus": {id_bau: true}} (ver Laboratorio).
var laboratorio := {}
## Baús surpresa fechados e garantia (ver Baus).
var baus := {}
## Missões do dia/semana e prêmio por entrar (ver Missoes).
var missoes := {}
## Nível e experiência do jogador (ver Experiencia).
var jogador := {}
## Doce Match: {"estrelas": {"1": 3, ...}} por nível (ver DoceMatch).
var doce_match := {}

## Quando verdadeiro, nada é gravado em disco (usado ao gerar prints e em testes).
var somente_memoria := false


func _ready() -> void:
	_zerar()
	carregar()


func _zerar() -> void:
	niveis.clear()
	for i in QUANTIDADE_NIVEIS:
		niveis.append({
			"recorde": 0, "ultima": -1, "estrelas": 0, "aprovado": false,
			"partidas": 0, "ultimas_perguntas": [], "recorde_pontos": 0,
		})
	titulos = {"noob": 0, "pro": 0, "mestre": 0}
	moedas = 0
	config = {"volume_musica": 0.8, "volume_efeitos": 1.0, "animacoes": true}
	perguntas = {}
	estatisticas = {
		"partidas": 0, "revisoes": 0, "respostas": 0, "acertos": 0, "tempo_total": 0.0,
		"melhor_sequencia": 0, "moedas_ganhas": 0, "match_recorde": 0, "match_partidas": 0,
	}
	conquistas = {}
	colecao = {"doces": [], "companheiro": "", "fragmentos": {}, "niveis": {}}
	confeitaria = Confeitaria.padrao()
	laboratorio = {"estrelas": {}, "baus": {}}
	baus = Baus.padrao()
	missoes = Missoes.padrao()
	jogador = {"xp": 0, "nivel": 1}
	doce_match = {"estrelas": {}}


# --- Consultas ---------------------------------------------------------------

## O primeiro nível está sempre liberado; os outros, depois de passar no anterior.
func nivel_liberado(indice: int) -> bool:
	return indice == 0 or niveis[indice - 1]["aprovado"]


func historico(id_pergunta: String) -> Dictionary:
	return perguntas.get(id_pergunta, {"vistas": 0, "acertos": 0, "erros": 0, "ultima_certa": true})


# --- Registro de uma partida -------------------------------------------------

## Guarda o resultado de uma partida. `respostas` é uma lista de
## {"id": String, "acertou": bool, "tempo": float}. Retorna o que mudou, para a
## tela de resultado comemorar: novo recorde, estrelas, aprovação, nível liberado.
func registrar_partida(nivel: int, respostas: Array, titulo: String, estrelas: int,
		moedas_ganhas: int, pontos := 0) -> Dictionary:
	var dados := niveis[nivel]
	var acertos := respostas.filter(func(r): return r["acertou"]).size()
	var aprovado := estrelas > 0
	var mudancas := {
		"novo_recorde": acertos > dados["recorde"] and dados["partidas"] > 0,
		"primeira_aprovacao": aprovado and not dados["aprovado"],
		"liberou_nivel": aprovado and not dados["aprovado"] and nivel + 1 < QUANTIDADE_NIVEIS,
		"mais_estrelas": estrelas > dados["estrelas"],
		"novo_recorde_pontos": pontos > dados["recorde_pontos"] and dados["partidas"] > 0,
	}
	dados["recorde_pontos"] = maxi(dados["recorde_pontos"], pontos)
	dados["recorde"] = maxi(dados["recorde"], acertos)
	dados["ultima"] = acertos
	dados["estrelas"] = maxi(dados["estrelas"], estrelas)
	dados["aprovado"] = dados["aprovado"] or aprovado
	dados["partidas"] += 1
	dados["ultimas_perguntas"] = respostas.map(func(r): return r["id"])
	if aprovado:
		titulos[titulo] = titulos.get(titulo, 0) + 1
	estatisticas["partidas"] += 1
	_registrar_respostas(respostas, moedas_ganhas)
	return mudancas


## Guarda uma partida de revisão: só atualiza o histórico das perguntas, as
## estatísticas e as moedas (os níveis não mudam).
func registrar_revisao(respostas: Array, moedas_ganhas: int) -> void:
	estatisticas["revisoes"] += 1
	_registrar_respostas(respostas, moedas_ganhas)


## Marca uma conquista como desbloqueada e dá a recompensa. Retorna falso se
## ela já tinha sido desbloqueada.
func desbloquear_conquista(id: String, recompensa: int) -> bool:
	if conquistas.has(id):
		return false
	conquistas[id] = Time.get_date_string_from_system()
	ganhar_moedas(recompensa)
	return true


func ganhar_moedas(quantidade: int) -> void:
	moedas += quantidade
	estatisticas["moedas_ganhas"] += quantidade
	salvar()


func _registrar_respostas(respostas: Array, moedas_ganhas: int) -> void:
	var sequencia := 0
	for r in respostas:
		var h := historico(r["id"])
		h["vistas"] += 1
		h[("acertos" if r["acertou"] else "erros")] += 1
		h["ultima_certa"] = r["acertou"]
		perguntas[r["id"]] = h
		sequencia = sequencia + 1 if r["acertou"] else 0
		estatisticas["melhor_sequencia"] = maxi(estatisticas["melhor_sequencia"], sequencia)
		estatisticas["tempo_total"] += r.get("tempo", 0.0)
		estatisticas["respostas"] += 1
		estatisticas["acertos"] += 1 if r["acertou"] else 0
	ganhar_moedas(moedas_ganhas)  # também salva


func gastar_moedas(quantidade: int) -> bool:
	if moedas < quantidade:
		return false
	moedas -= quantidade
	salvar()
	return true


## Apaga todo o progresso (as configurações de som são mantidas).
func apagar() -> void:
	var config_atual := config.duplicate()
	_zerar()
	config = config_atual
	salvar()


# --- Disco -------------------------------------------------------------------

func salvar() -> void:
	alterado.emit()
	if somente_memoria:
		return
	var dados := {
		"versao": VERSAO,
		"niveis": niveis,
		"titulos": titulos,
		"moedas": moedas,
		"config": config,
		"perguntas": perguntas,
		"estatisticas": estatisticas,
		"conquistas": conquistas,
		"colecao": colecao,
		"confeitaria": confeitaria,
		"laboratorio": laboratorio,
		"baus": baus,
		"missoes": missoes,
		"jogador": jogador,
		"doce_match": doce_match,
	}
	var arquivo := FileAccess.open(CAMINHO, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify(dados, "  "))


func carregar() -> void:
	if not FileAccess.file_exists(CAMINHO):
		return
	var dados = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO))
	if not dados is Dictionary:
		push_warning("Salvamento inválido; começando do zero.")
		return
	dados = _migrar(dados)
	for i in mini(QUANTIDADE_NIVEIS, dados.get("niveis", []).size()):
		niveis[i].merge(dados["niveis"][i], true)
		for chave in ["recorde", "ultima", "estrelas", "partidas", "recorde_pontos"]:
			niveis[i][chave] = int(niveis[i][chave])  # o JSON lê números como float
	titulos.merge(dados.get("titulos", {}), true)
	for chave in titulos:
		titulos[chave] = int(titulos[chave])
	moedas = int(dados.get("moedas", 0))
	config.merge(dados.get("config", {}), true)
	perguntas = dados.get("perguntas", {})
	for id in perguntas:
		for chave in ["vistas", "acertos", "erros"]:
			perguntas[id][chave] = int(perguntas[id][chave])
	var estatisticas_salvas: Dictionary = dados.get("estatisticas", {})
	if not estatisticas_salvas.has("moedas_ganhas"):
		# saves de antes desse campo: o mínimo que já ganhou é o que tem agora
		estatisticas_salvas["moedas_ganhas"] = moedas
	estatisticas.merge(estatisticas_salvas, true)
	for chave in estatisticas:
		if chave != "tempo_total":
			estatisticas[chave] = int(estatisticas[chave])
	conquistas = dados.get("conquistas", {})
	colecao.merge(dados.get("colecao", {}), true)
	confeitaria.merge(dados.get("confeitaria", {}), true)
	laboratorio.merge(dados.get("laboratorio", {}), true)
	for id in laboratorio["estrelas"]:
		laboratorio["estrelas"][id] = int(laboratorio["estrelas"][id])
	baus.merge(dados.get("baus", {}), true)
	for tipo in baus["fechados"]:
		baus["fechados"][tipo] = int(baus["fechados"][tipo])
	missoes.merge(dados.get("missoes", {}), true)
	jogador.merge(dados.get("jogador", {}), true)
	doce_match.merge(dados.get("doce_match", {}), true)
	jogador["xp"] = int(jogador["xp"])
	jogador["nivel"] = int(jogador["nivel"])
	for chave in ["fragmentos", "niveis"]:
		for id in colecao[chave]:
			colecao[chave][id] = int(colecao[chave][id])
	alterado.emit()


## Converte saves de versões antigas para o formato atual.
func _migrar(dados: Dictionary) -> Dictionary:
	var versao := int(dados.get("versao", 1))
	if versao < 2:
		# v1: {"acertos_por_nivel": [..3], "titulos": {...}, "moedas": n, "musica_ligada": bool}
		var niveis_v2 := []
		for acertos in dados.get("acertos_por_nivel", [0, 0, 0]):
			var a := int(acertos)
			# mesmas regras de Jogo.estrelas_para(): 6, 8 e 10 acertos de 10
			var estrelas := 3 if a >= 10 else (2 if a >= 8 else (1 if a >= 6 else 0))
			niveis_v2.append({
				"recorde": a, "ultima": a, "partidas": 1 if a > 0 else 0,
				"estrelas": estrelas, "aprovado": estrelas > 0,
			})
		dados["niveis"] = niveis_v2
		dados["config"] = {"volume_musica": 0.8 if dados.get("musica_ligada", true) else 0.0}
		dados.erase("acertos_por_nivel")
		dados.erase("musica_ligada")
	return dados
