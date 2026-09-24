extends Control
## Sobre o projeto: o que é, números, quem fez e redes sociais.

const NUMEROS := [
	["2023", "CRIADO EM"],
	["3", "NÍVEIS"],
	["10", "QUESTÕES POR NÍVEL"],
	["30S", "POR QUESTÃO"],
]
## Perfis do Instagram (ver PENDENCIAS.md: confirmar/atualizar os @).
const PERFIS := ["xz_.nataa", "savio.sant0s", "thaly_gilmore", "ifba.valenca"]
const ICONE_INSTAGRAM := preload("res://assets/icones/instagram.svg")
const NUNITO := preload("res://assets/fontes/Nunito.ttf")


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	for numero in NUMEROS:
		%Numeros.add_child(_criar_numero(numero[0], numero[1]))
	var fonte_perfil := FontVariation.new()
	fonte_perfil.base_font = NUNITO
	fonte_perfil.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
	for perfil in PERFIS:
		var botao := Button.new()
		botao.theme_type_variation = &"BotaoRoxo"
		botao.text = "@" + perfil
		botao.icon = ICONE_INSTAGRAM
		botao.expand_icon = true
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.custom_minimum_size = Vector2(0, 58)
		botao.add_theme_font_override("font", fonte_perfil)
		botao.add_theme_font_size_override("font_size", 21)
		botao.add_theme_constant_override("icon_max_width", 30)
		botao.pressed.connect(OS.shell_open.bind("https://instagram.com/" + perfil))
		%Perfis.add_child(botao)
	Animacoes.entrar(%Coluna, Vector2(0, 30))
	Animacoes.flutuar(%Mascote, 6.0)


func _criar_numero(valor: String, legenda: String) -> PanelContainer:
	var caixa := PanelContainer.new()
	caixa.theme_type_variation = &"PainelRoxo"
	caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", -4)
	caixa.add_child(coluna)
	var numero := Label.new()
	numero.theme_type_variation = &"Numero"
	numero.add_theme_font_size_override("font_size", 44)
	numero.text = valor
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(numero)
	var texto := Label.new()
	texto.theme_type_variation = &"TextoClaro"
	texto.add_theme_font_size_override("font_size", 16)
	texto.text = legenda
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(texto)
	return caixa
