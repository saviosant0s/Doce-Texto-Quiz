extends Control
## Créditos: equipe de desenvolvimento, orientadores e instituição.

const DESENVOLVIMENTO := ["Talita Argolo", "Sávio Santos", "Natalí Rocha"]
const ORIENTACAO := ["Eduardo Cambruzzi", "Peterson Lobato", "Alba Rogéria", "Nelson Valente", "Cristian Lins"]
const CORES_AVATAR := [Cores.ROSA, Cores.AZUL, Cores.VERDE, Cores.VERMELHO, Cores.ROXO]


func _ready() -> void:
	%Voltar.pressed.connect(Jogo.voltar)
	%Sobre.pressed.connect(Jogo.abrir.bind("sobre"))
	%Apoie.pressed.connect(Jogo.mostrar_aviso.bind("DISPONÍVEL EM BREVE"))
	for i in DESENVOLVIMENTO.size():
		$Margem/Coluna/Grupos/Equipe/Coluna/Pessoas.add_child(_criar_pessoa(DESENVOLVIMENTO[i], CORES_AVATAR[i], 36))
	var grade: GridContainer = $Margem/Coluna/Grupos/Orientacao/Coluna/Pessoas
	for i in ORIENTACAO.size():
		grade.add_child(_criar_pessoa(ORIENTACAO[i], CORES_AVATAR[(i + 3) % CORES_AVATAR.size()], 28))
	Animacoes.entrar(%Coluna, Vector2(0, 30))


## Linha com um círculo colorido com as iniciais e o nome.
func _criar_pessoa(nome: String, cor: Color, tamanho_nome: int) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_theme_constant_override("separation", 12)
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(52, 52)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(999)
	avatar.add_theme_stylebox_override("panel", estilo)
	var iniciais := Label.new()
	iniciais.theme_type_variation = &"Subtitulo"
	iniciais.add_theme_color_override("font_color", Color.WHITE)
	iniciais.add_theme_font_size_override("font_size", 26)
	var partes := nome.split(" ")
	iniciais.text = (partes[0][0] + partes[-1][0]).to_upper()
	iniciais.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	iniciais.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(iniciais)
	linha.add_child(avatar)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Subtitulo"
	rotulo.add_theme_font_size_override("font_size", tamanho_nome)
	rotulo.text = nome.to_upper()
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(rotulo)
	return linha
