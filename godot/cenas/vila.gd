class_name Vila
extends Node3D
## Vila dos Doces: o jogador anda com o seu doce (o companheiro da coleção)
## pela vila e entra nos prédios: Escola (quiz), Confeitaria (coleção),
## Troféus e Fliperama (em breve: Doce Match). Moradores passeiam pela praça.
## Anda com o joystick na tela ou com as setas/WASD; Enter/Espaço entra.

const METADE_MAPA := 20.0
const CAMERA_DISTANCIA := Vector3(0, 7.5, 8.5)
const CAMERA_SUAVIDADE := 5.0
const ICONE_CASA := preload("res://assets/icones/casa.svg")
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")

## Prédios da vila. "cena" = tela aberta ao entrar ("" = ainda não existe).
const PREDIOS := [
	{"id": "escola", "nome": "ESCOLA", "posicao": Vector3(0, 0, -14), "parede": "#F4E038",
		"telhado": "#7E57B1", "enfeite": "sino", "cena": "niveis", "acao": "JOGAR O QUIZ"},
	{"id": "confeitaria", "nome": "CONFEITARIA", "posicao": Vector3(-13, 0, -2), "parede": "#FFB3D1",
		"telhado": "#E8364F", "enfeite": "cupcake", "cena": "colecao", "acao": "MINHA COLEÇÃO"},
	{"id": "trofeus", "nome": "TROFÉUS", "posicao": Vector3(13, 0, -2), "parede": "#C9B3EC",
		"telhado": "#F2C230", "enfeite": "trofeu", "cena": "titulos", "acao": "VER TROFÉUS"},
	{"id": "fliperama", "nome": "FLIPERAMA", "posicao": Vector3(-10, 0, -13), "parede": "#8FD3F4",
		"telhado": "#5E3D8E", "enfeite": "fliperama", "cena": "", "acao": "FLIPERAMA"},
]
## Moradores que sempre passeiam (os mascotes dos níveis).
const MORADORES := ["bala_verde", "milho_doce"]

## Prédio de onde o jogador saiu por último (ele volta na porta dele).
static var ultima_porta := ""

var jogador: DoceAndante
var _camera: Camera3D
var _portas := {}  # id -> {"porta", "area", "no"}
var _porta_atual := ""
var _joystick: Joystick
var _botao_entrar: Button


func _ready() -> void:
	_criar_ambiente()
	CenarioVila.chao(self, METADE_MAPA)
	CenarioVila.praca(self, 4.2)
	for dados in PREDIOS:
		var predio := CenarioVila.predio(self, dados)
		_portas[dados["id"]] = predio
		var porta: Vector3 = predio["porta"]
		CenarioVila.caminho(self, porta.normalized() * 4.3, porta)
		predio["area"].body_entered.connect(_chegou_na_porta.bind(dados["id"]))
		predio["area"].body_exited.connect(_saiu_da_porta.bind(dados["id"]))
	_enfeitar()
	_criar_jogador()
	_criar_moradores()
	_criar_camera()
	_criar_interface()


# --- Controles -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var direcao := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var teclas := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	direcao = (direcao + teclas + _joystick.vetor).limit_length(1.0)
	jogador.andar(Vector3(direcao.x, 0, direcao.y), delta)


func _process(delta: float) -> void:
	var alvo := jogador.global_position + CAMERA_DISTANCIA
	_camera.global_position = _camera.global_position.lerp(alvo, minf(1.0, CAMERA_SUAVIDADE * delta))


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_accept") and not _porta_atual.is_empty():
		get_viewport().set_input_as_handled()
		entrar(_porta_atual)


## Entra no prédio (abre a tela dele; o "voltar" de lá traz de volta à vila).
func entrar(id: String) -> void:
	var dados: Dictionary = PREDIOS.filter(func(p): return p["id"] == id)[0]
	if String(dados["cena"]).is_empty():
		jogador.comemorar()
		Telas.mostrar_aviso("EM BREVE: DOCE MATCH, O JOGO DAS PEÇAS DO OFFICE!")
		return
	ultima_porta = id
	Telas.abrir(dados["cena"])


func _chegou_na_porta(corpo: Node3D, id: String) -> void:
	if corpo != jogador:
		return
	_porta_atual = id
	var dados: Dictionary = PREDIOS.filter(func(p): return p["id"] == id)[0]
	_botao_entrar.text = dados["acao"]
	_botao_entrar.visible = true
	_botao_entrar.pivot_offset = _botao_entrar.size / 2
	_botao_entrar.scale = Vector2.ONE * 0.7
	_botao_entrar.create_tween().tween_property(_botao_entrar, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _saiu_da_porta(corpo: Node3D, id: String) -> void:
	if corpo == jogador and _porta_atual == id:
		_porta_atual = ""
		_botao_entrar.visible = false


## Botão "voltar" do celular: volta para a tela inicial.
func ao_voltar() -> void:
	Telas.ir_para("inicio")


# --- Montagem ------------------------------------------------------------------

func _criar_ambiente() -> void:
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("#9FD4F7")
	ceu.sky_horizon_color = Color("#FFD6EA")
	ceu.ground_horizon_color = Color("#FFD6EA")
	ceu.ground_bottom_color = Color("#C9B3EC")
	var sky := Sky.new()
	sky.sky_material = ceu
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_SKY
	ambiente.sky = sky
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color.WHITE
	ambiente.ambient_light_energy = 0.5
	# sem reflexo do céu nas superfícies (deixava tudo desbotado)
	ambiente.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	add_child(mundo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.light_energy = 1.1
	add_child(sol)


func _enfeitar() -> void:
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 613
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF", "#FF8A5B"]
	# árvores de pirulito e bengalas em volta (longe da praça, dos prédios e dos caminhos)
	var colocados := 0
	var tentativas := 0
	while colocados < 34 and tentativas < 800:
		tentativas += 1
		var ponto := Vector3(sorteio.randf_range(-18, 18), 0, sorteio.randf_range(-18, 16))
		if not _lugar_livre(ponto, 2.2):
			continue
		colocados += 1
		match colocados % 4:
			0:
				CenarioVila.bengala(self, ponto)
			1, 2:
				CenarioVila.arvore_pirulito(self, ponto, cores[colocados % cores.size()])
			3:
				CenarioVila.jujuba(self, ponto, cores[(colocados * 7) % cores.size()], sorteio.randf_range(0.8, 1.4))
	# jujubas enfeitando a praça
	for i in 8:
		var angulo := i * TAU / 8.0 + 0.2
		var ponto := Vector3(cos(angulo) * 5.2, 0, sin(angulo) * 5.2)
		if _longe_dos_caminhos(ponto, 1.4):
			CenarioVila.jujuba(self, ponto, cores[i % cores.size()], 0.7)


func _lugar_livre(ponto: Vector3, folga: float) -> bool:
	if ponto.length() < 6.5:
		return false  # praça
	if ponto.z > 3.0 and absf(ponto.x) < 9.0:
		return false  # área na frente da câmera, onde o jogador começa
	for dados in PREDIOS:
		if ponto.distance_to(dados["posicao"]) < 5.0:
			return false
	for id in _portas:  # nada alto na frente das portas (taparia a câmera)
		if ponto.distance_to(_portas[id]["porta"]) < 7.0:
			return false
	return _longe_dos_caminhos(ponto, folga)


func _longe_dos_caminhos(ponto: Vector3, folga: float) -> bool:
	for id in _portas:
		var fim: Vector3 = _portas[id]["porta"]
		var inicio := fim.normalized() * 4.3
		var mais_perto := Geometry3D.get_closest_point_to_segment(ponto, inicio, fim)
		if ponto.distance_to(mais_perto) < folga + 1.2:
			return false
	return true


func _criar_jogador() -> void:
	jogador = DoceAndante.new()
	jogador.name = "Jogador"
	var id := Colecao.companheiro()
	jogador.id = id if not id.is_empty() else "brigadeiro"
	add_child(jogador)
	if _portas.has(ultima_porta):
		var porta: Vector3 = _portas[ultima_porta]["porta"]
		jogador.global_position = porta + porta.direction_to(Vector3.ZERO) * 0.4
		jogador.olhar_para(Vector3.ZERO)
	else:
		jogador.global_position = Vector3(0, 0, 7)
		jogador.olhar_para(Vector3(0, 0, 20))  # de frente para a câmera


func _criar_moradores() -> void:
	var ids: Array = MORADORES.duplicate()
	for doce in Colecao.LISTA:
		if Colecao.tem(doce["id"]) and doce["id"] != jogador.id and ids.size() < 5:
			ids.append(doce["id"])
	for i in ids.size():
		var morador := DoceAndante.new()
		morador.id = ids[i]
		morador.passeando = true
		add_child(morador)
		var angulo := i * TAU / ids.size()
		morador.global_position = Vector3(cos(angulo) * 5.5, 0, sin(angulo) * 5.5)
		morador.definir_area_passeio(Rect2(-9, -9, 18, 16))


func _criar_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 48.0
	add_child(_camera)
	_camera.global_position = jogador.global_position + CAMERA_DISTANCIA
	_camera.look_at(_camera.global_position - CAMERA_DISTANCIA + Vector3(0, 0.8, 0))


func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(raiz)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 28)
	raiz.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(coluna)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)
	var casa := Button.new()
	casa.name = "Casa"
	casa.theme_type_variation = &"BotaoIconeAmarelo"
	casa.custom_minimum_size = Vector2(72, 72)
	casa.icon = ICONE_CASA
	casa.expand_icon = true
	casa.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	casa.pressed.connect(Telas.ir_para.bind("inicio"))
	topo.add_child(casa)
	var titulo := PanelContainer.new()
	titulo.theme_type_variation = &"EtiquetaAmarela"
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var texto := Label.new()
	texto.theme_type_variation = &"Titulo"
	texto.text = "VILA DOS DOCES"
	titulo.add_child(texto)
	topo.add_child(titulo)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	var moedas := PanelContainer.new()
	moedas.theme_type_variation = &"Etiqueta"
	moedas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	moedas.add_child(linha)
	var icone := TextureRect.new()
	icone.texture = ICONE_MOEDA
	icone.modulate = Cores.AMARELO
	icone.custom_minimum_size = Vector2(32, 32)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(icone)
	var valor := Label.new()
	valor.theme_type_variation = &"TituloClaro"
	valor.text = Jogo.formatar(Progresso.moedas)
	linha.add_child(valor)
	topo.add_child(moedas)

	var meio := Control.new()
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(meio)

	var baixo := HBoxContainer.new()
	baixo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(baixo)
	_joystick = Joystick.new()
	_joystick.name = "Joystick"
	baixo.add_child(_joystick)
	var espaco2 := Control.new()
	espaco2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baixo.add_child(espaco2)
	_botao_entrar = Button.new()
	_botao_entrar.name = "Entrar"
	_botao_entrar.custom_minimum_size = Vector2(330, 96)
	_botao_entrar.size_flags_vertical = Control.SIZE_SHRINK_END
	_botao_entrar.visible = false
	_botao_entrar.pressed.connect(func(): entrar(_porta_atual))
	baixo.add_child(_botao_entrar)
