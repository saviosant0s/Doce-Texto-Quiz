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
	_testar_confeitaria()
	_testar_doce_match()
	_testar_formulas()
	_testar_documento_word()
	_testar_laboratorio()
	_testar_companheiros_e_baus()
	_testar_missoes_e_nivel()
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
	# Efeitos sonoros: todos carregam e vários tocam ao mesmo tempo
	verificar(Audio.EFEITOS.values().all(func(e): return e != null) and Audio.EFEITOS.size() >= 9, "efeitos sonoros carregados")
	Audio.tocar("moeda")
	Audio.tocar("estouro", 1.3, -6.0)
	var tocando := Audio._efeitos.filter(func(c): return c.stream != null).size()
	verificar(tocando >= 2, "dois efeitos tocam juntos (um não corta o outro)")
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
	verificar(Jogo.total_de_perguntas() == 150, "150 perguntas no total")


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
	await _testar_tela_confeitaria()
	await _testar_tela_doce_match()
	await _testar_tela_laboratorio()
	await _testar_telas_baus_e_missoes()
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
	# primeiros passos: a seta aponta o próximo prédio conforme o progresso
	var passo_esperado := Vila.proximo_passo()
	verificar(vila.passo_tutorial == passo_esperado, "tutorial aponta o próximo passo (%s)" % passo_esperado)
	verificar((vila.find_child("SetaTutorial", false, false) != null) == (passo_esperado != ""), "seta do tutorial só quando falta algo")
	var partidas_antes: int = Progresso.estatisticas["partidas"]
	var match_antes: int = Progresso.estatisticas["match_partidas"]
	var maquinas_antes: Dictionary = Progresso.confeitaria["maquinas"]
	Progresso.estatisticas["partidas"] = 0
	verificar(Vila.proximo_passo() == "escola", "tutorial: sem quiz jogado -> escola")
	Progresso.estatisticas["partidas"] = 1
	var lab_antes: Dictionary = Progresso.laboratorio.duplicate(true)
	Progresso.laboratorio = {"estrelas": {}, "baus": {}}
	verificar(Vila.proximo_passo() == "laboratorio", "tutorial: sem fase do laboratório -> laboratório")
	Progresso.laboratorio["estrelas"]["c1f1"] = 3
	Progresso.confeitaria["maquinas"] = {}
	verificar(Vila.proximo_passo() == "confeitaria", "tutorial: sem máquina -> confeitaria")
	Progresso.confeitaria["maquinas"] = {"brigadeiro": {"nivel": 1, "progresso": 0.0, "bandeja": 0}}
	Progresso.estatisticas["match_partidas"] = 0
	verificar(Vila.proximo_passo() == "fliperama", "tutorial: sem Doce Match -> fliperama")
	Progresso.estatisticas["match_partidas"] = 1
	verificar(Vila.proximo_passo() == "", "tutorial: tudo feito, some")
	Progresso.estatisticas["partidas"] = partidas_antes
	Progresso.estatisticas["match_partidas"] = match_antes
	Progresso.confeitaria["maquinas"] = maquinas_antes
	Progresso.laboratorio = lab_antes
	vila.set_physics_process(false)  # só o teste controla o doce
	var inicio := vila.jogador.global_position
	for i in 20:
		vila.jogador.andar(Vector3(0, 0, -1), 1.0 / 60.0)
		await get_tree().physics_frame
	verificar(vila.jogador.global_position.z < inicio.z - 0.5, "o doce anda para frente")
	# joystick até o fim corre; meio caminho só anda (num lugar aberto)
	vila.jogador.global_position = Vector3(-5, 0, 11)
	for i in 40:
		vila.jogador.andar(Vector3(1, 0, 0), 1.0 / 60.0)
		await get_tree().physics_frame
	var correndo := Vector2(vila.jogador.velocity.x, vila.jogador.velocity.z).length()
	verificar(correndo > DoceAndante.VELOCIDADE + 1.0, "joystick até o fim: corre")
	for i in 60:
		vila.jogador.andar(Vector3(0, 0, 0.6), 1.0 / 60.0)
		await get_tree().physics_frame
	var andando := Vector2(vila.jogador.velocity.x, vila.jogador.velocity.z).length()
	verificar(andando < DoceAndante.VELOCIDADE and andando > 1.0, "joystick pela metade: anda (freia e vira aos poucos)")
	# pulo: sobe e volta para o chão
	for i in 30:
		vila.jogador.andar(Vector3.ZERO, 1.0 / 60.0)
		await get_tree().physics_frame
	vila.jogador.pular()
	var mais_alto := 0.0
	for i in 90:
		vila.jogador.andar(Vector3.ZERO, 1.0 / 60.0)
		await get_tree().physics_frame
		mais_alto = maxf(mais_alto, vila.jogador.global_position.y)
	verificar(mais_alto > 0.8, "o doce pula")
	verificar(vila.jogador.is_on_floor() and vila.jogador.global_position.y < 0.1, "e cai de volta no chão")
	verificar(vila.find_child("Pular", true, false) is Button, "botão de pular na tela")
	# andando, o braço do "oi" desce e os braços balançam
	var aceno: Node3D = vila.jogador.find_child("Aceno", true, false)
	var balancos := []
	for i in 40:
		vila.jogador.andar(Vector3(1, 0, 0), 1.0 / 60.0)
		await get_tree().physics_frame
		balancos.append(aceno.rotation.x)
	verificar(absf(aceno.rotation.z - AnimacaoDoce.BRACO_ABAIXADO) < 0.2, "andando, o braço do aceno fica abaixado")
	verificar(balancos.max() - balancos.min() > 0.8, "os braços balançam ao andar")
	# passos: sempre um pé no chão e o outro no ar, alternando
	var anim: AnimacaoDoce = vila.jogador._animacao
	var alternou := {}
	var fisica_antes := vila.is_physics_processing()
	vila.set_physics_process(false)  # só o teste move o doce
	for i in 30:
		vila.jogador.andar(Vector3(1, 0, 0), 1.0 / 60.0)
		await get_tree().physics_frame
		await get_tree().process_frame
		var alturas := []
		for k in anim._pernas.size():
			alturas.append(anim._pernas[k].position.y - anim._base_pernas[k].y + anim._corpo.position.y)
		if alturas.min() < 0.005 and alturas.max() > 0.03:
			alternou[alturas.find(alturas.max())] = true
	vila.set_physics_process(fisica_antes)
	verificar(alternou.size() == 2, "os pés levantam alternados, um de cada vez (%s)" % str(alternou.keys()))
	# dois dedos: um no joystick e outro girando a visão / apertando PULAR
	vila.usar_camera(Vila.Camera.PERTO)
	var toque := InputEventScreenTouch.new()
	toque.index = 0
	toque.pressed = true
	toque.position = vila._joystick.get_global_rect().get_center() + Vector2(60, 0)
	vila._joystick._input(toque)
	verificar(vila._joystick.dedo == 0 and vila._joystick.vetor.x > 0.3, "1º dedo no joystick")
	var giro_antes: float = vila._giro
	var arrasto := InputEventScreenDrag.new()
	arrasto.index = 1
	arrasto.position = Vector2(900, 300)
	arrasto.relative = Vector2(80, 0)
	vila._unhandled_input(arrasto)
	verificar(absf(vila._giro - giro_antes) > 0.3 and vila._joystick.dedo == 0, "2º dedo gira a visão sem soltar o joystick")
	for i in 5:
		vila.jogador.andar(Vector3.ZERO, 1.0 / 60.0)
		await get_tree().physics_frame
	var pulo := InputEventScreenTouch.new()
	pulo.index = 1
	pulo.pressed = true
	pulo.position = vila._botao_pular.get_global_rect().get_center()
	vila._input(pulo)
	verificar(vila.jogador.velocity.y > 1.0, "2º dedo aperta PULAR")
	toque.pressed = false
	vila._joystick._input(toque)
	verificar(vila._joystick.dedo == -1 and vila._joystick.vetor == Vector2.ZERO, "soltar o dedo solta o joystick")
	vila.usar_camera(Vila.Camera.AEREA)
	vila.set_physics_process(true)
	# cada prédio tem o seu jeito, e tudo tem contorno de desenho
	var pecas := {}
	for id in ["escola", "confeitaria", "trofeus", "fliperama"]:
		var predio: Node3D = vila.find_child("Predio_" + id, true, false)
		pecas[predio.get_meta("pecas")] = true
	verificar(pecas.size() == 4, "os quatro prédios são diferentes")
	var blocos := vila.find_children("Bloco*", "MeshInstance3D", false, false)
	verificar(blocos.any(func(b): return b.name.begins_with("BlocoContorno")), "cenário com contorno de desenho")
	verificar(vila.find_children("*", "MeshInstance3D", true, false).size() < 300, "cenário juntado em poucos blocos (leve)")
	# câmeras: troca em ciclo, 1ª pessoa esconde o doce, a escolha fica salva
	vila.usar_camera(Vila.Camera.AEREA)
	vila.proxima_camera()
	verificar(vila.modo_camera == Vila.Camera.PERTO, "botão da câmera: aérea -> perto")
	vila.proxima_camera()
	verificar(vila.modo_camera == Vila.Camera.PRIMEIRA_PESSOA, "perto -> 1ª pessoa")
	verificar(not vila.jogador.get_node("Modelo/Corpo").visible, "em 1ª pessoa o doce fica escondido")
	verificar(Progresso.config["camera_vila"] == Vila.Camera.PRIMEIRA_PESSOA, "a câmera escolhida fica salva")
	var antes := vila.jogador.global_position
	var frente := vila._frente()
	for i in 20:
		vila.jogador.andar(frente, 1.0 / 60.0)
		await get_tree().physics_frame
	verificar((vila.jogador.global_position - antes).dot(frente) > 0.3, "em 1ª pessoa anda para onde olha")
	vila.proxima_camera()
	verificar(vila.modo_camera == Vila.Camera.AEREA and vila.jogador.get_node("Modelo/Corpo").visible, "volta para a aérea e o doce reaparece")
	# leva o doce até a porta da escola
	vila.jogador.global_position = vila._portas["escola"]["porta"]
	for i in 6:
		await get_tree().physics_frame
	verificar(vila._porta_atual == "escola", "chegou na porta da escola")
	verificar(vila._botao_entrar.visible and vila._botao_entrar.text == "JOGAR O QUIZ", "aparece o botão de entrar")
	verificar(Vila.PREDIOS.filter(func(p): return p["id"] == "fliperama")[0]["cena"] == "doce_match", "o Fliperama abre o Doce Match")
	# câmera não entra em parede: do lado de fora da escola até o meio dela
	var fora: Vector3 = vila._portas["escola"]["porta"] + Vector3(0, 1.5, 0)
	var meio: Vector3 = vila._portas["escola"]["no"].global_position + Vector3(0, 1.5, 0)
	var parou := CenarioVila.camera_sem_parede(vila.get_world_3d(), fora, meio)
	verificar(parou.distance_to(meio) > 1.8 and parou.distance_to(fora) < fora.distance_to(meio), "a câmera para antes da parede")
	vila._botao_entrar.pressed.emit()
	verificar(vila._entrando and not vila._botao_entrar.visible, "entrar começa a animação")
	await get_tree().create_timer(0.6).timeout
	verificar(vila._portas["escola"]["folha"].rotation.y < -1.0, "a porta abre")
	verificar(get_tree().current_scene == vila, "a tela do prédio espera a animação")
	verificar(await _esperar_tela("Niveis"), "entrar na escola abre os níveis")
	await get_tree().create_timer(0.4).timeout
	get_tree().current_scene.get_node("%Inicio").pressed.emit()
	verificar(await _esperar_tela("Vila"), "o botão de casa dos níveis volta para a vila")
	await get_tree().create_timer(0.3).timeout
	vila = get_tree().current_scene
	var porta: Vector3 = vila._portas["escola"]["porta"]
	verificar(vila.jogador.global_position.distance_to(porta) < 1.5, "volta na porta da escola")
	await get_tree().create_timer(1.2).timeout
	verificar(is_zero_approx(vila._portas["escola"]["folha"].rotation.y), "a porta fecha atrás do doce")
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


# --- Minha Confeitaria -----------------------------------------------------------

func _testar_confeitaria() -> void:
	_secao("minha confeitaria")
	Progresso.apagar()
	verificar(Confeitaria.liberada("brigadeiro") and not Confeitaria.liberada("maca"), "panela liberada; maçã só passando no fácil")
	verificar(not Confeitaria.construir_ou_melhorar("maca"), "não constrói máquina bloqueada")
	verificar(Confeitaria.construir_ou_melhorar("brigadeiro") and Confeitaria.nivel("brigadeiro") == 1, "constrói a panela de graça")
	verificar(Confeitaria.acucar() == Confeitaria.ACUCAR_PRESENTE, "primeira máquina vem com açúcar de presente")
	Progresso.confeitaria["acucar"] = 0
	var t0: float = Progresso.confeitaria["atualizado"]
	verificar(Confeitaria.atualizar(t0 + 60) == 0 and Confeitaria.parada("brigadeiro") == "SEM AÇÚCAR", "sem açúcar, a máquina para")
	Progresso.confeitaria["atualizado"] = t0
	Progresso.confeitaria["acucar"] = 22
	Confeitaria.atualizar(t0 + 12)  # 6 s já prontos + 12 s = 3 doces de 5 de açúcar
	verificar(Confeitaria.bandeja("brigadeiro") == 3 and Confeitaria.acucar() == 7, "açúcar vira doce na bandeja")
	Progresso.confeitaria["acucar"] = 5000
	Confeitaria.atualizar(t0 + 100000)
	verificar(Confeitaria.bandeja("brigadeiro") == Confeitaria.capacidade_bandeja("brigadeiro") and Confeitaria.parada("brigadeiro") == "BANDEJA CHEIA", "para com a bandeja cheia")
	var sobrou := Confeitaria.acucar()
	Confeitaria.atualizar(t0 + 100000 + 3 * Confeitaria.LIMITE_FORA)
	verificar(Confeitaria.acucar() == sobrou, "cheia, não gasta açúcar")
	verificar(Confeitaria.pegar("brigadeiro", 4) == 4 and Confeitaria.bandeja("brigadeiro") == 2, "pega doces da bandeja")
	verificar(Confeitaria.cobrar("brigadeiro", 3) == 3 * 2 + Confeitaria.GORJETA, "cliente paga o valor mais a gorjeta")
	Progresso.moedas = 0
	verificar(Confeitaria.vender_bandeja("brigadeiro") == 4 and Progresso.moedas == 4 and Confeitaria.bandeja("brigadeiro") == 0, "painel simples vende a bandeja")
	Progresso.moedas = 100
	verificar(Confeitaria.construir_ou_melhorar("brigadeiro") and Confeitaria.nivel("brigadeiro") == 2 \
		and Confeitaria.tempo("brigadeiro") < 6.0 and Confeitaria.capacidade_bandeja("brigadeiro") > 6, "melhorar: mais rápida e bandeja maior")
	verificar(not Confeitaria.construir_ou_melhorar("brigadeiro"), "sem moedas, não melhora")
	Progresso.moedas = 120
	verificar(Confeitaria.aumentar_carregar() and Confeitaria.carregar() == 8, "carrega mais doces")
	Progresso.niveis[0]["aprovado"] = true
	verificar(Confeitaria.liberada("maca") and not Confeitaria.construir_ou_melhorar("maca"), "passou no fácil: libera a maçã (mas custa moedas)")
	# o quiz dá açúcar: 10 por acerto
	Progresso.apagar()
	Jogo.preparar_partida(0)
	_jogar(7, 0)
	# 10 por acerto, +10% do brigadeiro (companheiro inicial)
	verificar(Jogo.resumo["acucar"] == 77 and Confeitaria.acucar() == 77, "cada acerto no quiz dá 10 de açúcar (+ bônus)")
	Jogo.preparar_revisao()
	_jogar(2, 0)
	verificar(Confeitaria.acucar() == 77 + Companheiros.com_bonus("acucar", Jogo.resumo["acertos"] * 10), "a revisão também dá açúcar")
	Progresso.apagar()


## Cozinha 3D: construir no círculo, pegar da bandeja, atender e recolher.
func _testar_cozinha() -> void:
	Progresso.apagar()
	var moedas_antes := 0
	Telas.ir_para("cozinha")
	verificar(await _esperar_tela("Cozinha"), "abre a cozinha da confeitaria")
	var cozinha: Cozinha = get_tree().current_scene
	cozinha.set_physics_process(false)  # o teste move o doce (e os clientes)
	cozinha._proximo_cliente = 999.0  # sem clientes chegando sozinhos
	var jogador := cozinha.jogador
	verificar(cozinha.find_child("JogarQuiz", true, false) is Button, "botão de ir para o quiz na cozinha")
	jogador.global_position = cozinha._circulos["brigadeiro"]["no"].global_position
	await get_tree().create_timer(Cozinha.TEMPO_CIRCULO + 0.4).timeout
	verificar(Confeitaria.construida("brigadeiro"), "parar no círculo constrói a panela")
	Progresso.confeitaria["maquinas"]["brigadeiro"]["bandeja"] = 3
	cozinha._atualizar_bandejas()
	verificar(cozinha._maquinas["brigadeiro"]["doces"].get_child_count() == 3, "a bandeja mostra os doces")
	jogador.global_position = cozinha._maquinas["brigadeiro"]["mesa"] + Vector3(0, 0, 1.0)
	await get_tree().create_timer(0.8).timeout
	verificar(cozinha.carregando.size() == 3 and Confeitaria.bandeja("brigadeiro") == 0, "pega os doces da bandeja")
	verificar(jogador.pilha().get_child_count() == 3, "carrega os doces em pilha")
	var cliente := cozinha.novo_cliente("brigadeiro", 2)
	cliente["no"].global_position = Cozinha.FILA[0]
	cliente["estado"] = "esperando"  # já chegou no balcão
	jogador.global_position = Cozinha.BALCAO + Vector3(0, 0, -1.0)
	await get_tree().create_timer(1.0).timeout
	verificar(cliente["estado"] == "saindo" and cozinha.carregando.size() == 1, "entrega no balcão e o cliente vai embora")
	verificar(cozinha.caixa == 2 * 2 + Confeitaria.GORJETA, "as moedas vão para o caixa")
	moedas_antes = Progresso.moedas
	jogador.global_position = Cozinha.CAIXA + Vector3(1.0, 0, 0)
	await get_tree().create_timer(0.3).timeout
	verificar(cozinha.caixa == 0 and Progresso.moedas == moedas_antes + 6, "recolhe as moedas do caixa")
	# câmeras: de cima -> perto -> 1ª pessoa, com paredes altas só nas de perto
	cozinha.usar_camera(Cozinha.Camera.DE_CIMA)
	verificar(not cozinha._paredes_altas.visible, "câmera de cima: cozinha aberta")
	cozinha.proxima_camera()
	verificar(cozinha.modo_camera == Cozinha.Camera.PERTO and cozinha._paredes_altas.visible, "câmera perto: com paredes altas")
	cozinha.proxima_camera()
	verificar(cozinha.modo_camera == Cozinha.Camera.PRIMEIRA_PESSOA and Progresso.config["camera_cozinha"] == Cozinha.Camera.PRIMEIRA_PESSOA, "1ª pessoa, e a escolha fica salva")
	verificar(jogador.pilha().is_visible_in_tree(), "em 1ª pessoa a pilha de doces continua aparecendo")
	var antes: float = cozinha._inclinacao
	var olhar := InputEventScreenDrag.new()
	olhar.index = 1
	olhar.relative = Vector2(0, -60)
	cozinha._unhandled_input(olhar)
	verificar(cozinha._inclinacao > antes + 0.3, "1ª pessoa: arrastar para cima olha para cima")
	olhar.relative = Vector2(0, 5000)
	cozinha._unhandled_input(olhar)
	verificar(is_equal_approx(cozinha._inclinacao, Cozinha.INCLINACAO_1P.x), "...e para baixo, até um limite")
	cozinha.usar_camera(Cozinha.Camera.DE_CIMA)
	jogador.global_position = Cozinha.SAIDA
	verificar(await _esperar_tela("Inicio"), "o tapete SAIR volta (sem histórico: início)")
	verificar(Confeitaria.bandeja("brigadeiro") == 1, "o doce que sobrou nas mãos volta para a bandeja")
	Progresso.apagar()


func _testar_tela_confeitaria() -> void:
	Progresso.apagar()
	Telas.ir_para("confeitaria")
	verificar(await _esperar_tela("Confeitaria"), "abre o painel simples da confeitaria")
	var caixa := await _esperar_confirmacao()
	verificar(caixa != null, "primeira visita explica como funciona")
	if caixa:
		caixa.cancelar()
	await get_tree().create_timer(0.3).timeout
	var tela := get_tree().current_scene
	verificar(tela._cartoes.size() == Confeitaria.MAQUINAS.size(), "um cartão por máquina")
	var principal: Button = tela._cartoes["brigadeiro"]["principal"]
	verificar(principal.text == "CONSTRUIR GRÁTIS", "a panela de brigadeiro começa para construir")
	verificar(tela._cartoes["cupcake"]["principal"].disabled, "máquina bloqueada não constrói")
	principal.pressed.emit()
	verificar(Confeitaria.construida("brigadeiro") and principal.text.begins_with("MELHORAR"), "botão constrói a máquina")
	Progresso.confeitaria["maquinas"]["brigadeiro"]["bandeja"] = 6
	tela._atualizar_tudo()
	var vender: Button = tela._cartoes["brigadeiro"]["vender"]
	verificar(vender.text == "VENDER 6/6 · +12", "botão de vender mostra quanto ganha")
	vender.pressed.emit()
	verificar(Progresso.moedas == 12 and Confeitaria.bandeja("brigadeiro") == 0, "vende pela tela")
	await _testar_cozinha()
	Progresso.moedas = 12
	Telas.ir_para("niveis")
	await _esperar_tela("Niveis")
	verificar(get_tree().current_scene.find_child("Confeitaria", true, false) is Button, "botão da confeitaria no menu dos níveis")


# --- Doce Match ----------------------------------------------------------------------

func _testar_doce_match() -> void:
	_secao("doce match")
	var jogo := DoceMatch.new(7)
	verificar(jogo.filas().is_empty(), "o tabuleiro começa sem filas prontas")
	verificar(not jogo.jogada_possivel().is_empty(), "e com pelo menos uma jogada")
	verificar(not jogo.trocar(Vector2i(0, 0), Vector2i(2, 0)), "só troca peças vizinhas")
	# tabuleiro montado à mão: trocar (2,1) com (2,0) forma uma fila de 3 na linha 0
	for y in DoceMatch.ALTURA:
		for x in DoceMatch.LARGURA:
			jogo.grade[y][x] = (x + y * 2) % 3 + 3  # tipos 3,4,5 sem filas
	jogo.grade[0][0] = 0
	jogo.grade[0][1] = 0
	jogo.grade[0][2] = 1
	jogo.grade[1][2] = 0
	verificar(jogo.filas().is_empty(), "(montado sem filas)")
	var antes := jogo.jogadas
	jogo.grade[7][7] = jogo.grade[7][6]  # duas iguais lado a lado: trocar não muda nada
	var copia := jogo.grade.duplicate(true)
	verificar(not jogo.trocar(Vector2i(6, 7), Vector2i(7, 7)) and jogo.grade == copia and jogo.jogadas == antes,
		"troca que não forma fila é desfeita e não gasta jogada")
	verificar(jogo.trocar(Vector2i(2, 1), Vector2i(2, 0)) and jogo.jogadas <= antes - 1, "troca que forma fila vale e gasta uma jogada")
	var passos := jogo.resolver()
	verificar(passos.size() >= 1 and jogo.pontos >= 3 * DoceMatch.PONTOS_POR_PECA, "a fila some e dá pontos")
	var vazias := 0
	for linha in jogo.grade:
		vazias += linha.count(-1)
	verificar(vazias == 0 and jogo.filas().is_empty(), "as peças caem e o tabuleiro fica cheio, sem filas")
	verificar(passos.size() < 2 or passos[1]["combo"] == 2, "cascata conta como combo")
	var outro := DoceMatch.new(3)
	outro.jogadas = 0
	var jogada := outro.jogada_possivel()
	verificar(outro.acabou() and not outro.trocar(jogada[0], jogada[1]), "sem jogadas, a partida acaba")
	outro.pontos = DoceMatch.METAS[1]
	verificar(outro.estrelas() == 2 and outro.moedas() > 0, "estrelas pela pontuação e moedas no fim")


func _testar_tela_doce_match() -> void:
	# sem açúcar, não joga: aviso com atalho para o quiz
	Progresso.confeitaria["acucar"] = 10
	Telas.ir_para("doce_match")
	verificar(await _esperar_tela("DoceMatch"), "abre o Doce Match")
	await get_tree().create_timer(0.3).timeout
	verificar(get_tree().current_scene.find_child("JogarQuiz", true, false) is Button and Confeitaria.acucar() == 10, "sem açúcar: aviso e botão para o quiz")
	Progresso.confeitaria["acucar"] = 2 * DoceMatch.CUSTO_ACUCAR
	Telas.ir_para("niveis")
	await _esperar_tela("Niveis")
	get_tree().current_scene.find_child("DoceMatch", true, false).pressed.emit()
	verificar(await _esperar_tela("DoceMatch"), "abre o Doce Match")
	var tela := get_tree().current_scene
	await get_tree().create_timer(0.4).timeout
	verificar(tela._tabuleiro.get_child_count() == DoceMatch.LARGURA * DoceMatch.ALTURA, "64 peças no tabuleiro")
	verificar(Confeitaria.acucar() == DoceMatch.CUSTO_ACUCAR, "a partida gastou açúcar (e o menu dos níveis abre o jogo)")
	var jogada: Array = tela.jogo.jogada_possivel()
	await tela.jogar(jogada[0], jogada[1])
	verificar(tela.jogo.jogadas == DoceMatch.JOGADAS - 1 and tela.jogo.pontos > 0, "jogada pela tela conta pontos")
	var cheias := 0
	for linha in tela._pecas:
		for peca in linha:
			if peca != null:
				cheias += 1
	verificar(cheias == 64, "depois da cascata, todas as casas têm peça")
	var moedas := Progresso.moedas
	tela.jogo.jogadas = 1
	jogada = tela.jogo.jogada_possivel()
	await tela.jogar(jogada[0], jogada[1])
	verificar(tela.find_child("Fim", true, false) != null, "acabaram as jogadas: aparece o fim da partida")
	verificar(Progresso.moedas == moedas + tela.jogo.moedas(), "o fim dá as moedas")
	tela.find_child("JogarDeNovo", true, false).pressed.emit()
	verificar(tela.jogo.jogadas == DoceMatch.JOGADAS and Confeitaria.acucar() == 0, "jogar de novo recomeça (e paga de novo)")

func _testar_configuracoes() -> void:
	_secao("configurações")
	# qualidade dos gráficos: BAIXA tira a grama e as sombras da vila
	Qualidade.escolher(Qualidade.BAIXA)
	Telas.ir_para("vila")
	await _esperar_tela("Vila")
	var vila := get_tree().current_scene
	verificar(vila.find_child("Grama", true, false) == null, "gráficos BAIXA: sem grama com volume")
	verificar(not vila.find_children("*", "DirectionalLight3D", true, false)[0].shadow_enabled, "gráficos BAIXA: sem sombras")
	Qualidade.escolher(Qualidade.ALTA)
	Telas.ir_para("niveis")
	await _esperar_tela("Niveis")
	Telas.abrir("configuracoes")
	verificar(await _esperar_tela("Configuracoes"), "abre as configurações")
	var tela := get_tree().current_scene
	verificar(tela.find_child("Qualidade", true, false) != null, "opção de qualidade dos gráficos")
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


# --- Laboratório do Office ------------------------------------------------------

func _testar_formulas() -> void:
	_secao("fórmulas do laboratório")
	var c := {"A1": "Doce", "A2": "Brigadeiro", "A3": "Cupcake", "A4": "Brigadeiro",
		"B1": "Vendas", "B2": 12.0, "B3": 8.0, "B4": 10.0, "C2": 2.5, "C3": 0.0, "D2": "7"}
	var casos := [
		["=B2+B3", 20.0], ["=2+3*4", 14.0], ["=(2+3)*4", 20.0], ["=-2^2", 4.0], ["=10/4", 2.5],
		["=50%", 0.5], ["=2,5*2", 5.0], ["=SOMA(B2:B4)", 30.0], ["=soma(b2:b4)", 30.0],
		["=SOMA(B1:B4)", 30.0], ["=MÉDIA(B2:B4)", 10.0], ["=MEDIA(B2:B4)", 10.0],
		["=MÁXIMO(B2:B4)", 12.0], ["=MÍNIMO(B2:B4;5)", 5.0], ["=SOMA(B2;B3;1)", 21.0],
		["=CONT.NÚM(A1:B4)", 3.0], ["=CONT.VALORES(A1:A5)", 4.0], ["=CONTAR.VAZIO(A1:A5)", 1.0],
		["=CONT.SE(A2:A4;\"Brigadeiro\")", 2.0], ["=CONT.SE(B2:B4;\">=10\")", 2.0],
		["=CONT.SE(A2:A4;\"B*\")", 2.0], ["=SOMASE(A2:A4;\"Brigadeiro\";B2:B4)", 22.0],
		["=MÉDIASE(A2:A4;\"Brigadeiro\";B2:B4)", 11.0],
		["=SE(B2>10;\"Muito\";\"Pouco\")", "Muito"], ["=SE(B3>10;\"Muito\";\"Pouco\")", "Pouco"],
		["=SE(B3>10;1)", false], ["=E(B2>5;B3>5)", true], ["=OU(B2>50;B3>5)", true], ["=NÃO(B2>5)", false],
		["=ARRED(2,345;2)", 2.35], ["=ARRED(-2,5;0)", -3.0], ["=A2&\" \"&B2", "Brigadeiro 12"],
		["=CONCATENAR(A2;\"!\")", "Brigadeiro!"], ["=MAIÚSCULA(A3)", "CUPCAKE"],
		["=ESQUERDA(A2;4)", "Brig"], ["=NÚM.CARACT(A1)", 4.0], ["=D2+1", 8.0], ["=$B$2*C2", 30.0],
		["=B$2+$B3", 20.0], ["=B2>=12", true], ["=A2=\"brigadeiro\"", true], ["=Z9+1", 1.0],
		["=\"a\"\"b\"", "a\"b"], ["=VERDADEIRO", true],
		["=PROCV(\"Cupcake\";A2:B4;2;FALSO)", 8.0], ["=PROCV(\"cupcake\";A2:C4;3;FALSO)", 0.0], ["=PROCV(\"Cupcake\";A2:D4;4;FALSO)", 0.0], ["=SEERRO(B2/C3;-1)", -1.0],
		["=SEERRO(B2/C2;0)", 4.8], ["=SES(B2>20;\"a\";B2>10;\"b\";VERDADEIRO;\"c\")", "b"],
		["=CONT.SES(A2:A4;\"Brigadeiro\";B2:B4;\">=10\")", 2.0], ["=SOMASES(B2:B4;A2:A4;\"Brigadeiro\";B2:B4;\">10\")", 12.0],
		["=ÍNDICE(A2:A4;2)", "Cupcake"], ["=INDICE(A1:B4;3;2)", 8.0], ["=CORRESP(10;B2:B4;0)", 3.0],
		["=ÍNDICE(A2:A4;CORRESP(MÁXIMO(B2:B4);B2:B4;0))", "Brigadeiro"],
	]
	for caso in casos:
		var r: Variant = Formulas.calcular(caso[0], c)
		verificar(not Formulas.eh_erro(r) and Formulas.iguais(r, caso[1]),
			"%s = %s (deu %s)" % [caso[0], Formulas.texto(caso[1]), Formulas.texto(r)])
	var erros := [
		["=B2/C3", Formulas.DIV0], ["=B2/Z1", Formulas.DIV0], ["=SOMAR(B2:B4)", Formulas.NOME],
		["=A2+1", Formulas.VALOR], ["=MÉDIA(Z1:Z3)", Formulas.DIV0], ["=SOMA(B2:B4", Formulas.INCOMPLETA],
		["=SOMA(B2,B3)", Formulas.VIRGULA], ["=SE(B2)", Formulas.ARGUMENTOS], ["=", Formulas.INCOMPLETA],
		["=B2+", Formulas.INCOMPLETA], ["=\"abc", Formulas.INCOMPLETA], ["=B2:B4", Formulas.VALOR],
		["=B2 B3", Formulas.INCOMPLETA], ["=SOMA", Formulas.NOME], ["=SE(A2;1;2)", Formulas.VALOR],
		["=PROCV(\"Sorvete\";A2:B4;2;FALSO)", Formulas.ND], ["=CORRESP(99;B2:B4;0)", Formulas.ND],
		["=SES(B2>99;1)", Formulas.ND], ["=PROCV(\"Cupcake\";A2:B4;5;FALSO)", Formulas.VALOR],
	]
	for caso in erros:
		var r: Variant = Formulas.calcular(caso[0], c)
		verificar(Formulas.eh_erro(r) and r.codigo == caso[1], "%s dá %s (deu %s)" % [caso[0], caso[1], Formulas.texto(r)])
	verificar(Formulas.calcular("=SOMAR(B2:B4)", c).explicacao() != "", "erro tem explicação")
	verificar(Formulas.texto(2.5) == "2,5" and Formulas.texto(12.0) == "12" and Formulas.texto(1.0 / 3.0) == "0,33", "números aparecem no jeito brasileiro")
	verificar(Formulas.texto(true) == "VERDADEIRO", "VERDADEIRO por extenso")
	verificar(Formulas.funcoes_usadas("=SE(MÉDIA(B2:B4)>5;SOMA(B2);0)") == ["SE", "MEDIA", "SOMA"], "lista as funções usadas")
	verificar(Formulas.usa_celulas("=SOMA(B2:B4)") and not Formulas.usa_celulas("=12+8"), "sabe se a fórmula usa células")
	verificar(Formulas.posicao("B12") == Vector2i(1, 11) and Formulas.nome_celula(Vector2i(27, 0)) == "AB1", "endereço <-> posição")


func _testar_documento_word() -> void:
	_secao("documento do word")
	var doc := DocumentoWord.new([{"texto": "Festa do Doce"}, {"texto": "Venha comer brigadeiro, beijinho e bolo."}])
	verificar(doc.total_palavras() == 9 and doc.onde(4) == Vector2i(1, 1), "conta e acha as palavras")
	doc.tocar(0)
	verificar(doc.sel_inicio == 0 and doc.sel_fim == 0, "um toque seleciona a palavra")
	doc.tocar(0)
	verificar(doc.sel_inicio == 0 and doc.sel_fim == 2, "outro toque seleciona o parágrafo")
	doc.fazer("negrito")
	verificar(doc.ligado("negrito") and not doc.palavra(3)["negrito"], "negrito só na seleção")
	verificar(doc.faltando([{"paragrafo": 0, "negrito": true}]).is_empty(), "meta de negrito cumprida")
	doc.fazer("negrito")
	verificar(not doc.palavra(0)["negrito"], "negrito de novo tira (como no Word)")
	doc.fazer("desfazer")
	verificar(doc.palavra(0)["negrito"], "Ctrl+Z desfaz")
	doc.fazer("tudo")
	doc.fazer("negrito")
	verificar(doc.faltando([{"paragrafo": 0, "negrito": true}]).size() == 1, "negrito no texto todo não vale para o título")
	doc.fazer("desfazer")
	doc.tocar(5)
	doc.fazer("centro")
	verificar(doc.paragrafos[1]["alinhamento"] == "centro" and doc.paragrafos[0]["alinhamento"] == "esquerda", "alinha só o parágrafo da seleção")
	doc.limpar_selecao()
	doc.tocar(5)
	doc.tocar(7, true)
	verificar(doc.sel_inicio == 5 and doc.sel_fim == 7, "Shift estende a seleção")
	doc.fazer("maior")
	verificar(doc.tamanho_atual() == 14, "A+ sobe um degrau da fonte")
	doc.fazer("cor_vermelho")
	verificar(doc.palavra(6)["cor"] == "vermelho" and doc.palavra(4)["cor"] == "preto", "pinta só a seleção")
	verificar(doc.faltando([{"paragrafo": 1, "palavras": ["beijinho"], "cor": "vermelho"}]).size() == 1, "pintar a mais não vale")
	verificar(DocumentoWord.acao_do_atalho(KEY_N, true, false) == "negrito" and DocumentoWord.acao_do_atalho(KEY_E, true, false) == "centro"
		and DocumentoWord.acao_do_atalho(KEY_T, true, false) == "tudo" and DocumentoWord.acao_do_atalho(KEY_N, false, false) == "", "atalhos do Word em português")
	verificar(doc.bbcode(0).begins_with("[p align=left]") and doc.bbcode(0).contains("[url=0]"), "desenha o parágrafo com toque nas palavras")
	var lista := DocumentoWord.new([{"texto": "Receita"}, {"texto": "Leite"}, {"texto": "Chocolate"}])
	lista.tocar(1)
	lista.fazer("marcadores")
	verificar(lista.paragrafos[1]["lista"] == "marcadores" and lista.bbcode(1).contains("•"), "lista com marcadores")
	lista.fazer("marcadores")
	verificar(lista.paragrafos[1]["lista"] == "", "apertar de novo tira a lista")
	lista.tocar(1)
	lista.tocar(2, true)
	lista.fazer("numeros")
	verificar(lista.bbcode(2).contains("2."), "lista numerada conta 1, 2...")
	verificar(lista.faltando([{"paragrafos": [1, 2], "lista": "numeros"}]).is_empty(), "meta de lista em vários parágrafos")
	lista.limpar_selecao()
	lista.tocar(0)
	lista.fazer("titulo1")
	verificar(lista.estilo_atual() == "titulo1" and lista.bbcode(0).contains("[b]"), "estilo Título 1")
	verificar(lista.faltando([{"paragrafos": [1, 2], "lista": "numeros"}]).size() == 1, "estilo a mais (não pedido) não vale")
	lista.tocar(1)
	lista.fazer("realce")
	verificar(lista.palavra(1)["realce"] and lista.bbcode(1).contains("FFF06A") == false, "marca-texto (a seleção aparece por cima)")
	lista.limpar_selecao()
	verificar(lista.bbcode(1).contains("FFF06A"), "marca-texto aparece sem seleção")
	verificar(DocumentoWord.acao_do_atalho(KEY_L, true, true) == "marcadores" and DocumentoWord.acao_do_atalho(KEY_1, true, false, true) == "titulo1", "atalhos de lista e estilo")


## Resolve os passos de Word pelas próprias ações da tela.
func _resolver_word(doc: DocumentoWord, metas: Array) -> void:
	for meta in metas:
		var alvos := []
		var varios: Array = meta.get("paragrafos", []).map(func(x): return int(x))
		for i in doc.paragrafos.size():
			if not varios.is_empty():
				if not i in varios:
					continue
			elif int(meta.get("paragrafo", -1)) >= 0 and i != int(meta["paragrafo"]):
				continue
			for j in doc.paragrafos[i]["palavras"].size():
				var t: String = doc.paragrafos[i]["palavras"][j]["texto"]
				if not meta.has("palavras") or DocumentoWord._limpa(t) in meta["palavras"].map(func(x): return DocumentoWord._limpa(x)):
					alvos.append(doc.indice(i, j))
		var feitos := {}  # parágrafos que já receberam lista/estilo/alinhamento
		for alvo in alvos:
			doc.limpar_selecao()
			doc.tocar(alvo)
			var par := doc.onde(alvo).x
			for prop in meta:
				match prop:
					"negrito", "italico", "sublinhado", "realce":
						if doc.ligado(prop) != meta[prop]:
							doc.fazer(prop)
					"cor":
						doc.fazer("cor_" + meta[prop])
					"alinhamento":
						doc.fazer(meta[prop])
					"lista":
						if not feitos.has([par, prop]) and doc.lista_atual() != meta[prop]:
							doc.fazer(meta[prop])
						feitos[[par, prop]] = true
					"estilo":
						doc.fazer(meta[prop])
					"tamanho_min":
						while doc.tamanho_atual() < int(meta[prop]):
							doc.fazer("maior")


func _testar_laboratorio() -> void:
	_secao("laboratório do office")
	var fases := Laboratorio.fases()
	verificar(Laboratorio.capitulos().size() == 5 and fases.size() == 40, "5 capítulos com 8 fases")
	var ids := {}
	for f in fases:
		ids[f["id"]] = true
	verificar(ids.size() == fases.size(), "ids das fases não se repetem")
	for c in Laboratorio.capitulos():
		verificar(c["fases"][-1].get("chefe", false), "capítulo termina num chefe")
	# todas as fases têm solução, e começar sem fazer nada não passa
	for f in fases:
		if f["tipo"] == "excel":
			var celulas: Dictionary = f["planilha"]["celulas"].duplicate()
			for passo in f["passos"]:
				verificar(not celulas.has(passo["celula"]), "%s: a célula %s começa vazia" % [f["id"], passo["celula"]])
				var r := Laboratorio.conferir_excel(passo, passo["resposta"], celulas)
				verificar(r["certo"], "%s: a resposta de %s confere (%s)" % [f["id"], passo["celula"], r["mensagem"]])
				var posicao := Formulas.posicao(passo["celula"])
				verificar(posicao.x < int(f["planilha"]["colunas"]) and posicao.y < int(f["planilha"]["linhas"]), "%s: %s cabe na planilha" % [f["id"], passo["celula"]])
				celulas[passo["celula"]] = r["valor"]
		else:
			var doc := DocumentoWord.new(f["documento"])
			for i in f["passos"].size():
				var metas := Laboratorio.metas_ate(f, i)
				verificar(not doc.faltando(metas).is_empty(), "%s: passo %d não começa pronto" % [f["id"], i + 1])
				_resolver_word(doc, f["passos"][i]["metas"])
				verificar(doc.faltando(metas).is_empty(), "%s: passo %d tem solução (%s)" % [f["id"], i + 1, doc.faltando(metas)])
	# conferência das fórmulas
	var soma: Dictionary = Laboratorio.fase("c1f3")
	var cel: Dictionary = soma["planilha"]["celulas"]
	var passo_soma: Dictionary = soma["passos"][0]
	verificar(not Laboratorio.conferir_excel(passo_soma, "SOMA(B2:B6)", cel)["certo"], "sem = não vale")
	verificar(Laboratorio.conferir_excel(passo_soma, "=65", cel)["mensagem"].contains("endereços"), "número digitado não vale")
	verificar(Laboratorio.conferir_excel(passo_soma, "=B2+B3+B4+B5+B6", cel)["mensagem"].contains("SOMA"), "fase pede a função certa")
	verificar(Laboratorio.conferir_excel(passo_soma, "=SOMA(B2:B5)", cel)["mensagem"].contains("deu 45"), "resultado errado mostra o que deu")
	verificar(Laboratorio.conferir_excel(passo_soma, "=SOMAR(B2:B6)", cel)["mensagem"].contains("#NOME?"), "erro do Excel é explicado")
	verificar(Laboratorio.conferir_excel(passo_soma, "=soma(b2:b6)", cel)["certo"], "minúsculas valem")
	# progresso, estrelas e baús
	var antes: Dictionary = Progresso.laboratorio.duplicate(true)
	var baus_lab_antes: Dictionary = Progresso.baus.duplicate(true)
	var moedas_antes := Progresso.moedas
	var acucar_antes := Confeitaria.acucar()
	Progresso.laboratorio = {"estrelas": {}, "baus": {}}
	verificar(Laboratorio.estrelas_por(0, 0) == 3 and Laboratorio.estrelas_por(2, 0) == 2 and Laboratorio.estrelas_por(0, 1) == 2
		and Laboratorio.estrelas_por(3, 0) == 1 and Laboratorio.estrelas_por(0, 2) == 1, "estrelas por erros e dicas")
	verificar(Laboratorio.liberada("c1f1") and not Laboratorio.liberada("c1f2"), "só a primeira fase começa liberada")
	verificar(Laboratorio.proxima_fase() == "c1f1", "próxima fase é a primeira")
	var r1 := Laboratorio.concluir("c1f1", 2)
	verificar(r1["primeira"] and r1["acucar"] == Laboratorio.ACUCAR_FASE and r1["moedas"] == Laboratorio.MOEDAS_FASE + 2 * Laboratorio.MOEDAS_POR_ESTRELA, "recompensa da primeira vez")
	verificar(Laboratorio.liberada("c1f2") and Laboratorio.proxima_fase() == "c1f2", "passar libera a próxima")
	var r2 := Laboratorio.concluir("c1f1", 1)
	verificar(r2["moedas"] == 0 and r2["acucar"] == 0 and Laboratorio.estrelas("c1f1") == 2, "jogar de novo sem melhorar não dá nada")
	var r3 := Laboratorio.concluir("c1f1", 3)
	verificar(r3["moedas"] == Laboratorio.MOEDAS_POR_ESTRELA and r3["acucar"] == 0 and Laboratorio.estrelas("c1f1") == 3, "estrela nova dá moedas")
	verificar(Laboratorio.baus().size() == 10 and Laboratorio.baus_prontos() == 0, "10 baús, nenhum pronto")
	verificar(Laboratorio.abrir_bau("c1_meio").is_empty(), "baú fechado antes da 4ª fase")
	for id in ["c1f2", "c1f3", "c1f4"]:
		Laboratorio.concluir(id, 3)
	verificar(Laboratorio.bau_pronto("c1_meio") and Laboratorio.baus_prontos() == 1, "baú fica pronto depois da 4ª fase")
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 7
	var moedas_bau := Progresso.moedas
	var conteudo := Laboratorio.abrir_bau("c1_meio", sorteio)
	verificar(conteudo["moedas"] >= 20 and conteudo["acucar"] >= 20 and Baus.quantos("prata") > 0 and Progresso.moedas == moedas_bau + conteudo["moedas"], "baú dá moedas e açúcar")
	verificar(Laboratorio.bau_aberto("c1_meio") and Laboratorio.abrir_bau("c1_meio").is_empty(), "baú só abre uma vez")
	verificar(Laboratorio.total_estrelas() == 12, "soma as estrelas")
	var chefe := Laboratorio.concluir("c1f8", 1)
	verificar(chefe["acucar"] == Laboratorio.ACUCAR_CHEFE, "chefe dá mais açúcar")
	Progresso.laboratorio = antes
	Progresso.baus = baus_lab_antes
	Progresso.moedas = moedas_antes
	Progresso.confeitaria["acucar"] = acucar_antes


func _testar_tela_laboratorio() -> void:
	_secao("telas do laboratório")
	var antes: Dictionary = Progresso.laboratorio.duplicate(true)
	Progresso.laboratorio = {"estrelas": {}, "baus": {}}
	Telas.ir_para("laboratorio")
	verificar(await _esperar_tela("Laboratorio"), "abre o mapa do laboratório")
	var mapa := get_tree().current_scene
	await get_tree().create_timer(0.3).timeout
	verificar(mapa.find_child("Fase_c1f1", true, false) is Button and mapa.find_child("Fase_c3f8", true, false) is Button, "mapa com as 24 fases")
	verificar(mapa.find_child("Bau_c1_meio", true, false) != null, "baús no mapa")
	verificar(mapa.find_child("Jogador", true, false) != null, "o doce do jogador fica na fase atual")
	mapa.find_child("Fase_c1f1", true, false).pressed.emit()
	await get_tree().process_frame
	var jogar: Button = mapa.find_child("Jogar", true, false)
	verificar(jogar != null, "tocar na fase abre o resumo com JOGAR")
	jogar.pressed.emit()
	verificar(await _esperar_tela("LabFase"), "abre a fase")
	var fase := get_tree().current_scene
	await get_tree().process_frame
	verificar(fase.find_child("Celula_B4", true, false).text == "?", "célula da tarefa marcada com ?")
	fase.find_child("Formula", true, false).text = "=12+8"
	fase.conferir()
	verificar(fase.erros == 1 and fase.find_child("Feedback", true, false).text.contains("endereços"), "número digitado conta erro e explica")
	fase.find_child("Formula", true, false).text = ""
	fase.tocar_celula("B2")
	fase._inserir("+")
	fase.tocar_celula("B3")
	verificar(fase.find_child("Formula", true, false).text == "=B2+B3", "tocar nas células escreve a fórmula")
	fase.conferir()
	verificar(fase.find_child("Celula_B4", true, false).text == "20", "fórmula certa mostra o resultado na célula")
	var moedas := Progresso.moedas
	fase.conferir()  # TERMINAR
	await get_tree().process_frame
	verificar(fase.find_child("Fim", true, false) != null and Laboratorio.estrelas("c1f1") == 2, "fim da fase: 1 erro = 2 estrelas")
	verificar(Progresso.moedas == moedas + Laboratorio.MOEDAS_FASE + 2 * Laboratorio.MOEDAS_POR_ESTRELA, "fim da fase dá as moedas")
	fase.find_child("DeNovo", true, false).pressed.emit()
	await get_tree().process_frame
	fase.find_child("Formula", true, false).text = ""
	fase.tocar_celula("B2")
	fase.tocar_celula("B3")
	verificar(fase.find_child("Formula", true, false).text == "=B2:B3", "tocar duas células seguidas vira intervalo")
	# fase de Word pelos botões da fita
	Laboratorio.fase_atual = "c1f2"
	Telas.ir_para("lab_fase")
	await get_tree().create_timer(0.5).timeout
	fase = get_tree().current_scene
	verificar(fase.doc != null and fase.find_child("Paragrafo0", true, false) is RichTextLabel, "fase de Word mostra a página")
	fase._tocar_palavra(0)
	fase._tocar_palavra(0)
	fase.find_child("Acao_negrito", true, false).pressed.emit()
	verificar(fase.find_child("Acao_negrito", true, false).theme_type_variation == &"BotaoRoxo", "botão N fica ligado")
	fase.conferir()
	verificar(fase.erros == 0 and fase.find_child("Conferir", true, false).text == "TERMINAR", "título em negrito confere")
	# chefe com várias tarefas
	Laboratorio.fase_atual = "c1f8"
	Telas.ir_para("lab_fase")
	await get_tree().create_timer(0.5).timeout
	fase = get_tree().current_scene
	verificar(fase.find_child("VidaChefe", true, false).get_child_count() == 3, "chefe com 3 corações")
	for p in fase.fase["passos"]:
		fase.find_child("Formula", true, false).text = p["resposta"]
		fase.conferir()
		fase.conferir()
	verificar(fase.terminou and Laboratorio.estrelas("c1f8") == 3, "chefe derrotado sem erros = 3 estrelas")
	# baú
	for id in ["c1f2", "c1f3", "c1f4"]:
		Laboratorio.concluir(id, 3)
	Telas.ir_para("laboratorio")
	await _esperar_tela("Laboratorio")
	mapa = get_tree().current_scene
	await get_tree().create_timer(0.2).timeout
	var moedas_bau := Progresso.moedas
	mapa.abrir_bau("c1_meio")
	verificar(Laboratorio.bau_aberto("c1_meio") and Progresso.moedas > moedas_bau, "abrir o baú pelo mapa dá o prêmio")
	await get_tree().create_timer(1.8).timeout
	verificar(not mapa.find_child("Pegar", true, false).disabled, "depois da animação dá para pegar o prêmio")
	Progresso.laboratorio = antes


func _testar_companheiros_e_baus() -> void:
	_secao("companheiros e baús surpresa")
	var colecao_antes: Dictionary = Progresso.colecao.duplicate(true)
	var baus_antes: Dictionary = Progresso.baus.duplicate(true)
	var moedas_antes := Progresso.moedas
	var acucar_antes := Confeitaria.acucar()
	Progresso.colecao = {"doces": [], "companheiro": "", "fragmentos": {}, "niveis": {}}
	Progresso.baus = Baus.padrao()
	for id in Companheiros.DOCES:
		verificar(not Colecao.dados(id).is_empty(), "%s existe na coleção" % id)
	verificar(Companheiros.DOCES.size() == Colecao.LISTA.size(), "todos os doces têm raridade e bônus")
	verificar(Companheiros.nivel("brigadeiro") == 1 and Companheiros.nivel("pudim") == 0, "nível: tem = 1, não tem = 0")
	verificar(Companheiros.bonus("acucar") == 10.0, "brigadeiro (inicial) dá +10% de açúcar")
	verificar(Companheiros.com_bonus("acucar", 100) == 110 and Companheiros.com_bonus("moedas_quiz", 100) == 100, "bônus só do tipo do companheiro")
	verificar(not Companheiros.receber_fragmentos("pudim", 6) and Companheiros.fragmentos("pudim") == 6, "junta fragmentos")
	verificar(Companheiros.receber_fragmentos("pudim", 5) and Colecao.tem("pudim") and Companheiros.fragmentos("pudim") == 1, "10 fragmentos = ganha o doce")
	verificar(Companheiros.valor_bonus("pudim") == 2.0 and Companheiros.valor_bonus("pudim", 5) == 8.0, "épico: gorjeta +2 no nível 1, +8 no 5")
	Colecao.escolher_companheiro("pudim")
	verificar(Companheiros.bonus("cozinha") == 2.0 and Companheiros.bonus("acucar") == 0.0, "trocar de companheiro troca o bônus")
	Progresso.moedas = 1000
	verificar(not Companheiros.melhorar("pudim"), "sem fragmentos não melhora")
	Companheiros.receber_fragmentos("pudim", 9)
	verificar(Companheiros.melhorar("pudim") and Companheiros.nivel("pudim") == 2 and Progresso.moedas == 950, "melhorar gasta fragmentos e moedas")
	verificar(Companheiros.descrever_bonus("pudim") == "+3 DE GORJETA POR CLIENTE", "descreve o bônus")
	verificar(Companheiros.valor_bonus("algodao_doce", 1) == 2.0 and Companheiros.valor_bonus("cupcake", 5) == 3.0, "ajudas grátis por raridade e nível")
	# baús
	verificar(Baus.abrir("doce").is_empty(), "sem baú não abre")
	Baus.ganhar("doce", 3)
	Baus.ganhar("ouro")
	verificar(Baus.total_fechados() == 4, "conta os baús fechados")
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 42
	var itens := Baus.abrir("doce", sorteio)
	verificar(itens.size() == Baus.ITENS["doce"] and itens[0]["tipo"] == "fragmentos", "baú de doce: 2 itens, o 1º é fragmento")
	var ouro := Baus.abrir("ouro", sorteio)
	verificar(ouro.size() == 4 and Baus.quantos("ouro") == 0, "baú de ouro: 4 itens")
	# garantia de épico
	Progresso.baus["sem_epico"] = Baus.GARANTIA_EPICO - 1
	var garantido := Baus.abrir("doce", sorteio)
	verificar(garantido.any(func(i): return i["tipo"] == "fragmentos" and i["raridade"] >= Companheiros.Raridade.EPICO), "garantia: o 10º baú traz épico ou lendário")
	verificar(Progresso.baus["sem_epico"] == 0, "garantia zera depois do épico")
	# muitos baús: raridades aparecem e nada quebra
	Baus.ganhar("prata", 200)
	var raridades := {}
	for i in 200:
		for item in Baus.abrir("prata", sorteio):
			if item["tipo"] == "fragmentos":
				raridades[item["raridade"]] = true
	verificar(raridades.size() == 4, "200 baús de prata trazem as 4 raridades")
	verificar(Colecao.quantidade() >= 8, "fragmentos dos baús dão doces novos")
	# baú do quiz: até 5 por dia
	Progresso.baus = Baus.padrao()
	Missoes.dia_fixo = 20000
	var ganhos := 0
	for i in 7:
		if Baus.ganhar_do_quiz():
			ganhos += 1
	verificar(ganhos == Baus.QUIZ_POR_DIA and Baus.quantos("doce") == 5, "até 5 baús do quiz por dia")
	Missoes.dia_fixo = 20001
	verificar(Baus.ganhar_do_quiz(), "no outro dia volta a dar baú")
	Missoes.dia_fixo = -1
	Progresso.colecao = colecao_antes
	Progresso.baus = baus_antes
	Progresso.moedas = moedas_antes
	Progresso.confeitaria["acucar"] = acucar_antes


func _testar_missoes_e_nivel() -> void:
	_secao("missões e nível do jogador")
	var missoes_antes: Dictionary = Progresso.missoes.duplicate(true)
	var jogador_antes: Dictionary = Progresso.jogador.duplicate(true)
	var baus_antes: Dictionary = Progresso.baus.duplicate(true)
	var moedas_antes := Progresso.moedas
	var acucar_antes := Confeitaria.acucar()
	Progresso.missoes = Missoes.padrao()
	Progresso.jogador = {"xp": 0, "nivel": 1}
	Progresso.baus = Baus.padrao()
	Missoes.dia_fixo = 20355  # uma segunda-feira
	var d := Missoes.diarias()
	verificar(d.size() == 3 and Missoes.semanais().size() == 3, "3 missões do dia e 3 da semana")
	var tipos := {}
	for m in d:
		tipos[m["tipo"]] = true
	verificar(tipos.size() == 3, "missões do dia de tipos diferentes")
	verificar(Missoes.diarias() == d, "mesmas missões o dia todo")
	var primeira: Dictionary = d[0]
	verificar(Missoes.resgatar("dia", 0).is_empty(), "missão não cumprida não resgata")
	Missoes.registrar(primeira["tipo"], 999)
	verificar(Missoes.cumprida(primeira) and int(primeira["progresso"]) == int(primeira["meta"]), "registrar cumpre a missão (sem passar da meta)")
	var moedas := Progresso.moedas
	var p := Missoes.resgatar("dia", 0)
	verificar(p["moedas"] == Missoes.PREMIO_DIA["moedas"] and Progresso.moedas == moedas + p["moedas"] and not p.has("bau"), "resgatar dá moedas e XP")
	verificar(Missoes.resgatar("dia", 0).is_empty(), "não resgata duas vezes")
	for i in [1, 2]:
		Missoes.registrar(d[i]["tipo"], 999)
	Missoes.resgatar("dia", 1)
	var ultima := Missoes.resgatar("dia", 2)
	verificar(ultima.get("bau", "") == "prata" and Baus.quantos("prata") == 1, "as 3 do dia = baú de prata")
	Missoes.dia_fixo = 20356
	verificar(not Missoes.diarias().any(func(m): return m["resgatada"]), "outro dia, missões novas")
	verificar(Missoes.semanais()[0]["tipo"] == Progresso.missoes["semanais"][0]["tipo"] and Progresso.missoes["semana"] == Missoes.semana(), "a semana continua a mesma")
	Missoes.dia_fixo = 20362
	verificar(Progresso.missoes["semana"] != Missoes.semana() or Missoes.semana() != floori((20356 + 3) / 7.0), "segunda seguinte troca a semana")
	# prêmio por entrar
	Progresso.missoes = Missoes.padrao()
	Missoes.dia_fixo = 20400
	verificar(Missoes.entrada_disponivel() and Missoes.dia_da_sequencia() == 1, "prêmio do 1º dia disponível")
	var e1 := Missoes.resgatar_entrada()
	verificar(e1["dia"] == 1 and e1.has("moedas") and not Missoes.entrada_disponivel(), "resgata uma vez por dia")
	for dia in range(20401, 20407):
		Missoes.dia_fixo = dia
		var premio := Missoes.resgatar_entrada()
		if dia == 20406:
			verificar(premio["dia"] == 7 and premio["bau"] == "ouro", "7º dia seguido = baú de ouro")
	Missoes.dia_fixo = 20409
	verificar(Missoes.dia_da_sequencia() == 1, "pulou um dia: volta ao 1º")
	# nível
	Progresso.jogador = {"xp": 0, "nivel": 1}
	Progresso.baus = Baus.padrao()
	Experiencia.subidas_pendentes.clear()
	verificar(Experiencia.ganhar(50) == 0 and Experiencia.xp() == 50, "junta XP")
	verificar(Experiencia.ganhar(60) == 1 and Experiencia.nivel() == 2 and Experiencia.xp() == 10, "sobe de nível e sobra XP")
	verificar(Baus.quantos("prata") == 1 and Experiencia.subidas_pendentes.size() == 1, "subir de nível dá baú de prata")
	Experiencia.ganhar(Experiencia.xp_para(2) + Experiencia.xp_para(3) + Experiencia.xp_para(4))
	verificar(Experiencia.nivel() == 5 and Baus.quantos("ouro") == 1, "nível 5 dá baú de ouro")
	Experiencia.subidas_pendentes.clear()
	Missoes.dia_fixo = -1
	Progresso.missoes = missoes_antes
	Progresso.jogador = jogador_antes
	Progresso.baus = baus_antes
	Progresso.moedas = moedas_antes
	Progresso.confeitaria["acucar"] = acucar_antes


func _testar_telas_baus_e_missoes() -> void:
	_secao("telas de baús, missões e coleção")
	var baus_antes: Dictionary = Progresso.baus.duplicate(true)
	var missoes_antes: Dictionary = Progresso.missoes.duplicate(true)
	var colecao_antes: Dictionary = Progresso.colecao.duplicate(true)
	var moedas_antes := Progresso.moedas
	Progresso.baus = Baus.padrao()
	Baus.ganhar("prata", 2)
	Telas.ir_para("inicio")
	await _esperar_tela("Inicio")
	var bolinha: Label = get_tree().current_scene.find_child("BausSurpresa", true, false).get_node("Bolinha")
	verificar(bolinha.visible and bolinha.text == "2", "tela inicial mostra os baús fechados")
	get_tree().current_scene.find_child("BausSurpresa", true, false).pressed.emit()
	verificar(await _esperar_tela("Baus"), "abre a tela de baús")
	var tela := get_tree().current_scene
	await get_tree().process_frame
	verificar(tela.find_child("Abrir_doce", true, false).disabled and not tela.find_child("Abrir_prata", true, false).disabled, "só abre o baú que tem")
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 3
	tela.abrir_bau("prata", sorteio)
	await get_tree().create_timer(3.0).timeout
	verificar(tela.find_child("Cartas", true, false).get_child_count() == 3 and Baus.quantos("prata") == 1, "baú de prata abre com 3 cartas")
	verificar(not tela.find_child("Pronto", true, false).disabled, "depois das cartas dá para fechar")
	tela.find_child("Pronto", true, false).pressed.emit()
	# missões
	Progresso.missoes = Missoes.padrao()
	Missoes.dia_fixo = 20500
	var d := Missoes.diarias()
	Missoes.registrar(d[0]["tipo"], 999)
	Telas.ir_para("missoes")
	verificar(await _esperar_tela("Missoes"), "abre a tela de missões")
	tela = get_tree().current_scene
	await get_tree().process_frame
	var resgatar: Button = tela.find_child("Resgatar_dia_0", true, false)
	verificar(resgatar != null and resgatar.text == "RESGATAR", "missão cumprida mostra RESGATAR")
	verificar(tela.find_child("Resgatar_dia_1", true, false).disabled, "missão não cumprida fica esperando")
	var moedas := Progresso.moedas
	resgatar.pressed.emit()
	await get_tree().process_frame
	verificar(Progresso.moedas == moedas + Missoes.PREMIO_DIA["moedas"], "resgatar pela tela dá o prêmio")
	verificar(tela.find_child("Resgatar_dia_0", true, false).text == "FEITO!", "depois fica FEITO!")
	var dia1: Button = tela.find_child("Dia1", true, false)
	verificar(dia1 != null and not dia1.disabled, "prêmio por entrar do dia disponível")
	dia1.pressed.emit()
	await get_tree().process_frame
	verificar(not Missoes.entrada_disponivel() and tela.find_child("Dia1", true, false).disabled, "prêmio por entrar pego")
	Missoes.dia_fixo = -1
	# coleção: raridade e melhorar
	Progresso.moedas = 500
	Companheiros.receber_fragmentos("brigadeiro", 10)
	Telas.ir_para("colecao")
	await _esperar_tela("Colecao")
	tela = get_tree().current_scene
	tela.selecionar("brigadeiro")
	verificar(tela.find_child("Raridade", true, false).text.begins_with("COMUM"), "coleção mostra a raridade")
	verificar(tela.find_child("Bonus", true, false).text.contains("AÇÚCAR"), "coleção mostra o bônus")
	var melhorar: Button = tela.find_child("Melhorar", true, false)
	verificar(melhorar.visible and not melhorar.disabled, "com pedaços e moedas, dá para melhorar")
	melhorar.pressed.emit()
	verificar(Companheiros.nivel("brigadeiro") == 2 and Companheiros.bonus("acucar") == 15.0, "melhorar pela tela sobe o nível e o bônus")
	# explicação de primeira vez: aparece uma vez só
	var vistas: Array = Progresso.config.get("dicas_vistas", []).duplicate()
	Progresso.config["dicas_vistas"] = []
	Telas.dica_primeira_vez("teste", "TESTE", "Texto.", true)
	await get_tree().process_frame
	var caixa := get_tree().root.find_child("DicaPrimeiraVez", true, false)
	verificar(caixa != null and not caixa.get_node("%Nao").visible, "explicação de primeira vez aparece (só com ENTENDI)")
	caixa.get_node("%Sim").pressed.emit()
	await get_tree().create_timer(0.3).timeout
	Telas.dica_primeira_vez("teste", "TESTE", "Texto.", true)
	await get_tree().process_frame
	verificar(get_tree().root.find_child("DicaPrimeiraVez", true, false) == null, "e não aparece de novo")
	Progresso.config["dicas_vistas"] = vistas
	Progresso.baus = baus_antes
	Progresso.missoes = missoes_antes
	Progresso.colecao = colecao_antes
	Progresso.moedas = moedas_antes
