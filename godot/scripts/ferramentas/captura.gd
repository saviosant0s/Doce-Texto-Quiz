extends Node
## Ferramenta para gerar prints de qualquer tela pela linha de comando (usada
## para documentação e para conferir o visual). Não faz nada no jogo normal.
##
## Uso: godot --path godot -- --capturar=niveis --saida=/caminho/print.png
## Opções:
##   --acertos=7   simula uma partida com 7 acertos (telas de resultado)
##   --nivel=1     nível da partida simulada (0 = fácil)
##   --liberar=2   marca como aprovados os níveis antes deste (para ver cadeados)
##   --moedas=120  começa com essa quantidade de moedas
##   --historico=6 simula 6 partidas antes (para estatísticas e conquistas)
##   --revisao=3   depois, simula uma revisão com 3 acertos (tela de resultado)
##   --aba=1       aba a mostrar (tela de troféus)
##   --tocar_nivel=1  toca no cartão desse nível (tela de níveis)
##   --selecionar=pudim  escolhe esse doce na tela da coleção
##   --camera=1   na Vila dos Doces: 0 = aérea, 1 = perto, 2 = primeira pessoa
##   --camera_cozinha=1  na cozinha: 0 = de cima, 1 = perto, 2 = primeira pessoa
##   --porta=escola  na Vila dos Doces, começa na porta desse prédio
##   --confeitaria  Minha Confeitaria já em andamento (máquinas, bandejas, açúcar)
##   --entrar=escola  na Vila, começa a animação de entrar nesse prédio (use --espera=0.9)
##   --andando  na Vila, o doce anda de lado (para ver o balanço dos braços)
##   --movimento  na cozinha: clientes chegando e o doce carregando uma pilha
##   --ver_predio=confeitaria  na Vila, câmera de perto olhando a fachada desse prédio
##   --sem_decoracao  fundo liso, sem estrelas/confete (para recortes)
##   --companheiro=pudim  compra esse doce e o escolhe como companheiro
##   --match=N  Doce Match: os N primeiros níveis vencidos (3, 2, 3, 1... estrelas)
##   --match_nivel=N  Doce Match: já começa jogando o nível N
##   --match_especiais  Doce Match: põe peças especiais no tabuleiro
##   --match_explodir  Doce Match: troca a bomba (use com --match_especiais)
##   --match_fim=venceu  Doce Match: mostra o fim do nível (venceu ou perdeu)
##   --nivel_doce=pudim:5  ganha esse doce já no nível 5 (vários: pudim:5,bala:3)
##   --titulos  ganha os 3 títulos (Noob, Pro, Mestre)
##   --podio=mestre:pudim  põe esse doce no degrau do título
##   --escolher_podio=pro  abre a escolha de doce desse degrau (Troféus)
##   --cortina=vila  mostra o carregamento de ir para a vila (ou cozinha)
##   --terrenos  compra lotes e constrói (moinho nv 2, cofre, casa, jardim, fonte; um vazio)
##   --vila_pos=0,20  na Vila, põe o doce nesse ponto (x,z)
##   --confeitaria_estagio  máquinas suficientes para a Confeitaria crescer (estágio 3)
##   --animacoes  liga as animações contínuas mesmo sem placa de vídeo (borboletas etc.)
##   --espera=1.2  segundos até tirar o print


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.trim_prefix("--").split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	if not args.has("capturar"):
		return
	Progresso.somente_memoria = true
	for i in int(args.get("liberar", "0")):
		Progresso.niveis[i]["aprovado"] = true
		Progresso.niveis[i]["estrelas"] = 3 - i
		Progresso.niveis[i]["recorde"] = 10 - i * 2
		Progresso.niveis[i]["partidas"] = 3
	for i in int(args.get("historico", "0")):
		_simular_partida(i % (int(args.get("liberar", "0")) + 1), [4, 7, 9, 6, 10, 8][i % 6])
	Progresso.moedas = int(args.get("moedas", str(Progresso.moedas)))
	if args.has("camera"):
		Progresso.config["camera_vila"] = int(args["camera"])
	if args.has("camera_cozinha"):
		Progresso.config["camera_cozinha"] = int(args["camera_cozinha"])
	if args.has("porta"):
		Vila.ultima_porta = args["porta"]
	if args.has("companheiro"):
		Progresso.colecao["doces"].append(args["companheiro"])
		Progresso.colecao["companheiro"] = args["companheiro"]
	if args.has("confeitaria"):
		Progresso.niveis[0]["aprovado"] = true
		Progresso.moedas = 400
		Progresso.config["viu_confeitaria"] = true
		Confeitaria.construir_ou_melhorar("brigadeiro")
		Confeitaria.construir_ou_melhorar("maca")
		Confeitaria.construir_ou_melhorar("brigadeiro")
		Progresso.confeitaria["acucar"] = 140
		Progresso.confeitaria["maquinas"]["brigadeiro"]["bandeja"] = 8
		Progresso.confeitaria["maquinas"]["maca"]["bandeja"] = 4
		Progresso.confeitaria["atendidos"] = 5
		Progresso.moedas = 180
	if args.has("lab"):
		# --lab=N: as N primeiras fases do laboratório feitas (3, 2, 3, 1... estrelas)
		var fases := Laboratorio.fases()
		for i in mini(int(args["lab"]), fases.size()):
			Progresso.laboratorio["estrelas"][fases[i]["id"]] = [3, 2, 3, 1][i % 4]
	if args.has("nivel_doce"):
		for par in args["nivel_doce"].split(","):
			var partes: PackedStringArray = par.split(":")
			if not partes[0] in Progresso.colecao["doces"]:
				Progresso.colecao["doces"].append(partes[0])
			Companheiros._colecao()["niveis"][partes[0]] = int(partes[1])
	if args.has("animacoes"):
		Telas.placa_rapida = true
	if args.has("titulos"):
		for t in ["noob", "pro", "mestre"]:
			Progresso.titulos[t] = 2
	if args.has("podio"):
		for par in args["podio"].split(","):
			Colecao.escolher_do_podio(par.split(":")[0], par.split(":")[1])
	if args.has("terrenos"):
		Progresso.moedas = 99999
		var obras := ["moinho", "cofre", "casa", "jardim", "fonte", ""]
		for i in Terrenos.LOTES.size():
			var id: String = Terrenos.LOTES[i]["id"]
			Terrenos.comprar(id)
			if obras[i] != "":
				Terrenos.construir(id, obras[i])
		Terrenos.melhorar("lote_1")
		Progresso.vila["lotes"]["lote_1"]["desde"] = Terrenos.agora() - 3 * 3600
		Progresso.vila["lotes"]["lote_2"]["desde"] = Terrenos.agora() - 2 * 3600
		Progresso.moedas = 850
	if args.has("confeitaria_estagio"):
		Progresso.moedas = 99999
		for m in Confeitaria.MAQUINAS:
			Progresso.niveis[0]["aprovado"] = true
			Progresso.niveis[1]["aprovado"] = true
			for k in 3:
				Confeitaria.construir_ou_melhorar(m["id"])
		Progresso.moedas = 300
	if args.has("match"):
		for i in int(args["match"]):
			Progresso.doce_match["estrelas"][str(i + 1)] = [3, 2, 3, 1][i % 4]
	if args.has("baus"):
		for tipo in Baus.TIPOS:
			Baus.ganhar(tipo, int(args["baus"]))
	if args.has("pedacos"):
		# --pedacos=N: pedaços em vários doces (para a coleção mostrar o progresso)
		for id in ["bala", "pirulito", "macaron", "pudim", "algodao_doce", "brigadeiro"]:
			Companheiros.receber_fragmentos(id, int(args["pedacos"]))
	if args.has("missao"):
		var d := Missoes.diarias()
		Missoes.registrar(d[0]["tipo"], 999)
		Missoes.registrar(d[1]["tipo"], 1)
		Missoes.registrar(Missoes.semanais()[0]["tipo"], 3)
	if args.has("xp"):
		Experiencia.ganhar(int(args["xp"]))
		Experiencia.subidas_pendentes.clear()
	if args.has("lab_fase"):
		Laboratorio.fase_atual = args["lab_fase"]
	if args.has("acertos"):
		_simular_partida(int(args.get("nivel", "0")), int(args["acertos"]))
	if args.has("revisao"):
		_simular_revisao(int(args["revisao"]))
	if args["capturar"] == "partida" and Jogo.perguntas_partida.is_empty():
		Jogo.preparar_partida(int(args.get("nivel", "0")))
	await get_tree().process_frame
	get_tree().change_scene_to_file(Telas.CENAS.get(args["capturar"], args["capturar"]))
	if args.has("sem_decoracao"):
		await get_tree().process_frame  # a troca de cena acontece no quadro seguinte
		await get_tree().process_frame
		for fundo in get_tree().current_scene.find_children("*", "Control", true, false):
			if fundo is Fundo:
				fundo.decoracao = Fundo.Decoracao.NENHUMA
	if args.has("tocar_nivel"):
		await get_tree().create_timer(0.8).timeout
		var cartoes := get_tree().current_scene.find_children("*", "Button", true, false) \
			.filter(func(b): return b.has_method("configurar"))
		cartoes[int(args["tocar_nivel"])].pressed.emit()
	if args.has("abrir_bau"):
		await get_tree().create_timer(0.5).timeout
		var semente := RandomNumberGenerator.new()
		semente.seed = int(args.get("semente", "5"))
		get_tree().current_scene.abrir_bau(args["abrir_bau"], semente)
	if args.has("digitar"):
		await get_tree().create_timer(0.5).timeout
		var campo: LineEdit = get_tree().current_scene.find_child("Formula", true, false)
		campo.text = args["digitar"]
		campo.text_changed.emit(campo.text)
	if args.has("fazer"):
		# --fazer=0,0,negrito,centro: números tocam palavras; o resto são ações da fita
		await get_tree().create_timer(0.5).timeout
		for t in args["fazer"].split(","):
			if t.is_valid_int():
				get_tree().current_scene._tocar_palavra(int(t))
			else:
				get_tree().current_scene.fazer(t)
	if args.has("match_nivel"):
		await get_tree().create_timer(0.3).timeout
		Progresso.confeitaria["acucar"] = 200
		var tela := get_tree().current_scene
		tela.comecar_nivel(int(args["match_nivel"]))
		if args.has("match_especiais"):
			for c in [[2, 3, DoceMatch.Especial.LINHA], [5, 2, DoceMatch.Especial.COLUNA], [3, 6, DoceMatch.Especial.EMBRULHO]]:
				tela.jogo.especial[c[1]][c[0]] = c[2]
			tela.jogo.grade[5][6] = DoceMatch.BOMBA
			tela.jogo.especial[5][6] = DoceMatch.Especial.BOMBA
			tela._criar_pecas()
		if args.has("match_explodir"):
			await get_tree().create_timer(0.6).timeout
			tela.jogar(Vector2i(6, 5), Vector2i(6, 4))  # troca a bomba: explode tudo de um tipo
		if args.has("match_fim"):
			await get_tree().create_timer(0.5).timeout
			if args["match_fim"] == "venceu":
				tela.jogo.pontos = int(tela.jogo.nivel["estrelas"][1]) + 200
				for obj in tela.jogo.nivel["objetivos"]:
					if obj["tipo"] == "coletar":
						tela.jogo.coletados[obj["peca"]] = obj["quantidade"]
				for linha in tela.jogo.gelatina:
					linha.fill(false)
				tela.jogo.jogadas = 0
			else:
				tela.jogo.jogadas = 0
				tela.jogo.pontos = 1830
			tela._terminar()
	if args.has("escolher_podio"):
		await get_tree().create_timer(0.5).timeout
		get_tree().current_scene.escolher_doce(args["escolher_podio"])
	if args.has("cortina"):
		await get_tree().create_timer(0.3).timeout
		Telas._cortina.color.a = 1.0
		Telas._mostrar_carregando(args["cortina"])
		Telas._carregando.barra(45.0)
	if args.has("vila_pos"):
		await get_tree().process_frame
		await get_tree().process_frame
		var xz: PackedStringArray = args["vila_pos"].split(",")
		var vila: Node = get_tree().current_scene
		vila.jogador.global_position = Vector3(float(xz[0]), 0, float(xz[1]))
		if xz.size() > 2:
			vila._giro = deg_to_rad(float(xz[2]))
	if args.has("conferir"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene.conferir()
	if args.has("selecionar"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene.selecionar(args["selecionar"])
	if args.has("aba"):
		await get_tree().process_frame
		get_tree().current_scene.mostrar_aba(int(args["aba"]))
	if args.has("movimento"):
		await get_tree().process_frame
		await get_tree().process_frame
		var cozinha: Cozinha = get_tree().current_scene
		for i in 3:
			var cliente := cozinha.novo_cliente(["brigadeiro", "maca", "brigadeiro"][i], 2 + i)
			cliente["no"].global_position = Cozinha.FILA[i] + Vector3(0.5, 0, 0.3)
		for i in 4:
			cozinha._empilhar("brigadeiro" if i < 3 else "maca", cozinha.jogador.global_position)
		cozinha.jogador.global_position = Vector3(-2.5, 0, -0.2)
		cozinha.jogador.olhar_para(Vector3(-2.5, 0, 3))
		cozinha.usar_camera(cozinha.modo_camera)  # olha para onde o doce olha
		cozinha.caixa = 18
		cozinha._atualizar_moedas_visiveis()
	if args.has("entrar"):
		await get_tree().process_frame
		await get_tree().process_frame
		var vila_entrada: Vila = get_tree().current_scene
		vila_entrada.jogador.global_position = vila_entrada._portas[args["entrar"]]["porta"]
		vila_entrada.entrar(args["entrar"])
	if args.has("andando"):
		await get_tree().process_frame
		await get_tree().process_frame
		var vila_andando: Vila = get_tree().current_scene
		vila_andando.set_physics_process(false)
		vila_andando.jogador.global_position = Vector3(-4, 0, 9)
		var fim := Time.get_ticks_msec() + int(float(args.get("espera", "1.2")) * 1000) + 500
		while Time.get_ticks_msec() < fim:
			vila_andando.jogador.andar(Vector3(0.6, 0, 0), 1.0 / 60.0)
			await get_tree().physics_frame
	if args.has("ver_predio"):
		await get_tree().process_frame
		await get_tree().process_frame
		var vila: Vila = get_tree().current_scene
		var porta: Vector3 = vila._portas[args["ver_predio"]]["porta"]
		var predio: Vector3 = vila._portas[args["ver_predio"]]["no"].global_position
		vila.jogador.global_position = porta + (porta - predio).normalized() * 3.0
		vila.jogador.olhar_para(predio)
		vila.usar_camera(Vila.Camera.PERTO)
	await get_tree().create_timer(float(args.get("espera", "1.2"))).timeout
	get_viewport().get_texture().get_image().save_png(args.get("saida", "user://captura.png"))
	get_tree().quit()


func _simular_partida(nivel: int, acertos: int) -> void:
	Jogo.preparar_partida(nivel)
	for i in Jogo.perguntas_partida.size():
		var correta: int = Jogo.perguntas_partida[i]["resposta"]
		var acertou := (i * 7) % 10 < acertos  # espalha os acertos
		var escolha := correta if acertou else (-1 if i == 9 else (correta + 1) % 4)
		Jogo.registrar_resposta(escolha, 5.0 + i)
	Jogo.finalizar_partida()


func _simular_revisao(acertos: int) -> void:
	Jogo.preparar_revisao()
	for i in Jogo.perguntas_partida.size():
		var correta: int = Jogo.perguntas_partida[i]["resposta"]
		Jogo.registrar_resposta(correta if i < acertos else (correta + 1) % 4, 4.0 + i)
	Jogo.finalizar_partida()
