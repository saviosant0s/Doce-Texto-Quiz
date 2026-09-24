extends Control
## Regras do jogo.

const REGRAS := [
	"Você terá 30 segundos para escolher uma alternativa",
	"Se o tempo acabar, a questão é registrada como erro",
	"Ao terminar todas as perguntas, você verá seu aproveitamento",
	"Seu aproveitamento dirá em qual nível de doceiro você se encaixa",
]


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	for regra in REGRAS:
		var caixa := PanelContainer.new()
		caixa.theme_type_variation = &"PainelRoxo"
		caixa.custom_minimum_size = Vector2(400, 116)
		var texto := Label.new()
		texto.theme_type_variation = &"SubtituloClaro"
		texto.add_theme_font_size_override("font_size", 32)
		texto.text = regra.to_upper()
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caixa.add_child(texto)
		%Regras.add_child(caixa)
	Animacoes.entrar(%Painel)
