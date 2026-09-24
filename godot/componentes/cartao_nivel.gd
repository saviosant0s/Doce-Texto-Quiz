extends Button
## Cartão clicável de um nível: personagem, estrelas e recorde, ou cadeado se
## o nível ainda não foi liberado.

const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")

var _indice := 0


func configurar(indice: int, nivel: Dictionary) -> void:
	_indice = indice
	var progresso: Dictionary = Progresso.niveis[indice]
	var liberado := Progresso.nivel_liberado(indice)
	%Personagem.texture = Personagens.textura(nivel["personagem"])
	%Nome.text = nivel["nome"].to_upper()
	%Numero.text = "NÍVEL %d" % (indice + 1)
	for i in 3:
		var estrela := TextureRect.new()
		estrela.texture = ICONE_ESTRELA
		estrela.custom_minimum_size = Vector2(30, 30)
		estrela.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrela.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		estrela.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ganhou: bool = i < progresso["estrelas"]
		estrela.modulate = Cores.AMARELO if ganhou else Color(1, 1, 1, 0.22)
		%Estrelas.add_child(estrela)
	if not liberado:
		%Personagem.self_modulate = Color(0.22, 0.13, 0.36, 0.85)
		var cadeado := TextureRect.new()
		cadeado.texture = ICONE_CADEADO
		cadeado.modulate = Cores.AMARELO
		cadeado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cadeado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cadeado.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cadeado.set_anchors_preset(Control.PRESET_CENTER)
		cadeado.offset_left = -36
		cadeado.offset_top = -36
		cadeado.offset_right = 36
		cadeado.offset_bottom = 36
		%Personagem.add_child(cadeado)
		%Estrelas.visible = false
		var anterior: String = Jogo.niveis[indice - 1]["nome"].to_upper()
		%Acertos.text = "Passe no %s\npara liberar" % anterior
	elif progresso["partidas"] == 0:
		%Acertos.text = "Ainda não jogado"
	else:
		%Acertos.text = "Recorde: %d/%d · %s pts" % [
			progresso["recorde"], Jogo.PERGUNTAS_POR_PARTIDA, Jogo.formatar(progresso["recorde_pontos"])]
	pressed.connect(_ao_tocar)
	Animacoes.destacar_ao_passar(self)


func _ao_tocar() -> void:
	if Progresso.nivel_liberado(_indice):
		Jogo.iniciar_nivel(_indice)
	else:
		Telas.mostrar_aviso("FAÇA %d ACERTOS NO NÍVEL ANTERIOR PARA LIBERAR" % Jogo.acertos_para_passar())
