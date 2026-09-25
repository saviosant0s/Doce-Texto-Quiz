extends Control
## Partida: mostra as perguntas do nível, uma por vez, com tempo limite.
## O cronômetro pausa enquanto a caixa "sair?" está aberta ou o app está em
## segundo plano (ex.: o jogador atendeu uma ligação).

const PAUSA_APOS_RESPOSTA := 1.1
const ICONE_SOM := preload("res://assets/icones/som.svg")
const ICONE_SOM_MUDO := preload("res://assets/icones/som_mudo.svg")
const ICONE_CERTO := preload("res://assets/icones/certo.svg")
const ICONE_ERRADO := preload("res://assets/icones/errado.svg")
const ICONE_METADE := preload("res://assets/icones/metade.svg")
const ICONE_RELOGIO_MAIS := preload("res://assets/icones/relogio_mais.svg")
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")

var _perguntas: Array
var _indice := 0
var _tempo_restante := 0.0
var _respondendo := false
var _pausado := false
var _botoes: Array[Button] = []
var _ajuda_eliminar: Button
var _ajuda_tempo: Button
var _saldo: Label
var _usou_eliminar := false
var _usou_tempo := false


func _ready() -> void:
	_perguntas = Jogo.perguntas_partida
	%Som.pressed.connect(_alternar_som)
	%Sair.pressed.connect(_perguntar_se_sai)
	_atualizar_icone_som()
	for i in 4:
		var botao := Button.new()
		botao.theme_type_variation = &"Alternativa"
		botao.custom_minimum_size = Vector2(0, 96)
		botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		botao.pressed.connect(_responder.bind(i))
		Animacoes.destacar_ao_passar(botao, 1.03)
		%Alternativas.add_child(botao)
		_botoes.append(botao)
	_criar_ajudas()
	_mostrar_pergunta()


func _process(delta: float) -> void:
	if not _respondendo or _pausado:
		return
	_tempo_restante = maxf(0.0, _tempo_restante - delta)
	# Atualiza a barra 10x por segundo (e não a cada quadro) para poupar o celular
	if absf(%BarraTempo.value - _tempo_restante) >= 0.1 or _tempo_restante <= 0.0:
		%BarraTempo.value = _tempo_restante
	%Tempo.text = str(ceili(_tempo_restante))
	var acabando := _tempo_restante <= 5.0
	%Tempo.modulate = Cores.VERMELHO if acabando else Color.WHITE
	if _tempo_restante <= 0.0:
		_finalizar_pergunta(-1)  # tempo esgotado conta como erro


func _mostrar_pergunta() -> void:
	var pergunta: Dictionary = _perguntas[_indice]
	%Contador.text = "PERGUNTA %d/%d" % [_indice + 1, _perguntas.size()]
	if Jogo.revisao:
		var nivel: String = Jogo.niveis[pergunta["nivel"]]["nome"].to_upper()
		%Contador.text = "REVISÃO · %s · %d/%d" % [nivel, _indice + 1, _perguntas.size()]
	%Enunciado.text = pergunta["enunciado"]
	for i in _botoes.size():
		var botao := _botoes[i]
		botao.text = pergunta["alternativas"][i]
		botao.icon = null
		botao.disabled = false
		botao.modulate.a = 1.0
		botao.remove_theme_stylebox_override("disabled")
		botao.remove_theme_color_override("font_disabled_color")
		botao.remove_theme_color_override("icon_disabled_color")
	_tempo_restante = Jogo.tempo_por_pergunta()
	%BarraTempo.max_value = Jogo.tempo_por_pergunta()
	_usou_eliminar = false
	_usou_tempo = false
	_respondendo = true
	_atualizar_ajudas()
	_igualar_altura.call_deferred()
	Animacoes.entrar(%CartaoPergunta, Vector2(-30, 0))
	for i in _botoes.size():
		Animacoes.entrar(_botoes[i], Vector2(30, 0), 0.05 * i)


## O cartão da pergunta fica da altura do bloco de alternativas (e não da tela
## toda); se o enunciado for grande, o cartão cresce o quanto precisar.
func _igualar_altura() -> void:
	%CartaoPergunta.custom_minimum_size.y = %Alternativas.get_combined_minimum_size().y


func _responder(escolha: int) -> void:
	if _respondendo and not _pausado:
		_finalizar_pergunta(escolha)


func _notification(aviso: int) -> void:
	# App em segundo plano (celular) ou janela sem foco: pausa o cronômetro
	if aviso == NOTIFICATION_APPLICATION_FOCUS_OUT or aviso == NOTIFICATION_APPLICATION_PAUSED:
		_pausado = true
	elif aviso == NOTIFICATION_APPLICATION_FOCUS_IN or aviso == NOTIFICATION_APPLICATION_RESUMED:
		_pausado = false


## Botão "voltar" do celular: pergunta antes de sair (ver Telas.voltar_pelo_botao).
func ao_voltar() -> void:
	_perguntar_se_sai()


func _perguntar_se_sai() -> void:
	if _pausado:
		return  # já está perguntando (ou o app está em segundo plano)
	_pausado = true
	var sair := await Telas.confirmar(
		"SAIR DA PARTIDA?", "As respostas desta partida não serão salvas.", "SAIR", "CONTINUAR")
	if sair:
		Telas.ir_para("niveis")
	else:
		_pausado = false


func _finalizar_pergunta(escolha: int) -> void:
	_respondendo = false
	var correta: int = _perguntas[_indice]["resposta"]
	var tempo_gasto: float = %BarraTempo.max_value - _tempo_restante
	var acertou := Jogo.registrar_resposta(escolha, tempo_gasto)
	_atualizar_ajudas()
	Audio.tocar("acerto" if acertou else "erro")

	for botao in _botoes:
		botao.disabled = true
	_pintar(_botoes[correta], Cores.VERDE, Cores.VERDE_ESCURO, ICONE_CERTO)
	if escolha >= 0 and not acertou:
		_pintar(_botoes[escolha], Cores.VERMELHO, Cores.VERMELHO_ESCURO, ICONE_ERRADO)
	if acertou:
		_comemorar_pontos(_botoes[correta])

	await get_tree().create_timer(PAUSA_APOS_RESPOSTA).timeout
	_indice += 1
	if _indice < _perguntas.size():
		_mostrar_pergunta()
	else:
		Jogo.finalizar_partida()
		Telas.ir_para("aproveitamento")


# --- Ajudas -----------------------------------------------------------------

func _criar_ajudas() -> void:
	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 14)
	%Lateral.add_child(espaco)
	_ajuda_eliminar = _criar_botao_ajuda(ICONE_METADE, Jogo.CUSTO_ELIMINAR, "Eliminar 2 alternativas erradas")
	_ajuda_eliminar.pressed.connect(_eliminar_alternativas)
	_ajuda_tempo = _criar_botao_ajuda(ICONE_RELOGIO_MAIS, Jogo.CUSTO_MAIS_TEMPO, "+%d segundos" % Jogo.SEGUNDOS_EXTRAS)
	_ajuda_tempo.pressed.connect(_ganhar_tempo)
	var titulo := Label.new()
	titulo.theme_type_variation = &"TextoClaro"
	titulo.add_theme_font_size_override("font_size", 14)
	titulo.text = "VOCÊ TEM"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%Lateral.add_child(titulo)
	var saldo := _valor_em_moedas("0", 22, 26)
	_saldo = saldo.get_child(1)
	%Lateral.add_child(saldo)


## "(moeda) 30": ícone de moeda seguido do número.
func _valor_em_moedas(texto: String, tamanho_icone: int, tamanho_texto: int) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 3)
	var icone := TextureRect.new()
	icone.texture = ICONE_MOEDA
	icone.modulate = Cores.AMARELO
	icone.custom_minimum_size = Vector2(tamanho_icone, tamanho_icone)
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(icone)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho_texto)
	rotulo.text = texto
	linha.add_child(rotulo)
	return linha


func _criar_botao_ajuda(icone: Texture2D, custo: int, dica: String) -> Button:
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 0)
	var botao := Button.new()
	botao.theme_type_variation = &"BotaoIconeAmarelo"
	botao.custom_minimum_size = Vector2(68, 68)
	botao.icon = icone
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.expand_icon = true
	botao.tooltip_text = "%s (%d moedas)" % [dica, custo]
	coluna.add_child(botao)
	coluna.add_child(_valor_em_moedas(str(custo), 18, 20))
	%Lateral.add_child(coluna)
	return botao


func _atualizar_ajudas() -> void:
	var moedas := Progresso.moedas
	_saldo.text = Jogo.formatar(moedas)
	var gratis := Jogo.eliminar_gratis()
	_ajuda_eliminar.disabled = not _respondendo or _usou_eliminar or (moedas < Jogo.CUSTO_ELIMINAR and not gratis)
	# com ajuda grátis do companheiro, o preço vira "GRÁTIS"
	var preco: Label = _ajuda_eliminar.get_parent().find_children("*", "Label", true, false)[0]
	preco.text = "GRÁTIS" if gratis else str(Jogo.CUSTO_ELIMINAR)
	_ajuda_tempo.disabled = not _respondendo or _usou_tempo or moedas < Jogo.CUSTO_MAIS_TEMPO


func _eliminar_alternativas() -> void:
	if not _respondendo or _pausado or not Jogo.usar_ajuda(Jogo.CUSTO_ELIMINAR):
		return
	_usou_eliminar = true
	for indice in Jogo.alternativas_para_eliminar():
		var botao := _botoes[indice]
		botao.disabled = true
		botao.create_tween().tween_property(botao, "modulate:a", 0.25, 0.3)
	_atualizar_ajudas()


func _ganhar_tempo() -> void:
	if not _respondendo or _pausado or not Jogo.usar_ajuda(Jogo.CUSTO_MAIS_TEMPO):
		return
	_usou_tempo = true
	_tempo_restante += Jogo.SEGUNDOS_EXTRAS
	%BarraTempo.max_value = maxf(%BarraTempo.max_value, _tempo_restante)
	%BarraTempo.value = _tempo_restante
	_atualizar_ajudas()


## Atualiza o placar e mostra "+pontos" (e o combo) saindo da alternativa certa.
func _comemorar_pontos(botao: Button) -> void:
	var ganho: Dictionary = Jogo.ultimo_ganho
	var placar := create_tween()
	placar.tween_method(func(v: int): %Pontos.text = "%s PONTOS" % Jogo.formatar(v),
		Jogo.pontos - ganho["pontos"], Jogo.pontos, 0.5)
	var texto := "+%d" % ganho["pontos"]
	if ganho["multiplicador"] > 1.0:
		texto += "   COMBO x%s!" % str(ganho["multiplicador"]).replace(".", ",").trim_suffix(",0")
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 48)
	rotulo.add_theme_color_override("font_outline_color", Cores.ROXO_ESCURO)
	rotulo.add_theme_constant_override("outline_size", 12)
	rotulo.text = texto
	add_child(rotulo)
	rotulo.global_position = botao.global_position + Vector2(botao.size.x * 0.5 - 60, -10)
	var tween := create_tween().set_parallel()
	tween.tween_property(rotulo, "position:y", rotulo.position.y - 70, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(rotulo, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tween.chain().tween_callback(rotulo.queue_free)


## Destaca uma alternativa (verde = correta, vermelho = escolha errada).
func _pintar(botao: Button, cor: Color, cor_borda: Color, icone: Texture2D) -> void:
	var estilo: StyleBoxFlat = botao.get_theme_stylebox("normal").duplicate()
	estilo.bg_color = cor
	estilo.border_color = cor_borda
	botao.add_theme_stylebox_override("disabled", estilo)
	botao.add_theme_color_override("font_disabled_color", Color.WHITE)
	botao.add_theme_color_override("icon_disabled_color", Color.WHITE)
	botao.icon = icone


func _alternar_som() -> void:
	Audio.alternar_musica()
	_atualizar_icone_som()


func _atualizar_icone_som() -> void:
	%Som.icon = ICONE_SOM if Audio.musica_ligada() else ICONE_SOM_MUDO
