extends Node
## Executa os testes (ver testes.gd).

var _falhas := 0
var _total := 0


func _ready() -> void:
	Progresso.somente_memoria = true
	await get_tree().process_frame
	_testar_regras()
	_testar_sorteio()
	_testar_progresso()
	_testar_migracao()
	await _testar_fluxo_completo()
	print("")
	if _falhas == 0:
		print("TODOS OS TESTES PASSARAM (%d verificações)" % _total)
	else:
		print("FALHARAM %d DE %d VERIFICAÇÕES" % [_falhas, _total])
	get_tree().quit(1 if _falhas > 0 else 0)


func verificar(condicao: bool, descricao: String) -> void:
	_total += 1
	if not condicao:
		_falhas += 1
		print("  FALHOU: ", descricao)


func _secao(nome: String) -> void:
	print("- ", nome)


# --- Regras ------------------------------------------------------------------

func _testar_regras() -> void:
	_secao("regras")
	verificar(Jogo.estrelas_para(50) == 0, "50% = 0 estrelas")
	verificar(Jogo.estrelas_para(60) == 1, "60% = 1 estrela")
	verificar(Jogo.estrelas_para(80) == 2, "80% = 2 estrelas")
	verificar(Jogo.estrelas_para(100) == 3, "100% = 3 estrelas")
	verificar(Jogo.acertos_para_passar() == 6, "passa com 6 de 10")
	verificar(Jogo.pontos_da_resposta(true, 0.0, 1) == 200, "resposta imediata vale 200")
	verificar(Jogo.pontos_da_resposta(true, 30.0, 1) == 100, "resposta no fim do tempo vale 100")
	verificar(Jogo.pontos_da_resposta(false, 1.0, 0) == 0, "erro vale 0")
	verificar(Jogo.multiplicador(2) == 1.0 and Jogo.multiplicador(3) == 1.5 and Jogo.multiplicador(5) == 2.0, "combos x1,5 e x2")
	verificar(Jogo.pontos_da_resposta(true, 15.0, 5) == 300, "meio tempo com combo x2 = 300")
	verificar(Jogo.formatar(2198) == "2.198" and Jogo.formatar(1234567) == "1.234.567" and Jogo.formatar(12) == "12", "formata milhar")
	var ids := {}
	for nivel in Jogo.niveis:
		verificar(nivel["perguntas"].size() >= Jogo.PERGUNTAS_POR_PARTIDA, "nível com perguntas suficientes")
		for p in nivel["perguntas"]:
			verificar(not ids.has(p["id"]), "id único: %s" % p["id"])
			ids[p["id"]] = true
			verificar(not str(p.get("explicacao", "")).strip_edges().is_empty(), "explicação em %s" % p["id"])
			var alternativas: Array = p["alternativas"]
			verificar(alternativas.size() == 4, "4 alternativas em %s" % p["id"])
			verificar(int(p["resposta"]) >= 0 and int(p["resposta"]) < 4, "resposta válida em %s" % p["id"])


# --- Sorteio -----------------------------------------------------------------

func _testar_sorteio() -> void:
	_secao("sorteio")
	Progresso.apagar()
	Jogo.preparar_partida(0)
	var primeira := Jogo.perguntas_partida.map(func(p): return p["id"])
	verificar(primeira.size() == 10, "sorteia 10 perguntas")
	verificar(_sem_repetidos(primeira), "sem perguntas repetidas na partida")
	for p in Jogo.perguntas_partida:
		verificar(p["id"].begins_with("f"), "pergunta do nível fácil")
		verificar(p["resposta"] >= 0 and p["alternativas"].size() == 4, "correta continua entre as alternativas")
	_jogar(10, 0)  # registra a partida no histórico
	Jogo.preparar_partida(0)
	var segunda := Jogo.perguntas_partida.map(func(p): return p["id"])
	var repetidas := segunda.filter(func(id): return id in primeira).size()
	verificar(repetidas == 0, "partida seguinte não repete as perguntas (repetiu %d)" % repetidas)


func _sem_repetidos(lista: Array) -> bool:
	var vistos := {}
	for item in lista:
		if vistos.has(item):
			return false
		vistos[item] = true
	return true


## Responde a partida preparada com `acertos` respostas certas e finaliza.
func _jogar(acertos: int, _nivel: int) -> void:
	for i in Jogo.perguntas_partida.size():
		var correta: int = Jogo.perguntas_partida[i]["resposta"]
		Jogo.registrar_resposta(correta if i < acertos else (correta + 1) % 4, 3.0)
	Jogo.finalizar_partida()


# --- Progresso ---------------------------------------------------------------

func _testar_progresso() -> void:
	_secao("progresso")
	Progresso.apagar()
	verificar(Progresso.nivel_liberado(0), "fácil começa liberado")
	verificar(not Progresso.nivel_liberado(1), "médio começa bloqueado")
	Jogo.preparar_partida(0)
	_jogar(5, 0)
	verificar(not Jogo.resumo["aprovado"], "5 acertos não passa")
	verificar(not Progresso.nivel_liberado(1), "médio continua bloqueado")
	verificar(Progresso.titulos["noob"] == 0, "sem título ao reprovar")
	Jogo.preparar_partida(0)
	_jogar(8, 0)
	verificar(Jogo.resumo["aprovado"] and Jogo.resumo["estrelas"] == 2, "8 acertos passa com 2 estrelas")
	verificar(Jogo.resumo["liberou_nivel"], "avisa que liberou o próximo nível")
	verificar(Jogo.resumo["novo_recorde"], "avisa novo recorde (5 -> 8)")
	verificar(Progresso.nivel_liberado(1), "médio liberado")
	verificar(Progresso.titulos["noob"] == 1, "ganhou o título Noob")
	var moedas_antes := Progresso.moedas
	Jogo.preparar_partida(0)
	_jogar(3, 0)
	verificar(Progresso.niveis[0]["recorde"] == 8, "recorde continua 8 depois de jogar pior")
	verificar(Progresso.niveis[0]["recorde_pontos"] > 0, "guarda recorde de pontos")
	verificar(not Jogo.resumo["novo_recorde_pontos"], "jogar pior não é recorde de pontos")
	verificar(Progresso.niveis[0]["ultima"] == 3, "última partida = 3")
	verificar(Progresso.niveis[0]["estrelas"] == 2, "estrelas não diminuem")
	verificar(Progresso.moedas == moedas_antes + 3 * Jogo.MOEDAS_POR_ACERTO[0], "moedas por acerto")
	verificar(not Jogo.resumo["liberou_nivel"], "não avisa liberar de novo")
	verificar(not Progresso.gastar_moedas(Progresso.moedas + 1), "não gasta mais moedas do que tem")


func _testar_migracao() -> void:
	_secao("migração de save antigo")
	var antigo := {"acertos_por_nivel": [8.0, 3.0, 0.0], "titulos": {"pro": 2}, "moedas": 160.0, "musica_ligada": false}
	var novo: Dictionary = Progresso._migrar(antigo)
	verificar(novo["niveis"][0]["aprovado"] and novo["niveis"][0]["estrelas"] == 2, "8 acertos antigos = aprovado, 2 estrelas")
	verificar(not novo["niveis"][1]["aprovado"], "3 acertos antigos = não aprovado")
	verificar(novo["config"]["volume_musica"] == 0.0, "música desligada vira volume 0")


# --- Fluxo completo pelas telas ---------------------------------------------

func _testar_fluxo_completo() -> void:
	_secao("fluxo completo")
	Progresso.apagar()
	Telas.ir_para("niveis")
	verificar(await _esperar_tela("Niveis"), "abre a tela de níveis")
	Jogo.iniciar_nivel(2)  # bloqueado: não deve iniciar
	await get_tree().create_timer(0.8).timeout
	verificar(get_tree().current_scene.name == "Niveis", "nível bloqueado não inicia")

	Jogo.iniciar_nivel(0)
	verificar(await _esperar_tela("Partida", 8.0), "carregamento leva à partida")
	var partida := get_tree().current_scene

	# Sair: cancelar mantém na partida; confirmar volta aos níveis
	partida.get_node("%Sair").pressed.emit()
	var caixa := await _esperar_confirmacao()
	verificar(caixa != null, "pergunta antes de sair")
	if caixa:
		caixa.get_node("%Nao").pressed.emit()
		await get_tree().create_timer(0.5).timeout
		verificar(get_tree().current_scene == partida, "cancelar mantém a partida")
		verificar(not partida._pausado, "cronômetro volta a andar")

	# Ajudas: sem moedas ficam desativadas; com moedas, eliminam 2 erradas e dão +10 s
	verificar(partida._ajuda_eliminar.disabled, "sem moedas, ajuda desativada")
	Progresso.moedas = 100
	partida._atualizar_ajudas()
	verificar(not partida._ajuda_eliminar.disabled, "com moedas, ajuda ativada")
	partida._ajuda_eliminar.pressed.emit()
	var desativadas: int = partida._botoes.filter(func(b): return b.disabled).size()
	verificar(desativadas == 2, "eliminar desativa 2 alternativas")
	verificar(not partida._botoes[Jogo.perguntas_partida[0]["resposta"]].disabled, "a correta nunca é eliminada")
	verificar(Progresso.moedas == 100 - Jogo.CUSTO_ELIMINAR, "cobra as moedas")
	verificar(partida._ajuda_eliminar.disabled, "eliminar só uma vez por pergunta")
	var antes: float = partida._tempo_restante
	partida._ajuda_tempo.pressed.emit()
	verificar(partida._tempo_restante > antes + 9.0, "ganha +10 segundos")
	verificar(Jogo.ajudas_usadas == 2, "conta as ajudas usadas")

	for i in Jogo.PERGUNTAS_POR_PARTIDA:
		await get_tree().create_timer(0.25).timeout
		var correta: int = Jogo.perguntas_partida[i]["resposta"]
		partida._botoes[correta].pressed.emit()
		partida._botoes[correta].pressed.emit()  # toque duplo conta uma vez só
		await get_tree().create_timer(1.3).timeout
	verificar(await _esperar_tela("Aproveitamento"), "termina na revisão")
	verificar(Jogo.resultados.size() == 10 and Jogo.resultados.count(true) == 10, "10 respostas, todas certas")
	get_tree().current_scene.get_node("%Continuar").pressed.emit()
	verificar(await _esperar_tela("Resultado"), "abre o resultado")
	verificar(Jogo.resumo["estrelas"] == 3 and Jogo.resumo["titulo"] == "noob", "3 estrelas e título Noob")
	verificar(get_tree().current_scene.get_node("%ProximoNivel").visible, "oferece ir ao próximo nível")

	await _testar_configuracoes()

	for tela in ["niveis", "titulos", "como_jogar", "creditos", "sobre", "configuracoes", "inicio"]:
		Telas.ir_para(tela)
		await get_tree().create_timer(0.7).timeout
		verificar(get_tree().current_scene.scene_file_path == Telas.CENAS[tela], "abre %s" % tela)


func _testar_configuracoes() -> void:
	_secao("configurações")
	Telas.abrir("configuracoes")
	verificar(await _esperar_tela("Configuracoes"), "abre as configurações")
	var tela := get_tree().current_scene
	var controles := tela.find_children("*", "HSlider", true, false)
	verificar(controles.size() == 2, "dois controles de volume")
	if controles.size() == 2:
		controles[0].value = 30
		var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Audio.BUS_MUSICA))
		verificar(is_equal_approx(Progresso.config["volume_musica"], 0.3), "volume da música salvo em 30%")
		verificar(absf(db - linear_to_db(0.3)) < 0.01, "canal de música no volume certo")
		controles[1].value = 0
		verificar(AudioServer.is_bus_mute(AudioServer.get_bus_index(Audio.BUS_EFEITOS)), "efeitos em 0% = mudo")
	var moedas := Progresso.moedas
	verificar(moedas > 0, "tem moedas antes de apagar")
	tela.get_node("%Apagar").pressed.emit()
	var caixa := await _esperar_confirmacao()
	if caixa:
		caixa.get_node("%Nao").pressed.emit()
	await get_tree().create_timer(0.4).timeout
	verificar(Progresso.moedas == moedas, "cancelar não apaga nada")
	tela.get_node("%Apagar").pressed.emit()
	caixa = await _esperar_confirmacao()
	if caixa:
		caixa.get_node("%Sim").pressed.emit()
	await get_tree().create_timer(0.4).timeout
	verificar(Progresso.moedas == 0 and Progresso.niveis[0]["recorde"] == 0, "confirmar apaga o progresso")
	verificar(is_equal_approx(Progresso.config["volume_musica"], 0.3), "ajustes de som continuam")
	Progresso.config["volume_efeitos"] = 1.0
	Audio.aplicar_volumes()


func _esperar_tela(nome: String, limite := 4.0) -> bool:
	var tempo := 0.0
	while tempo < limite:
		var atual := get_tree().current_scene
		if atual and atual.name == nome:
			return true
		await get_tree().create_timer(0.1).timeout
		tempo += 0.1
	return false


func _esperar_confirmacao() -> Node:
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		var caixas := get_tree().root.find_children("Confirmacao", "Control", true, false)
		if not caixas.is_empty():
			return caixas[0]
	return null
