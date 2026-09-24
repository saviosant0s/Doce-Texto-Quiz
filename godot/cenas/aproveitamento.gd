extends Control
## Mostra o aproveitamento da partida e o resultado de cada pergunta.

const ICONE_CERTO := preload("res://assets/icones/certo.svg")
const ICONE_ERRADO := preload("res://assets/icones/errado.svg")


func _ready() -> void:
	var acertos := Jogo.resultados.count(true)
	%Acertos.text = "%d DE %d ACERTOS" % [acertos, Jogo.resultados.size()]
	%Continuar.pressed.connect(Jogo.ir_para.bind("resultado"))
	_contar_porcentagem(Jogo.aproveitamento())
	for i in Jogo.resultados.size():
		var item := _criar_item(i, Jogo.resultados[i])
		%Lista.add_child(item)
		Animacoes.entrar(item, Vector2(20, 0), 0.05 * i)


## Anima o número subindo de 0 até o aproveitamento.
func _contar_porcentagem(valor: int) -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float): %Porcentagem.text = "%d%%" % roundi(v), 0.0, float(valor), 0.9)


func _criar_item(indice: int, acertou: bool) -> PanelContainer:
	var item := PanelContainer.new()
	item.theme_type_variation = &"PainelRoxo"
	item.custom_minimum_size = Vector2(250, 0)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var linha := HBoxContainer.new()
	item.add_child(linha)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", 28)
	rotulo.text = "QUESTÃO %02d" % (indice + 1)
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	var icone := TextureRect.new()
	icone.texture = ICONE_CERTO if acertou else ICONE_ERRADO
	icone.modulate = Cores.VERDE if acertou else Cores.VERMELHO
	icone.custom_minimum_size = Vector2(32, 32)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(icone)
	return item
