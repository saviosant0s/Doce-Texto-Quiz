class_name Dialogo
extends Control
## Caixa de conversa com os moradores (histórias da vila): nome do morador,
## a fala e os botões. Tudo assíncrono:
##   await dialogo.falar("SEU MILHO", ["Oi!", "Tudo bem?"])
##   var acertou: bool = await dialogo.perguntar("DONA BALA", pergunta)
##   var sim: bool = await dialogo.escolher("DONA BALA", "Me dá 50 de açúcar?", "DAR", "AGORA NÃO")
## Enquanto aberta, segura os toques (a vila embaixo não recebe).

signal _respondeu(indice: int)

var _nome: Label
var _texto: Label
var _botoes: HFlowContainer
## Aberta agora (a vila não mexe no doce nem abre outra conversa).
var aberto := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var fundo := ColorRect.new()
	fundo.color = Color(0.08, 0.04, 0.16, 0.35)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margem.grow_vertical = Control.GROW_DIRECTION_BEGIN
	for lado in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, 120)
	margem.add_theme_constant_override("margin_bottom", 26)
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", -8)
	margem.add_child(coluna)
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"EtiquetaAmarela"
	etiqueta.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	etiqueta.z_index = 1
	_nome = Label.new()
	_nome.name = "NomeMorador"
	_nome.theme_type_variation = &"Titulo"
	_nome.add_theme_font_size_override("font_size", 30)
	etiqueta.add_child(_nome)
	coluna.add_child(etiqueta)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	coluna.add_child(painel)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 14)
	painel.add_child(dentro)
	_texto = Label.new()
	_texto.name = "Fala"
	_texto.theme_type_variation = &"SubtituloClaro"
	_texto.add_theme_font_size_override("font_size", 28)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(600, 70)
	dentro.add_child(_texto)
	_botoes = HFlowContainer.new()
	_botoes.name = "Botoes"
	_botoes.alignment = FlowContainer.ALIGNMENT_END
	_botoes.add_theme_constant_override("h_separation", 10)
	_botoes.add_theme_constant_override("v_separation", 10)
	dentro.add_child(_botoes)


## Mostra as falas uma por uma (CONTINUAR entre elas).
func falar(nome: String, falas: Array) -> void:
	for fala in falas:
		await _mostrar(nome, str(fala), ["CONTINUAR"])
	_fechar()


## Pergunta do quiz ({"enunciado", "alternativas", "resposta"}). Retorna se acertou.
func perguntar(nome: String, pergunta: Dictionary) -> bool:
	var escolha: int = await _mostrar(nome, str(pergunta["enunciado"]), pergunta["alternativas"])
	var acertou := escolha == int(pergunta["resposta"])
	Audio.tocar("acerto" if acertou else "erro")
	var retorno := "ACERTOU! " if acertou else "Ops! A resposta era: %s. " % pergunta["alternativas"][int(pergunta["resposta"])]
	await _mostrar(nome, retorno + str(pergunta.get("explicacao", "")), ["CONTINUAR"])
	_fechar()
	return acertou


## Duas opções. Retorna true na primeira.
func escolher(nome: String, texto: String, sim: String, nao: String) -> bool:
	var escolha: int = await _mostrar(nome, texto, [sim, nao])
	_fechar()
	return escolha == 0


func _mostrar(nome: String, texto: String, opcoes: Array) -> int:
	aberto = true
	visible = true
	_nome.text = nome
	_texto.text = texto
	for b in _botoes.get_children():
		_botoes.remove_child(b)
		b.queue_free()
	for i in opcoes.size():
		var b := Button.new()
		b.name = "Opcao%d" % i
		b.text = str(opcoes[i])
		b.custom_minimum_size = Vector2(220, 62)
		b.add_theme_font_size_override("font_size", 22)
		b.focus_mode = Control.FOCUS_NONE
		# CONTINUAR e o "sim" em destaque; alternativas de pergunta todas iguais
		if opcoes.size() == 1 or (opcoes.size() == 2 and i == 0):
			b.theme_type_variation = &"Button"
		elif opcoes.size() == 2:
			b.theme_type_variation = &"BotaoSecundario"  # "agora não"
		else:
			b.theme_type_variation = &"Alternativa"  # respostas do quiz
		b.pressed.connect(func(): _respondeu.emit(i))
		_botoes.add_child(b)
	return await _respondeu


func _fechar() -> void:
	aberto = false
	visible = false


## Para os testes: aperta a opção `indice` da caixa aberta.
func responder(indice := 0) -> void:
	_respondeu.emit(indice)
