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
##   --porta=escola  na Vila dos Doces, começa na porta desse prédio
##   --ver_predio=confeitaria  na Vila, câmera de perto olhando a fachada desse prédio
##   --sem_decoracao  fundo liso, sem estrelas/confete (para recortes)
##   --companheiro=pudim  compra esse doce e o escolhe como companheiro
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
	if args.has("porta"):
		Vila.ultima_porta = args["porta"]
	if args.has("companheiro"):
		Progresso.colecao["doces"].append(args["companheiro"])
		Progresso.colecao["companheiro"] = args["companheiro"]
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
	if args.has("selecionar"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene.selecionar(args["selecionar"])
	if args.has("aba"):
		await get_tree().process_frame
		get_tree().current_scene.mostrar_aba(int(args["aba"]))
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
