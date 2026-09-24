extends Control
## Sobre o projeto: o que é, números, quem fez e redes sociais.

const SECOES := [
	["O QUE É", "Um quiz lúdico e interativo para testar o que você sabe sobre editores de texto e planilhas, como o Word e o Excel."],
	["PARA QUE SERVE", "Uma forma divertida e pedagógica de avaliar o aprendizado das principais funções desses programas."],
	["QUEM FEZ", "Alunos do 1º ano de Informática do IFBA Campus Valença, com orientação de professores do campus."],
]
const NUMEROS := [
	["2023", "CRIADO EM"],
	["3", "NÍVEIS"],
	["60", "PERGUNTAS"],
	["30S", "POR QUESTÃO"],
]
## Perfis do Instagram (ver PENDENCIAS.md: confirmar/atualizar os @).
const PERFIS := ["xz_.nataa", "savio.sant0s", "thaly_gilmore", "ifba.valenca"]
const ICONE_INSTAGRAM := preload("res://assets/icones/instagram.svg")
const NUNITO := preload("res://assets/fontes/Nunito.ttf")


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	%Jogar.pressed.connect(Jogo.ir_para.bind("niveis"))
	for secao in SECOES:
		%Secoes.add_child(_criar_secao(secao[0], secao[1]))
	# Dois blocos por linha, todos com a mesma largura
	for i in range(0, NUMEROS.size(), 2):
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 14)
		%Numeros.add_child(linha)
		for numero in NUMEROS.slice(i, i + 2):
			linha.add_child(_criar_numero(numero[0], numero[1]))
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
	Animacoes.flutuar(%Mascote)


func _criar_numero(valor: String, legenda: String) -> PanelContainer:
	var caixa := PanelContainer.new()
	caixa.theme_type_variation = &"PainelRoxo"
	caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caixa.custom_minimum_size = Vector2(0, 130)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", -2)
	caixa.add_child(coluna)
	var numero := Label.new()
	numero.theme_type_variation = &"Numero"
	numero.add_theme_font_size_override("font_size", 64)
	numero.text = valor
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(numero)
	var texto := Label.new()
	texto.theme_type_variation = &"TextoClaro"
	texto.add_theme_font_size_override("font_size", 17)
	texto.text = legenda
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # não força a largura do bloco
	texto.custom_minimum_size = Vector2(60, 0)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(texto)
	return caixa


func _criar_secao(titulo: String, texto: String) -> VBoxContainer:
	var secao := VBoxContainer.new()
	secao.add_theme_constant_override("separation", 4)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Subtitulo"
	rotulo.add_theme_font_size_override("font_size", 34)
	rotulo.text = titulo
	secao.add_child(rotulo)
	var corpo := Label.new()
	corpo.theme_type_variation = &"Texto"
	corpo.add_theme_font_size_override("font_size", 21)
	corpo.text = texto
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo.custom_minimum_size = Vector2(200, 0)
	secao.add_child(corpo)
	return secao
