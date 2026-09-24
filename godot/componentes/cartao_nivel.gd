extends Button
## Cartão clicável de um nível: personagem, estrelas e recorde, ou cadeado se
## o nível ainda não foi liberado.

const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")

var _indice := 0
var _cadeado: TextureRect
var _balao: Control


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
	# Altura da caixa roxa com estrelas e texto, para os cartões bloqueados
	# (só com estrelas) ficarem do mesmo tamanho dos outros
	var altura_caixa: float = %Caixa.get_combined_minimum_size().y
	if not liberado:
		%Personagem.material = Personagens.material_silhueta()
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
		_cadeado = cadeado
		cadeado.resized.connect(func(): cadeado.pivot_offset = cadeado.size / 2)
		# Só as estrelas apagadas; ao tocar, um balão explica como liberar
		%Acertos.visible = false
		%Info.alignment = BoxContainer.ALIGNMENT_CENTER
		%Caixa.custom_minimum_size.y = altura_caixa
	elif progresso["partidas"] == 0:
		%Acertos.text = "Ainda não jogado"
	else:
		%Acertos.text = "Recorde %d/%d · %s pts" % [
			progresso["recorde"], Jogo.PERGUNTAS_POR_PARTIDA, Jogo.formatar(progresso["recorde_pontos"])]
	pressed.connect(_ao_tocar)
	Animacoes.destacar_ao_passar(self)
	_caber_conteudo.call_deferred()


## O cartão (um botão) não cresce sozinho com o conteúdo: se não couber, aumenta
## a altura mínima para a margem de baixo não sumir (telas mais largas).
func _caber_conteudo() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, %Margem.get_combined_minimum_size().y)


func _ao_tocar() -> void:
	if Progresso.nivel_liberado(_indice):
		Jogo.iniciar_nivel(_indice)
	else:
		_mostrar_bloqueado()


## Cadeado balança e aparece um balão sobre o personagem dizendo como liberar.
func _mostrar_bloqueado() -> void:
	var tremida := create_tween()
	for angulo in [0.25, -0.25, 0.15, -0.1, 0.0]:
		tremida.tween_property(_cadeado, "rotation", angulo, 0.06)
	if is_instance_valid(_balao):
		_balao.queue_free()
	var anterior: String = Jogo.niveis[_indice - 1]["nome"].to_upper()  # ex.: "MÉDIO"
	_balao = PanelContainer.new()
	_balao.name = "Balao"
	_balao.theme_type_variation = &"Etiqueta"
	_balao.mouse_filter = MOUSE_FILTER_IGNORE
	var texto := Label.new()
	texto.theme_type_variation = &"SubtituloClaro"
	texto.add_theme_font_size_override("font_size", 28)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.text = "PASSE NO %s\nPARA LIBERAR" % anterior
	_balao.add_child(texto)
	var balao := _balao
	add_child(balao)
	balao.modulate.a = 0.0
	await get_tree().process_frame  # espera o texto ter o tamanho final
	if not is_instance_valid(balao) or balao != _balao:
		return
	balao.reset_size()
	# centro do cartão na horizontal; na altura, meio do personagem
	var meio_personagem: Vector2 = get_global_transform().affine_inverse() * %Personagem.get_global_rect().get_center()
	var centro := Vector2(size.x / 2, meio_personagem.y)
	_balao.position = (centro - _balao.size / 2).round()
	_balao.pivot_offset = _balao.size / 2
	_balao.scale = Vector2.ONE * 0.7
	_balao.modulate.a = 0.0
	var tween := _balao.create_tween()
	tween.set_parallel().tween_property(_balao, "modulate:a", 1.0, 0.15)
	tween.tween_property(_balao, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(1.8)
	tween.chain().tween_property(_balao, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(_balao.queue_free)
