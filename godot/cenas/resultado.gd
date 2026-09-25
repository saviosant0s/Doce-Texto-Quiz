extends Control
## Resultado da partida: título do nível e estrelas (se passou) ou quanto faltou
## para passar, moedas ganhas, recorde, nível liberado e conquistas novas.
## Na revisão, mostra quantas perguntas erradas o jogador corrigiu.

const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const ICONE_CERTO := preload("res://assets/icones/certo.svg")
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")
const ICONE_PONTOS := preload("res://assets/icones/grafico.svg")
const ICONE_LAMPADA := preload("res://assets/icones/lampada.svg")
const ICONE_ACUCAR := preload("res://assets/icones/acucar.svg")
## Personagem mostrado (nome como em Personagens.textura).
var _personagem := "brigadeiro_triste"

const PERSONAGENS_TITULO := {"noob": "maca_noob", "pro": "cupcake_pro", "mestre": "chocolate_mestre"}


func _ready() -> void:
	var r := Jogo.resumo
	%Detalhe.visible = false  # os números aparecem em etiquetas, sem texto corrido
	%Inicio.pressed.connect(Telas.ir_para_casa)
	if r["revisao"]:
		_mostrar_revisao(r)
	else:
		_mostrar_partida(r)
	if r.get("acucar", 0) > 0:  # vai para a Minha Confeitaria
		_destaque("+%d" % r["acucar"], ICONE_ACUCAR)
	%Destaques.visible = %Destaques.get_child_count() > 0
	%Personagem.texture = Personagens.textura(_personagem)
	Personagens.animar(%Personagem, _personagem)  # doce 3D vivo, se o aparelho aguentar
	Animacoes.entrar(%Personagem, Vector2(-60, 0))
	Animacoes.entrar(%Cartao, Vector2(60, 0), 0.1)
	if r["aprovado"] or (r["revisao"] and r["acertos"] > 0):
		Animacoes.flutuar(%Personagem)
	_anunciar_conquistas(r["conquistas"])


func _mostrar_partida(r: Dictionary) -> void:
	if r["aprovado"]:
		%Chamada.text = "PARABÉNS!"
		%Titulo.text = "VOCÊ É UM DOCEIRO %s!" % r["titulo"].to_upper()
		_personagem = PERSONAGENS_TITULO[r["titulo"]]
		%JogarDeNovo.text = "JOGAR DE NOVO"
	else:
		var faltaram: int = Jogo.acertos_para_passar() - r["acertos"]
		%Chamada.text = "QUASE LÁ! FALTOU 1 ACERTO" if faltaram == 1 else "FALTARAM %d ACERTOS" % faltaram
		%Titulo.text = "VOCÊ AINDA NÃO É UM DOCEIRO!"
		_personagem = "brigadeiro_triste"
		%JogarDeNovo.text = "TENTE NOVAMENTE"
		%Fundo.decoracao = Fundo.Decoracao.NENHUMA
	_mostrar_estrelas(r["estrelas"])
	_destaque("%d/%d" % [r["acertos"], r["total"]], ICONE_CERTO)
	_destaque("+%d" % r["moedas"], ICONE_MOEDA)
	_destaque(Jogo.formatar(r["pontos"]), ICONE_PONTOS)
	if r["novo_recorde_pontos"]:
		_destaque("NOVO RECORDE!", null, true)
	if r["liberou_nivel"]:
		var proximo: String = Jogo.niveis[r["nivel"] + 1]["nome"].to_upper()
		_destaque("%s LIBERADO!" % proximo, null, true)
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
	_personagem = "cupcake_pro" if r["acertos"] > 0 else "brigadeiro_triste"
	_destaque("%d/%d" % [r["acertos"], r["total"]], ICONE_CERTO)
	_destaque("+%d" % r["moedas"], ICONE_MOEDA)
	_destaque(Jogo.formatar(r["pontos"]), ICONE_PONTOS)
	if restantes > 0:
		_destaque("FALTA%s %d" % ["" if restantes == 1 else "M", restantes], ICONE_LAMPADA)
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


## Etiqueta com ícone opcional (ex.: moeda "+45"). As de `destaque` (recorde,
## nível liberado) são verdes.
func _destaque(texto: String, icone: Texture2D = null, destaque := false) -> void:
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"Etiqueta"
	var cor := Color.WHITE if destaque else Cores.AMARELO
	if destaque:
		var estilo: StyleBoxFlat = etiqueta.get_theme_stylebox("panel", &"Etiqueta").duplicate()
		estilo.bg_color = Cores.VERDE
		etiqueta.add_theme_stylebox_override("panel", estilo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	etiqueta.add_child(linha)
	if icone:
		var imagem := TextureRect.new()
		imagem.texture = icone
		imagem.modulate = cor
		imagem.custom_minimum_size = Vector2(26, 26)
		imagem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		linha.add_child(imagem)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", 30)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.text = texto
	linha.add_child(rotulo)
	%Destaques.add_child(etiqueta)
