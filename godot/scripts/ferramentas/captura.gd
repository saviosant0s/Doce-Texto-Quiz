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
	Progresso.moedas = int(args.get("moedas", str(Progresso.moedas)))
	if args.has("acertos"):
		_simular_partida(int(args.get("nivel", "0")), int(args["acertos"]))
	if args["capturar"] == "partida" and Jogo.perguntas_partida.is_empty():
		Jogo.preparar_partida(int(args.get("nivel", "0")))
	await get_tree().process_frame
	get_tree().change_scene_to_file(Telas.CENAS[args["capturar"]])
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
