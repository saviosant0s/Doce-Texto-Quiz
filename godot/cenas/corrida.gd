extends Node3D
## CORRIDA DE DOCES (a Pista de Corrida da vila; regras em scripts/corrida.gd).
## - INÍCIO: a câmera passeia pela largada; o painel mostra os rivais, o
##   recorde e o prêmio. CORRER! começa a contagem (o semáforo acende).
## - CORRIDA: a câmera vai atrás do seu kart. ◀ ▶ (ou o teclado: A/D,
##   setas) viram; o kart acelera sozinho. Nos PORTAIS DO QUIZ a pergunta
##   aparece em cima e tudo fica em câmera lenta: toque na resposta (ou 1 a
##   4) e o kart vai sozinho para a faixa colorida dela.
## - FIM: o pódio da corrida, o prêmio e CORRER DE NOVO.
## A pista inteira é montada por código (fitas de malha ao longo da curva).

const ICONE_VOLTAR := preload("res://assets/icones/voltar.svg")
const ICONE_SETA := preload("res://assets/icones/avancar.svg")
const ICONE_RELOGIO := preload("res://assets/icones/relogio.svg")
const FOTOS := "res://assets/doces_3d/fotos/%s.png"
const CORES_KARTS := ["#F4E038", "#FF6FAE", "#6FD3FF", "#7BE07B"]  # o 0 é o do jogador
const PASSO := 2.0  # metros entre os pedaços das fitas da pista
const CAMERA_ATRAS := 7.2
const CAMERA_ALTURA := 3.0
const FOV := 64.0
const FOV_TURBO := 78.0
const LAGO := Vector3(78, 0, -93)
const LAGO_RAIOS := Vector2(34, 19)
const VERDE := Color("#7BE07B")
const VERMELHO := Color("#FF5A5A")

var corrida: Corrida
var estado := "inicio"  # "inicio", "correndo", "fim"
var _karts: Array[Kart3D] = []
var _x_antes: Array[float] = []
var _giros: Array[float] = []
var _camera: Camera3D
var _olhar := Vector3.ZERO
var _tremor := 0.0
var _relogio := 0.0
var _cubos: MultiMesh  # os cubos de açúcar (desenhados de uma vez só)
var _cubos_lugar: Array[Vector3] = []
var _blocos_nos: Array[Node3D] = []
var _paineis: Array = []  # por portal da pista: [MeshInstance3D x4]
var _semaforo: Array[StandardMaterial3D] = []
var _mat_setas: StandardMaterial3D
var _karts_no: Node3D
var _qualidade_antes := {}
var _dedos := {}  # dedo na tela -> -1 (esquerda) / 1 (direita)
var _mouse_lado := 0
var _ultima_contagem := 99
var _ranking_relogio := 0.0
# interface
var _hud: Control
var _rotulo_volta: Label
var _rotulo_tempo: Label
var _rotulo_cubos: Label
var _rotulo_lugar: Label
var _lista: VBoxContainer
var _quadro: PanelContainer
var _enunciado: Label
var _cartoes: Array[Button] = []
var _barra_portal: ProgressBar
var _botoes_lado: Array[Control] = []
var _painel: Control


func _ready() -> void:
	corrida = Corrida.new()
	_criar_ambiente()
	_montar_pista()
	_montar_cenario()
	_montar_coisas()
	_karts_no = Node3D.new()
	_karts_no.name = "Karts"
	add_child(_karts_no)
	CenarioVila.estilo_desenho(self)
	# leve para o celular: o cenário parado vira poucos blocos (o que se mexe fica de fora)
	JuntarMalhas.simplificar(self)
	JuntarMalhas.juntar(self, ["Karts", "Cubos", "Blocos", "Painel", "Semaforo"])
	_qualidade_antes = CenarioVila.qualidade_3d(get_viewport())
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 420.0
	add_child(_camera)
	_criar_interface()
	mostrar_inicio()
	Telas.dica_primeira_vez("corrida", "CORRIDA DE DOCES",
		"O kart acelera sozinho: use ◀ ▶ para virar. Pegue as setas (turbo) e os cubos de açúcar e fuja das poças e dos blocos de gelatina. Nos PORTAIS DO QUIZ tudo fica lento: toque na resposta certa e passe pela faixa dela para ganhar TURBO!")


func _exit_tree() -> void:
	CenarioVila.restaurar_qualidade(get_viewport(), _qualidade_antes)


func ao_voltar() -> void:
	if is_instance_valid(_painel) and _painel.name == "Inicio":
		Telas.voltar()
	elif estado == "correndo":
		mostrar_inicio()  # desistiu: sem prêmio
	else:
		Telas.voltar()


# --- Mundo ------------------------------------------------------------------------------

func _criar_ambiente() -> void:
	var ambiente := Environment.new()
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("#6FB8F0")
	ceu.sky_horizon_color = Color("#FFD9EC")
	ceu.ground_horizon_color = Color("#FFD9EC")
	ceu.ground_bottom_color = Color("#86C96F")
	var sky := Sky.new()
	sky.sky_material = ceu
	ambiente.background_mode = Environment.BG_SKY
	ambiente.sky = sky
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color("#FFF1F7")
	ambiente.ambient_light_energy = 0.5 if CenarioVila.modo_leve() else 0.65
	# névoa rosada ao longe (esconde a borda do mundo)
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color("#FFE1EE")
	ambiente.fog_density = 0.0035
	ambiente.fog_sky_affect = 0.0
	CenarioVila.acabamento(ambiente)
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	add_child(mundo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_color = Color("#FFF4E0")
	sol.light_energy = 0.8 if CenarioVila.modo_leve() else 1.15
	sol.shadow_enabled = Qualidade.sombras()
	sol.shadow_opacity = 0.65
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sol.directional_shadow_max_distance = 45.0
	add_child(sol)


## Fita de malha ao longo da pista, de `de_x` a `ate_x` (de lado), `acima`
## metros acima do chão da pista, entre `s_de` e `s_ate` (metros). UV: u de 0
## a 1 de um lado ao outro; v = metros / `v_metros`.
func _fita(pai: Node3D, nome: String, de_x: float, ate_x: float, acima: float, mat: Material,
		v_metros: float, s_de := 0.0, s_ate := -1.0) -> MeshInstance3D:
	if s_ate < 0.0:
		s_ate = corrida.comprimento
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := maxi(1, ceili((s_ate - s_de) / PASSO))
	var passo := (s_ate - s_de) / n
	for i in n:
		var s0 := s_de + i * passo
		var s1 := s0 + passo
		var cima0 := corrida.lado(s0).cross(corrida.frente(s0))
		var cima1 := corrida.lado(s1).cross(corrida.frente(s1))
		var a0 := corrida.ponto(s0, de_x) + Vector3.UP * acima
		var b0 := corrida.ponto(s0, ate_x) + Vector3.UP * acima
		var a1 := corrida.ponto(s1, de_x) + Vector3.UP * acima
		var b1 := corrida.ponto(s1, ate_x) + Vector3.UP * acima
		var v0 := s0 / v_metros
		var v1 := s1 / v_metros
		for vertice in [[a0, Vector2(0, v0), cima0], [a1, Vector2(0, v1), cima1], [b0, Vector2(1, v0), cima0],
				[b0, Vector2(1, v0), cima0], [a1, Vector2(0, v1), cima1], [b1, Vector2(1, v1), cima1]]:
			st.set_normal(vertice[2])
			st.set_uv(vertice[1])
			st.add_vertex(vertice[0])
	var no := MeshInstance3D.new()
	no.name = nome
	no.mesh = st.commit()
	no.material_override = mat
	pai.add_child(no)
	return no


## Paredinha em pé na beira da pista (`lado` -1 ou 1), de `cima` (acima da
## pista) até a altura `fundo` (no mundo), onde a pista está a mais de
## `minimo` metros do chão. Vira o barranco de wafer da montanha e a lateral
## da ponte.
func _saia(pai: Node3D, lado: int, mat: Material, minimo: float, profundidade: float, so_lago: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := lado * (Corrida.MEIA_LARGURA + 0.9)
	var n := ceili(corrida.comprimento / PASSO)
	var passo := corrida.comprimento / n
	var algum := false
	for i in n:
		var s0 := i * passo
		var s1 := s0 + passo
		var t0 := corrida.ponto(s0, x) + Vector3.UP * 0.1
		var t1 := corrida.ponto(s1, x) + Vector3.UP * 0.1
		if minf(t0.y, t1.y) < minimo or (corrida.zona(s0)["id"] == "lago") != so_lago:
			continue
		algum = true
		var f0 := Vector3(t0.x, maxf(-0.3, t0.y - profundidade), t0.z)
		var f1 := Vector3(t1.x, maxf(-0.3, t1.y - profundidade), t1.z)
		var normal := corrida.lado(s0) * lado
		for vertice in [[t0, Vector2(s0 / 4.0, 0)], [t1, Vector2(s1 / 4.0, 0)], [f0, Vector2(s0 / 4.0, 1)],
				[f0, Vector2(s0 / 4.0, 1)], [t1, Vector2(s1 / 4.0, 0)], [f1, Vector2(s1 / 4.0, 1)]]:
			st.set_normal(normal)
			st.set_uv(vertice[1])
			st.add_vertex(vertice[0])
	if not algum:
		return
	var no := MeshInstance3D.new()
	no.name = "Barranco"
	no.mesh = st.commit()
	no.material_override = mat
	pai.add_child(no)


func _montar_pista() -> void:
	var pista := Node3D.new()
	pista.name = "Pista"
	add_child(pista)
	var w := Corrida.MEIA_LARGURA
	var estrada := StandardMaterial3D.new()
	estrada.albedo_texture = _textura_estrada()
	estrada.roughness = 0.8
	estrada.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	estrada.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fita(pista, "Estrada", -w, w, 0.06, estrada, 12.0)
	# zebras de bala (vermelho e branco) dos dois lados
	var zebra := StandardMaterial3D.new()
	zebra.albedo_texture = Pecas3D.faixas([Color("#E8364F"), Color("#FFFFFF")], 2, 16)
	zebra.roughness = 0.35
	zebra.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	zebra.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fita(pista, "Zebra", -w - 0.9, -w, 0.1, zebra, 2.0)
	_fita(pista, "Zebra", w, w + 0.9, 0.1, zebra, 2.0)
	# linha de chegada quadriculada
	var xadrez := StandardMaterial3D.new()
	xadrez.albedo_texture = _textura_xadrez(12, 2)
	xadrez.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	xadrez.roughness = 0.5
	xadrez.cull_mode = BaseMaterial3D.CULL_DISABLED
	_fita(pista, "Chegada", -w, w, 0.075, xadrez, 2.0, 0.0, 2.0)
	# barranco de wafer onde a pista sobe (montanha) e a lateral da ponte
	var wafer := CenarioVila._texturizado("#E8B878", "biscoito", 0.6, 0.7)
	wafer.cull_mode = BaseMaterial3D.CULL_DISABLED
	for lado in [-1, 1]:
		_saia(pista, lado, wafer, 0.25, 99.0, false)
		_saia(pista, lado, Pecas3D.material(Color("#FFF1F5"), 0.4), 0.25, 0.7, true)
	# pilares de bengala e corrimão na ponte do lago
	var bengala := Pecas3D.material_textura(Pecas3D.faixas([Color("#E8364F"), Color("#FFFFFF")], 6), 0.25)
	var corrimao := Pecas3D.material(Color("#FFFFFF"), 0.3)
	var s := 0.0
	var antes := {}
	while s < corrida.comprimento:
		if corrida.zona(s)["id"] == "lago":
			for lado in [-1, 1]:
				var topo := corrida.ponto(s, lado * (w + 0.6))
				if topo.y > 0.35:
					Pecas3D.cilindro(pista, 0.22, 0.26, topo.y + 0.9, Vector3(topo.x, (topo.y + 0.9) / 2.0 - 0.1, topo.z), bengala)
					var cima := topo + Vector3.UP * 0.9
					if antes.has(lado):
						Pecas3D.cano(pista, antes[lado], cima, 0.07, corrimao)
					antes[lado] = cima
				else:
					antes.erase(lado)
		s += 6.0
	# chão de grama e o lago de morango com a margem de areia de biscoito
	var chao := MeshInstance3D.new()
	chao.name = "Chao"
	var plano := PlaneMesh.new()
	plano.size = Vector2(700, 700)
	chao.mesh = plano
	chao.material_override = CenarioVila.gramado()
	chao.position = Vector3(68, 0, -25)
	pista.add_child(chao)
	var margem := Pecas3D.cilindro(pista, 1.0, 1.0, 0.1, LAGO + Vector3(0, 0.02, 0), Pecas3D.material(Color("#F6D2A2"), 0.9),
		Vector3(LAGO_RAIOS.x + 3.0, 1, LAGO_RAIOS.y + 3.0))
	(margem.mesh as CylinderMesh).radial_segments = 64
	var agua := Pecas3D.material(Color("#FF86B8"), 0.06, 0.1)
	var lago := Pecas3D.cilindro(pista, 1.0, 1.0, 0.1, LAGO + Vector3(0, 0.12, 0), agua, Vector3(LAGO_RAIOS.x, 1, LAGO_RAIOS.y))
	(lago.mesh as CylinderMesh).radial_segments = 64
	_portico_largada(pista)
	for k in Corrida.PORTAIS_EM.size():
		_portal(pista, k)


## Asfalto de chocolate com granulado colorido, faixas tracejadas entre as
## pistas dos portais e as bordas brancas.
func _textura_estrada() -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var base := Color("#5E3523")
	img.fill(base)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 4
	for i in 3000:
		var tom := sorteio.randf_range(-0.12, 0.1)
		img.set_pixel(sorteio.randi() % 128, sorteio.randi() % 128, base.lightened(tom) if tom > 0.0 else base.darkened(-tom))
	var cores := [Color("#FF6FAE"), Color("#FFD23F"), Color("#6FD3FF"), Color("#7BE07B"), Color("#FFFFFF")]
	for i in 90:
		var x := sorteio.randi_range(6, 120)
		var y := sorteio.randi_range(0, 125)
		var cor: Color = cores[i % cores.size()].lerp(base, 0.35)
		var deitado := sorteio.randf() < 0.5
		for k in 3:
			img.set_pixel(x + (k if deitado else 0), y + (0 if deitado else k), cor)
	var linha := Color("#FFF1DC")
	for y in 128:
		if (y / 16) % 2 == 0:
			for x in [31, 32, 63, 64, 95, 96]:
				img.set_pixel(x, y, linha)
		for x in [0, 1, 2, 125, 126, 127]:
			img.set_pixel(x, y, linha)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _textura_xadrez(colunas: int, linhas: int) -> ImageTexture:
	var img := Image.create(colunas, linhas, false, Image.FORMAT_RGBA8)
	for x in colunas:
		for y in linhas:
			img.set_pixel(x, y, Color("#2E1D4A") if (x + y) % 2 == 0 else Color("#FFFFFF"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Pórtico da largada: duas bengalas, a faixa quadriculada com LARGADA e o
## semáforo de 3 luzes (acendem na contagem).
func _portico_largada(pai: Node3D) -> void:
	var no := Node3D.new()
	no.name = "Largada"
	pai.add_child(no)
	no.global_transform = Transform3D(Basis.looking_at(corrida.frente(0.0)), corrida.ponto(0.0))
	var largura := Corrida.MEIA_LARGURA + 1.4
	var bengala := Pecas3D.material_textura(Pecas3D.faixas([Color("#E8364F"), Color("#FFFFFF")], 10), 0.25)
	for lado in [-1, 1]:
		Pecas3D.cilindro(no, 0.3, 0.34, 6.4, Vector3(lado * largura, 3.2, 0), bengala)
		Pecas3D.esfera(no, 0.45, Vector3(lado * largura, 6.5, 0), Pecas3D.material(Color("#FFD23F"), 0.3))
	Pecas3D.caixa(no, Vector3(largura * 2.0, 1.3, 0.22), Vector3(0, 5.6, 0), Pecas3D.material(Color("#2E1D4A"), 0.5))
	var xadrez := StandardMaterial3D.new()
	xadrez.albedo_texture = _textura_xadrez(16, 2)
	xadrez.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	xadrez.cull_mode = BaseMaterial3D.CULL_DISABLED
	for lado in [-1, 1]:
		CenarioVila._placa_plana(no, Vector2(largura * 2.0 - 0.1, 1.2), Vector3(0, 5.6, lado * 0.12), xadrez)
	for lado in [-1, 1]:
		var placa := Label3D.new()
		placa.text = "LARGADA" if lado > 0 else "CHEGADA"
		placa.font = CenarioVila.FONTE
		placa.font_size = 150
		placa.pixel_size = 0.008
		placa.outline_size = 36
		placa.modulate = Color("#FFD23F")
		placa.outline_modulate = Color("#2E1D4A")
		placa.double_sided = false
		placa.position = Vector3(0, 7.0, 0.05 * lado)
		placa.rotation.y = 0.0 if lado > 0 else PI
		no.add_child(placa)
	var semaforo := Node3D.new()
	semaforo.name = "Semaforo"
	semaforo.position = Vector3(0, 4.4, 0.2)
	no.add_child(semaforo)
	Pecas3D.caixa(semaforo, Vector3(2.4, 0.85, 0.3), Vector3.ZERO, Pecas3D.material(Color("#2E1D4A"), 0.4))
	for k in 3:
		var luz := Pecas3D.material(Color("#5A4A6A"), 0.2)
		luz.emission_enabled = true
		luz.emission = Color.BLACK
		Pecas3D.esfera(semaforo, 0.28, Vector3((k - 1) * 0.75, 0, 0.18), luz)
		_semaforo.append(luz)


## Portal do quiz: arco com quatro placas (A, B, C, D) nas cores das faixas,
## e as faixas pintadas no chão antes dele.
func _portal(pai: Node3D, k: int) -> void:
	var s := corrida.curva.get_closest_offset(Corrida.PORTAIS_EM[k])
	var no := Node3D.new()
	no.name = "Portal%d" % k
	pai.add_child(no)
	no.global_transform = Transform3D(Basis.looking_at(corrida.frente(s)), corrida.ponto(s))
	var largura := Corrida.MEIA_LARGURA + 1.0
	var roxo := Pecas3D.material(Color("#7E57B1"), 0.3)
	for lado in [-1, 1]:
		Pecas3D.cilindro(no, 0.35, 0.4, 6.8, Vector3(lado * largura, 3.4, 0), roxo)
		Pecas3D.esfera(no, 0.55, Vector3(lado * largura, 7.0, 0), Pecas3D.material(Color("#FFD23F"), 0.25))
	Pecas3D.caixa(no, Vector3(largura * 2.0 + 0.6, 0.6, 0.6), Vector3(0, 6.6, 0), roxo)
	var titulo := Label3D.new()
	titulo.text = "PORTAL DO QUIZ"
	titulo.font = CenarioVila.FONTE
	titulo.font_size = 110
	titulo.pixel_size = 0.008
	titulo.outline_size = 28
	titulo.modulate = Color("#FFD23F")
	titulo.outline_modulate = Color("#2E1D4A")
	titulo.position = Vector3(0, 6.6, 0.32)
	titulo.double_sided = false
	no.add_child(titulo)
	var placas := []
	for f in Corrida.FAIXAS.size():
		var cor := Color(Corrida.CORES_FAIXAS[f])
		var painel := Node3D.new()
		painel.name = "Painel%d" % f
		painel.position = Vector3(Corrida.FAIXAS[f], 5.2, 0)
		no.add_child(painel)
		var mat := Pecas3D.material(cor, 0.3)
		mat.emission_enabled = true
		mat.emission = cor
		mat.emission_energy_multiplier = 0.25
		Pecas3D.caixa(painel, Vector3(2.7, 1.3, 0.16), Vector3.ZERO, mat)
		var letra := Label3D.new()
		letra.text = "ABCD"[f]
		letra.font = CenarioVila.FONTE
		letra.font_size = 160
		letra.pixel_size = 0.007
		letra.outline_size = 30
		letra.outline_modulate = Color("#2E1D4A")
		letra.position = Vector3(0, 0, 0.1)
		letra.double_sided = false
		painel.add_child(letra)
		placas.append(painel)
		# faixa da cor pintada no chão antes do portal
		_fita(pai, "FaixaPortal", Corrida.FAIXAS[f] - 1.25, Corrida.FAIXAS[f] + 1.25, 0.08,
			Pecas3D.material(cor.lerp(Color.WHITE, 0.15), 0.5), 4.0, s - 16.0, s)
	_paineis.append(placas)


# --- Cenário em volta ---------------------------------------------------------------------

## Se dá para pôr uma coisa em `p` (longe da pista e fora do lago).
func _livre(p: Vector3, folga: float) -> bool:
	var perto := corrida.curva.get_closest_point(p)
	if Vector2(p.x - perto.x, p.z - perto.z).length() < Corrida.MEIA_LARGURA + 1.5 + folga:
		return false
	var no_lago := Vector2((p.x - LAGO.x) / (LAGO_RAIOS.x + 4.0), (p.z - LAGO.z) / (LAGO_RAIOS.y + 4.0))
	return no_lago.length() > 1.0


func _montar_cenario() -> void:
	var cenario := Node3D.new()
	cenario.name = "Cenario"
	add_child(cenario)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 21
	var cores_pirulito := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#B07CFF", "#7BE07B", "#FF8A5C"]
	var cores_casas := [["#FFE3EE", "#E8364F"], ["#E4F6FF", "#2E9BE8"], ["#FFF6C8", "#E8A23A"], ["#EFE6FF", "#7E57B1"]]
	var s := 6.0
	var n := 0
	while s < corrida.comprimento:
		var zona: String = corrida.zona(s)["id"]
		for lado in [-1, 1]:
			n += 1
			match zona:
				"vila":
					if n % 4 == 0:
						var poste := corrida.ponto(s, lado * (Corrida.MEIA_LARGURA + 2.4))
						if _livre(poste, -1.5):
							CenarioVila.bengala(cenario, Vector3(poste.x, 0, poste.z))
					if sorteio.randf() < 0.45:
						var p := _no_chao(corrida.ponto(s, lado * sorteio.randf_range(13.0, 24.0)))
						if _livre(p, 4.0):
							var cores: Array = cores_casas[sorteio.randi() % cores_casas.size()]
							_casinha(cenario, p, cores[0], cores[1], sorteio.randf() * TAU)
					elif sorteio.randf() < 0.5:
						var p := _no_chao(corrida.ponto(s, lado * sorteio.randf_range(9.0, 20.0)))
						if _livre(p, 1.5):
							CenarioVila.arvore_pirulito(cenario, p, cores_pirulito[sorteio.randi() % cores_pirulito.size()])
				"lago":
					if sorteio.randf() < 0.6:
						var p := _no_chao(corrida.ponto(s, lado * sorteio.randf_range(10.0, 26.0)))
						if _livre(p, 2.0):
							RegioesVila.arvore_algodao(cenario, p, ["#FFC2DA", "#C9B3EC", "#9FD4F7"][sorteio.randi() % 3],
								sorteio.randf_range(0.9, 1.4))
				"bosque":
					for vez in 2:
						var p := _no_chao(corrida.ponto(s + vez * 3.0, lado * sorteio.randf_range(9.0, 28.0)))
						if not _livre(p, 1.5):
							continue
						var sorte := sorteio.randf()
						if sorte < 0.6:
							CenarioVila.arvore_pirulito(cenario, p, cores_pirulito[sorteio.randi() % cores_pirulito.size()])
						elif sorte < 0.85:
							RegioesVila._cogumelo(cenario, p, sorteio.randf_range(1.2, 2.2))
						else:
							CenarioVila.jujuba(cenario, p, cores_pirulito[sorteio.randi() % cores_pirulito.size()], 1.6)
				"montanha":
					if sorteio.randf() < 0.25:
						var p := _no_chao(corrida.ponto(s, lado * sorteio.randf_range(10.0, 16.0)))
						if _livre(p, 1.5):
							_boneco_de_neve(cenario, p)
		s += 7.0
	_montanhas(cenario)
	_arquibancada(cenario)


func _no_chao(p: Vector3) -> Vector3:
	return Vector3(p.x, 0, p.z)


## Casinha de doce: paredes clarinhas, telhado de glacê, porta e janelas.
func _casinha(pai: Node3D, p: Vector3, parede: String, telhado: String, giro: float) -> void:
	var no := Node3D.new()
	no.position = p
	no.rotation.y = giro
	pai.add_child(no)
	Pecas3D.caixa(no, Vector3(4.0, 3.0, 3.6), Vector3(0, 1.5, 0), Pecas3D.material(Color(parede), 0.7))
	var prisma := PrismMesh.new()
	prisma.size = Vector3(4.6, 1.8, 4.0)
	var teto := MeshInstance3D.new()
	teto.mesh = prisma
	teto.material_override = Pecas3D.material(Color(telhado), 0.4)
	teto.position = Vector3(0, 3.9, 0)
	no.add_child(teto)
	Pecas3D.caixa(no, Vector3(1.0, 1.7, 0.1), Vector3(0, 0.85, 1.81), Pecas3D.material(Color("#7A4322"), 0.6))
	for x in [-1.3, 1.3]:
		Pecas3D.caixa(no, Vector3(0.8, 0.8, 0.1), Vector3(x, 1.9, 1.81), CenarioVila.vidro_janela())
	CenarioVila.sombra_contato(pai, p, 3.2, 0.4)


func _boneco_de_neve(pai: Node3D, p: Vector3) -> void:
	var neve := Pecas3D.material(Color("#FFFFFF"), 0.85)
	Pecas3D.esfera(pai, 0.8, p + Vector3(0, 0.8, 0), neve)
	Pecas3D.esfera(pai, 0.58, p + Vector3(0, 1.95, 0), neve)
	Pecas3D.esfera(pai, 0.4, p + Vector3(0, 2.8, 0), neve)
	Pecas3D.cilindro(pai, 0.0, 0.07, 0.4, p + Vector3(0, 2.8, 0.48), Pecas3D.material(Color("#FF8A1F"), 0.5), Vector3.ONE, Vector3(90, 0, 0))
	CenarioVila.sombra_contato(pai, p, 1.0, 0.4)


## Montanhas de sorvete grandes em volta do trecho da montanha.
func _montanhas(pai: Node3D) -> void:
	var sabores := [["#FFC2DA", "#FFFFFF"], ["#9FD4F7", "#FFFFFF"], ["#A8E6C1", "#FFF1F5"], ["#FFE08A", "#8B4A2B"], ["#C9B3EC", "#FFFFFF"]]
	var lugares := [[Vector3(96, 0, 74), 15.0], [Vector3(60, 0, 78), 13.0], [Vector3(130, 0, 52), 12.0],
		[Vector3(28, 0, 66), 11.0], [Vector3(76, 0, 8), 10.0], [Vector3(150, 0, 20), 13.0], [Vector3(-30, 0, 40), 14.0],
		[Vector3(170, 0, -60), 16.0], [Vector3(-40, 0, -70), 15.0], [Vector3(60, 0, -140), 17.0]]
	for i in lugares.size():
		var centro: Vector3 = lugares[i][0]
		var raio: float = lugares[i][1]
		if not _livre(centro, raio):
			continue
		var par: Array = sabores[i % sabores.size()]
		Pecas3D.cilindro(pai, raio * 0.55, raio, raio * 0.9, centro + Vector3(0, raio * 0.45, 0),
			CenarioVila._texturizado(par[0], "glace", 0.3, 0.7))
		Pecas3D.esfera(pai, raio * 0.62, centro + Vector3(0, raio * 1.05, 0),
			CenarioVila._texturizado(par[1], "glace", 0.3, 0.45), Vector3(1, 0.7, 1))
		Pecas3D.esfera(pai, raio * 0.12, centro + Vector3(0, raio * 1.5, 0), Pecas3D.material(Color("#E8263F"), 0.15))


## Arquibancada na reta da largada com a torcida de doces.
func _arquibancada(pai: Node3D) -> void:
	var no := Node3D.new()
	no.name = "Arquibancada"
	no.position = Vector3(-15.5, 0, -18)
	no.rotation.y = PI / 2.0  # de frente para a pista (leste)
	pai.add_child(no)
	var degraus := [Pecas3D.material(Color("#FFF6EE"), 0.6), Pecas3D.material(Color("#FFB3D1"), 0.6)]
	for k in 4:
		Pecas3D.caixa(no, Vector3(26, 0.7, 1.6), Vector3(0, 0.35 + k * 0.7, -k * 1.6), degraus[k % 2])
		Pecas3D.caixa(no, Vector3(26, 0.7 * (k + 1), 0.1), Vector3(0, 0.35 * (k + 1), -k * 1.6 - 0.8), degraus[1])
	# torcida: cabecinhas coloridas
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 8
	var cores := ["#FF6FAE", "#6FD3FF", "#FFD23F", "#B07CFF", "#7BE07B", "#FF8A5C", "#7A4322", "#FFFFFF"]
	for k in 4:
		var x := -12.0
		while x < 12.0:
			if sorteio.randf() < 0.7:
				var cor: String = cores[sorteio.randi() % cores.size()]
				Pecas3D.esfera(no, 0.36, Vector3(x, 1.05 + k * 0.7, -k * 1.6), Pecas3D.material(Color(cor), 0.35))
			x += sorteio.randf_range(0.8, 1.3)
	# toldo listrado em cima
	var toldo := Pecas3D.material_textura(Pecas3D.listras([Color("#E8364F"), Color("#FFFFFF")], 20), 0.5)
	Pecas3D.caixa(no, Vector3(27, 0.2, 7.2), Vector3(0, 5.2, -2.4), toldo, Vector3(8, 0, 0))
	for x in [-13.0, 0.0, 13.0]:
		Pecas3D.cilindro(no, 0.16, 0.16, 5.4, Vector3(x, 2.7, -5.6), Pecas3D.material(Color("#FFFFFF"), 0.4))


# --- Coisas na pista ------------------------------------------------------------------------

func _montar_coisas() -> void:
	var coisas := Node3D.new()
	coisas.name = "Coisas"
	add_child(coisas)
	# setas de turbo (as setinhas "andam" para a frente)
	_mat_setas = StandardMaterial3D.new()
	_mat_setas.albedo_texture = _textura_setas()
	_mat_setas.emission_enabled = true
	_mat_setas.emission_texture = _mat_setas.albedo_texture
	_mat_setas.emission_energy_multiplier = 0.6
	_mat_setas.roughness = 0.3
	_mat_setas.uv1_scale = Vector3(1, 2, 1)
	for e in corrida.setas:
		var plano := PlaneMesh.new()
		plano.size = Vector2(2.6, 3.6)
		var no := MeshInstance3D.new()
		no.mesh = plano
		no.material_override = _mat_setas
		coisas.add_child(no)
		no.global_transform = Transform3D(Basis.looking_at(corrida.frente(e["s"])), corrida.ponto(e["s"], e["x"]) + Vector3.UP * 0.09)
	# poças de calda de chocolate (com bolhas)
	var calda := Pecas3D.material(Color("#4A2412"), 0.08)
	for e in corrida.pocas:
		var centro := corrida.ponto(e["s"], e["x"]) + Vector3.UP * 0.07
		Pecas3D.cilindro(coisas, 1.7, 1.7, 0.06, centro, calda, Vector3(1, 1, 1.25))
		for k in 3:
			Pecas3D.esfera(coisas, 0.18 + k * 0.05, centro + Vector3(cos(k * 2.1) * 0.8, 0.02, sin(k * 2.1) * 0.9), calda, Vector3(1, 0.6, 1))
	# blocos de gelatina (balançam quando alguém bate)
	var blocos := Node3D.new()
	blocos.name = "Blocos"
	add_child(blocos)
	var cores := ["#FF4F7B", "#4CC36B", "#FFB13D", "#8B7CF6"]
	for i in corrida.blocos.size():
		var e: Dictionary = corrida.blocos[i]
		var no := Node3D.new()
		blocos.add_child(no)
		no.global_transform = Transform3D(Basis.looking_at(corrida.frente(e["s"])), corrida.ponto(e["s"], e["x"]) + Vector3.UP * 0.06)
		var gelatina := Pecas3D.material(Color(cores[i % cores.size()]), 0.12)
		gelatina.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gelatina.albedo_color.a = 0.82
		gelatina.rim_enabled = true
		gelatina.rim = 0.6
		Pecas3D.caixa(no, Vector3(1.8, 1.3, 1.3), Vector3(0, 0.65, 0), gelatina)
		Pecas3D.caixa(no, Vector3(1.4, 0.12, 1.0), Vector3(0, 1.36, 0), Pecas3D.material(Color("#FFFFFF"), 0.4))
		_blocos_nos.append(no)
	# cubos de açúcar
	var cubos := Node3D.new()
	cubos.name = "Cubos"
	add_child(cubos)
	var acucar := Pecas3D.material(Color("#FFFFFF"), 0.9)
	acucar.emission_enabled = true
	acucar.emission = Color("#FFF6D8")
	acucar.emission_energy_multiplier = 0.25
	var caixinha := BoxMesh.new()
	caixinha.size = Vector3.ONE * 0.55
	_cubos = MultiMesh.new()
	_cubos.transform_format = MultiMesh.TRANSFORM_3D
	_cubos.mesh = caixinha
	_cubos.instance_count = corrida.cubos_pista.size()
	var desenho := MultiMeshInstance3D.new()
	desenho.multimesh = _cubos
	desenho.material_override = acucar
	cubos.add_child(desenho)
	for e in corrida.cubos_pista:
		_cubos_lugar.append(corrida.ponto(e["s"], e["x"]) + Vector3.UP * 0.9)
	_girar_cubos()


func _textura_setas() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color("#FF8A1F"))
	for y in 64:
		for x in 64:
			# divisa "^" apontando para cima (v = 0 é a frente do plano)
			var meio := absf(x - 31.5)
			var faixa := fposmod(y + meio * 0.9, 32.0)
			if faixa < 12.0:
				img.set_pixel(x, y, Color("#FFF27A"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# --- Karts ------------------------------------------------------------------------------------

func _criar_karts() -> void:
	for kart in _karts:
		kart.queue_free()
	_karts.clear()
	_x_antes.clear()
	_giros.clear()
	for i in corrida.corredores.size():
		var c: Dictionary = corrida.corredores[i]
		var kart := Kart3D.new()
		kart.name = "Kart%d" % i
		kart.doce = c["doce"]
		kart.nivel = Companheiros.nivel(c["doce"]) if c["jogador"] else 0
		kart.cor = Color(CORES_KARTS[i % CORES_KARTS.size()])
		_karts_no.add_child(kart)
		kart.otimizar()
		var placa := Label3D.new()
		placa.text = c["nome"]
		placa.font = CenarioVila.FONTE
		placa.font_size = 64
		placa.pixel_size = 0.006
		placa.outline_size = 16
		placa.modulate = Color("#FFD23F") if c["jogador"] else Color.WHITE
		placa.outline_modulate = Color("#2E1D4A")
		placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		placa.fixed_size = true
		placa.pixel_size = 0.0006
		placa.position = Vector3(0, 2.2, 0)
		placa.name = "Nome"
		placa.visible = false
		kart.add_child(placa)
		_karts.append(kart)
		_x_antes.append(float(c["x"]))
		_giros.append(0.0)
	_posicionar_karts(0.0)


func _posicionar_karts(dt: float) -> void:
	for i in _karts.size():
		var c: Dictionary = corrida.corredores[i]
		var kart := _karts[i]
		var s: float = c["s"]
		var lateral: float = (c["x"] - _x_antes[i]) / maxf(dt, 0.0001) if dt > 0.0 else 0.0
		_x_antes[i] = c["x"]
		_giros[i] = lerpf(_giros[i], clampf(lateral / Corrida.LATERAL, -1.0, 1.0), 0.18)
		var base := Basis.looking_at(corrida.frente(s))
		base = base.rotated(base.y, -_giros[i] * 0.32)
		kart.global_transform = Transform3D(base, corrida.ponto(s, c["x"]) + Vector3.UP * 0.06)
		kart.corpo.rotation.z = _giros[i] * 0.08
		kart.corpo.position.y = sin(_relogio * 30.0 + i) * 0.025 * minf(1.0, c["v"] / 10.0)
		kart.rodar(c["v"] * dt)
		kart.turbo(c["turbo"] > 0.0)
		# o nome dos rivais só aparece a uma distância boa de ler
		var distancia := kart.global_position.distance_to(_camera.global_position)
		(kart.get_node("Nome") as Label3D).visible = not c["jogador"] and distancia > 9.0 and distancia < 70.0


# --- Câmera -------------------------------------------------------------------------------------

func _seguir_com_camera(delta: float, imediato := false) -> void:
	var c := corrida.jogador()
	var s: float = c["s"]
	var f := corrida.frente(s)
	var plano := Vector3(f.x, 0, f.z).normalized()
	var kart := corrida.ponto(s, c["x"])
	# (+ v / 10: a câmera "adivinha" o quanto o kart anda, e não fica para trás no turbo)
	var alvo: Vector3 = kart - plano * (CAMERA_ATRAS - c["v"] / 10.0) + Vector3.UP * (CAMERA_ALTURA + maxf(0.0, -f.y) * 4.0)
	var olhar := kart + f * 6.0 + Vector3.UP * 1.1
	if corrida.portal_ativo >= 0:
		# na pergunta, a câmera sobe um pouco e mostra o portal lá na frente
		var portal := corrida.ponto(corrida.portais[corrida.portal_ativo]) + Vector3.UP * 3.0
		olhar = olhar.lerp(portal, 0.35)
		alvo += Vector3.UP * 1.2
	var peso := 1.0 if imediato else 1.0 - exp(-delta * 10.0)
	_camera.global_position = _camera.global_position.lerp(alvo, peso)
	_olhar = olhar if imediato else _olhar.lerp(olhar, 1.0 - exp(-delta * 9.0))
	var tremor := Vector3.ZERO
	if _tremor > 0.0:
		tremor = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _tremor * 0.35
		_tremor = maxf(0.0, _tremor - delta * 2.5)
	_camera.look_at(_olhar + tremor)
	var fov_alvo := FOV_TURBO if c["turbo"] > 0.0 else FOV
	_camera.fov = lerpf(_camera.fov, fov_alvo, 1.0 - exp(-delta * 4.0))


## Câmera na frente e à direita do grid de largada, balançando devagar (o
## painel do começo fica à esquerda; os karts aparecem na metade direita).
func _passear_com_camera(delta: float) -> void:
	var grade := corrida.ponto(-6.5) + Vector3.UP * 0.9
	var alvo := corrida.ponto(6.0, 9.5 + sin(_relogio * 0.3) * 1.5) + Vector3.UP * 3.2
	_camera.global_position = _camera.global_position.lerp(alvo, 1.0 - exp(-delta * 2.0)) if delta > 0.0 else alvo
	var direcao := grade - _camera.global_position
	_camera.look_at(_camera.global_position + direcao.rotated(Vector3.UP, deg_to_rad(24.0)))
	_camera.fov = FOV


# --- Andamento ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_relogio += delta
	_mat_setas.uv1_offset.y = fposmod(_mat_setas.uv1_offset.y + delta * 1.2, 1.0)
	_girar_cubos()
	if estado == "inicio":
		_passear_com_camera(delta)
		return
	if estado == "correndo":
		corrida.direcao = _direcao()
		var antes := corrida.contagem
		var eventos := corrida.avancar(delta)
		_contagem(antes)
		for e in eventos:
			_tratar(e)
		_posicionar_karts(delta * corrida.ritmo)
		_atualizar_hud(delta)
	elif estado == "fim":
		corrida.direcao = 0.0
		# os outros continuam andando devagar depois da chegada
		for c in corrida.corredores:
			c["s"] = c["s"] + c["v"] * 0.5 * delta
		_posicionar_karts(delta)
	_seguir_com_camera(delta)


## Os cubos giram; os já pegos nesta volta somem.
func _girar_cubos() -> void:
	var volta := corrida.volta(0)
	for k in _cubos_lugar.size():
		var tamanho := 1.0 if corrida.cubos_pista[k]["pego"] != volta else 0.001
		var giro := Basis.from_euler(Vector3(0.6, _relogio * 2.0 + k, 0.4)).scaled(Vector3.ONE * tamanho)
		_cubos.set_instance_transform(k, Transform3D(giro, _cubos_lugar[k]))


## Para onde virar: dedos nos botões ◀ ▶, o mouse neles ou o teclado.
func _direcao() -> float:
	var d := 0
	for lado in _dedos.values():
		d += lado
	d += _mouse_lado
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		d -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		d += 1
	for i in _botoes_lado.size():
		var apertado := (d < 0 and i == 0) or (d > 0 and i == 1)
		_botoes_lado[i].modulate.a = 1.0 if apertado else 0.7
	return clampf(d, -1.0, 1.0)


func _input(evento: InputEvent) -> void:
	if estado != "correndo":
		_dedos.clear()
		_mouse_lado = 0
		return
	if evento is InputEventScreenTouch:
		if evento.pressed:
			var lado := _lado_tocado(evento.position)
			if lado != 0:
				_dedos[evento.index] = lado
		else:
			_dedos.erase(evento.index)
	elif evento is InputEventScreenDrag and _dedos.has(evento.index):
		var lado := _lado_tocado(evento.position)
		if lado != 0:
			_dedos[evento.index] = lado
	elif evento is InputEventMouseButton and evento.device != InputEvent.DEVICE_ID_EMULATION \
			and evento.button_index == MOUSE_BUTTON_LEFT:
		_mouse_lado = _lado_tocado(evento.position) if evento.pressed else 0
	elif evento is InputEventKey and evento.pressed and not evento.echo and corrida.portal_ativo >= 0:
		var k: int = evento.keycode - KEY_1
		if k >= 0 and k < 4:
			escolher(k)


func _lado_tocado(posicao: Vector2) -> int:
	for i in _botoes_lado.size():
		if _botoes_lado[i].get_global_rect().grow(20.0).has_point(posicao):
			return -1 if i == 0 else 1
	return 0


func _contagem(antes: float) -> void:
	if antes <= 0.0:
		return
	var numero := ceili(corrida.contagem)
	if numero != _ultima_contagem and numero > 0:
		_ultima_contagem = numero
		_mensagem(str(numero), 120, Color.WHITE)
		Audio.tocar("bip")
		for k in _semaforo.size():
			var acesa := k < Corrida.CONTAGEM - numero + 1
			_semaforo[k].emission = Color("#FF3030") if acesa else Color.BLACK
			_semaforo[k].emission_energy_multiplier = 2.0


func _tratar(e: Dictionary) -> void:
	var meu: bool = e.get("quem", 0) == 0
	match e["tipo"]:
		"largada":
			_mensagem("JÁ!", 130, Color("#7BE07B"))
			Audio.tocar("largada")
			for luz in _semaforo:
				luz.emission = Color("#3CFF6A")
		"pergunta":
			_mostrar_pergunta()
		"portal":
			_passou_portal(e)
		"seta":
			if meu:
				Audio.tocar("turbo", 1.1, -2.0)
				_mensagem("TURBO!", 60, Color("#FFD23F"))
		"poca":
			if meu:
				Audio.tocar("chape", 1.1, -3.0)
				_mensagem("CALDA! DEVAGAR...", 48, Color("#C98A5A"))
		"batida":
			if meu:
				Audio.tocar("pulo", 0.6)
				_tremor = 1.0
				_mensagem("TROMBADA!", 52, Color("#FF6FAE"))
			_balancar_bloco(e["quem"])
		"cubo":
			Audio.tocar("moeda", 1.3, -6.0)
			_rotulo_cubos.text = str(corrida.cubos)
			_pulo(_rotulo_cubos)
		"volta":
			if meu:
				Audio.tocar("construir")
				_mensagem("VOLTA FINAL!" if e["volta"] == Corrida.VOLTAS else "VOLTA %d" % e["volta"], 70, Color("#FFD23F"))
		"fim":
			_chegou()


## A trombada balança o bloco de gelatina mais perto do kart.
func _balancar_bloco(quem: int) -> void:
	var kart := _karts[quem].global_position
	var perto: Node3D = null
	for no in _blocos_nos:
		if perto == null or no.global_position.distance_to(kart) < perto.global_position.distance_to(kart):
			perto = no
	if perto == null:
		return
	var tween := perto.create_tween()
	for k in 4:
		var forca := 0.25 * (1.0 - k / 4.0)
		tween.tween_property(perto, "scale", Vector3(1.0 + forca, 1.0 - forca, 1.0 + forca), 0.07)
		tween.tween_property(perto, "scale", Vector3(1.0 - forca * 0.6, 1.0 + forca * 0.6, 1.0 - forca * 0.6), 0.07)
	tween.tween_property(perto, "scale", Vector3.ONE, 0.08)


# --- Fluxo -----------------------------------------------------------------------------------

func mostrar_inicio() -> void:
	estado = "inicio"
	corrida = Corrida.new()
	_criar_karts()
	_hud.visible = false
	_quadro.visible = false
	for luz in _semaforo:
		luz.emission = Color.BLACK
	var coluna := _abrir_painel("Inicio", "CORRIDA DE DOCES", true)
	_texto(coluna, "2 voltas pela vila, pela ponte do Lago de Morango, pelo Bosque de Pirulitos e pela Montanha de Sorvete. Nos PORTAIS DO QUIZ, passe pela faixa da resposta certa para ganhar TURBO!", 21, 540)
	var rivais := HBoxContainer.new()
	rivais.alignment = BoxContainer.ALIGNMENT_CENTER
	rivais.add_theme_constant_override("separation", 12)
	coluna.add_child(rivais)
	for i in corrida.corredores.size():
		var c: Dictionary = corrida.corredores[i]
		var cartao := VBoxContainer.new()
		cartao.add_theme_constant_override("separation", 2)
		rivais.add_child(cartao)
		var foto := TextureRect.new()
		if ResourceLoader.exists(FOTOS % c["doce"]):
			foto.texture = load(FOTOS % c["doce"])
		foto.custom_minimum_size = Vector2(80, 80)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cartao.add_child(foto)
		var nome := _texto(cartao, c["nome"], 17, 110)
		nome.add_theme_color_override("font_color", Color(CORES_KARTS[i]))
	var recorde := Corrida.recorde()
	var linha := "1º LUGAR: 40 MOEDAS + 30 AÇÚCAR  ·  CADA CUBO: +1 AÇÚCAR"
	if recorde > 0.0:
		linha += "\nRECORDE: %s  ·  VITÓRIAS: %d" % [Corrida.texto_tempo(recorde), Corrida.vitorias()]
	_texto(coluna, linha, 19, 540)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR", &"BotaoSecundario", Telas.voltar, 200))
	botoes.add_child(_botao("Correr", "CORRER!", &"BotaoComprar", comecar, 260))


func comecar() -> void:
	if is_instance_valid(_painel):
		_painel.queue_free()
	estado = "correndo"
	_ultima_contagem = 99
	_hud.visible = true
	_rotulo_cubos.text = "0"
	_seguir_com_camera(0.0, true)
	_atualizar_hud(1.0)


func _mostrar_pergunta() -> void:
	var p := corrida.pergunta()
	_quadro.visible = true
	_quadro.find_child("Aviso", true, false).visible = corrida.portal_ativo == 0
	_enunciado.text = str(p["enunciado"])
	for k in _cartoes.size():
		var cartao := _cartoes[k]
		cartao.text = "%s   %s" % ["ABCD"[k], str(p["alternativas"][k])]
		cartao.disabled = false
		cartao.modulate = Color.WHITE
		cartao.scale = Vector2.ONE
	_quadro.offset_bottom = _quadro.offset_top  # encolhe para o tamanho da pergunta nova
	_quadro.pivot_offset = _quadro.size / 2.0
	_quadro.scale = Vector2.ONE * 0.85
	_quadro.create_tween().tween_property(_quadro, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.tocar("especial", 0.8, -4.0)


## Tocou numa resposta: o kart vai para a faixa dela.
func escolher(k: int) -> void:
	if corrida.portal_ativo < 0 or corrida.escolha >= 0:
		return
	corrida.escolher(k)
	for i in _cartoes.size():
		_cartoes[i].modulate = Color.WHITE if i == k else Color(1, 1, 1, 0.45)
	var escolhido := _cartoes[k]
	escolhido.pivot_offset = escolhido.size / 2.0
	escolhido.create_tween().tween_property(escolhido, "scale", Vector2.ONE * 1.08, 0.12)
	Audio.tocar("pulo", 1.2, -6.0)


func _passou_portal(e: Dictionary) -> void:
	var placas: Array = _paineis[e["portal"] % _paineis.size()]
	var certa: int = corrida.perguntas[e["portal"]]["resposta"]
	if e["quem"] != 0:
		return
	# a placa certa pula; a resposta fica marcada no quadro por um instante
	var placa: Node3D = placas[certa]
	var pulo := placa.create_tween()
	pulo.tween_property(placa, "scale", Vector3.ONE * 1.35, 0.12)
	pulo.tween_property(placa, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	for i in _cartoes.size():
		_cartoes[i].disabled = true
		if i == certa:
			_cartoes[i].modulate = VERDE.lightened(0.3)
		elif i == e["faixa"]:
			_cartoes[i].modulate = VERMELHO.lightened(0.3)
	if e["acertou"]:
		Audio.tocar("acerto")
		Audio.tocar("turbo")
		_mensagem("ACERTOU! TURBO!", 70, Color("#7BE07B"))
	else:
		Audio.tocar("erro")
		_mensagem("ERROU! MAIS DEVAGAR...", 56, Color("#FF6F6F"))
	var quadro := _quadro
	get_tree().create_timer(1.3).timeout.connect(func():
		if is_instance_valid(quadro) and corrida.portal_ativo < 0:
			quadro.visible = false)


func _chegou() -> void:
	estado = "fim"
	_quadro.visible = false
	var lugar := corrida.colocacao(0)
	if lugar == 1:
		Audio.tocar("vitoria")
		_mensagem("1º LUGAR!", 110, Color("#FFD23F"))
	else:
		Audio.tocar("construir")
		_mensagem("%dº LUGAR" % lugar, 100, Color.WHITE)
	var ganho := corrida.concluir()
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree() or estado != "fim":
		return
	_hud.visible = false
	_resultado(ganho)


func _resultado(ganho: Dictionary) -> void:
	var lugar: int = ganho["lugar"]
	var coluna := _abrir_painel("Resultado", "VOCÊ VENCEU A CORRIDA!" if lugar == 1 else "VOCÊ CHEGOU EM %dº" % lugar)
	var tabela := GridContainer.new()
	tabela.columns = 3
	tabela.add_theme_constant_override("h_separation", 26)
	tabela.add_theme_constant_override("v_separation", 2)
	var centro := CenterContainer.new()
	centro.add_child(tabela)
	coluna.add_child(centro)
	var ordem := corrida.ranking()
	for posicao in ordem.size():
		var i: int = ordem[posicao]
		var c: Dictionary = corrida.corredores[i]
		var cor := Color("#FFD23F") if c["jogador"] else Color.WHITE
		for texto in ["%dº" % (posicao + 1), c["nome"], Corrida.texto_tempo(c["fim"])]:
			var rotulo := _texto(tabela, texto, 26, 0)
			rotulo.autowrap_mode = TextServer.AUTOWRAP_OFF
			rotulo.add_theme_color_override("font_color", cor)
	var premios := HBoxContainer.new()
	premios.alignment = BoxContainer.ALIGNMENT_CENTER
	premios.add_theme_constant_override("separation", 22)
	coluna.add_child(premios)
	for par in [[Itens.MOEDA, int(ganho["moedas"])], [Itens.ACUCAR, int(ganho["acucar"])]]:
		var icone := TextureRect.new()
		icone.texture = par[0]
		icone.custom_minimum_size = Vector2(50, 50)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		premios.add_child(icone)
		var numero := _texto(premios, "+0", 42)
		numero.autowrap_mode = TextServer.AUTOWRAP_OFF
		numero.custom_minimum_size.x = 90
		var total: int = par[1]
		numero.create_tween().tween_method(func(v: float): numero.text = "+%d" % roundi(v), 0.0, float(total), 0.9)
	var extras := []
	if ganho["recorde_novo"]:
		extras.append("RECORDE NOVO: %s!" % Corrida.texto_tempo(ganho["tempo"]))
	if ganho["bau"] != "":
		extras.append("+ BAÚ DE DOCE")
	extras.append("%d DE %d PORTAIS CERTOS  ·  %d CUBOS" % [corrida.jogador()["acertos"], corrida.portais.size(), corrida.cubos])
	_texto(coluna, "\n".join(extras), 22)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	coluna.add_child(botoes)
	botoes.add_child(_botao("Sair", "VOLTAR PARA A VILA", &"BotaoSecundario", Telas.voltar))
	botoes.add_child(_botao("DeNovo", "CORRER DE NOVO", &"BotaoComprar", func():
		mostrar_inicio()
		comecar()))


# --- Interface -------------------------------------------------------------------------------

func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.name = "Interface"
	add_child(camada)
	_hud = Control.new()
	_hud.name = "Hud"
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_hud)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 16)
	_hud.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 10)
	margem.add_child(coluna)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(54, 54)
	voltar.icon = ICONE_VOLTAR
	voltar.expand_icon = true
	voltar.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.tooltip_text = "Desistir da corrida"
	voltar.pressed.connect(ao_voltar)
	topo.add_child(voltar)
	_rotulo_volta = _etiqueta(topo, null)
	_rotulo_tempo = _etiqueta(topo, ICONE_RELOGIO)
	_rotulo_cubos = _etiqueta(topo, Itens.ACUCAR)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	_rotulo_lugar = Label.new()
	_rotulo_lugar.name = "Lugar"
	_rotulo_lugar.theme_type_variation = &"TituloClaro"
	_rotulo_lugar.add_theme_font_size_override("font_size", 64)
	_rotulo_lugar.add_theme_constant_override("outline_size", 14)
	_rotulo_lugar.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	topo.add_child(_rotulo_lugar)
	# os 4 corredores em ordem (embaixo do botão de voltar)
	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(linha)
	var fundo := PanelContainer.new()
	fundo.theme_type_variation = &"Etiqueta"
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(fundo)
	_lista = VBoxContainer.new()
	_lista.name = "Posicoes"
	_lista.add_theme_constant_override("separation", 0)
	fundo.add_child(_lista)
	for i in 4:
		var rotulo := Label.new()
		rotulo.theme_type_variation = &"SubtituloClaro"
		rotulo.add_theme_font_size_override("font_size", 19)
		_lista.add_child(rotulo)
	# quadro da pergunta (aparece perto de cada portal)
	_quadro = PanelContainer.new()
	_quadro.name = "QuadroPergunta"
	_quadro.theme_type_variation = &"PainelRoxo"
	_quadro.anchor_left = 0.17
	_quadro.anchor_right = 0.83
	_quadro.offset_top = 80
	_quadro.visible = false
	camada.add_child(_quadro)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 6)
	_quadro.add_child(caixa)
	var aviso := Label.new()
	aviso.name = "Aviso"
	aviso.theme_type_variation = &"SubtituloClaro"
	aviso.add_theme_font_size_override("font_size", 16)
	aviso.add_theme_color_override("font_color", Color("#FFD23F"))
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.text = "PORTAL DO QUIZ: TOQUE NA RESPOSTA (O KART VAI PARA A FAIXA DELA)"
	caixa.add_child(aviso)
	_enunciado = Label.new()
	_enunciado.theme_type_variation = &"TituloClaro"
	_enunciado.add_theme_font_size_override("font_size", 23)
	_enunciado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enunciado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(_enunciado)
	_barra_portal = ProgressBar.new()
	_barra_portal.show_percentage = false
	_barra_portal.max_value = 1.0
	_barra_portal.custom_minimum_size = Vector2(0, 8)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color("#FFD23F")
	cheio.set_corner_radius_all(99)
	var vazio := StyleBoxFlat.new()
	vazio.bg_color = Color(0, 0, 0, 0.3)
	vazio.set_corner_radius_all(99)
	_barra_portal.add_theme_stylebox_override("fill", cheio)
	_barra_portal.add_theme_stylebox_override("background", vazio)
	caixa.add_child(_barra_portal)
	var grade := GridContainer.new()
	grade.name = "Alternativas"
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 8)
	caixa.add_child(grade)
	for k in 4:
		var cartao := Button.new()
		cartao.name = "Alternativa%d" % k
		cartao.custom_minimum_size = Vector2(0, 50)
		cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cartao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cartao.focus_mode = Control.FOCUS_NONE
		cartao.add_theme_font_size_override("font_size", 19)
		cartao.add_theme_color_override("font_color", Color.WHITE)
		cartao.add_theme_color_override("font_hover_color", Color.WHITE)
		cartao.add_theme_color_override("font_pressed_color", Color.WHITE)
		cartao.add_theme_color_override("font_disabled_color", Color.WHITE)
		cartao.add_theme_color_override("font_outline_color", Color("#2E1D4A"))
		cartao.add_theme_constant_override("outline_size", 7)
		for estado_botao in ["normal", "hover", "pressed", "disabled"]:
			var estilo := StyleBoxFlat.new()
			estilo.bg_color = Color(Corrida.CORES_FAIXAS[k])
			if estado_botao == "hover":
				estilo.bg_color = estilo.bg_color.lightened(0.12)
			estilo.set_corner_radius_all(14)
			estilo.set_border_width_all(3)
			estilo.border_color = Color(1, 1, 1, 0.85)
			estilo.content_margin_left = 12
			estilo.content_margin_right = 12
			cartao.add_theme_stylebox_override(estado_botao, estilo)
		cartao.pressed.connect(escolher.bind(k))
		grade.add_child(cartao)
		_cartoes.append(cartao)
	# botões de virar nos cantos de baixo
	for i in 2:
		var botao := PanelContainer.new()
		botao.name = "Esquerda" if i == 0 else "Direita"
		botao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.18, 0.11, 0.29, 0.55)
		estilo.set_corner_radius_all(80)
		estilo.set_border_width_all(4)
		estilo.border_color = Color(1, 1, 1, 0.7)
		botao.add_theme_stylebox_override("panel", estilo)
		botao.anchor_top = 1.0
		botao.anchor_bottom = 1.0
		botao.anchor_left = 0.0 if i == 0 else 1.0
		botao.anchor_right = botao.anchor_left
		botao.offset_top = -190
		botao.offset_bottom = -26
		botao.offset_left = 26 if i == 0 else -230
		botao.offset_right = 230 if i == 0 else -26
		var seta := TextureRect.new()
		seta.texture = ICONE_SETA
		seta.flip_h = i == 0
		seta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		seta.custom_minimum_size = Vector2(90, 90)
		seta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(seta)
		_hud.add_child(botao)
		_botoes_lado.append(botao)


func _etiqueta(pai: Control, icone: Texture2D) -> Label:
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"Etiqueta"
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	etiqueta.add_child(linha)
	if icone:
		var imagem := TextureRect.new()
		imagem.texture = icone
		imagem.custom_minimum_size = Vector2(26, 26)
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(imagem)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", 28)
	linha.add_child(rotulo)
	pai.add_child(etiqueta)
	return rotulo


func _atualizar_hud(delta: float) -> void:
	_rotulo_volta.text = "VOLTA %d/%d" % [corrida.volta(0), Corrida.VOLTAS]
	_rotulo_tempo.text = Corrida.texto_tempo(corrida.tempo)
	_rotulo_lugar.text = "%dº/%d" % [corrida.colocacao(0), corrida.corredores.size()]
	if corrida.portal_ativo >= 0:
		_barra_portal.value = corrida.falta_portal()
	_ranking_relogio -= delta
	if _ranking_relogio > 0.0:
		return
	_ranking_relogio = 0.25
	var ordem := corrida.ranking()
	for posicao in ordem.size():
		var c: Dictionary = corrida.corredores[ordem[posicao]]
		var rotulo: Label = _lista.get_child(posicao)
		rotulo.text = "%dº  %s" % [posicao + 1, c["nome"]]
		rotulo.add_theme_color_override("font_color", Color(CORES_KARTS[ordem[posicao]]))


## Painel no meio da tela (ou na metade esquerda, `a_esquerda`, com o 3D à direita).
func _abrir_painel(nome: String, titulo: String, a_esquerda := false) -> VBoxContainer:
	if is_instance_valid(_painel):
		_painel.queue_free()
	_painel = Control.new()
	_painel.name = nome
	_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	$Interface.add_child(_painel)
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.05, 0.2, 0.2 if a_esquerda else 0.45)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	if a_esquerda:
		centro.anchor_right = 0.52
	_painel.add_child(centro)
	var painel := PanelContainer.new()
	painel.theme_type_variation = &"PainelRoxo"
	centro.add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	painel.add_child(coluna)
	var rotulo := _texto(coluna, titulo, 52)
	rotulo.name = "Titulo"
	return coluna


func _texto(pai: Control, texto: String, tamanho: int, largura := 720) -> Label:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro" if tamanho >= 30 else &"SubtituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.custom_minimum_size.x = 0 if tamanho >= 40 else largura
	rotulo.text = texto
	pai.add_child(rotulo)
	return rotulo


func _botao(nome: String, texto: String, estilo: StringName, acao: Callable, largura := 280) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.text = texto
	botao.theme_type_variation = estilo
	botao.custom_minimum_size = Vector2(largura, 66)
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(acao)
	return botao


## Texto grande no meio da tela que aparece pulando e some.
func _mensagem(texto: String, tamanho: int, cor: Color) -> void:
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_constant_override("outline_size", 16)
	rotulo.add_theme_color_override("font_outline_color", Color("#3B2A5C"))
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.text = texto
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Interface.add_child(rotulo)
	var tela := get_viewport().get_visible_rect().size
	var tamanho_texto := rotulo.get_combined_minimum_size()
	rotulo.position = Vector2(tela.x / 2.0, tela.y * 0.36) - tamanho_texto / 2.0
	rotulo.pivot_offset = tamanho_texto / 2.0
	rotulo.scale = Vector2.ONE * 0.4
	var tween := rotulo.create_tween()
	tween.tween_property(rotulo, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.45)
	tween.tween_property(rotulo, "modulate:a", 0.0, 0.3)
	tween.tween_callback(rotulo.queue_free)


func _pulo(no: Control) -> void:
	no.pivot_offset = no.size / 2.0
	var tween := no.create_tween()
	tween.tween_property(no, "scale", Vector2.ONE * 1.3, 0.08)
	tween.tween_property(no, "scale", Vector2.ONE, 0.15)
