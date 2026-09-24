extends Control
## Aproveitamento da partida e revisão de cada pergunta (sua resposta x resposta certa).

const ICONE_CERTO := preload("res://assets/icones/certo.svg")
const ICONE_ERRADO := preload("res://assets/icones/errado.svg")
const ICONE_RELOGIO := preload("res://assets/icones/relogio.svg")


func _ready() -> void:
	var acertos := Jogo.resultados.count(true)
	%Acertos.text = "%d DE %d ACERTOS" % [acertos, Jogo.resultados.size()]
	%Continuar.pressed.connect(Jogo.ir_para.bind("resultado"))
	for acertou in Jogo.resultados:
		%Bolinhas.add_child(_criar_bolinha(acertou))
	var perguntas := Jogo.perguntas_do_nivel()
	for i in Jogo.resultados.size():
		var escolha: int = Jogo.respostas[i] if i < Jogo.respostas.size() else -1
		var item := _criar_revisao(i, perguntas[i], escolha, Jogo.resultados[i])
		%Lista.add_child(item)
		Animacoes.entrar(item, Vector2(30, 0), 0.05 * i)
	_animar_anel(Jogo.aproveitamento())


## Enche o anel e conta a porcentagem de 0 até o valor final.
func _animar_anel(valor: int) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float):
		%Anel.valor = v
		%Porcentagem.text = "%d%%" % roundi(v), 0.0, float(valor), 1.2)


func _criar_bolinha(acertou: bool) -> Panel:
	var bolinha := Panel.new()
	bolinha.custom_minimum_size = Vector2(22, 22)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Cores.VERDE if acertou else Cores.VERMELHO
	estilo.set_corner_radius_all(999)
	estilo.border_color = Cores.CREME
	estilo.set_border_width_all(2)
	bolinha.add_theme_stylebox_override("panel", estilo)
	return bolinha


## Cartão de revisão: número, enunciado, sua resposta e (se errou) a certa.
func _criar_revisao(indice: int, pergunta: Dictionary, escolha: int, acertou: bool) -> PanelContainer:
	var cor := Cores.VERDE if acertou else Cores.VERMELHO
	var cartao := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Cores.CREME
	estilo.set_corner_radius_all(16)
	estilo.set_content_margin_all(12)
	estilo.border_width_left = 8
	estilo.border_color = cor
	cartao.add_theme_stylebox_override("panel", estilo)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	cartao.add_child(linha)

	var numero := Label.new()
	numero.theme_type_variation = &"Subtitulo"
	numero.add_theme_font_size_override("font_size", 38)
	numero.add_theme_color_override("font_color", cor)
	numero.text = "%02d" % (indice + 1)
	numero.custom_minimum_size = Vector2(44, 0)
	linha.add_child(numero)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 4)
	linha.add_child(textos)

	var enunciado := Label.new()
	enunciado.theme_type_variation = &"Texto"
	enunciado.add_theme_font_size_override("font_size", 19)
	enunciado.text = pergunta["enunciado"]
	enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enunciado.custom_minimum_size = Vector2(150, 0)
	textos.add_child(enunciado)

	var correta: String = pergunta["alternativas"][int(pergunta["resposta"])]
	if acertou:
		textos.add_child(_resposta(ICONE_CERTO, "Você respondeu: " + correta, Cores.VERDE_ESCURO))
	else:
		if escolha < 0:
			textos.add_child(_resposta(ICONE_RELOGIO, "Tempo esgotado", Cores.VERMELHO_ESCURO))
		else:
			textos.add_child(_resposta(ICONE_ERRADO, "Você respondeu: " + pergunta["alternativas"][escolha], Cores.VERMELHO_ESCURO))
		textos.add_child(_resposta(ICONE_CERTO, "Resposta certa: " + correta, Cores.VERDE_ESCURO))
	return cartao


func _resposta(icone: Texture2D, texto: String, cor: Color) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	var imagem := TextureRect.new()
	imagem.texture = icone
	imagem.modulate = cor
	imagem.custom_minimum_size = Vector2(20, 20)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(imagem)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Texto"
	rotulo.add_theme_font_size_override("font_size", 18)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	return linha
