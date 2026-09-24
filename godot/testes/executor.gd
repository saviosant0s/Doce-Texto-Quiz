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
	_testar_revisao()
	_testar_conquistas()
	_testar_estatisticas()
	_testar_colecao()
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
	# Músicas: uma rodada toca todas, sem repetir a última em seguida
	Audio._fila.clear()  # começa uma rodada nova
	for rodada in 5:
		var tocadas := []
		for i in Audio.MUSICAS.size():
			var anterior := Audio.musica_atual
			Audio.proxima_musica()
			verificar(Audio.musica_atual != anterior, "não repete a música em seguida")
			tocadas.append(Audio.musica_atual)
		tocadas.sort()
		verificar(tocadas == range(Audio.MUSICAS.size()), "a rodada toca todas as músicas")
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
func _jogar(acertos: int, _nivel: int, tempo := 3.0) -> void:
	for i in Jogo.perguntas_partida.size():
		var correta: int = Jogo.perguntas_partida[i]["resposta"]
		Jogo.registrar_resposta(correta if i < acertos else (correta + 1) % 4, tempo)
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


# --- Revisão, conquistas e estatísticas -----------------------------------

func _testar_revisao() -> void:
	_secao("revisão de erros")
	Progresso.apagar()
	verificar(Jogo.perguntas_para_revisar().is_empty(), "sem erros, nada para revisar")
	Jogo.preparar_partida(0)
	_jogar(6, 0)  # passa com 6; erra 4
	var erradas := []
	for i in 10:
		if not Jogo.resultados[i]:
			erradas.append(Jogo.perguntas_partida[i]["id"])
	var para_revisar := Jogo.perguntas_para_revisar().map(func(p): return p["id"])
	verificar(para_revisar.size() == 4, "4 perguntas para revisar")
	verificar(erradas.all(func(id): return id in para_revisar), "são as que errou")
	var nivel_antes: Dictionary = Progresso.niveis[0].duplicate(true)
	var moedas_antes := Progresso.moedas
	Jogo.preparar_revisao()
	verificar(Jogo.revisao and Jogo.perguntas_partida.size() == 4, "revisão tem só as 4 erradas")
	verificar(Jogo.perguntas_partida.all(func(p): return p["nivel"] == 0), "cada pergunta sabe o nível de origem")
	_jogar(3, 0)
	verificar(Jogo.resumo["revisao"] and Jogo.resumo["restantes"] == 1, "corrigiu 3; falta 1")
	verificar(Progresso.niveis[0] == nivel_antes, "revisão não mexe no nível")
	verificar(Progresso.estatisticas["revisoes"] == 1, "conta a revisão")
	verificar(Progresso.moedas >= moedas_antes + 3 * Jogo.MOEDAS_POR_ACERTO_REVISAO, "moedas da revisão")
	Jogo.preparar_partida(0)
	verificar(not Jogo.revisao, "partida normal depois da revisão")
	Jogo.preparar_revisao()
	_jogar(1, 0)
	verificar(Jogo.perguntas_para_revisar().is_empty(), "revisou tudo")
	verificar(Progresso.conquistas.has("revisor"), "conquista por acertar a revisão toda")


func _testar_conquistas() -> void:
	_secao("conquistas")
	Progresso.apagar()
	var ids := {}
	for c in Conquistas.LISTA:
		verificar(not ids.has(c["id"]), "id de conquista único: %s" % c["id"])
		ids[c["id"]] = true
		verificar(ResourceLoader.exists("res://assets/icones/%s.svg" % c["icone"]), "ícone de %s existe" % c["id"])
	Jogo.preparar_partida(0)
	_jogar(4, 0, 10.0)
	var novas: Array = Jogo.resumo["conquistas"].map(func(c): return c["id"])
	verificar(novas == ["primeira_partida"], "primeira partida (e só ela): %s" % [novas])
	var moedas := Progresso.moedas
	verificar(Progresso.estatisticas["moedas_ganhas"] == moedas, "moedas ganhas incluem a recompensa")
	Jogo.preparar_partida(0)
	_jogar(10, 0, 2.0)
	novas = Jogo.resumo["conquistas"].map(func(c): return c["id"])
	for id in ["primeira_aprovacao", "gabarito", "embalado", "relampago"]:
		verificar(id in novas, "desbloqueia %s" % id)
	verificar(not "primeira_partida" in novas, "não repete conquista")
	verificar(not "todos_niveis" in novas, "ainda não passou em todos")
	# difícil sem ajudas
	Progresso.niveis[1]["aprovado"] = true
	Jogo.preparar_partida(2)
	Jogo.ajudas_usadas = 0
	_jogar(7, 2, 12.0)
	novas = Jogo.resumo["conquistas"].map(func(c): return c["id"])
	verificar("sem_rodinhas" in novas and "todos_niveis" in novas, "sem rodinhas e confeitaria completa")
	verificar(Conquistas.quantidade_desbloqueada() == Progresso.conquistas.size(), "contagem de desbloqueadas")
	Progresso.estatisticas["partidas"] = 24
	Jogo.preparar_partida(0)
	_jogar(2, 0, 20.0)
	novas = Jogo.resumo["conquistas"].map(func(c): return c["id"])
	verificar("persistente" in novas and "dedicado" in novas, "10 e 25 partidas")


func _testar_estatisticas() -> void:
	_secao("estatísticas")
	Progresso.apagar()
	var zerado := Jogo.acerto_por_assunto()
	verificar(zerado["word"]["respostas"] == 0 and zerado["excel"]["respostas"] == 0, "começa sem respostas")
	verificar(Jogo.mais_erradas(3).is_empty(), "sem erradas no começo")
	for nivel in Jogo.niveis:
		for p in nivel["perguntas"]:
			verificar(p.get("assunto", "") in ["word", "excel", "geral"], "assunto válido em %s" % p["id"])
	Jogo.preparar_partida(0)
	_jogar(7, 0)
	var totais := Jogo.acerto_por_assunto()
	var respostas := 0
	var acertos := 0
	for assunto in totais:
		respostas += totais[assunto]["respostas"]
		acertos += totais[assunto]["acertos"]
	verificar(respostas == 10 and acertos == 7, "soma por assunto bate com a partida")
	verificar(Progresso.estatisticas["respostas"] == 10 and Progresso.estatisticas["acertos"] == 7, "totais gerais")
	var erradas := Jogo.mais_erradas(5)
	verificar(erradas.size() == 3 and erradas.all(func(p): return p["erros"] == 1), "3 mais erradas")
	verificar(Jogo.pergunta_por_id("m07")["nivel"] == 1, "acha pergunta pelo id")
	verificar(Jogo.total_de_perguntas() == 60, "60 perguntas no total")


func _testar_colecao() -> void:
	_secao("coleção de doces 3D")
	Progresso.apagar()
	var ids := {}
	for doce in Colecao.LISTA:
		verificar(not ids.has(doce["id"]), "doce com id único: %s" % doce["id"])
		ids[doce["id"]] = true
		verificar(not doce["curiosidade"].is_empty(), "curiosidade em %s" % doce["id"])
		var pivo := Node3D.new()
		verificar(Doces3D.montar(doce["id"], pivo), "monta o doce 3D %s" % doce["id"])
		verificar(pivo.find_child("Olhos", true, false) != null, "%s tem olhos (para piscar)" % doce["id"])
		pivo.free()
	for id in Colecao.LISTA.map(func(d): return d["id"]) + Doces3D.PERSONAGENS:
		verificar(ResourceLoader.exists("res://assets/doces_3d/fotos/%s.png" % id), "foto 3D de %s" % id)
	for nome in Personagens.FOTOS_3D:
		verificar(Personagens.textura(nome).resource_path.contains("doces_3d/fotos"), "%s usa a foto 3D" % nome)
	verificar(Colecao.tem("brigadeiro"), "começa com o brigadeiro")
	verificar(Colecao.quantidade() == 1, "começa com 1 doce")
	verificar(not Colecao.tem("bala"), "bala não vem de graça")
	verificar(not Colecao.comprar("bala"), "sem moedas não compra")
	Progresso.moedas = 150
	verificar(Colecao.comprar("bala"), "compra a bala com 150 moedas")
	verificar(Progresso.moedas == 50 and Colecao.tem("bala"), "cobrou 100 e a bala é sua")
	verificar(not Colecao.comprar("bala"), "não compra o mesmo doce duas vezes")
	Progresso.moedas = 9999
	verificar(not Colecao.comprar("cupcake") and not Colecao.tem("cupcake"), "doce de título não se compra")
	Progresso.titulos["pro"] = 1
	verificar(Colecao.tem("cupcake"), "cupcake vem com o título Pro")
	verificar(not Colecao.escolher_companheiro("pudim"), "não escolhe companheiro que não tem")
	verificar(Colecao.escolher_companheiro("bala") and Colecao.companheiro() == "bala", "bala é a companheira")
	var novas: Array = Conquistas.verificar({}).map(func(c): return c["id"])
	verificar("primeira_compra" in novas, "conquista da primeira compra")
	verificar(Progresso.colecao["doces"] == ["bala"], "salva os doces comprados")


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

	# Botão "voltar" do celular: pergunta antes de sair; voltar de novo cancela
	Telas.voltar_pelo_botao()
	caixa = await _esperar_confirmacao()
	verificar(caixa != null, "voltar do celular pergunta antes de sair")
	Telas.voltar_pelo_botao()
	await get_tree().create_timer(0.5).timeout
	verificar(get_tree().current_scene == partida and not partida._pausado, "voltar de novo cancela e continua")

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

	await _testar_telas_novas()
	await _testar_vila()
	await _testar_tela_colecao()
	await _testar_configuracoes()

	# Botão "voltar" fora da partida
	Telas.ir_para("niveis")
	await _esperar_tela("Niveis")
	await get_tree().create_timer(0.4).timeout
	Telas.abrir("creditos")
	verificar(await _esperar_tela("Creditos"), "abre créditos")
	await get_tree().create_timer(0.4).timeout
	Telas.voltar_pelo_botao()
	verificar(await _esperar_tela("Niveis"), "voltar do celular retorna à tela anterior")
	await get_tree().create_timer(0.4).timeout
	Telas.voltar_pelo_botao()
	verificar(await _esperar_tela("Inicio"), "voltar nos níveis vai ao início")
	await get_tree().create_timer(0.4).timeout
	Telas.voltar_pelo_botao()
	caixa = await _esperar_confirmacao()
	verificar(caixa != null, "voltar no início pergunta se quer sair do jogo")
	if caixa:
		caixa.get_node("%Nao").pressed.emit()
	await get_tree().create_timer(0.4).timeout

	for tela in ["niveis", "titulos", "como_jogar", "creditos", "sobre", "configuracoes", "inicio"]:
		Telas.ir_para(tela)
		await get_tree().create_timer(0.7).timeout
		verificar(get_tree().current_scene.scene_file_path == Telas.CENAS[tela], "abre %s" % tela)


## Botão de revisão na tela de níveis e abas da tela de troféus.
func _testar_telas_novas() -> void:
	Progresso.apagar()
	Jogo.preparar_partida(0)
	_jogar(6, 0)
	Telas.ir_para("niveis")
	verificar(await _esperar_tela("Niveis"), "volta aos níveis")
	await get_tree().create_timer(0.2).timeout
	var botao := get_tree().current_scene.find_child("Revisar", true, false) as Button
	verificar(botao != null and botao.text == "REVISAR ERROS (4)", "botão de revisar com 4 erros")
	if botao:
		botao.pressed.emit()
		verificar(await _esperar_tela("Partida", 8.0), "revisão abre a partida")
		verificar(Jogo.revisao, "partida em modo revisão")
		var contador: String = get_tree().current_scene.get_node("%Contador").text
		verificar(contador.begins_with("REVISÃO"), "contador mostra REVISÃO")
	# Doces 3D vivos nos cartões: toque rápido no doce abre o nível
	Telas.ir_para("niveis")
	await _esperar_tela("Niveis")
	await get_tree().create_timer(0.3).timeout
	var doces := get_tree().current_scene.find_children("Doce3D", "Control", true, false)
	verificar(doces.size() == 3, "doce 3D em cada cartão de nível (%d)" % doces.size())
	if doces.size() == 3:
		verificar(doces[2].silhueta and not doces[0].silhueta, "nível bloqueado (difícil) em silhueta 3D")
		doces[0].tocado.emit()
		verificar(await _esperar_tela("Carregamento"), "toque no doce do cartão abre o nível")
		Telas.ir_para("titulos")
	verificar(await _esperar_tela("Titulos"), "abre os troféus")
	var tela := get_tree().current_scene
	for aba in 3:
		tela.mostrar_aba(aba)
		await get_tree().process_frame
		verificar(tela._paginas[aba].visible, "aba %d visível" % aba)
	var cartoes: Array = tela._paginas[1].find_children("*", "PanelContainer", true, false) \
		.filter(func(c): return Conquistas.dados(c.name) != {})
	verificar(cartoes.size() == Conquistas.LISTA.size(), "um cartão por conquista")


## Vila dos Doces: andar, chegar na porta, entrar e voltar para a porta.
func _testar_vila() -> void:
	_secao("vila dos doces")
	Vila.ultima_porta = ""
	Telas.ir_para("vila")
	verificar(await _esperar_tela("Vila"), "abre a vila")
	var vila: Vila = get_tree().current_scene
	verificar(vila.jogador != null and vila.jogador.id == "brigadeiro", "o jogador é o brigadeiro (sem companheiro)")
	verificar(vila.find_children("*", "DoceAndante", true, false).size() >= 3, "moradores passeando")
	var inicio := vila.jogador.global_position
	for i in 20:
		vila.jogador.andar(Vector3(0, 0, -1), 1.0 / 60.0)
		await get_tree().physics_frame
	verificar(vila.jogador.global_position.z < inicio.z - 0.5, "o doce anda para frente")
	# leva o doce até a porta da escola
	vila.jogador.global_position = vila._portas["escola"]["porta"]
	for i in 6:
		await get_tree().physics_frame
	verificar(vila._porta_atual == "escola", "chegou na porta da escola")
	verificar(vila._botao_entrar.visible and vila._botao_entrar.text == "JOGAR O QUIZ", "aparece o botão de entrar")
	vila.entrar("fliperama")
	await get_tree().create_timer(0.3).timeout
	verificar(get_tree().current_scene == vila, "fliperama ainda não abre nada (em breve)")
	vila._botao_entrar.pressed.emit()
	verificar(await _esperar_tela("Niveis"), "entrar na escola abre os níveis")
	await get_tree().create_timer(0.4).timeout
	get_tree().current_scene.get_node("%Inicio").pressed.emit()
	verificar(await _esperar_tela("Vila"), "o botão de casa dos níveis volta para a vila")
	await get_tree().create_timer(0.3).timeout
	vila = get_tree().current_scene
	var porta: Vector3 = vila._portas["escola"]["porta"]
	verificar(vila.jogador.global_position.distance_to(porta) < 1.5, "volta na porta da escola")
	Vila.ultima_porta = ""


## Tela da coleção: comprar pela tela e ver o companheiro no carregamento.
func _testar_tela_colecao() -> void:
	Progresso.apagar()
	Progresso.moedas = 300
	Telas.ir_para("colecao")
	verificar(await _esperar_tela("Colecao"), "abre a coleção")
	var tela := get_tree().current_scene
	verificar(tela._cartoes.size() == Colecao.LISTA.size(), "um cartão por doce")
	# toque curto num cartão seleciona o doce; arrastar não
	var cartao: Control = tela._cartoes["pirulito"]
	var toque := InputEventMouseButton.new()
	toque.button_index = MOUSE_BUTTON_LEFT
	toque.pressed = true
	toque.global_position = Vector2(100, 100)
	cartao.gui_input.emit(toque)
	var solta: InputEventMouseButton = toque.duplicate()
	solta.pressed = false
	solta.global_position = Vector2(100, 160)  # arrastou 60 px: é rolagem
	cartao.gui_input.emit(solta)
	verificar(tela._selecionado != "pirulito", "arrastar sobre o cartão não seleciona")
	cartao.gui_input.emit(toque)
	solta.global_position = Vector2(103, 102)
	cartao.gui_input.emit(solta)
	verificar(tela._selecionado == "pirulito", "toque curto seleciona o doce")
	verificar(tela._visor.silhueta, "doce não comprado aparece em silhueta")
	var acao: Button = tela._acao
	verificar(acao.text == "COMPRAR POR 150", "botão mostra o preço")
	acao.pressed.emit()
	var caixa := await _esperar_confirmacao()
	verificar(caixa != null, "pergunta antes de comprar")
	if caixa:
		caixa.get_node("%Sim").pressed.emit()
	await get_tree().create_timer(0.5).timeout
	verificar(Colecao.tem("pirulito") and Progresso.moedas == 150 + 20, "comprou (e ganhou a conquista)")
	verificar(Colecao.companheiro() == "pirulito", "primeiro doce comprado vira companheiro")
	verificar(not tela._visor.silhueta, "depois de comprar aparece colorido")
	tela.selecionar("algodao_doce")
	verificar(acao.disabled and acao.text.begins_with("FALTAM"), "sem moedas: mostra quanto falta")
	Jogo.preparar_partida(0)
	Telas.ir_para("carregamento")
	verificar(await _esperar_tela("Carregamento"), "abre o carregamento")
	await get_tree().process_frame
	verificar(get_tree().current_scene.find_child("Companheiro", true, false) != null, "companheiro aparece no carregamento")
	Telas.ir_para("niveis")
	await _esperar_tela("Niveis")


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
