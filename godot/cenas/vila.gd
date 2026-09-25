class_name Vila
extends Node3D
## Vila dos Doces: o jogador anda com o seu doce (o companheiro da coleção)
## pela vila e entra nos prédios: Escola (quiz), Confeitaria (fábrica de doces),
## Troféus, Fliperama (Doce Match) e Laboratório do Office. Moradores passeiam pela praça.
## Anda com o joystick na tela ou com as setas/WASD (Shift corre); Espaço ou o
## botão PULAR pula; Enter/E entra no prédio.
##
## Três câmeras (botão no topo; a escolha fica salva):
## - AÉREA: de cima e de longe, sempre olhando para o norte.
## - PERTO: atrás do doce; acompanha quando ele anda para frente; arrastar o
##   dedo na tela gira a visão; se um prédio ficar no meio, ela se aproxima.
## - 1ª PESSOA: pelos olhos do doce; joystick para cima/baixo anda e para os
##   lados vira; arrastar o dedo também vira.

const METADE_MAPA := 38.0  # a vila vai até o Bairro dos Terrenos, o Lago e o Mirante
const CAMERA_DISTANCIA := Vector3(0, 7.5, 8.5)
const CAMERA_SUAVIDADE := 5.0
const CAMERA_DE_CIMA := Vector3(0, 13.0, 3.0)  # quando um prédio tapa a visão
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
const ICONE_MOEDA := Itens.MOEDA

## Prédios da vila. "cena" = tela aberta ao entrar ("" = ainda não existe).
const PREDIOS := [
	{"id": "escola", "nome": "ESCOLA", "posicao": Vector3(0, 0, -14), "parede": "#F4E038",
		"telhado": "#7E57B1", "cena": "niveis", "acao": "JOGAR O QUIZ"},
	{"id": "confeitaria", "nome": "CONFEITARIA", "posicao": Vector3(-13, 0, -2), "parede": "#FFB3D1",
		"telhado": "#E8364F", "cena": "cozinha", "acao": "ENTRAR NA CONFEITARIA"},
	{"id": "trofeus", "nome": "TROFÉUS", "posicao": Vector3(13, 0, -2), "parede": "#C9B3EC",
		"telhado": "#F2C230", "cena": "titulos", "acao": "VER TROFÉUS"},
	{"id": "fliperama", "nome": "FLIPERAMA", "posicao": Vector3(-10, 0, -13), "parede": "#8FD3F4",
		"telhado": "#5E3D8E", "cena": "doce_match", "acao": "JOGAR DOCE MATCH"},
	{"id": "laboratorio", "nome": "LABORATÓRIO", "posicao": Vector3(10, 0, -13), "parede": "#F3EEF9",
		"telhado": "#7E57B1", "cena": "laboratorio", "acao": "ENTRAR NO LABORATÓRIO"},
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
var _pos_antes := Vector3.ZERO
var _pos_agora := Vector3.ZERO
var _olhar := Vector3.ZERO
## Primeiros passos: seta em cima da porta do próximo prédio e uma dica.
var _seta: Node3D
var _dica: PanelContainer
var _interface: Control
var passo_tutorial := ""
## Caminhos além dos que saem das portas: avenida até os terrenos e ruas até
## o Lago de Chocolate e o Mirante do Sorvete. [de, até].
const CAMINHOS_EXTRA := [
	[Vector3(0, 0, 4.3), Vector3(0, 0, 12)],
	[Vector3(0, 0, 12), Vector3(-22.6, 0, 12)],
	[Vector3(0, 0, 12), Vector3(25.8, 0, 12)],
	[Vector3(3.2, 0, -3.0), Vector3(5.2, 0, -19.5)],
	[Vector3(-19, 0, -19.5), Vector3(19, 0, -19.5)],
	[Vector3(0, 0, -19.5), Vector3(0, 0, -35)],
]
## Onde ficam os presentes do dia (perto do lugar, do lado da vila).
const PRESENTES := {"lago": Vector3(-27.0, 0.13, 12), "mirante": Vector3(27.5, 0.1, 10.5)}
var _ponto_atual := ""  # lote ou presente perto do doce ("" = nenhum)
var _lotes := {}  # id -> Node3D
var _presentes := {}  # lugar -> Node3D
var _rotulos_producao := {}  # id do lote -> Label3D ("12 AÇÚCAR")
var _pas: Array[Node3D] = []  # pás dos moinhos (giram)
var _painel_lote: Control
var _tempo_rotulos := 0.0
var _alto := 0.0  # 0 = câmera aérea normal, 1 = de cima (prédio no meio)
var _borboletas: Array = []  # [{"no": Sprite3D, "centro", "raio", "velocidade", "fase"}]
var _tempo_vida := 0.0
var _brilhos_presente := {}  # lugar -> CPUParticles3D


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
		if dados["id"] == "confeitaria":
			BairroVila.anexos_confeitaria(predio["no"], Terrenos.estagio_confeitaria())
	for c in CAMINHOS_EXTRA:
		CenarioVila.caminho(self, c[0], c[1])
	_criar_bairro()
	_enfeitar()
	Telas.por_cima_fechou.connect(_atualizar_topo)  # voltou das missões/baús abertos por cima
	_criar_jogador()
	_criar_moradores()
	CenarioVila.estilo_desenho(self)
	# leve para o celular: menos faces nas peças pequenas e o cenário parado
	# juntado em poucos blocos (portas e nuvens se mexem, ficam de fora)
	JuntarMalhas.simplificar(self)
	JuntarMalhas.juntar(self, ["Folha", "Nuvem", "Lote", "Presente"])  # lotes e presentes mudam
	for no in _lotes.values() + _presentes.values():
		JuntarMalhas.juntar(no, ["Pas", "Tampa"])  # cada um no seu bloco (dá para remontar)
		_so_de_perto(no)
	for boneco in find_children("*", "DoceAndante", true, false):
		boneco.otimizar()
	_criar_vida()
	_criar_camera()
	_criar_interface()
	_criar_tutorial()
	_criar_avisos()
	usar_camera(int(Progresso.config.get("camera_vila", Camera.AEREA)))


# --- Controles -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_mover(delta)
	_guardar_posicao()


func _mover(delta: float) -> void:
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
	for pas in _pas:
		if is_instance_valid(pas):
			pas.rotation.z += delta * 0.8
	_animar_borboletas(delta)
	_tempo_rotulos += delta
	if _tempo_rotulos > 1.0:
		_tempo_rotulos = 0.0
		_atualizar_rotulos_producao()
	var pos := _pos_visual()
	var cabeca := pos + Vector3(0, ALTURA_OLHOS, 0)
	match modo_camera:
		Camera.AEREA:
			# prédio no meio (ex.: atrás da Escola): a câmera sobe e olha mais de cima
			var tapado := _tapado(cabeca, pos + CAMERA_DISTANCIA)
			_alto = lerpf(_alto, 1.0 if tapado else 0.0, minf(1.0, 3.0 * delta))
			var distancia := CAMERA_DISTANCIA.lerp(CAMERA_DE_CIMA, _alto)
			var alvo := pos + distancia
			_camera.global_position = _camera.global_position.lerp(alvo, minf(1.0, CAMERA_SUAVIDADE * delta))
			_camera.look_at(_camera.global_position - distancia + Vector3(0, 0.8, 0))
		Camera.PERTO:
			var alvo := _posicao_perto(cabeca, PERTO_DISTANCIA, PERTO_ALTURA - ALTURA_OLHOS + 0.6)
			alvo = _sem_atravessar_paredes(cabeca, alvo)
			# se uma parede ficou no meio, a câmera pula na hora (sem passar por dentro dela)
			if alvo.distance_to(cabeca) < _camera.global_position.distance_to(cabeca) - 0.05:
				_camera.global_position = alvo
			else:
				_camera.global_position = _camera.global_position.lerp(alvo, minf(1.0, 8.0 * delta))
			_camera.look_at(_olhar_suave(cabeca + _frente() * 1.5 + Vector3(0, _inclinacao * 2.0, 0), delta))
		Camera.PRIMEIRA_PESSOA:
			_camera.global_position = cabeca + _frente() * 0.25
			_camera.look_at(_camera.global_position + _olhar_1p())


## Câmera de perto: gira em volta da cabeça do doce; olhando para cima ela
## desce, olhando para baixo ela sobe.
## Qual prédio o tutorial aponta agora ("" = já fez tudo): primeiro o quiz
## (que dá moedas e açúcar), depois o laboratório, a confeitaria e por fim o
## Doce Match.
static func proximo_passo() -> String:
	if int(Progresso.estatisticas.get("partidas", 0)) == 0:
		return "escola"
	if Laboratorio.total_estrelas() == 0:
		return "laboratorio"
	if not Confeitaria.alguma_construida():
		return "confeitaria"
	if int(Progresso.estatisticas.get("match_partidas", 0)) == 0:
		return "fliperama"
	return ""


const DICAS := {
	"escola": "COMECE PELA ESCOLA: JOGUE O QUIZ PARA GANHAR MOEDAS E AÇÚCAR!",
	"laboratorio": "NO LABORATÓRIO VOCÊ USA O WORD E O EXCEL DE VERDADE. VAMOS?",
	"confeitaria": "AGORA VÁ À CONFEITARIA E MONTE SUA PANELA DE BRIGADEIRO!",
	"fliperama": "NO FLIPERAMA TEM O DOCE MATCH: TROQUE AÇÚCAR POR PONTOS!",
}


func _criar_tutorial() -> void:
	passo_tutorial = proximo_passo()
	if passo_tutorial == "":
		return
	var porta: Vector3 = _portas[passo_tutorial]["porta"]
	_seta = CenarioCozinha.seta(self)
	_seta.name = "SetaTutorial"
	_seta.scale = Vector3.ONE * 1.8
	_seta.position = porta - porta.normalized() * 1.0 + Vector3(0, 2.6, 0)
	var tween := _seta.create_tween().set_loops()
	tween.tween_property(_seta, "position:y", 3.2, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_seta, "position:y", 2.6, 0.5).set_trans(Tween.TRANS_SINE)
	_dica = PanelContainer.new()
	_dica.name = "Dica"
	_dica.theme_type_variation = &"EtiquetaAmarela"
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_dica.position.y = 84
	var texto := Label.new()
	texto.theme_type_variation = &"Titulo"
	texto.text = DICAS[passo_tutorial]
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(540, 0)
	texto.add_theme_font_size_override("font_size", 21)
	_dica.add_child(texto)
	_interface.add_child(_dica)
	_dica.grow_horizontal = Control.GROW_DIRECTION_BOTH


## Prédios com algo esperando o jogador (baú pronto no laboratório, bandeja
## cheia na confeitaria) ganham um "!" pulando em cima.
static func predios_com_aviso() -> Array:
	var lista := []
	if Laboratorio.baus_prontos() > 0:
		lista.append("laboratorio")
	if Confeitaria.alguma_construida():
		Confeitaria.atualizar()
		for m in Confeitaria.MAQUINAS:
			if Confeitaria.construida(m["id"]) and Confeitaria.bandeja(m["id"]) >= Confeitaria.capacidade_bandeja(m["id"]):
				lista.append("confeitaria")
				break
	return lista


func _criar_avisos() -> void:
	for id in predios_com_aviso():
		if id == passo_tutorial:
			continue  # a seta do tutorial já aponta para ele
		var porta: Vector3 = _portas[id]["porta"]
		var aviso := Label3D.new()
		aviso.name = "Aviso_" + id
		aviso.text = "!"
		aviso.font_size = 220
		aviso.pixel_size = 0.006
		aviso.outline_size = 40
		aviso.outline_modulate = Color("#5E3D8E")
		aviso.modulate = Color("#F4E038")
		aviso.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		aviso.no_depth_test = true
		aviso.position = porta - porta.normalized() * 1.0 + Vector3(0, 3.0, 0)
		add_child(aviso)
		var tween := aviso.create_tween().set_loops()
		tween.tween_property(aviso, "position:y", 3.5, 0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_property(aviso, "position:y", 3.0, 0.45).set_trans(Tween.TRANS_SINE)


func _posicao_perto(cabeca: Vector3, distancia: float, altura: float) -> Vector3:
	var raio := Vector2(distancia, altura).length()
	var elevacao := clampf(atan2(altura, distancia) - _inclinacao, -0.05, 1.35)
	return cabeca - _frente() * raio * cos(elevacao) + Vector3(0, raio * sin(elevacao), 0)


## Para onde se olha em 1ª pessoa (frente inclinada para cima/baixo).
func _olhar_1p() -> Vector3:
	return _frente() * cos(_inclinacao) + Vector3(0, sin(_inclinacao), 0)


## Se um prédio ficar entre o doce e a câmera, a câmera chega mais perto.
func _sem_atravessar_paredes(de: Vector3, ate: Vector3) -> Vector3:
	var perto := CenarioVila.camera_sem_parede(get_world_3d(), de, ate)
	if perto.is_equal_approx(ate):
		return ate
	# chegou mais perto: sobe um pouco, para ver por cima do doce (sem bater no alto)
	var encolheu := 1.0 - de.distance_to(perto) / maxf(de.distance_to(ate), 0.01)
	return CenarioVila.camera_sem_parede(get_world_3d(), perto, perto + Vector3(0, encolheu * 1.8, 0))


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
		Telas.mostrar_aviso("EM BREVE!")
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
	Audio.tocar("porta", randf_range(0.95, 1.05), -2.0)
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
	if is_instance_valid(_painel_lote):
		_fechar_painel_lote()
		return
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
	# luz ambiente vinda do céu (azulada em cima, rosada no horizonte): as
	# sombras ganham cor em vez de ficarem cinzas
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	ambiente.ambient_light_sky_contribution = 0.6
	ambiente.ambient_light_energy = 0.32
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
	sol.light_color = Color("#FFF0D6")  # sol de fim de tarde, quentinho
	sol.light_energy = 0.75 if CenarioVila.modo_leve() else 1.1
	sol.light_specular = 0.8
	sol.shadow_enabled = Qualidade.sombras()
	sol.shadow_opacity = 0.8
	sol.shadow_blur = 1.5  # borda da sombra macia
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if Qualidade.nivel() == Qualidade.ALTA \
		else DirectionalLight3D.SHADOW_ORTHOGONAL
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
	while colocados < 70 and tentativas < 2000:
		tentativas += 1
		var ponto := Vector3(sorteio.randf_range(-34, 34), 0, sorteio.randf_range(-34, 34))
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
	while pontos.size() < Qualidade.flores() and tentativas < 1500:
		tentativas += 1
		var ponto := Vector3(sorteio.randf_range(-34, 34), 0, sorteio.randf_range(-34, 34))
		if ponto.length() > 5.0 and _longe_dos_caminhos(ponto, 0.0) and _longe_dos_predios(ponto, 3.8):
			pontos.append(ponto)
	CenarioVila.flores(self, pontos, 17)
	# grama com volume: mais tufos perto da praça e dos caminhos, onde a
	# câmera passa; nada em cima de caminhos, praça e prédios
	var tufos := []
	tentativas = 0
	while tufos.size() < Qualidade.grama() and tentativas < 20000:
		tentativas += 1
		var raio := sqrt(sorteio.randf()) * 19.5
		var angulo := sorteio.randf() * TAU
		var ponto := Vector3(cos(angulo) * raio, 0, sin(angulo) * raio)
		if absf(ponto.x) > 19.5 or absf(ponto.z) > 19.5 or ponto.length() < 4.6:
			continue
		if _longe_dos_caminhos(ponto, 0.15) and _longe_dos_predios(ponto, 3.6):
			tufos.append(ponto)
	if not tufos.is_empty():
		CenarioVila.grama(self, tufos, 23)
	CenarioVila.morros(self, METADE_MAPA + 8.0)
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
	return _longe_dos_caminhos(ponto, folga) and _longe_dos_predios(ponto, 0.0)


func _longe_dos_predios(ponto: Vector3, folga: float) -> bool:
	for dados in PREDIOS:
		if ponto.distance_to(dados["posicao"]) < folga:
			return false
	# lotes, lago e mirante também
	for l in Terrenos.LOTES:
		var d: Vector3 = (ponto - l["posicao"]).abs()
		if d.x < Terrenos.TAMANHO_LOTE / 2.0 + folga * 0.5 and d.z < Terrenos.TAMANHO_LOTE / 2.0 + folga * 0.5:
			return false
	for lugar in Terrenos.LUGARES:
		if ponto.distance_to(Terrenos.LUGARES[lugar]["posicao"]) < 7.5 + folga * 0.5:
			return false
	return true


func _longe_dos_caminhos(ponto: Vector3, folga: float) -> bool:
	for c in CAMINHOS_EXTRA:
		var perto := Geometry3D.get_closest_point_to_segment(ponto, c[0], c[1])
		if ponto.distance_to(perto) < folga + 1.2:
			return false
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
	jogador.com_som = true
	var id := Colecao.companheiro()
	jogador.id = id if not id.is_empty() else "brigadeiro"
	jogador.nivel = Companheiros.nivel(jogador.id)
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
	for l in Terrenos.LOTES:
		if Terrenos.construcao(l["id"]) == "casa":
			_vizinho_da_casa(l["id"])


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
	_interface = raiz
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 18)
	raiz.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(coluna)

	# topo compacto: casa, nível/missões/baús, moedas e câmera numa linha só
	# (a vila fica à mostra; nada de faixa com o nome)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 10)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)
	var casa := Button.new()
	casa.name = "Casa"
	casa.theme_type_variation = &"BotaoIconeAmarelo"
	casa.custom_minimum_size = Vector2(54, 54)
	casa.icon = ICONE_CASA
	casa.expand_icon = true
	casa.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	casa.focus_mode = Control.FOCUS_NONE
	casa.tooltip_text = "Vila dos Doces: voltar ao início"
	casa.pressed.connect(Telas.ir_para.bind("inicio"))
	topo.add_child(casa)
	var progresso := BotoesProgresso.new()
	progresso.name = "Progresso"
	progresso.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(progresso)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	# açúcar e moedas (o açúcar vai para as máquinas da confeitaria)
	var saldos := PanelContainer.new()
	saldos.name = "Saldos"
	saldos.theme_type_variation = &"Etiqueta"
	saldos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	saldos.add_child(linha)
	Confeitaria.atualizar()
	for par in [[Itens.ACUCAR, str(Confeitaria.acucar()), "Acucar"], [ICONE_MOEDA, Jogo.formatar(Progresso.moedas), "Moedas"]]:
		var icone := TextureRect.new()
		icone.texture = par[0]
		icone.custom_minimum_size = Vector2(24, 24)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(icone)
		var valor := Label.new()
		valor.name = par[2]
		valor.theme_type_variation = &"TituloClaro"
		valor.add_theme_font_size_override("font_size", 26)
		valor.text = par[1]
		linha.add_child(valor)
		if par[2] == "Acucar":
			var espaco_saldo := Control.new()
			espaco_saldo.custom_minimum_size = Vector2(8, 0)
			linha.add_child(espaco_saldo)
	topo.add_child(saldos)
	var camera := Button.new()
	camera.name = "Camera"
	camera.theme_type_variation = &"BotaoIconeAmarelo"
	camera.custom_minimum_size = Vector2(54, 54)
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
	_botao_entrar.custom_minimum_size = Vector2(250, 68)
	_botao_entrar.add_theme_font_size_override("font_size", 26)
	_botao_entrar.size_flags_vertical = Control.SIZE_SHRINK_END
	_botao_entrar.visible = false
	_botao_entrar.focus_mode = Control.FOCUS_NONE
	_botao_entrar.pressed.connect(func(): agir(_ponto_atual) if _ponto_atual != "" else entrar(_porta_atual))
	baixo.add_child(_botao_entrar)
	var pular := Button.new()
	pular.name = "Pular"
	pular.theme_type_variation = &"BotaoIconeAmarelo"
	pular.custom_minimum_size = Vector2(88, 88)
	pular.size_flags_vertical = Control.SIZE_SHRINK_END
	pular.icon = ICONE_PULAR
	pular.expand_icon = true
	pular.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pular.focus_mode = Control.FOCUS_NONE
	pular.button_down.connect(func(): jogador.pular())
	_botao_pular = pular
	baixo.add_child(pular)
	baixo.add_theme_constant_override("separation", 18)


# --- Câmera suave --------------------------------------------------------------
# O doce anda no ritmo da física; a câmera, a cada quadro da tela. Seguir a
# posição "crua" fazia a tela tremer na câmera de terceira pessoa (o ponto
# para onde ela olha pulava a cada passo da física). A câmera segue uma
# posição interpolada entre os dois últimos passos e olha para um ponto suave.

func _guardar_posicao() -> void:
	_pos_antes = _pos_agora
	_pos_agora = jogador.global_position


## Posição do doce para a câmera, sem os "degraus" da física.
func _pos_visual() -> Vector3:
	var real := jogador.global_position
	if not is_physics_processing() or _pos_agora.distance_to(real) > 1.0:
		_pos_antes = real  # teleporte (porta, começo) ou teste: sem interpolar
		_pos_agora = real
		return real
	return _pos_antes.lerp(_pos_agora, Engine.get_physics_interpolation_fraction())


func _olhar_suave(alvo: Vector3, delta: float) -> Vector3:
	if _olhar.distance_to(alvo) > 3.0:
		_olhar = alvo
	else:
		_olhar = _olhar.lerp(alvo, minf(1.0, 14.0 * delta))
	return _olhar


## Nível, missões, baús, açúcar e moedas do topo (depois de missões/baús).
func _atualizar_topo() -> void:
	var progresso := find_child("Progresso", true, false) as BotoesProgresso
	if progresso:
		progresso.atualizar()
	var acucar := find_child("Acucar", true, false) as Label
	if acucar:
		acucar.text = str(Confeitaria.acucar())
	var moedas := find_child("Moedas", true, false) as Label
	if moedas:
		moedas.text = Jogo.formatar(Progresso.moedas)


# --- Bairro dos Terrenos, Lago e Mirante (ver Terrenos e BairroVila) ----------------

func _criar_bairro() -> void:
	BairroVila.placa_direcoes(self, Vector3(2.4, 0, 9.6))
	for l in Terrenos.LOTES:
		var no := Node3D.new()
		no.name = "Lote_" + l["id"]
		no.position = l["posicao"]
		add_child(no)
		var area := BairroVila.area(no, "Area", Vector3.ZERO, Vector3(Terrenos.TAMANHO_LOTE + 1.5, 2, Terrenos.TAMANHO_LOTE + 1.5))
		area.body_entered.connect(_chegou_no_ponto.bind(l["id"]))
		area.body_exited.connect(_saiu_do_ponto.bind(l["id"]))
		_lotes[l["id"]] = no
		BairroVila.cerca(self, l["id"])
		_montar_lote(l["id"], false)
	for lugar in Terrenos.LUGARES:
		var centro: Vector3 = Terrenos.LUGARES[lugar]["posicao"]
		if lugar == "lago":
			BairroVila.lago(self, centro)
		else:
			BairroVila.mirante(self, centro)
		BairroVila._texto(self, Terrenos.LUGARES[lugar]["nome"], centro + Vector3(0, 5.2 if lugar == "mirante" else 3.2, 0), 220)
		var no := Node3D.new()
		no.name = "Presente_" + lugar
		no.position = PRESENTES[lugar]
		add_child(no)
		var area := BairroVila.area(no, "Area", Vector3.ZERO, Vector3(3, 2, 3))
		area.body_entered.connect(_chegou_no_ponto.bind("presente_" + lugar))
		area.body_exited.connect(_saiu_do_ponto.bind("presente_" + lugar))
		_presentes[lugar] = no
		BairroVila.presente(no, not Terrenos.presente_disponivel(lugar))


## (Re)monta o lote com o que tem nele agora; `desenho` aplica o contorno de
## desenho animado (na montagem da vila isso é feito de uma vez só no fim).
func _montar_lote(id: String, desenho := true) -> void:
	var no: Node3D = _lotes[id]
	BairroVila.montar_lote(no, id)
	_pas.assign(find_children("Pas", "Node3D", true, false))
	if _rotulos_producao.has(id) and is_instance_valid(_rotulos_producao[id]):
		_rotulos_producao[id].queue_free()
	_rotulos_producao.erase(id)
	if Terrenos.produz(id) != "":
		var rotulo := BairroVila._texto(self, "", no.position + Vector3(0, 5.2, 0), 150)
		rotulo.name = "Producao_" + id
		_rotulos_producao[id] = rotulo
	_atualizar_rotulos_producao()
	if desenho:
		CenarioVila.estilo_desenho(no)
		JuntarMalhas.juntar(no, ["Pas"])
		_so_de_perto(no)


func _atualizar_rotulos_producao() -> void:
	for id in _rotulos_producao:
		var rotulo: Label3D = _rotulos_producao[id]
		if not is_instance_valid(rotulo):
			continue
		var pronto := Terrenos.pronto(id)
		rotulo.visible = pronto > 0
		rotulo.text = "%d %s" % [pronto, "AÇÚCAR" if Terrenos.produz(id) == "acucar" else "MOEDAS"]
		if pronto >= Terrenos.maximo(id):
			rotulo.text += " · CHEIO!"
	if _ponto_atual != "" and not is_instance_valid(_painel_lote):
		_botao_entrar.text = _texto_ponto(_ponto_atual)


func _chegou_no_ponto(corpo: Node3D, id: String) -> void:
	if corpo != jogador:
		return
	_ponto_atual = id
	_porta_atual = ""
	_botao_entrar.text = _texto_ponto(id)
	_botao_entrar.visible = true
	_botao_entrar.pivot_offset = _botao_entrar.size / 2
	_botao_entrar.scale = Vector2.ONE * 0.7
	_botao_entrar.create_tween().tween_property(_botao_entrar, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if id.begins_with("lote"):
		Telas.dica_primeira_vez("terrenos", "BAIRRO DOS TERRENOS",
			"Compre um terreno com moedas e escolha o que construir: o MOINHO faz açúcar e o COFRE junta moedas sozinhos, é só passar aqui para coletar. A CASA traz um vizinho novo!")


func _saiu_do_ponto(corpo: Node3D, id: String) -> void:
	if corpo == jogador and _ponto_atual == id:
		_ponto_atual = ""
		_botao_entrar.visible = false


## Texto do botão perto de um lote ou presente.
func _texto_ponto(id: String) -> String:
	if id.begins_with("presente_"):
		return "ABRIR PRESENTE" if Terrenos.presente_disponivel(id.trim_prefix("presente_")) else "PRESENTE: VOLTE AMANHÃ"
	if not Terrenos.comprado(id):
		return "COMPRAR TERRENO (%d)" % Terrenos.lote(id)["preco"]
	var tipo := Terrenos.construcao(id)
	if tipo == "":
		return "CONSTRUIR"
	var pronto := Terrenos.pronto(id)
	if pronto > 0:
		return "COLETAR %d %s" % [pronto, "AÇÚCAR" if Terrenos.produz(id) == "acucar" else "MOEDAS"]
	return Terrenos.CONSTRUCOES[tipo]["nome"]


## Ação do botão perto de um lote ou presente.
func agir(id: String) -> void:
	if id.begins_with("presente_"):
		var lugar := id.trim_prefix("presente_")
		var premio := Terrenos.abrir_presente(lugar)
		if premio.is_empty():
			Telas.mostrar_aviso("VOCÊ JÁ ABRIU O DE HOJE. VOLTE AMANHÃ!")
			return
		Audio.tocar("caixa")
		jogador.comemorar()
		BairroVila.presente(_presentes[lugar], true)
		if _brilhos_presente.has(lugar) and is_instance_valid(_brilhos_presente[lugar]):
			_brilhos_presente[lugar].emitting = false
		CenarioVila.estilo_desenho(_presentes[lugar])
		Telas.mostrar_aviso("PRESENTE: +%d AÇÚCAR  +%d MOEDAS" % [premio["acucar"], premio["moedas"]])
		_depois_de_agir()
		return
	if not Terrenos.comprado(id):
		var preco: int = Terrenos.lote(id)["preco"]
		if Progresso.moedas < preco:
			Telas.mostrar_aviso("FALTAM MOEDAS: O TERRENO CUSTA %d" % preco)
			return
		if not await Telas.confirmar("COMPRAR TERRENO?", "Custa %d moedas. Depois você escolhe o que construir nele." % preco, "COMPRAR", "AGORA NÃO"):
			return
		if Terrenos.comprar(id):
			Audio.tocar("construir")
			_montar_lote(id)
			_depois_de_agir()
			abrir_construcoes(id)
		return
	var tipo := Terrenos.construcao(id)
	if tipo == "":
		abrir_construcoes(id)
		return
	if Terrenos.pronto(id) > 0:
		var quanto := Terrenos.coletar(id)
		Audio.tocar("moeda")
		Telas.mostrar_aviso("+%d %s" % [quanto, "AÇÚCAR" if Terrenos.produz(id) == "acucar" else "MOEDAS"])
		_depois_de_agir()
		return
	if Terrenos.produz(id) != "":
		_abrir_producao(id)
	else:
		jogador.comemorar()
		Telas.mostrar_aviso(Terrenos.CONSTRUCOES[tipo]["texto"].to_upper())


func _depois_de_agir() -> void:
	_atualizar_topo()
	_atualizar_rotulos_producao()
	if _ponto_atual != "":
		_botao_entrar.text = _texto_ponto(_ponto_atual)


## Painel com o que dá para construir no lote.
func abrir_construcoes(id: String) -> void:
	var coluna := _abrir_painel_lote("O QUE CONSTRUIR AQUI?")
	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	coluna.add_child(grade)
	for tipo in Terrenos.CONSTRUCOES:
		var dados: Dictionary = Terrenos.CONSTRUCOES[tipo]
		var botao := Button.new()
		botao.name = "Construir_" + tipo
		botao.custom_minimum_size = Vector2(250, 120)
		botao.theme_type_variation = &"BotaoRoxo" if Progresso.moedas < int(dados["preco"]) else &"Button"
		botao.text = "%s\n%d MOEDAS\n%s" % [dados["nome"], dados["preco"], dados["texto"]]
		botao.add_theme_font_size_override("font_size", 19)
		botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		botao.focus_mode = Control.FOCUS_NONE
		botao.pressed.connect(func():
			if not Terrenos.construir(id, tipo):
				Telas.mostrar_aviso("FALTAM MOEDAS: CUSTA %d" % dados["preco"])
				return
			Audio.tocar("construir")
			_fechar_painel_lote()
			_montar_lote(id)
			if tipo == "casa":
				_vizinho_da_casa(id)
			jogador.comemorar()
			Telas.mostrar_aviso("%s CONSTRUÍDO!" % dados["nome"])
			_depois_de_agir())
		grade.add_child(botao)


## Painel do moinho/cofre: quanto produz, quanto guarda e o botão de melhorar.
func _abrir_producao(id: String) -> void:
	var tipo := Terrenos.construcao(id)
	var coluna := _abrir_painel_lote("%s · NÍVEL %d" % [Terrenos.CONSTRUCOES[tipo]["nome"], Terrenos.nivel(id)])
	var coisa := "AÇÚCAR" if Terrenos.produz(id) == "acucar" else "MOEDAS"
	var info := Label.new()
	info.theme_type_variation = &"SubtituloClaro"
	info.add_theme_font_size_override("font_size", 28)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.text = "FAZ %d %s POR HORA E GUARDA ATÉ %d.\nPRONTO AGORA: %d" % [Terrenos.por_hora(id), coisa, Terrenos.maximo(id), Terrenos.pronto(id)]
	coluna.add_child(info)
	var preco := Terrenos.preco_melhoria(id)
	if preco > 0:
		var melhorar := Button.new()
		melhorar.name = "Melhorar"
		melhorar.custom_minimum_size = Vector2(420, 70)
		melhorar.focus_mode = Control.FOCUS_NONE
		melhorar.text = "MELHORAR PARA NÍVEL %d (%d MOEDAS)" % [Terrenos.nivel(id) + 1, preco]
		melhorar.pressed.connect(func():
			if not Terrenos.melhorar(id):
				Telas.mostrar_aviso("FALTAM MOEDAS: CUSTA %d" % preco)
				return
			Audio.tocar("construir")
			_fechar_painel_lote()
			_montar_lote(id)
			jogador.comemorar()
			Telas.mostrar_aviso("AGORA É NÍVEL %d!" % Terrenos.nivel(id))
			_depois_de_agir())
		coluna.add_child(melhorar)
	else:
		var maximo := Label.new()
		maximo.theme_type_variation = &"TituloClaro"
		maximo.add_theme_font_size_override("font_size", 30)
		maximo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		maximo.text = "NÍVEL MÁXIMO!"
		coluna.add_child(maximo)


func _abrir_painel_lote(titulo: String) -> VBoxContainer:
	_fechar_painel_lote()
	var camada := Control.new()
	camada.name = "PainelLote"
	camada.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interface.add_child(camada)
	_painel_lote = camada
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.55)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(centro)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	painel.add_child(coluna)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 44)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.text = titulo
	coluna.add_child(rotulo)
	var fechar := Button.new()
	fechar.name = "FecharPainel"
	fechar.text = "FECHAR"
	fechar.theme_type_variation = &"Alternativa"
	fechar.custom_minimum_size = Vector2(200, 64)
	fechar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.pressed.connect(_fechar_painel_lote)
	coluna.add_child(fechar)
	coluna.move_child.call_deferred(fechar, -1)  # sempre por último
	return coluna


func _fechar_painel_lote() -> void:
	if is_instance_valid(_painel_lote):
		_painel_lote.queue_free()
	_painel_lote = null


## Vizinho novo que passeia na frente da casa construída no lote.
func _vizinho_da_casa(id: String) -> void:
	var vizinhos := ["jujuba", "beijinho", "marshmallow", "pacoca", "cocada", "sorvete"]
	var k := Terrenos.LOTES.map(func(l): return l["id"]).find(id)
	var posicao: Vector3 = Terrenos.lote(id)["posicao"]
	var aberto: Vector3 = Terrenos.lote(id)["aberto"]
	var frente := aberto * (Terrenos.TAMANHO_LOTE / 2.0 + 1.5)
	var vizinho := DoceAndante.new()
	vizinho.name = "Vizinho_" + id
	vizinho.id = vizinhos[k % vizinhos.size()]
	vizinho.passeando = true
	vizinho.sombra_redonda = false
	add_child(vizinho)
	vizinho.global_position = posicao + frente
	var centro := posicao + frente
	var largura := Vector2(6.0, 2.0) if absf(aberto.z) > 0.5 else Vector2(2.0, 6.0)
	vizinho.definir_area_passeio(Rect2(centro.x - largura.x / 2, centro.z - largura.y / 2, largura.x, largura.y))


## Tem parede (prédio) entre a cabeça do doce e o ponto da câmera?
func _tapado(de: Vector3, ate: Vector3) -> bool:
	var consulta := PhysicsRayQueryParameters3D.create(de, ate, 1)
	return not get_world_3d().direct_space_state.intersect_ray(consulta).is_empty()


## Lotes e presentes longe da câmera não são desenhados (leve no celular).
func _so_de_perto(no: Node3D) -> void:
	for malha: GeometryInstance3D in no.find_children("*", "GeometryInstance3D", true, false):
		malha.visibility_range_end = 45.0
		malha.visibility_range_end_margin = 5.0


# --- Vida na vila: borboletas, respingos da fonte, brilho dos presentes -------------

const BORBOLETA := preload("res://assets/icones/borboleta.svg")
const BRILHO := preload("res://assets/doce_match/brilho.svg")
const CORES_BORBOLETA := ["#FF7EB6", "#FFD23F", "#7FD6FF", "#B98CFF", "#FF9F5A", "#8BE38B"]


func _criar_vida() -> void:
	if not Telas.animacoes_continuas or Qualidade.nivel() == Qualidade.BAIXA:
		return
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 42
	var quantas := 10 if Qualidade.nivel() == Qualidade.MEDIA else 18
	for i in quantas:
		var borboleta := Sprite3D.new()
		borboleta.name = "Borboleta"
		borboleta.texture = BORBOLETA
		borboleta.pixel_size = 0.006
		borboleta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		borboleta.shaded = false
		borboleta.modulate = Color(CORES_BORBOLETA[i % CORES_BORBOLETA.size()])
		add_child(borboleta)
		var angulo := sorteio.randf() * TAU
		var distancia := sorteio.randf_range(6.0, 26.0)
		_borboletas.append({"no": borboleta, "centro": Vector3(cos(angulo) * distancia, 0, sin(angulo) * distancia),
			"raio": sorteio.randf_range(1.5, 4.0), "velocidade": sorteio.randf_range(0.25, 0.6),
			"fase": sorteio.randf() * TAU})
	_respingos_da_fonte()
	for lugar in _presentes:
		var brilho := _faiscas(_presentes[lugar], Vector3(0, 0.9, 0), Color("#FFE27A"))
		brilho.emitting = Terrenos.presente_disponivel(lugar)
		_brilhos_presente[lugar] = brilho


func _animar_borboletas(delta: float) -> void:
	_tempo_vida += delta
	for b in _borboletas:
		var t: float = _tempo_vida * b["velocidade"] + b["fase"]
		var no: Sprite3D = b["no"]
		# voo em "oito", subindo e descendo, batendo as asas
		no.position = b["centro"] + Vector3(sin(t) * b["raio"], 0.9 + sin(t * 2.3) * 0.35 + 0.3, sin(t * 2.0) * b["raio"] * 0.6)
		no.scale = Vector3(0.35 + absf(sin(_tempo_vida * 14.0 + b["fase"])) * 0.65, 1.0, 1.0)


## Pingos de chocolate caindo do pratinho de cima da fonte da praça.
func _respingos_da_fonte() -> void:
	var gotas := CPUParticles3D.new()
	gotas.name = "RespingosFonte"
	gotas.position = Vector3(0, 2.35, 0)
	gotas.amount = 36
	gotas.lifetime = 0.55
	gotas.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	gotas.emission_ring_axis = Vector3.UP
	gotas.emission_ring_radius = 0.95
	gotas.emission_ring_inner_radius = 0.85
	gotas.emission_ring_height = 0.02
	gotas.direction = Vector3.DOWN
	gotas.spread = 8.0
	gotas.initial_velocity_min = 0.2
	gotas.initial_velocity_max = 0.6
	gotas.gravity = Vector3(0, -6.0, 0)
	var gota := SphereMesh.new()
	gota.radius = 0.04
	gota.height = 0.1
	gota.radial_segments = 6
	gota.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#5A2E17")
	mat.roughness = 0.15
	gota.material = mat
	gotas.mesh = gota
	add_child(gotas)


## Faíscas douradas subindo (presente do dia esperando ser aberto).
func _faiscas(pai: Node3D, posicao: Vector3, cor: Color) -> CPUParticles3D:
	var faiscas := CPUParticles3D.new()
	faiscas.name = "Faiscas"
	faiscas.position = posicao
	faiscas.amount = 14
	faiscas.lifetime = 1.4
	faiscas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	faiscas.emission_sphere_radius = 0.6
	faiscas.direction = Vector3.UP
	faiscas.spread = 25.0
	faiscas.initial_velocity_min = 0.4
	faiscas.initial_velocity_max = 0.9
	faiscas.gravity = Vector3.ZERO
	faiscas.scale_amount_min = 0.6
	faiscas.scale_amount_max = 1.2
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = BRILHO
	mat.albedo_color = cor
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	faiscas.mesh = quad
	var sumir := Gradient.new()
	sumir.set_color(0, Color(1, 1, 1, 1))
	sumir.set_color(1, Color(1, 1, 1, 0))
	faiscas.color_ramp = sumir
	pai.add_child(faiscas)
	return faiscas
