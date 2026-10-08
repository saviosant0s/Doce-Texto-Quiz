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
##   --terrenos=4  terrenos comprados, construções no nível 4 (lote 6 em obra)
##   --confeitaria_estagio  máquinas suficientes para a Confeitaria crescer (estágio 3)
##   --animacoes  liga as animações contínuas mesmo sem placa de vídeo (borboletas etc.)
##   --torre=12  Torre de Doces: já empilha 12 andares (--torre_pergunta para na pergunta)
##   --fabrica=4  Fábrica de Chocolate: já começa e completa 4 pedidos
##   --historia=0,0  histórias da vila neste capítulo e passo; --conversar=N abre a
##                 conversa com o morador da vez e passa N falas
##   --casa_cheia  Minha Casa decorada; --loja_casa=moveis|paredes|pisos; --decorar
##   --casa_tamanho=2  tamanho da casa (0 a 3; na sala e na vila); --aumentar abre o painel
##   --evento=natal  tema do evento (roda; criancas = data do calendário); --fichas=150; --painel_evento abre a trilha
##   --hora=21     Vila: hora do dia (noite, pôr do sol...); sem ela, 14h
##   --chuva       Vila: chuva de granulado (com as gotas pelo chão)
##   --sujo        Vila: o doce sujo de chocolate (como ao sair da fonte da praça)
##   --foto=praca  Vila: tira a foto nesse ponto de foto (--foto_vista: só a vista, sem o painel)
##   --album       Vila: abre o álbum de fotos
##   --chefao=cce  Vila: enfrenta o chefão da praça e responde (c = certa, e = errada); --chefao= só abre a luta
##   --mapa        Vila: abre o mapa cheio; --regioes=ilha,bosque exploradas (e liberadas: nível 9 e títulos)
##   --batalha=0,ccec  Arena: luta contra o desafiante 0 e responde (c = certa, e = errada)
##   --batalha_time    Arena: abre a escolha do time; --arena_vencidos=3 já venceu os 3 primeiros
##   --corrida=120  Corrida: já correndo, com o seu kart a 120 m da largada (os rivais em volta);
##                 --corrida_turbo com turbo; --corrida_pergunta perto do 1º portal (a pergunta
##                 na tela); --corrida_escolha=2 toca na resposta; --corrida_fim corre até o fim
##   --abertura    Vila: passa a abertura animada (--abertura_final vai direto para o
##                 nome do jogo); --trailer grava até o fim da abertura e fecha o jogo
##                 (use com o --write-movie do Godot: ver ferramentas/gerar_divulgacao.sh)
##   --trailer_corrida=24  Corrida: corre sozinho (acerta os portais, pega as setas) por 24 s
##                 e fecha o jogo (para o vídeo do trailer, com o --write-movie)
##   --amigos      Vila: abre o painel AMIGOS com 3 amigos de exemplo no ranking
##   --visita      Vila: visita a vila de uma amiga de exemplo (com terrenos e casa grande)
##   VÍDEO VERTICAL (ferramentas/gerar_video_stories.sh, com o --write-movie do Godot):
##   --retrato     não mostra o "gire o celular" (tela em pé)
##   --sem_musica  sem a música de fundo (o vídeo tem a trilha dele)
##   --duracao=6   grava 6 s e fecha o jogo (em vez de tirar o print)
##   --video_vila  Vila sem interface, câmera descendo do alto até a praça
##   --video_batalha / --video_chefao  luta jogando sozinha (responde certo depois de "ler")
##   --corrida_inicio=120  com o --trailer_corrida, já larga a 120 m
##   --abertura_sem_texto  a abertura sem legendas, faixas nem logo (só a câmera)
##   --premio      mostra o cartão de prêmio (ícones) e um aviso com prêmio
##   --qualidade=1  gráficos BAIXA (0), MÉDIA (1) ou ALTA (2)
##   --painel_desempenho  liga o indicador de FPS e memória
##   --desempenho  imprime objetos, chamadas de desenho, triângulos e nós da tela
##   --espera=1.2  segundos até tirar o print


## Segundos já gravados nos modos de vídeo que jogam sozinhos (ver --duracao).
var _tempo_video := 0.0


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.trim_prefix("--").split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	if not args.has("capturar"):
		return
	Progresso.somente_memoria = true
	if args.has("sem_musica"):
		Progresso.config["volume_musica"] = 0.0
		Audio.aplicar_volumes()
	for i in int(args.get("liberar", "0")):
		Progresso.niveis[i]["aprovado"] = true
		Progresso.niveis[i]["estrelas"] = 3 - i
		Progresso.niveis[i]["recorde"] = 10 - i * 2
		Progresso.niveis[i]["partidas"] = 3
	for i in int(args.get("historico", "0")):
		_simular_partida(i % (int(args.get("liberar", "0")) + 1), [4, 7, 9, 6, 10, 8][i % 6])
	Progresso.moedas = int(args.get("moedas", str(Progresso.moedas)))
	# prints da vila de cima (a aérea mostra mais); --camera=1 para a de perto
	Progresso.config["camera_vila_v2"] = int(args.get("camera", "0"))
	if args.has("camera_cozinha"):
		Progresso.config["camera_cozinha"] = int(args["camera_cozinha"])
	if args.has("porta"):
		Vila.ultima_porta = args["porta"]
	# evento da temporada: --evento=2026-10-20 (data do evento), --fichas=150
	if args.has("evento"):
		# --evento=natal: o dia do jogo em que esse tema está no meio (fora
		# das datas do calendário); --evento=criancas: uma data dele
		Eventos.data_fixa = "2026-09-01"
		if args["evento"] in Eventos.ORDEM:
			CicloDia.dia_fixo = 24870 * Eventos.DIAS_POR_EVENTO + Eventos.ORDEM.find(args["evento"]) * Eventos.DIAS_POR_EVENTO + 10
		else:
			for ev in Eventos.CALENDARIO:
				if ev["tema"] == args["evento"]:
					Eventos.data_fixa = "2026-" + str(ev["inicio"]).right(5)
	if args.has("fichas"):
		Eventos.ganhar_fichas(int(args["fichas"]))
	if args.has("painel_desempenho"):
		Progresso.config["desempenho"] = true
		Telas.mostrar_desempenho(true)
	if args.has("qualidade"):
		Progresso.config["qualidade"] = int(args["qualidade"])  # 0 baixa, 1 média, 2 alta
	# dia e noite: --hora=21 (fixa a hora), --chuva (chuva de granulado)
	CicloDia.hora_fixa = float(args.get("hora", "14"))
	CicloDia.chuva_fixa = 1 if args.has("chuva") else 0
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
		# --terrenos=N: todas as construções no nível N (e a do lote 6 em obra)
		var nivel_todos := int(args["terrenos"]) if args["terrenos"] != "" else 2
		for i in 5:
			Progresso.vila["lotes"][Terrenos.LOTES[i]["id"]]["nivel"] = nivel_todos
		Terrenos.construir("lote_6", "casa")
		Terrenos.melhorar("lote_6")
		Progresso.vila["lotes"]["lote_1"]["desde"] = Terrenos.agora() - 3 * 3600
		Progresso.vila["lotes"]["lote_2"]["desde"] = Terrenos.agora() - 2 * 3600
		Progresso.moedas = 850
	if args.has("historia"):
		# --historia=2,1: capítulo 3, passo 2 (contando do 0)
		var partes: PackedStringArray = args["historia"].split(",")
		Progresso.vila["historia"] = {"capitulo": int(partes[0]), "passo": int(partes[1]) if partes.size() > 1 else 0, "progresso": 0}
		Progresso.jogador["nivel"] = 9
	if args.has("casa_cheia"):
		# sala decorada: parede, piso e vários móveis
		var casa := Casa.padrao()
		casa["parede"] = "listras_rosa"
		casa["piso"] = "biscoito"
		casa["colocados"] = [{"id": "tapete_glace", "x": 3, "z": 2, "giro": 0}, {"id": "sofa_marshmallow", "x": 3, "z": 1, "giro": 0},
			{"id": "mesa_biscoito", "x": 4, "z": 3, "giro": 0}, {"id": "planta_cupcake", "x": 0, "z": 0, "giro": 0},
			{"id": "estante_chocolate", "x": 5, "z": 0, "giro": 0}, {"id": "tv_wafer", "x": 0, "z": 2, "giro": 1},
			{"id": "cama_bolo", "x": 7, "z": 3, "giro": 0}, {"id": "luminaria_bala", "x": 7, "z": 0, "giro": 0},
			{"id": "piano_chocolate", "x": 1, "z": 0, "giro": 0}, {"id": "aquario_gelatina", "x": 2, "z": 5, "giro": 0},
			{"id": "cadeira_pirulito", "x": 5, "z": 3, "giro": 3}, {"id": "trofeu_gigante", "x": 6, "z": 5, "giro": 0}]
		for c in casa["colocados"]:
			casa["moveis"][c["id"]] = int(casa["moveis"].get(c["id"], 0)) + 1
		casa["moveis"]["geladeira_sorvete"] = 1
		casa["moveis"]["relogio_cuco"] = 1
		Progresso.vila["casa"] = casa
		Progresso.moedas = 1200
	if args.has("regioes"):
		Progresso.jogador["nivel"] = 9
		Progresso.titulos = {"noob": 1, "pro": 1, "mestre": 1}
		Progresso.vila["regioes"] = {"exploradas": Array(args["regioes"].split(",", false)), "coletados": {"dia": -1, "ids": []}}
	if args.has("arena_vencidos"):
		Progresso.vila["arena"] = {"vencidos": range(int(args["arena_vencidos"])), "time": [], "vitorias": int(args["arena_vencidos"])}
	if args.has("casa_tamanho"):
		if not Progresso.vila.has("casa"):
			Progresso.vila["casa"] = Casa.padrao()
		var n := int(args["casa_tamanho"])
		# os móveis vão para o meio da sala maior (como em Casa.aumentar)
		for c in Progresso.vila["casa"]["colocados"]:
			c["x"] = int(c["x"]) + (int(Casa.TAMANHOS[n]["grade"][0]) - 8) / 2
		Progresso.vila["casa"]["tamanho"] = n
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
	if args.has("conversar"):
		await get_tree().create_timer(0.5).timeout
		var vila: Node = get_tree().current_scene
		var id: String = Historia.morador_da_vez()
		vila.jogador.global_position = vila._moradores_historia[id].global_position + Vector3(0, 0, 2)
		vila.conversar()
		for i in int(args["conversar"]):
			await get_tree().create_timer(0.2).timeout
			vila.dialogo.responder(0)
	if args.has("painel_evento"):
		await get_tree().create_timer(0.4).timeout
		get_tree().current_scene.abrir_evento()
	if args.has("loja_casa"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene._aba_loja = args["loja_casa"] if args["loja_casa"] != "" else "moveis"
		get_tree().current_scene.abrir_loja()
		get_tree().current_scene.escolher_na_loja(get_tree().current_scene._escolha_loja)
	if args.has("aumentar"):
		await get_tree().create_timer(0.3).timeout
		Progresso.moedas = 2000
		Progresso.confeitaria["acucar"] = 700
		get_tree().current_scene.abrir_aumentar()
	if args.has("decorar"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene.usar_modo(true)
		get_tree().current_scene.selecionar(1)
	if args.has("vila_pos"):
		await get_tree().process_frame
		await get_tree().process_frame
		var xz: PackedStringArray = args["vila_pos"].split(",")
		var vila: Node = get_tree().current_scene
		vila.jogador.global_position = Vector3(float(xz[0]), 0, float(xz[1]))
		if xz.size() > 2:
			vila._giro = deg_to_rad(float(xz[2]))
	if args.has("foto"):
		await get_tree().create_timer(0.3).timeout
		var vila: Node = get_tree().current_scene
		vila.tirar_foto(args["foto"])
		if args.has("foto_vista"):
			while not is_instance_valid(vila._camada_foto):
				await get_tree().process_frame
			vila._camada_foto.visible = false
	if args.has("batalha"):
		await get_tree().create_timer(0.3).timeout
		var arena: Node = get_tree().current_scene
		var partes: PackedStringArray = args["batalha"].split(",")
		arena.lutar(int(partes[0]))
		for letra in (partes[1] if partes.size() > 1 else ""):
			while arena.luta != null and not arena.respondendo and not arena.luta.acabou():
				await get_tree().process_frame
			if arena.luta == null or arena.luta.acabou():
				break
			var certa := int(arena.luta.pergunta["resposta"])
			arena.responder(certa if letra == "c" else (certa + 1) % arena.luta.pergunta["alternativas"].size())
			await get_tree().process_frame
		if partes.size() > 1 and arena.luta != null and not arena.luta.acabou():
			while not arena.respondendo:
				await get_tree().process_frame
	if args.has("batalha_time"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene.mostrar_time()
	if args.has("mapa"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene.abrir_mapa()
	if args.has("chefao"):
		await get_tree().create_timer(0.3).timeout
		var vila_chefao: Node = get_tree().current_scene
		vila_chefao.enfrentar_chefao()
		var luta: LutaChefao = vila_chefao._luta_chefao
		for letra in args["chefao"]:
			while is_instance_valid(luta) and not luta.respondendo and not luta.luta.acabou():
				await get_tree().process_frame
			if not is_instance_valid(luta) or luta.luta.acabou():
				break
			var certa := int(luta.luta.pergunta["resposta"])
			luta.responder(certa if letra == "c" else (certa + 1) % luta.luta.pergunta["alternativas"].size())
			await get_tree().process_frame
	if args.has("album"):
		await get_tree().create_timer(0.3).timeout
		get_tree().current_scene.abrir_album()
	if args.has("sujo"):
		await get_tree().process_frame
		var vila: Node = get_tree().current_scene
		vila.jogador.sujar(vila.jogador.altura_no_modelo(CenarioVila.ALTURA_FONTE))
		await get_tree().process_frame
		vila.jogador.olhar_para(vila._camera.global_position)  # de frente para ver a sujeira
	if args.has("torre"):
		await get_tree().create_timer(0.3).timeout
		Progresso.confeitaria["acucar"] = 200
		var t: Node = get_tree().current_scene
		t.comecar()
		for i in int(args["torre"]):
			t.jogo.atual["x"] = t.jogo.topo()["x"] + [0.0, 14.0, -10.0, 0.0, 22.0, -6.0, 0.0][i % 7]
			t.soltar()
			await get_tree().create_timer(0.1).timeout
			if t.jogo.pergunta_pendente:
				await get_tree().create_timer(0.5).timeout
				if args.has("torre_pergunta"):
					break
				t._resultado_pergunta(true)
	if args.has("fabrica"):
		await get_tree().create_timer(0.3).timeout
		Progresso.confeitaria["acucar"] = 200
		var f: Node = get_tree().current_scene
		f.comecar()
		f.jogo.pedidos_feitos = int(args["fabrica"])
		f.jogo._novo_pedido()
		f._montar_pedido()
	if args.has("trailer_corrida"):
		await get_tree().create_timer(0.8).timeout
		var pista_demo: Node = get_tree().current_scene
		pista_demo.comecar()
		var demo: Corrida = pista_demo.corrida
		if args.has("corrida_inicio"):
			demo.contagem = 0.0
			var inicio := float(args["corrida_inicio"])
			for i in demo.corredores.size():
				demo.colocar(i, inicio + [0.0, 9.0, 5.0, -6.0][i], [0.5, -3.0, 3.5, -1.5][i])
				demo.corredores[i]["v"] = 22.0
			pista_demo._seguir_com_camera(0.0, true)
		var fim_demo := Time.get_ticks_msec()  # (no --write-movie o relógio do jogo anda a 30 quadros por segundo)
		var segundos := 0.0
		var pensando := 0.0
		while segundos < float(args["trailer_corrida"]):
			await get_tree().process_frame
			var passo := get_process_delta_time()
			segundos += passo
			# toca na resposta certa depois de "ler" um pouquinho
			if demo.portal_ativo >= 0 and demo.escolha < 0:
				pensando += passo
				if pensando > 1.6:
					pista_demo.escolher(int(demo.pergunta()["resposta"]))
					pensando = 0.0
			# fora dos portais, vai para as setas e desvia das poças e blocos
			pista_demo._dedos.clear()
			var eu := demo.jogador()
			if demo.portal_ativo < 0 and not eu["auto"] and demo.contagem <= 0.0:
				var alvo: float = eu["x"]
				for e in demo.setas:
					var falta := demo._distancia_a_frente(eu["s"], e["s"])
					if falta > 0.0 and falta < 30.0:
						alvo = e["x"]
				for e in demo.pocas + demo.blocos:
					var falta := demo._distancia_a_frente(eu["s"], e["s"])
					if falta > 0.0 and falta < 20.0 and absf(alvo - e["x"]) < 2.4:
						alvo = e["x"] + (3.0 if e["x"] < 0.0 else -3.0)
				if absf(alvo - eu["x"]) > 0.3:
					pista_demo._dedos[0] = int(signf(alvo - eu["x"]))
		print("trailer da corrida: %.1f s (%d ms de verdade)" % [segundos, Time.get_ticks_msec() - fim_demo])
		get_tree().quit()
		return
	if args.has("corrida") or args.has("corrida_pergunta") or args.has("corrida_fim"):
		await get_tree().create_timer(0.3).timeout
		var pista: Node = get_tree().current_scene
		pista.comecar()
		var c: Corrida = pista.corrida
		c.contagem = 0.0
		var s := float(args.get("corrida", "60"))
		if args.has("corrida_pergunta"):
			s = c.portais[0] - Corrida.AVISO_PORTAL + 6.0
		for i in c.corredores.size():
			c.colocar(i, s + [0.0, 10.0, 5.0, -7.0][i], [0.5, -3.0, 3.5, -1.5][i])
			c.corredores[i]["v"] = 22.0
		if args.has("corrida_turbo"):
			c.jogador()["turbo"] = 3.0
		pista._seguir_com_camera(0.0, true)
		# meio segundo de corrida a 60 quadros por segundo (o print sem placa de
		# vídeo desenha poucos quadros; a câmera e o fogo ficariam estranhos)
		for i in 30:
			pista._process(1.0 / 60.0)
			if i % 10 == 0:
				await get_tree().process_frame
		pista.set_process(false)
		if args.has("corrida_escolha"):
			for i in 30:
				await get_tree().process_frame
			pista.escolher(int(args["corrida_escolha"]))
		if args.has("corrida_fim"):
			for i in 6000:
				if c.portal_ativo >= 0 and c.escolha < 0:
					pista.escolher(int(c.pergunta()["resposta"]))
				pista._process(1.0 / 30.0)
				if pista.estado == "fim":
					break
			await get_tree().create_timer(1.8).timeout
	if args.has("abertura") or args.has("abertura_final") or args.has("trailer"):
		await get_tree().process_frame
		var vila_abertura: Vila = get_tree().current_scene
		Vila.abrir_com_abertura = false
		vila_abertura.ver_abertura()  # (a captura abre a cena direto, sem o aquecer do Telas)
		var abertura: AberturaVila = vila_abertura._abertura
		if args.has("abertura_final"):
			abertura.pular()
		elif args.has("trailer"):
			while abertura.tomada >= 0:
				await get_tree().process_frame
			await get_tree().create_timer(4.5).timeout
			get_tree().quit()
			return
	if args.has("amigos") or args.has("visita"):
		await get_tree().create_timer(0.3).timeout
		Progresso.jogador["nome"] = "ANA"
		Progresso.jogador["semana"] = {"id": Amigos.semana(), "pontos": 340}
		for exemplo in [["bia00001", "BIA", "pudim", 520, 0], ["leo00002", "LEO", "churros", 210, 0], ["duda0003", "DUDA", "sorvete", 90, 1]]:
			var d := Amigos.meus_dados()
			d["i"] = exemplo[0]
			d["n"] = exemplo[1]
			d["d"] = exemplo[2]
			d["dn"] = 3
			d["l"] = 9
			d["lo"] = {"lote_1": ["moinho", 3], "lote_2": ["cofre", 2], "lote_3": ["casa", 2], "lote_4": ["jardim", 2], "lote_5": ["fonte", 1]}
			d["m"] = {"brigadeiro": 3, "maca": 2, "cupcake": 2}
			d["c"] = {"t": 2, "p": "creme", "pi": "madeira", "o": []}
			d["r"] = ["ilha"]
			d["s"] = [Amigos.semana() - exemplo[4], exemplo[3]]
			Amigos.adicionar(Amigos.codificar(d))
		if args.has("amigos"):
			get_tree().current_scene.abrir_amigos()
		else:
			Vila.visitar(Amigos.amigo("bia00001"))
			await get_tree().create_timer(1.5).timeout
			while get_tree().current_scene == null or get_tree().current_scene.name != "Vila":
				await get_tree().process_frame
			await get_tree().create_timer(1.0).timeout
	if args.has("video_vila"):
		await get_tree().process_frame
		var vila_video: Vila = get_tree().current_scene
		vila_video.camera_externa = true
		vila_video._interface.visible = false
		var cam: Camera3D = vila_video._camera
		var de := Transform3D(Basis.looking_at(Vector3(0, -60, -48)), Vector3(0, 62, 46))
		var ate := Transform3D(Basis.looking_at(Vector3(0, -9, -15)), Vector3(0, 11, 13))
		var segundos := float(args.get("duracao", "4"))
		var voo := create_tween()
		voo.tween_method(func(p: float): cam.global_transform = de.interpolate_with(ate, p), 0.0, 1.0, segundos) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if args.has("video_batalha") or args.has("video_chefao"):
		await get_tree().create_timer(0.3).timeout
		var cena: Node = get_tree().current_scene
		var luta_no: Node = cena
		if args.has("video_batalha"):
			cena.lutar(0)
		else:
			cena.enfrentar_chefao()
			luta_no = cena._luta_chefao
		var lendo := 0.0
		while _tempo_video < float(args.get("duracao", "999")):
			await get_tree().process_frame
			_tempo_video += get_process_delta_time()
			if not is_instance_valid(luta_no) or luta_no.luta == null or luta_no.luta.acabou():
				break
			if luta_no.respondendo:
				lendo += get_process_delta_time()
				if lendo > 1.4:
					luta_no.responder(int(luta_no.luta.pergunta["resposta"]))
					lendo = 0.0
	if args.has("abertura_sem_texto"):
		await get_tree().process_frame
		var vila_fim: Vila = get_tree().current_scene
		if is_instance_valid(vila_fim._abertura):
			vila_fim._abertura.visible = false
	if args.has("premio"):
		await get_tree().create_timer(0.3).timeout
		Telas.mostrar_aviso("+15 AÇÚCAR  +8 MOEDAS")
		Telas.mostrar_premio({"moedas": 40, "acucar": 30, "xp": 25, "bau": "ouro"}, "MISSÃO CUMPRIDA!")
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
	if args.has("perfil"):
		# tempo de CPU por quadro (sem desenhar: só scripts, física e motor), a
		# toda velocidade (o modo de baixo consumo esperaria entre os quadros)
		OS.low_processor_usage_mode = false
		await get_tree().process_frame
		var inicio_perfil := Time.get_ticks_usec()
		var quadros := 0
		var soma := 0.0
		var pior := 0.0
		var soma_fisica := 0.0
		var fim_perfil := Time.get_ticks_msec() + int(float(args["perfil"]) * 1000)
		while Time.get_ticks_msec() < fim_perfil:
			await get_tree().process_frame
			var t := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			soma += t
			pior = maxf(pior, t)
			soma_fisica += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			quadros += 1
		print("PERFIL %s: %.2f ms/quadro de CPU (%d quadros), processo %.2f (pior %.1f), física %.2f ms, nós %d, objetos %d" % [args["capturar"],
			(Time.get_ticks_usec() - inicio_perfil) / 1000.0 / maxi(1, quadros), quadros,
			soma / maxi(1, quadros), pior, soma_fisica / maxi(1, quadros), Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.OBJECT_COUNT)])
		get_tree().quit()
		return
	if args.has("duracao"):
		await get_tree().create_timer(maxf(0.05, float(args["duracao"]) - _tempo_video)).timeout
		get_tree().quit()
		return
	await get_tree().create_timer(float(args.get("espera", "1.2"))).timeout
	if args.has("desempenho"):
		# quanto a tela pesa para desenhar (o FPS aqui não vale: é sem placa de vídeo)
		print("DESEMPENHO %s: objetos=%d chamadas=%d triangulos=%d nos=%d luzes=%d particulas=%d" % [args["capturar"],
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			get_tree().current_scene.find_children("*", "Light3D", true, false).filter(func(l): return l.is_visible_in_tree()).size(),
			get_tree().current_scene.find_children("*", "CPUParticles3D", true, false).size()])
		if args["desempenho"] == "detalhe":
			# triângulos por parte da cena (filho direto da raiz), dos maiores para os menores
			var raiz := get_tree().current_scene
			var somas := {}
			for no in raiz.find_children("*", "GeometryInstance3D", true, false):
				if not no.is_visible_in_tree():
					continue
				var malha: Mesh = no.mesh if no is MeshInstance3D else (no.multimesh.mesh if no is MultiMeshInstance3D and no.multimesh else null)
				if malha == null:
					continue
				var tri := 0
				for sup in malha.get_surface_count():
					var arr := malha.surface_get_arrays(sup)
					var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
					tri += (ind.size() if ind.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
				if no is MultiMeshInstance3D:
					tri *= no.multimesh.visible_instance_count if no.multimesh.visible_instance_count >= 0 else no.multimesh.instance_count
				var parte: Node = no
				while parte.get_parent() != raiz:
					parte = parte.get_parent()
				var chave := String(parte.name).split("@")[0] + " (" + parte.get_class() + ")"
				somas[chave] = somas.get(chave, 0) + tri
			var chaves := somas.keys()
			chaves.sort_custom(func(a, b): return somas[a] > somas[b])
			for c in chaves.slice(0, 15):
				print("  ", c, ": ", somas[c])
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
