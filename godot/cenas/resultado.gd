extends Control
## Resultado da partida: título do nível e estrelas (se passou) ou quanto faltou
## para passar, moedas ganhas, recorde, nível liberado e conquistas novas.
## Na revisão, mostra quantas perguntas erradas o jogador corrigiu.

const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const PERSONAGENS_TITULO := {"noob": "maca_noob", "pro": "cupcake_pro", "mestre": "chocolate_mestre"}


func _ready() -> void:
	var r := Jogo.resumo
	%Inicio.pressed.connect(Telas.ir_para.bind("inicio"))
	if r["revisao"]:
		_mostrar_revisao(r)
	else:
		_mostrar_partida(r)
	%Destaques.visible = %Destaques.get_child_count() > 0
	Animacoes.entrar(%Personagem, Vector2(-60, 0))
	Animacoes.entrar(%Cartao, Vector2(60, 0), 0.1)
	if r["aprovado"] or (r["revisao"] and r["acertos"] > 0):
		Animacoes.flutuar(%Personagem)
	_anunciar_conquistas(r["conquistas"])


func _mostrar_partida(r: Dictionary) -> void:
	var nome_nivel: String = Jogo.niveis[r["nivel"]]["nome"].to_upper()
	if r["aprovado"]:
		%Chamada.text = "PARABÉNS!"
		%Titulo.text = "VOCÊ É UM DOCEIRO %s!" % r["titulo"].to_upper()
		%Personagem.texture = Personagens.textura(PERSONAGENS_TITULO[r["titulo"]])
		%Detalhe.text = "Você acertou %d de %d no nível %s e ganhou %d moedas." % [
			r["acertos"], r["total"], nome_nivel.to_lower(), r["moedas"]]
		%JogarDeNovo.text = "JOGAR DE NOVO"
	else:
		var faltaram: int = Jogo.acertos_para_passar() - r["acertos"]
		%Chamada.text = "QUASE LÁ!" if faltaram == 1 else "QUE PENA!"
		%Titulo.text = "VOCÊ AINDA NÃO É UM DOCEIRO!"
		%Personagem.texture = Personagens.textura("brigadeiro_triste")
		%Detalhe.text = "Você acertou %d de %d. Faltou %s para passar no nível %s. Você ganhou %d moedas." % [
			r["acertos"], r["total"], _acertos(faltaram), nome_nivel.to_lower(), r["moedas"]]
		%JogarDeNovo.text = "TENTE NOVAMENTE"
		%Fundo.decoracao = Fundo.Decoracao.NENHUMA
	_mostrar_estrelas(r["estrelas"])
	_destaque("%s PONTOS" % Jogo.formatar(r["pontos"]))
	if r["novo_recorde_pontos"]:
		_destaque("NOVO RECORDE!")
	if r["liberou_nivel"]:
		var proximo: String = Jogo.niveis[r["nivel"] + 1]["nome"].to_upper()
		_destaque("NÍVEL %s LIBERADO!" % proximo)
		%ProximoNivel.visible = true
		%ProximoNivel.text = "IR PARA O NÍVEL %s" % proximo
		%ProximoNivel.pressed.connect(Jogo.iniciar_nivel.bind(r["nivel"] + 1))
	%JogarDeNovo.pressed.connect(Jogo.iniciar_nivel.bind(r["nivel"]))


func _mostrar_revisao(r: Dictionary) -> void:
	var restantes: int = r["restantes"]
	%Estrelas.visible = false
	if r["acertos"] == r["total"]:
		%Chamada.text = "MANDOU BEM!"
		%Titulo.text = "VOCÊ CORRIGIU TODOS OS ERROS!"
	elif r["acertos"] > 0:
		%Chamada.text = "BOA!"
		%Titulo.text = "VOCÊ CORRIGIU %d DE %d!" % [r["acertos"], r["total"]]
	else:
		%Chamada.text = "NÃO DESISTA!"
		%Titulo.text = "LEIA AS EXPLICAÇÕES E TENTE DE NOVO!"
		%Fundo.decoracao = Fundo.Decoracao.NENHUMA
	%Personagem.texture = Personagens.textura("cupcake_pro" if r["acertos"] > 0 else "brigadeiro_triste")
	var faltam := "Não sobrou nenhuma pergunta para revisar." if restantes == 0 \
		else "Ainda falta%s %d para revisar." % ["" if restantes == 1 else "m", restantes]
	%Detalhe.text = "Você ganhou %d moedas. %s" % [r["moedas"], faltam]
	_destaque("%s PONTOS" % Jogo.formatar(r["pontos"]))
	if restantes > 0:
		%JogarDeNovo.text = "REVISAR DE NOVO"
		%JogarDeNovo.pressed.connect(Jogo.iniciar_revisao)
	else:
		%JogarDeNovo.text = "ESCOLHER NÍVEL"
		%JogarDeNovo.pressed.connect(Telas.ir_para.bind("niveis"))


## Faixa "CONQUISTA DESBLOQUEADA" descendo do topo, uma de cada vez.
func _anunciar_conquistas(novas: Array) -> void:
	if novas.is_empty():
		return
	await get_tree().create_timer(1.4).timeout
	for conquista in novas:
		if not is_inside_tree():
			return
		var faixa := _criar_faixa_conquista(conquista)
		add_child(faixa)
		# No canto de cima, sobre o espaço do personagem (sem cobrir o cartão)
		faixa.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)
		var destino := faixa.position.y
		faixa.position.y = -faixa.size.y - 10
		var tween := create_tween()
		tween.tween_property(faixa, "position:y", destino, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(1.8)
		tween.tween_property(faixa, "position:y", -faixa.size.y - 10, 0.3).set_ease(Tween.EASE_IN)
		tween.tween_callback(faixa.queue_free)
		Audio.tocar("acerto")
		await tween.finished


func _criar_faixa_conquista(conquista: Dictionary) -> PanelContainer:
	var faixa := PanelContainer.new()
	faixa.name = "Conquista"
	faixa.theme_type_variation = &"EtiquetaAmarela"
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	faixa.add_child(linha)
	var icone := TextureRect.new()
	icone.texture = Conquistas.icone(conquista)
	icone.modulate = Cores.ROXO
	icone.custom_minimum_size = Vector2(48, 48)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(icone)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", -4)
	linha.add_child(textos)
	var chamada := Label.new()
	chamada.theme_type_variation = &"Subtitulo"
	chamada.add_theme_font_size_override("font_size", 20)
	chamada.text = "CONQUISTA DESBLOQUEADA · +%d MOEDAS" % conquista["moedas"]
	textos.add_child(chamada)
	var nome := Label.new()
	nome.theme_type_variation = &"Titulo"
	nome.add_theme_font_size_override("font_size", 38)
	nome.text = conquista["nome"]
	textos.add_child(nome)
	return faixa


func _acertos(n: int) -> String:
	return "1 acerto" if n == 1 else "%d acertos" % n


## Três estrelas; as conquistadas aparecem uma a uma com um "pop".
func _mostrar_estrelas(quantidade: int) -> void:
	for i in 3:
		var estrela := TextureRect.new()
		estrela.texture = ICONE_ESTRELA
		estrela.custom_minimum_size = Vector2(54, 54)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrela.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		estrela.pivot_offset = Vector2(27, 27)
		%Estrelas.add_child(estrela)
		if i < quantidade:
			estrela.modulate = Cores.OURO
			estrela.scale = Vector2.ZERO
			var tween := create_tween()
			tween.tween_interval(0.6 + i * 0.3)
			tween.tween_property(estrela, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			estrela.modulate = Color(Cores.ROXO, 0.18)


func _destaque(texto: String) -> void:
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"Etiqueta"
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", 28)
	rotulo.text = texto
	etiqueta.add_child(rotulo)
	%Destaques.add_child(etiqueta)
