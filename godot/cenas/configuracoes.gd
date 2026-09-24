extends Control
## Configurações: volume da música e dos efeitos, animações e apagar progresso.

const ICONE_SOM := preload("res://assets/icones/som.svg")
const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")


func _ready() -> void:
	%Voltar.pressed.connect(_voltar)
	%Versao.text = Telas.versao()
	%Apagar.pressed.connect(_apagar_progresso)
	_criar_volume("MÚSICA", "volume_musica", false)
	_criar_volume("EFEITOS SONOROS", "volume_efeitos", true)
	_criar_chave_animacoes()
	_atualizar_resumo()
	Animacoes.entrar(%Coluna, Vector2(0, 30))


## Linha com nome, controle deslizante (0 a 100%) e o valor atual.
func _criar_volume(nome: String, chave: String, tocar_exemplo: bool) -> void:
	var linha := VBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	var topo := HBoxContainer.new()
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Texto"
	rotulo.text = nome
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var valor := Label.new()
	valor.theme_type_variation = &"Subtitulo"
	topo.add_child(rotulo)
	topo.add_child(valor)
	linha.add_child(topo)

	var controle := HSlider.new()
	controle.min_value = 0
	controle.max_value = 100
	controle.step = 5
	controle.custom_minimum_size = Vector2(0, 40)
	controle.value = roundf(Progresso.config.get(chave, 1.0) * 100)
	valor.text = "%d%%" % controle.value
	controle.value_changed.connect(func(v: float):
		Progresso.config[chave] = v / 100.0
		valor.text = "%d%%" % v
		Audio.aplicar_volumes())
	controle.drag_ended.connect(func(_mudou):
		Progresso.salvar()
		if tocar_exemplo:
			Audio.tocar("acerto"))
	linha.add_child(controle)
	%Linhas.add_child(linha)


func _criar_chave_animacoes() -> void:
	var chave := CheckButton.new()
	chave.text = "Animações de fundo (mascote, estrelas, confete)"
	chave.button_pressed = Progresso.config.get("animacoes", true)
	chave.toggled.connect(func(ligado: bool):
		Progresso.config["animacoes"] = ligado
		Progresso.salvar())
	%Linhas.add_child(chave)
	if not Telas.placa_rapida:
		var aviso := Label.new()
		aviso.theme_type_variation = &"Texto"
		aviso.add_theme_font_size_override("font_size", 17)
		aviso.text = "Este aparelho está sem aceleração de vídeo, então as animações ficam desligadas para o jogo não travar."
		aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		aviso.custom_minimum_size = Vector2(200, 0)
		%Linhas.add_child(aviso)
		chave.disabled = true


func _atualizar_resumo() -> void:
	var estrelas := 0
	for nivel in Progresso.niveis:
		estrelas += nivel["estrelas"]
	var titulos := 0
	for quantidade in Progresso.titulos.values():
		titulos += int(quantidade > 0)
	%Resumo.text = "%d partidas jogadas\n%d de 9 estrelas\n%d de 3 títulos\n%d moedas" % [
		Progresso.estatisticas["partidas"], estrelas, titulos, Progresso.moedas]


func _apagar_progresso() -> void:
	var apagar := await Telas.confirmar(
		"APAGAR TODO O PROGRESSO?",
		"Estrelas, recordes, títulos, moedas e o histórico das perguntas serão apagados. Isso não pode ser desfeito.",
		"APAGAR", "CANCELAR")
	if apagar:
		Progresso.apagar()
		_atualizar_resumo()
		Telas.mostrar_aviso("PROGRESSO APAGADO")


func _voltar() -> void:
	Progresso.salvar()
	Telas.voltar()
