class_name Vila
extends Node3D
## Vila dos Doces: o jogador anda com o seu doce (o companheiro da coleção)
## pela vila e entra nos prédios: Escola (quiz), Confeitaria (fábrica de doces),
## Troféus e Fliperama (em breve: Doce Match). Moradores passeiam pela praça.
## Anda com o joystick na tela ou com as setas/WASD (Shift corre); Espaço ou o
## botão PULAR pula; Enter/E entra no prédio.
##
## Três câmeras (botão no topo; a escolha fica salva):
## - AÉREA: de cima e de longe, sempre olhando para o norte.
## - PERTO: atrás do doce; acompanha quando ele anda para frente; arrastar o
##   dedo na tela gira a visão; se um prédio ficar no meio, ela se aproxima.
## - 1ª PESSOA: pelos olhos do doce; joystick para cima/baixo anda e para os
##   lados vira; arrastar o dedo também vira.

const METADE_MAPA := 20.0
const CAMERA_DISTANCIA := Vector3(0, 7.5, 8.5)
const CAMERA_SUAVIDADE := 5.0
const ICONE_CASA := preload("res://assets/icones/casa.svg")
const ICONE_CAMERA := preload("res://assets/icones/camera.svg")
const ICONE_PULAR := preload("res://assets/icones/pular.svg")

enum Camera { AEREA, PERTO, PRIMEIRA_PESSOA }
const NOMES_CAMERA := ["AÉREA", "PERTO", "1ª PESSOA"]
const PERTO_DISTANCIA := 4.3
const PERTO_ALTURA := 2.3
const ALTURA_OLHOS := 1.35
const GIRO_JOYSTICK := 2.4  # radianos por segundo (1ª pessoa)
const GIRO_ARRASTO := 0.01  # radianos por pixel arrastado
## Inclinação da visão (arrastar o dedo para cima/baixo), em radianos.
const INCLINACAO_1P := Vector2(-1.2, 1.1)  # 1ª pessoa: olhar para baixo / para cima
const INCLINACAO_PERTO := Vector2(-0.5, 0.7)
const INCLINACAO_INICIAL_1P := -0.12
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")

## Prédios da vila. "cena" = tela aberta ao entrar ("" = ainda não existe).
const PREDIOS := [
	{"id": "escola", "nome": "ESCOLA", "posicao": Vector3(0, 0, -14), "parede": "#F4E038",
		"telhado": "#7E57B1", "cena": "niveis", "acao": "JOGAR O QUIZ"},
	{"id": "confeitaria", "nome": "CONFEITARIA", "posicao": Vector3(-13, 0, -2), "parede": "#FFB3D1",
		"telhado": "#E8364F", "cena": "cozinha", "acao": "ENTRAR NA CONFEITARIA"},
	{"id": "trofeus", "nome": "TROFÉUS", "posicao": Vector3(13, 0, -2), "parede": "#C9B3EC",
		"telhado": "#F2C230", "cena": "titulos", "acao": "VER TROFÉUS"},
	{"id": "fliperama", "nome": "FLIPERAMA", "posicao": Vector3(-10, 0, -13), "parede": "#8FD3F4",
		"telhado": "#5E3D8E", "cena": "", "acao": "FLIPERAMA"},
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
var modo_camera := Camera.AEREA
## Para onde a câmera olha (radianos no eixo Y; 0 = norte, para dentro da vila).
var _giro := 0.0
## Para cima (+) ou para baixo (-) nas câmeras de perto (ver INCLINACAO_*).
var _inclinacao := 0.0
var _nuvens: Array = []
## Animação de entrar num prédio em andamento.
var _entrando := false
var _cena_entrando := ""
var _passos_entrada: Array = []
var _botao_pular: Button
var _botao_camera: Button
## Segundos desde a última vez que o jogador girou a visão com o dedo (a
## câmera de perto só volta para as costas do doce depois de um tempinho).
var _girou_ha := 99.0
## Dedos que começaram num botão (não giram a visão).
var _dedos_em_botao := {}
var _qualidade_antes := {}


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
	CenarioVila.estilo_desenho(self)
	# leve para o celular: menos faces nas peças pequenas e o cenário parado
	# juntado em poucos blocos (portas e nuvens se mexem, ficam de fora)
	JuntarMalhas.simplificar(self)
	JuntarMalhas.juntar(self, ["Folha", "Nuvem"])
	for boneco in find_children("*", "DoceAndante", true, false):
		boneco.otimizar()
	_criar_camera()
	_criar_interface()
	usar_camera(int(Progresso.config.get("camera_vila", Camera.AEREA)))


# --- Controles -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _entrando:
		_andar_na_entrada(delta)
		return
	var direcao := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var teclas := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	# no teclado anda; com Shift corre (no joystick, corre empurrando até o fim)
	direcao = (direcao + teclas).limit_length(1.0) * (1.0 if Input.is_key_pressed(KEY_SHIFT) else 0.8)
	direcao = (direcao + _joystick.vetor).limit_length(1.0)
	if modo_camera == Camera.PRIMEIRA_PESSOA:
		# para os lados vira; para cima/baixo anda para frente/trás
		_giro -= direcao.x * GIRO_JOYSTICK * delta
		jogador.andar(_frente() * -direcao.y, delta)
		jogador.virar_para_angulo(_giro + PI)
		return
	var direita := Vector3(cos(_giro), 0, -sin(_giro))
	jogador.andar(direita * direcao.x + _frente() * -direcao.y, delta)
	_girou_ha += delta
	if modo_camera == Camera.PERTO and direcao.y < -0.3 and _girou_ha > 1.5:
		# andando para frente: a câmera vai para as costas do doce, devagar
		var costas := atan2(-jogador.frente().x, -jogador.frente().z)
		_giro = lerp_angle(_giro, costas, minf(1.0, 1.5 * delta))


## Direção "para frente" da câmera, no chão.
func _frente() -> Vector3:
	return Vector3(-sin(_giro), 0, -cos(_giro))


func _process(delta: float) -> void:
	for nuvem: Node3D in _nuvens:  # nuvens passeando devagar
		nuvem.position.x = wrapf(nuvem.position.x + delta * 0.4, -34.0, 34.0)
	var cabeca := jogador.global_position + Vector3(0, ALTURA_OLHOS, 0)
	match modo_camera:
		Camera.AEREA:
			var alvo := jogador.global_position + CAMERA_DISTANCIA
			_camera.global_position = _camera.global_position.lerp(alvo, minf(1.0, CAMERA_SUAVIDADE * delta))
			_camera.look_at(_camera.global_position - CAMERA_DISTANCIA + Vector3(0, 0.8, 0))
		Camera.PERTO:
			var alvo := _posicao_perto(cabeca, PERTO_DISTANCIA, PERTO_ALTURA - ALTURA_OLHOS + 0.6)
			alvo = _sem_atravessar_paredes(cabeca, alvo)
			_camera.global_position = _camera.global_position.lerp(alvo, minf(1.0, 8.0 * delta))
			_camera.look_at(cabeca + _frente() * 1.5 + Vector3(0, _inclinacao * 2.0, 0))
		Camera.PRIMEIRA_PESSOA:
			_camera.global_position = cabeca + _frente() * 0.25
			_camera.look_at(_camera.global_position + _olhar_1p())


## Câmera de perto: gira em volta da cabeça do doce; olhando para cima ela
## desce, olhando para baixo ela sobe.
func _posicao_perto(cabeca: Vector3, distancia: float, altura: float) -> Vector3:
	var raio := Vector2(distancia, altura).length()
	var elevacao := clampf(atan2(altura, distancia) - _inclinacao, -0.05, 1.35)
	return cabeca - _frente() * raio * cos(elevacao) + Vector3(0, raio * sin(elevacao), 0)


## Para onde se olha em 1ª pessoa (frente inclinada para cima/baixo).
func _olhar_1p() -> Vector3:
	return _frente() * cos(_inclinacao) + Vector3(0, sin(_inclinacao), 0)


## Se um prédio ficar entre o doce e a câmera, a câmera chega mais perto.
func _sem_atravessar_paredes(de: Vector3, ate: Vector3) -> Vector3:
	var consulta := PhysicsRayQueryParameters3D.create(de, ate)
	consulta.exclude = [jogador.get_rid()]
	var batida := get_world_3d().direct_space_state.intersect_ray(consulta)
	if batida.is_empty():
		return ate
	# chega mais perto e sobe um pouco, para ver por cima do doce
	var perto: Vector3 = batida["position"] + (de - ate).normalized() * 0.3
	var encolheu := 1.0 - de.distance_to(perto) / maxf(de.distance_to(ate), 0.01)
	return perto + Vector3(0, encolheu * 1.8, 0)


## Troca a câmera (e salva a escolha).
func usar_camera(modo: int) -> void:
	modo_camera = modo as Camera
	jogador.mostrar_modelo(modo_camera != Camera.PRIMEIRA_PESSOA)
	_inclinacao = INCLINACAO_INICIAL_1P if modo_camera == Camera.PRIMEIRA_PESSOA else 0.0
	if modo_camera == Camera.AEREA:
		_giro = 0.0
	else:
		if ultima_porta.is_empty() and jogador.global_position.distance_to(Vector3(0, 0, 7)) < 0.5:
			jogador.olhar_para(Vector3.ZERO)  # no começo, virado para a praça
		# começa olhando para onde o doce está virado
		_giro = atan2(-jogador.frente().x, -jogador.frente().z)
	_camera.fov = 48.0 if modo_camera == Camera.AEREA else 62.0
	if modo_camera != Camera.AEREA:
		_camera.global_position = jogador.global_position + Vector3(0, ALTURA_OLHOS, 0) - _frente() * PERTO_DISTANCIA
	if Progresso.config.get("camera_vila", -1) != modo:
		Progresso.config["camera_vila"] = modo
		Progresso.salvar()


func proxima_camera() -> void:
	usar_camera((modo_camera + 1) % NOMES_CAMERA.size())
	Telas.mostrar_aviso("CÂMERA: " + NOMES_CAMERA[modo_camera])


## Toques de outros dedos (o celular só transforma o 1º dedo em "mouse"):
## com um dedo no joystick, outro dedo ainda aperta PULAR, ENTRAR e a câmera.
func _input(evento: InputEvent) -> void:
	if not evento is InputEventScreenTouch:
		return
	if not evento.pressed:
		_dedos_em_botao.erase(evento.index)
		return
	for botao: Button in [_botao_pular, _botao_entrar, _botao_camera]:
		if botao.is_visible_in_tree() and botao.get_global_rect().has_point(evento.position):
			_dedos_em_botao[evento.index] = true
			if evento.index != 0:  # o 1º dedo o próprio botão já recebe
				get_viewport().set_input_as_handled()
				if botao == _botao_pular:
					jogador.pular()
				elif botao == _botao_entrar:
					entrar(_porta_atual)
				else:
					proxima_camera()
			return


func _unhandled_input(evento: InputEvent) -> void:
	if _entrando:
		# um toque ou tecla durante a animação pula direto para dentro
		if (evento is InputEventScreenTouch or evento is InputEventMouseButton or evento is InputEventKey) \
				and evento.is_pressed():
			get_viewport().set_input_as_handled()
			_terminar_entrada()
		return
	# arrastar um dedo (fora do joystick) gira a visão nas câmeras de perto,
	# mesmo com o outro dedo andando no joystick
	if evento is InputEventScreenDrag and evento.index != _joystick.dedo \
			and not _dedos_em_botao.has(evento.index):
		_girar_visao(evento.relative)
		return
	if evento is InputEventMouseMotion and evento.device != InputEvent.DEVICE_ID_EMULATION \
			and evento.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_girar_visao(evento.relative)
		return
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_C:
		proxima_camera()
		return
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		jogador.pular()
		return
	var entrar_tecla: bool = evento is InputEventKey and evento.pressed and not evento.echo \
		and evento.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]
	if (entrar_tecla or evento.is_action_pressed("ui_accept")) and not _porta_atual.is_empty():
		get_viewport().set_input_as_handled()
		entrar(_porta_atual)


func _girar_visao(pixels: Vector2) -> void:
	if modo_camera == Camera.AEREA:
		return
	_giro -= pixels.x * GIRO_ARRASTO
	var limites := INCLINACAO_1P if modo_camera == Camera.PRIMEIRA_PESSOA else INCLINACAO_PERTO
	_inclinacao = clampf(_inclinacao - pixels.y * GIRO_ARRASTO, limites.x, limites.y)
	_girou_ha = 0.0


## Entra no prédio (abre a tela dele; o "voltar" de lá traz de volta à vila).
func entrar(id: String) -> void:
	var dados: Dictionary = PREDIOS.filter(func(p): return p["id"] == id)[0]
	if String(dados["cena"]).is_empty():
		jogador.comemorar()
		Telas.mostrar_aviso("EM BREVE: DOCE MATCH, O JOGO DAS PEÇAS DO OFFICE!")
		return
	if _entrando:
		return
	ultima_porta = id
	_entrar_animado(id, dados["cena"])


## Animação de entrar: o doce vai até a porta, ela abre, ele entra e a tela
## escurece. Um toque na tela (ou tecla) pula direto para dentro.
func _entrar_animado(id: String, cena: String) -> void:
	_entrando = true
	_botao_entrar.visible = false
	_cena_entrando = cena
	var predio: Dictionary = _portas[id]
	var folha: Node3D = predio["folha"]
	jogador.atravessar(true)
	# primeiro vai para o meio da frente da porta (fora do giro da folha),
	# depois entra
	_passos_entrada = [predio["porta"], predio["entrada"]]
	if modo_camera == Camera.PRIMEIRA_PESSOA:
		usar_camera(Camera.PERTO)
	var tween := create_tween()
	tween.tween_interval(0.1)
	tween.tween_property(folha, "rotation:y", deg_to_rad(-105), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	tween.tween_callback(_terminar_entrada)


func _terminar_entrada() -> void:
	if _cena_entrando.is_empty():
		return
	var cena := _cena_entrando
	_cena_entrando = ""
	Telas.abrir(cena)


## Anda sozinho pelos pontos da entrada (usado durante a animação).
func _andar_na_entrada(delta: float) -> void:
	if _passos_entrada.is_empty():
		jogador.andar(Vector3.ZERO, delta)
		return
	var alvo: Vector3 = _passos_entrada[0]
	var caminho := alvo - jogador.global_position
	caminho.y = 0.0
	if caminho.length() < 0.2:
		_passos_entrada.pop_front()
	jogador.andar(caminho.normalized() * 0.7, delta)


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
	ambiente.ambient_light_energy = 0.45  # luz em degraus: lado claro ~0,9, sombra ~0,45
	# sem reflexo do céu nas superfícies (deixava tudo desbotado)
	ambiente.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	add_child(mundo)
	# névoa rosinha ao longe: o horizonte se mistura com o céu
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color("#FFE3F0")
	ambiente.fog_density = 0.004
	ambiente.fog_sky_affect = 0.0
	CenarioVila.acabamento(ambiente)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = 0.45
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.55  # sombra suave, de desenho
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sol.directional_shadow_max_distance = 45.0
	add_child(sol)
	# antisserrilhado e 3D um pouco menor (volta ao normal ao sair da vila)
	_qualidade_antes = CenarioVila.qualidade_3d(get_viewport())


func _exit_tree() -> void:
	CenarioVila.restaurar_qualidade(get_viewport(), _qualidade_antes)


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
	# florzinhas pelo gramado
	var pontos := []
	tentativas = 0
	while pontos.size() < 90 and tentativas < 1500:
		tentativas += 1
		var ponto := Vector3(sorteio.randf_range(-19, 19), 0, sorteio.randf_range(-19, 19))
		if ponto.length() > 5.0 and _longe_dos_caminhos(ponto, 0.0) and _longe_dos_predios(ponto, 3.8):
			pontos.append(ponto)
	CenarioVila.flores(self, pontos, 17)
	# grama com volume: mais tufos perto da praça e dos caminhos, onde a
	# câmera passa; nada em cima de caminhos, praça e prédios
	var tufos := []
	tentativas = 0
	while tufos.size() < 5000 and tentativas < 20000:
		tentativas += 1
		var raio := sqrt(sorteio.randf()) * 19.5
		var angulo := sorteio.randf() * TAU
		var ponto := Vector3(cos(angulo) * raio, 0, sin(angulo) * raio)
		if absf(ponto.x) > 19.5 or absf(ponto.z) > 19.5 or ponto.length() < 4.6:
			continue
		if _longe_dos_caminhos(ponto, 0.15) and _longe_dos_predios(ponto, 3.6):
			tufos.append(ponto)
	CenarioVila.grama(self, tufos, 23)
	CenarioVila.morros(self, 31.0)
	_nuvens = CenarioVila.nuvens(self)
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


func _longe_dos_predios(ponto: Vector3, folga: float) -> bool:
	for dados in PREDIOS:
		if ponto.distance_to(dados["posicao"]) < folga:
			return false
	return true


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
	jogador.sombra_redonda = false  # o sol já faz sombra de verdade
	var id := Colecao.companheiro()
	jogador.id = id if not id.is_empty() else "brigadeiro"
	add_child(jogador)
	if _portas.has(ultima_porta):
		var porta: Vector3 = _portas[ultima_porta]["porta"]
		jogador.global_position = porta + porta.direction_to(Vector3.ZERO) * 0.4
		jogador.olhar_para(Vector3.ZERO)
		# acabou de sair: a porta está aberta e fecha atrás dele
		var folha: Node3D = _portas[ultima_porta]["folha"]
		folha.rotation.y = deg_to_rad(-105)
		var tween := create_tween()
		tween.tween_interval(0.5)
		tween.tween_property(folha, "rotation:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
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
		morador.sombra_redonda = false
		add_child(morador)
		var angulo := i * TAU / ids.size()
		morador.global_position = Vector3(cos(angulo) * 5.5, 0, sin(angulo) * 5.5)
		morador.definir_area_passeio(Rect2(-9, -9, 18, 16))


func _criar_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 48.0
	add_child(_camera)
	_camera.global_position = jogador.global_position + CAMERA_DISTANCIA


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
	casa.focus_mode = Control.FOCUS_NONE
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
	var camera := Button.new()
	camera.name = "Camera"
	camera.theme_type_variation = &"BotaoIconeAmarelo"
	camera.custom_minimum_size = Vector2(72, 72)
	camera.icon = ICONE_CAMERA
	camera.expand_icon = true
	camera.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camera.tooltip_text = "Trocar a câmera (C)"
	camera.focus_mode = Control.FOCUS_NONE
	camera.pressed.connect(proxima_camera)
	_botao_camera = camera
	topo.add_child(camera)

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
	_botao_entrar.focus_mode = Control.FOCUS_NONE
	_botao_entrar.pressed.connect(func(): entrar(_porta_atual))
	baixo.add_child(_botao_entrar)
	var pular := Button.new()
	pular.name = "Pular"
	pular.theme_type_variation = &"BotaoIconeAmarelo"
	pular.custom_minimum_size = Vector2(112, 112)
	pular.size_flags_vertical = Control.SIZE_SHRINK_END
	pular.icon = ICONE_PULAR
	pular.expand_icon = true
	pular.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pular.focus_mode = Control.FOCUS_NONE
	pular.button_down.connect(func(): jogador.pular())
	_botao_pular = pular
	baixo.add_child(pular)
	baixo.add_theme_constant_override("separation", 18)
