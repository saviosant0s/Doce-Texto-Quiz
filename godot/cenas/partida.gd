extends Control
## Partida: mostra as perguntas do nível, uma por vez, com tempo limite.
## O cronômetro pausa enquanto a caixa "sair?" está aberta ou o app está em
## segundo plano (ex.: o jogador atendeu uma ligação).

const PAUSA_APOS_RESPOSTA := 1.1
const ICONE_SOM := preload("res://assets/icones/som.svg")
const ICONE_SOM_MUDO := preload("res://assets/icones/som_mudo.svg")
const ICONE_CERTO := preload("res://assets/icones/certo.svg")
const ICONE_ERRADO := preload("res://assets/icones/errado.svg")

var _perguntas: Array
var _indice := 0
var _tempo_restante := 0.0
var _respondendo := false
var _pausado := false
var _botoes: Array[Button] = []


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
	%Enunciado.text = pergunta["enunciado"]
	for i in _botoes.size():
		var botao := _botoes[i]
		botao.text = pergunta["alternativas"][i]
		botao.icon = null
		botao.disabled = false
		botao.remove_theme_stylebox_override("disabled")
		botao.remove_theme_color_override("font_disabled_color")
		botao.remove_theme_color_override("icon_disabled_color")
	_tempo_restante = Jogo.TEMPO_POR_PERGUNTA
	%BarraTempo.max_value = Jogo.TEMPO_POR_PERGUNTA
	_respondendo = true
	Animacoes.entrar(%CartaoPergunta, Vector2(-30, 0))
	for i in _botoes.size():
		Animacoes.entrar(_botoes[i], Vector2(30, 0), 0.05 * i)


func _responder(escolha: int) -> void:
	if _respondendo and not _pausado:
		_finalizar_pergunta(escolha)


func _notification(aviso: int) -> void:
	# App em segundo plano (celular) ou janela sem foco: pausa o cronômetro
	if aviso == NOTIFICATION_APPLICATION_FOCUS_OUT or aviso == NOTIFICATION_APPLICATION_PAUSED:
		_pausado = true
	elif aviso == NOTIFICATION_APPLICATION_FOCUS_IN or aviso == NOTIFICATION_APPLICATION_RESUMED:
		_pausado = false


func _perguntar_se_sai() -> void:
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
	var acertou := Jogo.registrar_resposta(escolha, Jogo.TEMPO_POR_PERGUNTA - _tempo_restante)
	Audio.tocar("acerto" if acertou else "erro")

	for botao in _botoes:
		botao.disabled = true
	_pintar(_botoes[correta], Cores.VERDE, Cores.VERDE_ESCURO, ICONE_CERTO)
	if escolha >= 0 and not acertou:
		_pintar(_botoes[escolha], Cores.VERMELHO, Cores.VERMELHO_ESCURO, ICONE_ERRADO)

	await get_tree().create_timer(PAUSA_APOS_RESPOSTA).timeout
	_indice += 1
	if _indice < _perguntas.size():
		_mostrar_pergunta()
	else:
		Jogo.finalizar_partida()
		Telas.ir_para("aproveitamento")


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
