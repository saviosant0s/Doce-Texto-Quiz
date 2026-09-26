extends Node3D
## MINHA CASA: a sala do jogador (ver Casa). Vista de cima e de frente, como
## uma casinha de bonecas; o doce companheiro passeia por ela.
## - LOJA: móveis, papel de parede e piso (com prévia 3D girando).
## - DECORAR: a grade aparece no chão. Escolha um móvel guardado na bandeja e
##   toque no chão para pôr; toque num móvel para GIRAR, MUDAR DE LUGAR ou
##   GUARDAR.
## - CONFORTO no topo: cada faixa nova dá prêmio.

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const CASA := 1.0  # metros por casa da grade
const ALTURA_PAREDE := 3.0

var _camera: Camera3D
var _chao: MeshInstance3D
var _paredes: Array[MeshInstance3D] = []
var _moveis: Node3D
var _grade: Node3D
var _fantasma: MeshInstance3D
var _doce: DoceAndante
var _interface: Control
var _rotulo_conforto: Label
var _rotulo_moedas: Label
var _barra_ver: HBoxContainer
var _barra_decorar: VBoxContainer
var _bandeja: HBoxContainer
var _acoes: PanelContainer
var _loja: Control
var _dica: Label
## Decorando: móvel guardado escolhido para pôr ("" = nenhum), colocado
## selecionado (-1 = nenhum) e se está mudando ele de lugar.
var decorando := false
var escolhido := ""
var selecionado := -1
var movendo := false


func _ready() -> void:
	var novos := Casa.liberar_especiais()
	_criar_ambiente()
	_montar_sala()
	_moveis = Node3D.new()
	_moveis.name = "Moveis"
	add_child(_moveis)
	montar_moveis()
	_criar_grade()
	_criar_doce()
	_camera = Camera3D.new()
	_camera.fov = 50.0
	add_child(_camera)
	_camera.position = Vector3(0, 7.4, 8.0)
	_camera.look_at(Vector3(0, 0.2, -0.6))
	_criar_interface()
	usar_modo(false)
	Telas.dica_primeira_vez("minha_casa", "MINHA CASA",
		"Compre móveis, papel de parede e piso na LOJA. Depois toque em DECORAR e escolha onde pôr cada coisa. Quanto mais bonita, mais CONFORTO, e cada nível de conforto dá prêmio!")
	for id in novos:
		Telas.mostrar_aviso("MÓVEL ESPECIAL NOVO: " + Casa.MOVEIS[id]["nome"] + "!")


func ao_voltar() -> void:
	if is_instance_valid(_loja):
		fechar_loja()
		return
	if decorando:
		usar_modo(false)
		return
	Telas.voltar()


# --- Sala --------------------------------------------------------------------------

func _criar_ambiente() -> void:
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color("#3B2A5C")
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color("#FFE6F0")
	ambiente.ambient_light_energy = 0.45
	CenarioVila.acabamento(ambiente)
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	add_child(mundo)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-58, -30, 0)
	luz.light_color = Color("#FFF1DC")
	luz.light_energy = 0.9
	luz.shadow_enabled = Qualidade.sombras()
	luz.shadow_blur = 1.5
	add_child(luz)
	var janela := OmniLight3D.new()  # luz quentinha do meio da sala
	janela.position = Vector3(0, 2.6, 0)
	janela.light_color = Color("#FFD9A8")
	janela.omni_range = 7.0
	janela.light_energy = 0.6
	add_child(janela)


func _montar_sala() -> void:
	var largura := Casa.LARGURA * CASA
	var fundo := Casa.FUNDO * CASA
	_chao = Pecas3D.caixa(self, Vector3(largura, 0.1, fundo), Vector3(0, -0.05, 0), StandardMaterial3D.new())
	_chao.name = "Piso"
	CenarioVila._parede(self, Vector3(largura, 0.1, fundo), Vector3(0, -0.05, 0))  # chão firme para o doce
	# parede do fundo e das laterais (a da frente fica aberta, como casinha de bonecas)
	for dados in [[Vector3(largura, ALTURA_PAREDE, 0.15), Vector3(0, ALTURA_PAREDE / 2.0, -fundo / 2.0 - 0.075)],
			[Vector3(0.15, ALTURA_PAREDE, fundo), Vector3(-largura / 2.0 - 0.075, ALTURA_PAREDE / 2.0, 0)],
			[Vector3(0.15, ALTURA_PAREDE, fundo), Vector3(largura / 2.0 + 0.075, ALTURA_PAREDE / 2.0, 0)]]:
		var parede := Pecas3D.caixa(self, dados[0], dados[1], StandardMaterial3D.new())
		parede.name = "Parede"
		_paredes.append(parede)
		CenarioVila._parede(self, dados[0], dados[1])
	# rodapé de chocolate e topo de glacê
	var rodape := Pecas3D.material(Color("#6B3A1F"), 0.5)
	var glace := Pecas3D.material(Color("#FFFFFF"), 0.4)
	Pecas3D.caixa(self, Vector3(largura, 0.18, 0.06), Vector3(0, 0.09, -fundo / 2.0 + 0.03), rodape)
	for x in [-1, 1]:
		Pecas3D.caixa(self, Vector3(0.06, 0.18, fundo), Vector3(x * (largura / 2.0 - 0.03), 0.09, 0), rodape)
		Pecas3D.caixa(self, Vector3(0.3, 0.12, fundo + 0.3), Vector3(x * (largura / 2.0 + 0.075), ALTURA_PAREDE + 0.06, 0), glace)
	Pecas3D.caixa(self, Vector3(largura + 0.3, 0.12, 0.3), Vector3(0, ALTURA_PAREDE + 0.06, -fundo / 2.0 - 0.075), glace)
	# janela no fundo, com céu e cortinas
	var janela := Vector3(-1.6, 1.7, -fundo / 2.0 + 0.02)
	Pecas3D.caixa(self, Vector3(1.5, 1.2, 0.05), janela, Pecas3D.material(Color("#FFFFFF"), 0.4))
	var ceu := Pecas3D.material(Color("#9FD4F7"), 0.3)
	ceu.emission_enabled = true
	ceu.emission = Color("#BFE6FF")
	ceu.emission_energy_multiplier = 0.6
	Pecas3D.caixa(self, Vector3(1.3, 1.0, 0.05), janela + Vector3(0, 0, 0.02), ceu)
	Pecas3D.caixa(self, Vector3(0.06, 1.0, 0.07), janela + Vector3(0, 0, 0.04), Pecas3D.material(Color("#FFFFFF"), 0.4))
	for x in [-0.85, 0.85]:
		Pecas3D.caixa(self, Vector3(0.35, 1.45, 0.06), janela + Vector3(x, -0.05, 0.08), Pecas3D.material(Color("#FF8FB8"), 0.8))
	# porta na lateral direita
	Pecas3D.caixa(self, Vector3(0.06, 2.0, 1.1), Vector3(largura / 2.0 - 0.03, 1.0, 1.5), Pecas3D.material(Color("#7A4322"), 0.5))
	Pecas3D.esfera(self, 0.06, Vector3(largura / 2.0 - 0.08, 1.0, 1.1), Pecas3D.material(Color("#FFC83D"), 0.2, 0.6))
	# quadro de doce na parede
	Pecas3D.caixa(self, Vector3(1.0, 0.8, 0.05), Vector3(1.6, 1.8, -fundo / 2.0 + 0.03), Pecas3D.material(Color("#C99A52"), 0.5))
	Pecas3D.caixa(self, Vector3(0.85, 0.65, 0.05), Vector3(1.6, 1.8, -fundo / 2.0 + 0.05), Pecas3D.material(Color("#FFE3EE"), 0.8))
	Pecas3D.esfera(self, 0.2, Vector3(1.6, 1.8, -fundo / 2.0 + 0.08), Pecas3D.material(Color("#7A4322"), 0.3), Vector3(1, 1, 0.3))
	aplicar_parede_e_piso()
	CenarioVila.estilo_desenho(self)


## Põe a textura do papel de parede e do piso escolhidos.
func aplicar_parede_e_piso() -> void:
	var mat_piso := StandardMaterial3D.new()
	mat_piso.albedo_texture = Moveis3D.textura_piso(Casa.piso())
	mat_piso.uv1_triplanar = true
	mat_piso.uv1_scale = Vector3.ONE * 0.5
	mat_piso.roughness = 0.35 if Casa.piso() == "marmore" else 0.8
	mat_piso.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_chao.material_override = mat_piso
	var mat_parede := StandardMaterial3D.new()
	mat_parede.albedo_texture = Moveis3D.textura_parede(Casa.parede())
	mat_parede.uv1_triplanar = true
	mat_parede.uv1_scale = Vector3.ONE * 0.5
	mat_parede.roughness = 0.85
	mat_parede.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for parede in _paredes:
		parede.material_override = mat_parede


## Centro no mundo de um móvel com canto na casa (x, z) e esse tamanho.
static func centro(x: int, z: int, tam: Vector2i) -> Vector3:
	return Vector3(-Casa.LARGURA / 2.0 + x + tam.x / 2.0, 0, -Casa.FUNDO / 2.0 + z + tam.y / 2.0) * CASA


## (Re)monta os móveis colocados.
func montar_moveis() -> void:
	for filho in _moveis.get_children():
		_moveis.remove_child(filho)  # sai já (o nome "MovelN" fica livre para o novo)
		filho.queue_free()
	var lista := Casa.colocados()
	for i in lista.size():
		var c: Dictionary = lista[i]
		var tam := Casa.tamanho(c["id"], int(c["giro"]))
		var no := Node3D.new()
		no.name = "Movel%d" % i
		no.position = centro(int(c["x"]), int(c["z"]), tam)
		_moveis.add_child(no)
		var modelo := Node3D.new()
		modelo.rotation.y = -int(c["giro"]) * PI / 2.0
		no.add_child(modelo)
		Moveis3D.montar(c["id"], modelo)
		CenarioVila.estilo_desenho(modelo)
		# caixa para o toque achar o móvel (e o doce não atravessar)
		var corpo := StaticBody3D.new()
		corpo.collision_layer = 1 if not Casa.MOVEIS[c["id"]].get("tapete", false) else 4
		corpo.set_meta("indice", i)
		var forma := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(tam.x * CASA - 0.1, 1.2, tam.y * CASA - 0.1)
		forma.shape = caixa
		forma.position.y = 0.6
		corpo.add_child(forma)
		no.add_child(corpo)
		if i == selecionado:
			_realcar(no, tam)


func _realcar(no: Node3D, tam: Vector2i) -> void:
	var marca := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(tam.x * CASA, 0.04, tam.y * CASA)
	marca.mesh = caixa
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.85, 0.2, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marca.material_override = mat
	marca.position.y = 0.03
	no.add_child(marca)


func _criar_grade() -> void:
	_grade = Node3D.new()
	_grade.name = "Grade"
	add_child(_grade)
	var linha := StandardMaterial3D.new()
	linha.albedo_color = Color(1, 1, 1, 0.55)
	linha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	linha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for x in range(1, Casa.LARGURA):
		Pecas3D.caixa(_grade, Vector3(0.03, 0.01, Casa.FUNDO * CASA), Vector3(-Casa.LARGURA / 2.0 + x, 0.02, 0), linha)
	for z in range(1, Casa.FUNDO):
		Pecas3D.caixa(_grade, Vector3(Casa.LARGURA * CASA, 0.01, 0.03), Vector3(0, 0.02, -Casa.FUNDO / 2.0 + z), linha)
	_fantasma = MeshInstance3D.new()
	_fantasma.name = "Fantasma"
	_fantasma.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fantasma.material_override = mat
	_fantasma.visible = false
	add_child(_fantasma)


func _criar_doce() -> void:
	_doce = DoceAndante.new()
	_doce.name = "Doce"
	_doce.id = Colecao.companheiro() if Colecao.companheiro() != "" else "brigadeiro"
	_doce.nivel = Companheiros.nivel(_doce.id)
	_doce.passeando = true
	add_child(_doce)
	_doce.global_position = Vector3(0.5, 0, 1.5)
	_doce.definir_area_passeio(Rect2(-3.3, -2.3, 6.6, 4.8))
	CenarioVila.estilo_desenho(_doce)


# --- Toques ------------------------------------------------------------------------

func _unhandled_input(evento: InputEvent) -> void:
	if not decorando or is_instance_valid(_loja):
		return
	var ponto := Vector2(-1, -1)
	if evento is InputEventScreenTouch and not evento.pressed:
		ponto = evento.position
	elif evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed \
			and evento.device != InputEvent.DEVICE_ID_EMULATION:
		ponto = evento.position
	if ponto.x < 0:
		return
	get_viewport().set_input_as_handled()
	tocar(ponto)


## Toque na tela (em pixels) no modo decorar.
func tocar(ponto: Vector2) -> void:
	var de := _camera.project_ray_origin(ponto)
	var direcao := _camera.project_ray_normal(ponto)
	var consulta := PhysicsRayQueryParameters3D.create(de, de + direcao * 50.0, 1 | 4)
	var batida := get_world_3d().direct_space_state.intersect_ray(consulta)
	var casa := Vector2i(-1, -1)
	if direcao.y < -0.01:
		var no_chao := de + direcao * (-de.y / direcao.y)
		casa = Vector2i(floori(no_chao.x / CASA + Casa.LARGURA / 2.0), floori(no_chao.z / CASA + Casa.FUNDO / 2.0))
	tocar_casa(casa, int(batida["collider"].get_meta("indice")) if batida and batida["collider"].has_meta("indice") else -1)


## O que fazer com um toque na casa `casa` da grade (ou no móvel `indice`).
func tocar_casa(casa: Vector2i, indice := -1) -> void:
	if escolhido != "":
		var tam := Casa.tamanho(escolhido, 0)
		var x := casa.x - (tam.x - 1) / 2
		var z := casa.y - (tam.y - 1) / 2
		if Casa.colocar(escolhido, x, z, 0):
			Audio.tocar("construir", 1.2, -4.0)
			if Casa.guardados(escolhido) <= 0:
				escolhido = ""
			_depois_de_mudar()
		else:
			Telas.mostrar_aviso("NÃO CABE AQUI")
		return
	if movendo and selecionado >= 0:
		var c: Dictionary = Casa.colocados()[selecionado]
		var tam := Casa.tamanho(c["id"], int(c["giro"]))
		if Casa.mover(selecionado, casa.x - (tam.x - 1) / 2, casa.y - (tam.y - 1) / 2):
			Audio.tocar("construir", 1.3, -6.0)
			movendo = false
			_depois_de_mudar()
		else:
			Telas.mostrar_aviso("NÃO CABE AQUI")
		return
	if indice < 0 and casa.x >= 0:
		indice = Casa.no_lugar(casa.x, casa.y)
	selecionar(indice)


func selecionar(indice: int) -> void:
	selecionado = indice
	movendo = false
	montar_moveis()
	_atualizar_acoes()


func girar_selecionado() -> void:
	if selecionado >= 0 and not Casa.girar(selecionado):
		Telas.mostrar_aviso("GIRADO NÃO CABE: MUDE DE LUGAR ANTES")
	_depois_de_mudar()


func guardar_selecionado() -> void:
	if selecionado < 0:
		return
	Casa.guardar(selecionado)
	selecionado = -1
	_depois_de_mudar()


func mover_selecionado() -> void:
	movendo = selecionado >= 0
	_atualizar_acoes()


func _depois_de_mudar() -> void:
	montar_moveis()
	_atualizar_bandeja()
	_atualizar_acoes()
	_atualizar_topo()
	for ganho in Casa.premiar():
		var texto := "SUA CASA FICOU %s!" % Casa.nome_faixa(int(ganho["faixa"]))
		if ganho.has("moedas"):
			texto += " +%d MOEDAS" % ganho["moedas"]
		if ganho.has("bau"):
			texto += " + BAÚ " + ("DE OURO" if ganho["bau"] == "ouro" else "DE DOCE")
		Audio.tocar("vitoria")
		_doce.comemorar()
		Telas.mostrar_aviso(texto)
		_atualizar_topo()


# --- Interface ---------------------------------------------------------------------

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	_interface = Control.new()
	_interface.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_interface)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 20)
	_interface.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(coluna)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(60, 60)
	voltar.icon = ICONE_VOLTAR
	voltar.expand_icon = true
	voltar.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.pressed.connect(ao_voltar)
	topo.add_child(voltar)
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"EtiquetaAmarela"
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var titulo := Label.new()
	titulo.theme_type_variation = &"Titulo"
	titulo.add_theme_font_size_override("font_size", 36)
	titulo.text = "MINHA CASA"
	etiqueta.add_child(titulo)
	topo.add_child(etiqueta)
	var conforto := PanelContainer.new()
	conforto.theme_type_variation = &"PainelRoxo"
	conforto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_rotulo_conforto = Label.new()
	_rotulo_conforto.name = "Conforto"
	_rotulo_conforto.theme_type_variation = &"TituloClaro"
	_rotulo_conforto.add_theme_font_size_override("font_size", 24)
	conforto.add_child(_rotulo_conforto)
	topo.add_child(conforto)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	var saldo := PanelContainer.new()
	saldo.theme_type_variation = &"Etiqueta"
	saldo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	saldo.add_child(linha)
	var icone := TextureRect.new()
	icone.texture = Itens.MOEDA
	icone.custom_minimum_size = Vector2(26, 26)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(icone)
	_rotulo_moedas = Label.new()
	_rotulo_moedas.name = "Moedas"
	_rotulo_moedas.theme_type_variation = &"TituloClaro"
	_rotulo_moedas.add_theme_font_size_override("font_size", 26)
	linha.add_child(_rotulo_moedas)
	topo.add_child(saldo)

	var meio := Control.new()
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(meio)
	_dica = Label.new()
	_dica.name = "Dica"
	_dica.theme_type_variation = &"TituloClaro"
	_dica.add_theme_font_size_override("font_size", 26)
	_dica.add_theme_constant_override("outline_size", 8)
	_dica.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_dica)

	# modo ver: DECORAR e LOJA
	_barra_ver = HBoxContainer.new()
	_barra_ver.alignment = BoxContainer.ALIGNMENT_END
	_barra_ver.add_theme_constant_override("separation", 14)
	_barra_ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_barra_ver)
	for par in [["LOJA", abrir_loja, &"Alternativa"], ["DECORAR", usar_modo.bind(true), &"Button"]]:
		var b := Button.new()
		b.name = "Botao" + par[0]
		b.text = par[0]
		b.theme_type_variation = par[2]
		b.custom_minimum_size = Vector2(220, 72)
		b.add_theme_font_size_override("font_size", 30)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(par[1])
		_barra_ver.add_child(b)

	# modo decorar: ações do móvel escolhido, bandeja dos guardados e PRONTO
	_barra_decorar = VBoxContainer.new()
	_barra_decorar.add_theme_constant_override("separation", 10)
	_barra_decorar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_barra_decorar)
	_acoes = PanelContainer.new()
	_acoes.name = "Acoes"
	_acoes.theme_type_variation = &"PainelRoxo"
	_acoes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var linha_acoes := HBoxContainer.new()
	linha_acoes.add_theme_constant_override("separation", 10)
	_acoes.add_child(linha_acoes)
	for par in [["GIRAR", girar_selecionado], ["MUDAR DE LUGAR", mover_selecionado], ["GUARDAR", guardar_selecionado]]:
		var b := Button.new()
		b.name = "Acao" + par[0].replace(" ", "")
		b.text = par[0]
		b.custom_minimum_size = Vector2(170, 58)
		b.add_theme_font_size_override("font_size", 22)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(par[1])
		linha_acoes.add_child(b)
	_barra_decorar.add_child(_acoes)
	var baixo := HBoxContainer.new()
	baixo.add_theme_constant_override("separation", 12)
	_barra_decorar.add_child(baixo)
	var rolar := ScrollContainer.new()
	rolar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolar.custom_minimum_size.y = 84
	rolar.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	baixo.add_child(rolar)
	_bandeja = HBoxContainer.new()
	_bandeja.name = "Bandeja"
	_bandeja.add_theme_constant_override("separation", 8)
	rolar.add_child(_bandeja)
	var pronto := Button.new()
	pronto.name = "Pronto"
	pronto.text = "PRONTO"
	pronto.custom_minimum_size = Vector2(170, 72)
	pronto.add_theme_font_size_override("font_size", 28)
	pronto.focus_mode = Control.FOCUS_NONE
	pronto.pressed.connect(usar_modo.bind(false))
	baixo.add_child(pronto)
	_atualizar_topo()


func usar_modo(decorar: bool) -> void:
	decorando = decorar
	escolhido = ""
	selecionado = -1
	movendo = false
	_grade.visible = decorar
	_barra_ver.visible = not decorar
	_barra_decorar.visible = decorar
	_doce.visible = not decorar  # o doce sai da frente enquanto decora
	_doce.process_mode = Node.PROCESS_MODE_DISABLED if decorar else Node.PROCESS_MODE_INHERIT
	montar_moveis()
	_atualizar_bandeja()
	_atualizar_acoes()


func _atualizar_topo() -> void:
	var falta := Casa.falta_proxima()
	_rotulo_conforto.text = "CONFORTO %d · %s" % [Casa.conforto(), Casa.nome_faixa()]
	if falta > 0:
		_rotulo_conforto.text += "  (FALTAM %d)" % falta
	_rotulo_moedas.text = Jogo.formatar(Progresso.moedas)


func _atualizar_bandeja() -> void:
	for filho in _bandeja.get_children():
		filho.queue_free()
	var algum := false
	for id in Casa.MOVEIS:
		var n := Casa.guardados(id)
		if n <= 0:
			continue
		algum = true
		var b := Button.new()
		b.name = "Guardado_" + id
		b.text = "%s ×%d" % [Casa.MOVEIS[id]["nome"], n]
		b.custom_minimum_size = Vector2(0, 72)
		b.add_theme_font_size_override("font_size", 20)
		b.focus_mode = Control.FOCUS_NONE
		b.theme_type_variation = &"BotaoRoxo" if id == escolhido else &"Alternativa"
		b.pressed.connect(func():
			escolhido = "" if escolhido == id else id
			selecionado = -1
			movendo = false
			montar_moveis()
			_atualizar_bandeja()
			_atualizar_acoes())
		_bandeja.add_child(b)
	if not algum:
		var vazio := Label.new()
		vazio.theme_type_variation = &"TituloClaro"
		vazio.add_theme_font_size_override("font_size", 24)
		vazio.text = "NADA GUARDADO: COMPRE MÓVEIS NA LOJA"
		_bandeja.add_child(vazio)


func _atualizar_acoes() -> void:
	_acoes.visible = decorando and selecionado >= 0 and not movendo
	if not decorando:
		_dica.text = ""
	elif movendo:
		_dica.text = "TOQUE NO CHÃO ONDE O MÓVEL VAI FICAR"
	elif escolhido != "":
		_dica.text = "TOQUE NO CHÃO PARA PÔR: " + Casa.MOVEIS[escolhido]["nome"]
	elif selecionado >= 0:
		_dica.text = Casa.MOVEIS[Casa.colocados()[selecionado]["id"]]["nome"]
	else:
		_dica.text = "ESCOLHA UM MÓVEL GUARDADO OU TOQUE NUM MÓVEL DA SALA"


# --- Loja --------------------------------------------------------------------------

var _aba_loja := "moveis"
var _escolha_loja := ""
var _previa: Node3D
var _info_loja: Label
var _comprar: Button
var _itens_loja: GridContainer


func abrir_loja() -> void:
	fechar_loja()
	var camada := Control.new()
	camada.name = "Loja"
	camada.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interface.add_child(camada)
	_loja = camada
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.6)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(escuro)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 30)
	camada.add_child(margem)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	margem.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 10)
	coluna.add_child(topo)
	var titulo := Label.new()
	titulo.theme_type_variation = &"TituloClaro"
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.text = "LOJA DE MÓVEIS"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	for par in [["moveis", "MÓVEIS"], ["paredes", "PAREDES"], ["pisos", "PISOS"]]:
		var aba := Button.new()
		aba.name = "Aba_" + par[0]
		aba.text = par[1]
		aba.custom_minimum_size = Vector2(150, 54)
		aba.add_theme_font_size_override("font_size", 22)
		aba.focus_mode = Control.FOCUS_NONE
		aba.theme_type_variation = &"Button" if par[0] == _aba_loja else &"Alternativa"
		aba.pressed.connect(func():
			_aba_loja = par[0]
			_escolha_loja = ""
			abrir_loja())
		topo.add_child(aba)
	var fechar := Button.new()
	fechar.name = "FecharLoja"
	fechar.text = "FECHAR"
	fechar.theme_type_variation = &"Alternativa"
	fechar.custom_minimum_size = Vector2(150, 54)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.pressed.connect(fechar_loja)
	topo.add_child(fechar)
	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 16)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(corpo)
	# prévia 3D girando + informação + comprar
	var lado := VBoxContainer.new()
	lado.add_theme_constant_override("separation", 8)
	corpo.add_child(lado)
	var janela := SubViewportContainer.new()
	janela.stretch = true
	janela.custom_minimum_size = Vector2(320, 260)
	lado.add_child(janela)
	var visor := SubViewport.new()
	visor.own_world_3d = true
	visor.transparent_bg = true
	janela.add_child(visor)
	_previa = Node3D.new()
	visor.add_child(_previa)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.5, 2.5)
	visor.add_child(camera)
	camera.look_at(Vector3(0, 0.55, 0))
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, -30, 0)
	visor.add_child(luz)
	var mundo := WorldEnvironment.new()
	mundo.environment = Environment.new()
	mundo.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	mundo.environment.ambient_light_color = Color("#FFE6F0")
	mundo.environment.ambient_light_energy = 0.6
	visor.add_child(mundo)
	_info_loja = Label.new()
	_info_loja.name = "InfoLoja"
	_info_loja.theme_type_variation = &"SubtituloClaro"
	_info_loja.add_theme_font_size_override("font_size", 22)
	_info_loja.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_loja.custom_minimum_size = Vector2(320, 0)
	lado.add_child(_info_loja)
	_comprar = Button.new()
	_comprar.name = "Comprar"
	_comprar.custom_minimum_size = Vector2(320, 64)
	_comprar.add_theme_font_size_override("font_size", 24)
	_comprar.focus_mode = Control.FOCUS_NONE
	_comprar.pressed.connect(_comprar_escolha)
	lado.add_child(_comprar)
	var rolar := ScrollContainer.new()
	rolar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corpo.add_child(rolar)
	_itens_loja = GridContainer.new()
	_itens_loja.columns = 3
	_itens_loja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_itens_loja.add_theme_constant_override("h_separation", 10)
	_itens_loja.add_theme_constant_override("v_separation", 10)
	rolar.add_child(_itens_loja)
	var lista: Dictionary = Casa.MOVEIS if _aba_loja == "moveis" else (Casa.PAREDES if _aba_loja == "paredes" else Casa.PISOS)
	for id in lista:
		var b := Button.new()
		b.name = "Item_" + id
		b.custom_minimum_size = Vector2(0, 76)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.focus_mode = Control.FOCUS_NONE
		b.text = "%s\n%s" % [lista[id]["nome"], _preco_texto(id)]
		b.theme_type_variation = &"Button" if id == _escolha_loja else &"Alternativa"
		b.pressed.connect(escolher_na_loja.bind(id))
		_itens_loja.add_child(b)
	if _escolha_loja == "":
		_escolha_loja = lista.keys()[0]
	escolher_na_loja(_escolha_loja)


func _preco_texto(id: String) -> String:
	match _aba_loja:
		"moveis":
			var m: Dictionary = Casa.MOVEIS[id]
			if m.has("libera"):
				return "TEM ✓" if Casa.quantos(id) > 0 else "ESPECIAL"
			return "%d MOEDAS" % m["preco"] + (" · TEM %d" % Casa.quantos(id) if Casa.quantos(id) > 0 else "")
		"paredes":
			return "USANDO" if Casa.parede() == id else ("TEM ✓" if Casa.tem_parede(id) else "%d MOEDAS" % Casa.PAREDES[id]["preco"])
		_:
			return "USANDO" if Casa.piso() == id else ("TEM ✓" if Casa.tem_piso(id) else "%d MOEDAS" % Casa.PISOS[id]["preco"])


func escolher_na_loja(id: String) -> void:
	_escolha_loja = id
	for b in _itens_loja.get_children():
		b.theme_type_variation = &"Button" if b.name == "Item_" + id else &"Alternativa"
	for filho in _previa.get_children():
		filho.queue_free()
	match _aba_loja:
		"moveis":
			var m: Dictionary = Casa.MOVEIS[id]
			var modelo := Node3D.new()
			_previa.add_child(modelo)
			Moveis3D.montar(id, modelo)
			var escala := 1.25 / maxf(1.0, maxf(m["tam"][0], m["tam"][1]) * 0.85)
			modelo.scale = Vector3.ONE * escala
			_info_loja.text = "%s\nCONFORTO +%d" % [m["nome"], m["conforto"]]
			if m.has("libera"):
				_info_loja.text += "\n" + m["como"].to_upper()
				_comprar.text = "JÁ É SEU!" if Casa.quantos(id) > 0 else "NÃO ESTÁ À VENDA"
				_comprar.disabled = true
			else:
				_comprar.text = "COMPRAR (%d MOEDAS)" % m["preco"]
				_comprar.disabled = false
		"paredes", "pisos":
			var dados: Dictionary = Casa.PAREDES[id] if _aba_loja == "paredes" else Casa.PISOS[id]
			var amostra := MeshInstance3D.new()
			var caixa := BoxMesh.new()
			caixa.size = Vector3(1.8, 1.8, 0.1) if _aba_loja == "paredes" else Vector3(2.2, 0.1, 2.2)
			amostra.mesh = caixa
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = Moveis3D.textura_parede(id) if _aba_loja == "paredes" else Moveis3D.textura_piso(id)
			mat.uv1_triplanar = true
			mat.uv1_scale = Vector3.ONE * 0.5
			amostra.material_override = mat
			amostra.position.y = 0.9 if _aba_loja == "paredes" else 0.2
			_previa.add_child(amostra)
			var usando := (Casa.parede() if _aba_loja == "paredes" else Casa.piso()) == id
			var tem := Casa.tem_parede(id) if _aba_loja == "paredes" else Casa.tem_piso(id)
			_info_loja.text = "%s\nCONFORTO +%d" % [dados["nome"], dados["conforto"]]
			_comprar.disabled = usando
			_comprar.text = "USANDO" if usando else ("USAR" if tem else "COMPRAR E USAR (%d)" % dados["preco"])


func _comprar_escolha() -> void:
	var id := _escolha_loja
	var ok := false
	match _aba_loja:
		"moveis":
			ok = Casa.comprar(id)
			if ok:
				Telas.mostrar_aviso("COMPROU! TOQUE EM DECORAR PARA PÔR NA SALA")
		"paredes":
			ok = Casa.usar_parede(id)
		"pisos":
			ok = Casa.usar_piso(id)
	if not ok:
		Telas.mostrar_aviso("FALTAM MOEDAS")
		return
	Audio.tocar("moeda")
	if _aba_loja != "moveis":
		aplicar_parede_e_piso()
	_depois_de_mudar()
	abrir_loja()


func fechar_loja() -> void:
	if is_instance_valid(_loja):
		_loja.queue_free()
	_loja = null


func _process(delta: float) -> void:
	if is_instance_valid(_previa):
		_previa.rotation.y += delta * 0.8
	if not decorando or escolhido == "" and not movendo:
		_fantasma.visible = false
		return
	# prévia (verde = cabe, vermelho = não cabe) onde o dedo/mouse está
	var ponto := get_viewport().get_mouse_position()
	var de := _camera.project_ray_origin(ponto)
	var direcao := _camera.project_ray_normal(ponto)
	if direcao.y > -0.01:
		_fantasma.visible = false
		return
	var no_chao := de + direcao * (-de.y / direcao.y)
	var casa := Vector2i(floori(no_chao.x / CASA + Casa.LARGURA / 2.0), floori(no_chao.z / CASA + Casa.FUNDO / 2.0))
	var id := escolhido if escolhido != "" else str(Casa.colocados()[selecionado]["id"])
	var giro := 0 if escolhido != "" else int(Casa.colocados()[selecionado]["giro"])
	var tam := Casa.tamanho(id, giro)
	var x := casa.x - (tam.x - 1) / 2
	var z := casa.y - (tam.y - 1) / 2
	var cabe := Casa.cabe(id, x, z, giro, selecionado if movendo else -1)
	(_fantasma.mesh as BoxMesh).size = Vector3(tam.x * CASA, 0.06, tam.y * CASA)
	_fantasma.position = centro(x, z, tam) + Vector3(0, 0.04, 0)
	(_fantasma.material_override as StandardMaterial3D).albedo_color = Color(0.3, 1, 0.4, 0.45) if cabe else Color(1, 0.3, 0.3, 0.45)
	_fantasma.visible = true
