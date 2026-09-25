extends Control
## Troféus, em três abas:
## - TÍTULOS: pódio com Mestre no centro, Pro e Noob dos lados. Cada título é
##   ganho ao passar no nível correspondente (ver Jogo.TITULOS).
## - CONQUISTAS: metas especiais com recompensa em moedas (ver Conquistas).
## - ESTATÍSTICAS: números gerais, por nível, por assunto e as mais erradas.

const ICONE_CADEADO := preload("res://assets/icones/cadeado.svg")
const ICONE_ESTRELA := preload("res://assets/icones/estrela.svg")
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")
const ABAS := ["TÍTULOS", "CONQUISTAS", "ESTATÍSTICAS"]
const NOMES_ASSUNTOS := {"word": "WORD (TEXTOS)", "excel": "EXCEL (PLANILHAS)", "geral": "OFFICE EM GERAL"}

var _botoes_abas: Array[Button] = []
var _paginas: Array[Control] = []
var _fonte_texto: FontVariation

## Na ordem em que aparecem no pódio (da esquerda para a direita).
const TITULOS := [
	{"id": "pro", "nome": "PRO", "personagem": "cupcake_pro", "meta": "PASSE NO NÍVEL MÉDIO",
		"altura": 150, "tamanho": 230, "cor": Color("#E4DCF2")},
	{"id": "mestre", "nome": "MESTRE", "personagem": "chocolate_mestre", "meta": "PASSE NO NÍVEL DIFÍCIL",
		"altura": 210, "tamanho": 270, "cor": Cores.AMARELO},
	{"id": "noob", "nome": "NOOB", "personagem": "maca_noob", "meta": "PASSE NO NÍVEL FÁCIL",
		"altura": 105, "tamanho": 210, "cor": Color("#F1B874")},
]


func _ready() -> void:
	%Voltar.pressed.connect(Telas.voltar)
	%Quantidade.text = "%s MOEDAS" % Jogo.formatar(Progresso.moedas)
	%Titulo.text = "TROFÉUS"
	_fonte_texto = FontVariation.new()
	_fonte_texto.base_font = preload("res://assets/fontes/Nunito.ttf")
	_fonte_texto.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	_criar_abas()
	_paginas = [%Podio, _criar_pagina_conquistas(), _criar_pagina_estatisticas()]
	for pagina in _paginas.slice(1):
		%Podio.get_parent().add_child(pagina)
		var rolagem: ScrollContainer = pagina if pagina is ScrollContainer \
			else pagina.find_children("*", "ScrollContainer", true, false)[0]
		Interface.deixar_rolar(rolagem.get_child(0))
	mostrar_aba(0)


## Mostra a aba `indice` (0 = títulos, 1 = conquistas, 2 = estatísticas).
func mostrar_aba(indice: int) -> void:
	for i in _paginas.size():
		_paginas[i].visible = i == indice
		_botoes_abas[i].theme_type_variation = &"Button" if i == indice else &"BotaoRoxo"
	if indice == 0:
		for i in %Podio.get_child_count():
			%Podio.get_child(i).queue_free()
		for i in TITULOS.size():
			var coluna := _criar_coluna(TITULOS[i])
			%Podio.add_child(coluna)
			Animacoes.entrar(coluna, Vector2(0, 80), 0.1 * i)
	else:
		Animacoes.entrar(_paginas[indice], Vector2(0, 30))


func _criar_abas() -> void:
	var abas := HBoxContainer.new()
	abas.add_theme_constant_override("separation", 8)
	abas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in ABAS.size():
		var botao := Button.new()
		botao.name = "Aba%d" % i
		botao.text = ABAS[i]
		botao.custom_minimum_size = Vector2(0, 60)
		botao.add_theme_font_size_override("font_size", 30)
		botao.pressed.connect(mostrar_aba.bind(i))
		abas.add_child(botao)
		_botoes_abas.append(botao)
	var topo: Control = %Titulo.get_parent().get_parent()
	topo.add_child(abas)
	topo.move_child(abas, %Titulo.get_parent().get_index() + 1)


# --- Conquistas --------------------------------------------------------------

func _criar_pagina_conquistas() -> Control:
	var pagina := VBoxContainer.new()
	pagina.name = "Conquistas"
	pagina.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pagina.add_theme_constant_override("separation", 8)
	var resumo := Label.new()
	resumo.theme_type_variation = &"SubtituloClaro"
	resumo.add_theme_font_size_override("font_size", 28)
	resumo.text = "%d DE %d CONQUISTAS DESBLOQUEADAS" % [Conquistas.quantidade_desbloqueada(), Conquistas.LISTA.size()]
	pagina.add_child(resumo)
	var rolagem := _rolagem()
	pagina.add_child(rolagem)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 12)
	rolagem.add_child(_com_margem(grade))
	for conquista in Conquistas.LISTA:
		grade.add_child(_criar_cartao_conquista(conquista))
	return pagina


func _criar_cartao_conquista(conquista: Dictionary) -> PanelContainer:
	var data: String = Progresso.conquistas.get(conquista["id"], "")
	var desbloqueada := not data.is_empty()
	var cartao := _cartao(Cores.CREME if desbloqueada else Color(Cores.ROXO_ESCURO, 0.55))
	cartao.name = conquista["id"]
	cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	cartao.add_child(linha)

	var circulo := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Cores.AMARELO if desbloqueada else Color(1, 1, 1, 0.12)
	estilo.set_corner_radius_all(999)
	estilo.set_content_margin_all(12)
	circulo.add_theme_stylebox_override("panel", estilo)
	circulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(circulo)
	circulo.add_child(_icone(Conquistas.icone(conquista) if desbloqueada else ICONE_CADEADO,
		Cores.ROXO if desbloqueada else Color(1, 1, 1, 0.5), 40))

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	linha.add_child(textos)
	var nome := Label.new()
	nome.theme_type_variation = &"Titulo" if desbloqueada else &"TituloClaro"
	nome.add_theme_font_size_override("font_size", 32)
	nome.text = conquista["nome"]
	textos.add_child(nome)
	var descricao := _texto(conquista["descricao"], 18, Cores.ROXO_ESCURO if desbloqueada else Color(1, 1, 1, 0.8))
	textos.add_child(descricao)
	if desbloqueada:
		textos.add_child(_texto("Conquistada em " + _data(data), 15, Color(Cores.ROXO_ESCURO, 0.65)))

	var premio := _valor_em_moedas("+%d" % conquista["moedas"], Cores.ROXO if desbloqueada else Cores.AMARELO)
	premio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(premio)
	if not desbloqueada:
		premio.modulate.a = 0.8
	return cartao


## "2026-09-24" -> "24/09/2026".
func _data(iso: String) -> String:
	var partes := iso.split("-")
	return "%s/%s/%s" % [partes[2], partes[1], partes[0]] if partes.size() == 3 else iso


# --- Estatísticas ------------------------------------------------------------

func _criar_pagina_estatisticas() -> Control:
	var rolagem := _rolagem()
	rolagem.name = "Estatisticas"
	var colunas := HBoxContainer.new()
	colunas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colunas.add_theme_constant_override("separation", 16)
	rolagem.add_child(_com_margem(colunas))

	var e := Progresso.estatisticas
	var respostas: int = e["respostas"]
	var geral := _secao_estatisticas("GERAL", colunas)
	geral.size_flags_stretch_ratio = 0.8
	var taxa := "-" if respostas == 0 else "%d%%" % roundi(100.0 * e["acertos"] / respostas)
	var tempo_medio := "-" if respostas == 0 else ("%.1f s" % (e["tempo_total"] / respostas)).replace(".", ",")
	for item in [
		["Partidas jogadas", Jogo.formatar(e["partidas"])],
		["Revisões feitas", Jogo.formatar(e["revisoes"])],
		["Perguntas respondidas", Jogo.formatar(respostas)],
		["Taxa de acerto", taxa],
		["Tempo médio por resposta", tempo_medio],
		["Melhor sequência de acertos", str(e["melhor_sequencia"])],
		["Moedas ganhas no total", Jogo.formatar(e["moedas_ganhas"])],
		["Perguntas já vistas", "%d de %d" % [Progresso.perguntas.size(), Jogo.total_de_perguntas()]],
	]:
		geral.add_child(_linha_numero(item[0], item[1]))

	var direita := VBoxContainer.new()
	direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	direita.add_theme_constant_override("separation", 16)
	colunas.add_child(direita)

	var por_nivel := _secao_estatisticas("POR NÍVEL", direita)
	for i in Jogo.niveis.size():
		por_nivel.add_child(_linha_nivel(i))

	var por_assunto := _secao_estatisticas("ACERTO POR ASSUNTO", direita)
	var assuntos := Jogo.acerto_por_assunto()
	for assunto in ["word", "excel", "geral"]:
		por_assunto.add_child(_barra_assunto(NOMES_ASSUNTOS[assunto], assuntos[assunto]))

	var erradas := Jogo.mais_erradas(3)
	var secao_erradas := _secao_estatisticas("PARA ESTUDAR (MAIS ERRADAS)", direita)
	if erradas.is_empty():
		secao_erradas.add_child(_texto("Nenhuma pergunta errada até agora. Continue assim!", 18, Cores.ROXO_ESCURO))
	for pergunta in erradas:
		secao_erradas.add_child(_linha_numero(pergunta["enunciado"],
			"errou %dx" % pergunta["erros"], Cores.VERMELHO_ESCURO))
	return rolagem


## Cartão com título; retorna o VBox onde vão as linhas.
func _secao_estatisticas(titulo: String, pai: Control) -> VBoxContainer:
	var cartao := _cartao(Cores.CREME)
	cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cartao.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pai.add_child(cartao)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 6)
	cartao.add_child(coluna)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Titulo"
	rotulo.add_theme_font_size_override("font_size", 32)
	rotulo.text = titulo
	coluna.add_child(rotulo)
	return coluna


func _linha_numero(texto: String, valor: String, cor_valor := Cores.ROXO) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	var rotulo := _texto(texto, 18, Cores.ROXO_ESCURO)
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	var numero := Label.new()
	numero.theme_type_variation = &"Subtitulo"
	numero.add_theme_font_size_override("font_size", 26)
	numero.add_theme_color_override("font_color", cor_valor)
	numero.text = valor
	numero.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	linha.add_child(numero)
	return linha


## "FÁCIL  ★★☆  recorde 8/10 · 2.198 pts · 5 partidas"
func _linha_nivel(indice: int) -> HBoxContainer:
	var dados: Dictionary = Progresso.niveis[indice]
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	var nome := Label.new()
	nome.theme_type_variation = &"Subtitulo"
	nome.add_theme_font_size_override("font_size", 26)
	nome.text = Jogo.niveis[indice]["nome"].to_upper()
	nome.custom_minimum_size = Vector2(96, 0)
	linha.add_child(nome)
	for i in 3:
		var estrela := _icone(ICONE_ESTRELA, Cores.OURO if i < dados["estrelas"] else Color(Cores.ROXO, 0.2), 24)
		estrela.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(estrela)
	var detalhe := "ainda não jogou"
	if not Progresso.nivel_liberado(indice):
		detalhe = "bloqueado"
	elif dados["partidas"] > 0:
		detalhe = "recorde %d/%d · %s pts · %d partida%s" % [dados["recorde"], Jogo.PERGUNTAS_POR_PARTIDA,
			Jogo.formatar(dados["recorde_pontos"]), dados["partidas"], "" if dados["partidas"] == 1 else "s"]
	var texto := _texto(detalhe, 17, Cores.ROXO_ESCURO)
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	texto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(texto)
	return linha


func _barra_assunto(nome: String, totais: Dictionary) -> VBoxContainer:
	var bloco := VBoxContainer.new()
	bloco.add_theme_constant_override("separation", 2)
	var respostas: int = totais["respostas"]
	var porcentagem := 0 if respostas == 0 else roundi(100.0 * totais["acertos"] / respostas)
	var valor := "sem respostas" if respostas == 0 else "%d%% de %d" % [porcentagem, respostas]
	bloco.add_child(_linha_numero(nome, valor))
	var barra := ProgressBar.new()
	barra.show_percentage = false
	for parte in [["background", Color(Cores.ROXO, 0.15)], ["fill", Cores.ROXO]]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = parte[1]
		estilo.set_corner_radius_all(7)
		barra.add_theme_stylebox_override(parte[0], estilo)
	barra.custom_minimum_size = Vector2(0, 14)
	barra.value = porcentagem
	bloco.add_child(barra)
	return bloco


# --- Peças de interface --------------------------------------------------------

func _rolagem() -> ScrollContainer:
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return rolagem


## Conteúdo da rolagem com espaço embaixo (o pódio encosta embaixo de propósito).
func _com_margem(conteudo: Control) -> MarginContainer:
	var margem := MarginContainer.new()
	margem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margem.add_theme_constant_override("margin_bottom", 28)
	margem.add_child(conteudo)
	return margem


func _cartao(cor: Color) -> PanelContainer:
	var cartao := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(18)
	estilo.set_content_margin_all(14)
	cartao.add_theme_stylebox_override("panel", estilo)
	return cartao


func _texto(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Texto"
	rotulo.add_theme_font_override("font", _fonte_texto)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.custom_minimum_size = Vector2(120, 0)
	return rotulo


func _icone(textura: Texture2D, cor: Color, tamanho: int) -> TextureRect:
	var icone := TextureRect.new()
	icone.texture = textura
	icone.modulate = cor
	icone.custom_minimum_size = Vector2(tamanho, tamanho)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icone


func _valor_em_moedas(texto: String, cor: Color) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 4)
	var icone := _icone(ICONE_MOEDA, cor, 26)
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(icone)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"Subtitulo"
	rotulo.add_theme_font_size_override("font_size", 30)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.text = texto
	linha.add_child(rotulo)
	return linha


func _criar_coluna(titulo: Dictionary) -> VBoxContainer:
	var quantidade: int = Progresso.titulos[titulo["id"]]
	var conquistado := quantidade > 0

	var coluna := VBoxContainer.new()
	coluna.custom_minimum_size = Vector2(330, 0)
	coluna.alignment = BoxContainer.ALIGNMENT_END
	coluna.add_theme_constant_override("separation", 0)

	# Personagem (silhueta com cadeado se ainda não foi conquistado)
	var imagem := TextureRect.new()
	imagem.texture = Personagens.textura(titulo["personagem"])
	imagem.custom_minimum_size = Vector2(0, titulo["tamanho"])
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coluna.add_child(imagem)
	if conquistado:
		imagem.ready.connect(func(): if is_instance_valid(imagem): Animacoes.flutuar(imagem, 8.0), CONNECT_DEFERRED)  # depois de entrar na tela
	else:
		imagem.material = Personagens.material_silhueta(Color(1, 1, 1, 0.28))
		var cadeado := TextureRect.new()
		cadeado.texture = ICONE_CADEADO
		cadeado.modulate = Cores.AMARELO
		cadeado.custom_minimum_size = Vector2(64, 64)
		cadeado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cadeado.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cadeado.set_anchors_preset(Control.PRESET_CENTER)
		cadeado.offset_left = -32
		cadeado.offset_top = -32
		cadeado.offset_right = 32
		cadeado.offset_bottom = 32
		imagem.add_child(cadeado)
	# Doce 3D vivo no lugar da foto (gira com o dedo); silhueta clara se bloqueado
	Personagens.animar(imagem, titulo["personagem"], not conquistado, Color("#A58AD0"))

	# Degrau do pódio
	var degrau := PanelContainer.new()
	degrau.custom_minimum_size = Vector2(0, titulo["altura"])
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = titulo["cor"]
	estilo.corner_radius_top_left = 22
	estilo.corner_radius_top_right = 22
	estilo.border_width_top = 8
	estilo.border_color = titulo["cor"].lightened(0.35)
	estilo.set_content_margin_all(12)
	degrau.add_theme_stylebox_override("panel", estilo)
	coluna.add_child(degrau)

	var textos := VBoxContainer.new()
	textos.alignment = BoxContainer.ALIGNMENT_BEGIN
	textos.add_theme_constant_override("separation", 0)
	degrau.add_child(textos)
	var nome := Label.new()
	nome.theme_type_variation = &"Titulo"
	nome.add_theme_font_size_override("font_size", 46)
	nome.text = "DOCEIRO " + titulo["nome"]
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	textos.add_child(nome)
	var detalhe := Label.new()
	detalhe.theme_type_variation = &"Subtitulo"
	detalhe.add_theme_font_size_override("font_size", 26)
	detalhe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if conquistado:
		detalhe.text = "CONQUISTADO %dX" % quantidade
	else:
		detalhe.text = titulo["meta"]
		detalhe.modulate = Color(1, 1, 1, 0.75)
	detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(detalhe)
	return coluna
