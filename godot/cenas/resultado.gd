extends Control
## Resultado da partida: título do nível e estrelas (se passou) ou quanto faltou
## para passar, moedas ganhas, recorde e nível liberado.

const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const PERSONAGENS_TITULO := {"noob": "maca_noob", "pro": "cupcake_pro", "mestre": "chocolate_mestre"}


func _ready() -> void:
	var r := Jogo.resumo
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
	%Destaques.visible = %Destaques.get_child_count() > 0

	%Inicio.pressed.connect(Telas.ir_para.bind("inicio"))
	%JogarDeNovo.pressed.connect(Jogo.iniciar_nivel.bind(r["nivel"]))
	Animacoes.entrar(%Personagem, Vector2(-60, 0))
	Animacoes.entrar(%Cartao, Vector2(60, 0), 0.1)
	if r["aprovado"]:
		Animacoes.flutuar(%Personagem)


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
