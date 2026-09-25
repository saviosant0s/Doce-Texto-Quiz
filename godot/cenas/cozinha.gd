class_name Cozinha
extends Node3D
## Cozinha da Minha Confeitaria (no estilo dos jogos "de loja" como Pizza
## Ready): o jogador anda com o seu doce pela cozinha.
## - As máquinas fazem doces sozinhas (com o açúcar ganho no quiz) e põem na
##   mesa-bandeja da frente delas.
## - Passando na frente da bandeja, o doce pega os doces e carrega em pilha.
## - Os clientes (moradores da vila) entram pela porta da direita e fazem fila
##   no balcão, cada um pedindo um doce; parando atrás do balcão, o doce
##   entrega os pedidos. Quem é atendido paga, e as moedas ficam na mesinha do
##   caixa até o jogador passar lá.
## - Parando em cima de um círculo amarelo, constrói ou melhora a máquina (ou
##   aumenta quantos doces carrega), se tiver as moedas.
## - Uma seta mostra o próximo passo. O tapete "SAIR" volta para a vila.
## - Três câmeras (botão no alto ou tecla C; a escolha fica salva): DE CIMA
##   (a padrão, como nos jogos de loja), PERTO (atrás do doce; arrastar o dedo
##   gira a visão, mesmo com o outro dedo no joystick) e 1ª PESSOA.
## Regras (preços, tempos, açúcar) em scripts/confeitaria.gd.

const MEIA_LARGURA := 9.0
const MEIO_FUNDO := 6.0
const PORTA_Z := 3.8
const MAQUINA_Z := -4.8
const MESA_Z := -3.3
const MAQUINAS_X := [-5.5, 0.0, 5.5]
const BALCAO := Vector3(0, 0, 1.4)
const LARGURA_BALCAO := 6.0
const CAIXA := Vector3(-4.8, 0, 0.5)
const CIRCULO_CARREGAR := Vector3(-7.3, 0, -0.9)
const SAIDA := Vector3(-7.2, 0, 4.6)
const INICIO := Vector3(-5.6, 0, 3.0)
const FILA := [Vector3(0, 0, 2.7), Vector3(1.7, 0, 2.8), Vector3(3.4, 0, 2.9), Vector3(5.1, 0, 3.0)]
const ENTRADA_CLIENTES := Vector3(10.5, 0, PORTA_Z)
const CAMERA_DISTANCIA := Vector3(0, 11.0, 9.0)
## Segundos entre um doce e outro ao pegar da bandeja ou entregar no balcão.
const RITMO_PEGAR := 0.12
const RITMO_ENTREGAR := 0.16
## Segundos parado no círculo para construir/melhorar.
const TEMPO_CIRCULO := 1.2
## Chegada de clientes: um a cada tantos segundos (se a fila não estiver cheia).
const INTERVALO_CLIENTES := Vector2(4.0, 7.0)
## Clientes que vêm sempre (os mascotes dos níveis); os doces da coleção
## também aparecem.
const CLIENTES := ["bala_verde", "milho_doce", "fantasma"]
const NOMES_NIVEIS := ["FÁCIL", "MÉDIO", "DIFÍCIL"]
const ICONE_CASA := preload("res://assets/icones/voltar.svg")
const ICONE_CAMERA := preload("res://assets/icones/camera.svg")

enum Camera { DE_CIMA, PERTO, PRIMEIRA_PESSOA }
const NOMES_CAMERA := ["DE CIMA", "PERTO", "1ª PESSOA"]
const PERTO_DISTANCIA := 3.4
const PERTO_ALTURA := 2.4
const ALTURA_OLHOS := 1.3
const GIRO_JOYSTICK := 2.4  # radianos por segundo (1ª pessoa)
const GIRO_ARRASTO := 0.01  # radianos por pixel arrastado
## Inclinação da visão (arrastar o dedo para cima/baixo), em radianos.
const INCLINACAO_1P := Vector2(-1.2, 1.1)  # 1ª pessoa: olhar para baixo / para cima
const INCLINACAO_PERTO := Vector2(-0.5, 0.7)
const INCLINACAO_INICIAL_1P := -0.45
const ICONE_MOEDA := preload("res://assets/icones/moeda.svg")
const ICONE_ACUCAR := preload("res://assets/icones/acucar.svg")

var jogador: DoceAndante
## Doces que o jogador está carregando (ids, de baixo para cima).
var carregando: Array[String] = []
## Moedas pagas e ainda não recolhidas (na mesinha do caixa).
var caixa := 0
## Clientes: {"no": DoceAndante, "doce", "falta", "total", "estado"
## ("chegando", "esperando", "saindo"), "balao": Label3D}.
var clientes: Array[Dictionary] = []

var _camera: Camera3D
var _joystick: Joystick
var _maquinas := {}  # id -> {"no", "vapor", "gira", "mesa": Vector3, "doces": Node3D, "placa": Label3D}
var _circulos := {}  # id da máquina ou "carregar" -> {"no", "enchimento", "texto", "anel", "tempo"}
var _moedas_visiveis: Node3D
var _seta: Node3D
var _dica: Label
var _rotulo_acucar: Label
var _rotulo_moedas: Label
var _relogio_maquinas := 0.0
var _relogio_pegar := 0.0
var _relogio_entregar := 0.0
var _proximo_cliente := 2.0
var _tempo := 0.0
var _saindo := false
var _qualidade_antes := {}
var _botao_quiz: Button
var modo_camera := Camera.DE_CIMA
## Para onde a câmera olha nas câmeras de perto (radianos no eixo Y; 0 = fundo da cozinha).
var _giro := 0.0
## Para cima (+) ou para baixo (-) nas câmeras de perto (ver INCLINACAO_*).
var _inclinacao := 0.0
var _girou_ha := 99.0
var _paredes_altas: Node3D


func _ready() -> void:
	Confeitaria.atualizar()
	_criar_ambiente()
	CenarioCozinha.sala(self, MEIA_LARGURA, MEIO_FUNDO, PORTA_Z)
	CenarioCozinha.tapete_saida(self, SAIDA)
	_paredes_altas = CenarioCozinha.paredes_altas(self, MEIA_LARGURA, MEIO_FUNDO, PORTA_Z, SAIDA.x)
	for i in Confeitaria.MAQUINAS.size():
		_criar_maquina(Confeitaria.MAQUINAS[i], MAQUINAS_X[i])
	CenarioCozinha.balcao(self, BALCAO, LARGURA_BALCAO)
	CenarioCozinha.mesa_caixa(self, CAIXA)
	_moedas_visiveis = Node3D.new()
	_moedas_visiveis.name = "Moedas"
	_moedas_visiveis.position = CAIXA
	add_child(_moedas_visiveis)
	_circulos["carregar"] = CenarioCozinha.circulo(self, CIRCULO_CARREGAR)
	_circulos["carregar"]["tempo"] = 0.0
	_criar_jogador()
	CenarioVila.estilo_desenho(self)
	_seta = CenarioCozinha.seta(self)
	# leve para o celular: o que não se mexe vira poucos blocos
	JuntarMalhas.simplificar(self)
	JuntarMalhas.juntar(self, ["Maquina_", "Bandeja_", "Moedas", "Circulo", "Seta", "ParedesAltas"])
	JuntarMalhas.juntar(_paredes_altas, [])
	jogador.otimizar()
	_qualidade_antes = CenarioVila.qualidade_3d(get_viewport())
	_criar_camera()
	_criar_interface()
	usar_camera(int(Progresso.config.get("camera_cozinha", Camera.DE_CIMA)))
	_atualizar_tudo()


func _exit_tree() -> void:
	CenarioVila.restaurar_qualidade(get_viewport(), _qualidade_antes)
	# o que ficou nas mãos volta para as bandejas; as moedas do caixa vão para o jogador
	for doce in carregando:
		var id := Confeitaria.maquina_do_doce(doce)
		if Confeitaria.construida(id) and Confeitaria.bandeja(id) < Confeitaria.capacidade_bandeja(id):
			Progresso.confeitaria["maquinas"][id]["bandeja"] = Confeitaria.bandeja(id) + 1
	carregando.clear()
	Confeitaria.receber(caixa)
	caixa = 0
	Confeitaria.atualizar()
	Progresso.salvar()


# --- Laço principal -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var direcao := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var teclas := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	direcao = (direcao + teclas).limit_length(1.0) * (1.0 if Input.is_key_pressed(KEY_SHIFT) else 0.8)
	direcao = (direcao + _joystick.vetor).limit_length(1.0)
	_girou_ha += delta
	match modo_camera:
		Camera.DE_CIMA:
			jogador.andar(Vector3(direcao.x, 0, direcao.y), delta)
		Camera.PRIMEIRA_PESSOA:
			# para os lados vira; para cima/baixo anda para frente/trás
			_giro -= direcao.x * GIRO_JOYSTICK * delta
			jogador.andar(_frente() * -direcao.y, delta)
			jogador.virar_para_angulo(_giro + PI)
		Camera.PERTO:
			var direita := Vector3(cos(_giro), 0, -sin(_giro))
			jogador.andar(direita * direcao.x + _frente() * -direcao.y, delta)
			if direcao.y < -0.3 and _girou_ha > 1.5:
				var costas := atan2(-jogador.frente().x, -jogador.frente().z)
				_giro = lerp_angle(_giro, costas, minf(1.0, 1.5 * delta))
	for cliente in clientes.duplicate():  # quem sai é tirado da lista
		_mover_cliente(cliente, delta)


func _process(delta: float) -> void:
	_tempo += delta
	_seguir_com_camera(delta)
	_relogio_maquinas += delta
	if _relogio_maquinas >= 0.25:
		_relogio_maquinas = 0.0
		if Confeitaria.atualizar() > 0:
			_atualizar_bandejas()
		_atualizar_maquinas()
	_pegar_das_bandejas(delta)
	_entregar_no_balcao(delta)
	_recolher_moedas()
	_pisar_nos_circulos(delta)
	_chegar_clientes(delta)
	_girar_maquinas(delta)
	_mostrar_dica()
	if not _saindo and _perto(SAIDA, 0.9):
		_saindo = true
		Telas.voltar()


## Botão "voltar" do celular: volta para a vila.
func ao_voltar() -> void:
	Telas.voltar()


func _perto(ponto: Vector3, raio: float) -> bool:
	var p := jogador.global_position
	return Vector2(p.x - ponto.x, p.z - ponto.z).length() < raio


# --- Bandejas: pegar doces -------------------------------------------------------------

func _pegar_das_bandejas(delta: float) -> void:
	_relogio_pegar -= delta
	if _relogio_pegar > 0.0 or carregando.size() >= Confeitaria.carregar():
		return
	for m in Confeitaria.MAQUINAS:
		var id: String = m["id"]
		if not Confeitaria.construida(id) or Confeitaria.bandeja(id) == 0:
			continue
		var mesa: Vector3 = _maquinas[id]["mesa"]
		if not _perto(mesa + Vector3(0, 0, 1.0), 1.3):
			continue
		var doces: Node3D = _maquinas[id]["doces"]
		var origem: Vector3 = doces.get_child(doces.get_child_count() - 1).global_position if doces.get_child_count() > 0 else mesa
		Confeitaria.pegar(id)
		Audio.tocar("estouro", 0.9 + carregando.size() * 0.06, -6.0)  # mais agudo quanto mais alta a pilha
		_atualizar_bandeja(id)
		_empilhar(m["doce"], origem)
		_relogio_pegar = RITMO_PEGAR
		return


## Põe um doce no alto da pilha do jogador, voando de `origem`.
func _empilhar(doce: String, origem: Vector3) -> void:
	carregando.append(doce)
	var pilha := jogador.pilha()
	var mini := CenarioCozinha.mini_doce(pilha, doce)
	var destino := Vector3(0, (carregando.size() - 1) * CenarioCozinha.ALTURA_DOCE, 0)
	mini.global_position = origem
	var tween := mini.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mini, "position", destino, 0.18)


## Tira o doce mais alto do tipo `doce` da pilha e ajeita os de cima.
func _desempilhar(doce: String) -> Vector3:
	var indice := carregando.rfind(doce)
	carregando.remove_at(indice)
	var pilha := jogador.pilha()
	var mini: Node3D = pilha.get_child(indice)
	var saida := mini.global_position
	pilha.remove_child(mini)
	mini.queue_free()
	for i in pilha.get_child_count():
		(pilha.get_child(i) as Node3D).position = Vector3(0, i * CenarioCozinha.ALTURA_DOCE, 0)
	return saida


# --- Clientes -------------------------------------------------------------------------------

func _chegar_clientes(delta: float) -> void:
	if not Confeitaria.alguma_construida():
		return
	_proximo_cliente -= delta
	var na_fila := clientes.filter(func(c): return c["estado"] != "saindo").size()
	if _proximo_cliente > 0.0 or na_fila >= FILA.size():
		return
	_proximo_cliente = randf_range(INTERVALO_CLIENTES.x, INTERVALO_CLIENTES.y)
	var feitos: Array = Confeitaria.MAQUINAS.filter(func(m): return Confeitaria.construida(m["id"]))
	var m: Dictionary = feitos.pick_random()
	novo_cliente(m["doce"], randi_range(1, 2 + Confeitaria.nivel(m["id"])))


## Cria um cliente que quer `quantos` doces do tipo `doce` (entra pela porta).
func novo_cliente(doce: String, quantos: int) -> Dictionary:
	var ids: Array = CLIENTES.duplicate()
	for d in Colecao.LISTA:
		if Colecao.tem(d["id"]) and d["id"] != jogador.id:
			ids.append(d["id"])
	var no := DoceAndante.new()
	no.id = ids.pick_random()
	no.sem_colisao = true
	no.sombra_redonda = false
	add_child(no)
	CenarioVila.estilo_desenho(no)  # mesmo visual de desenho do resto
	no.otimizar()
	no.global_position = ENTRADA_CLIENTES
	var balao := CenarioCozinha.rotulo(no, "", Vector3(0, 2.3, 0), 80, Color("#F4E038"))
	var foto := Sprite3D.new()
	foto.texture = Personagens.textura(doce)
	foto.pixel_size = 0.55 / maxf(foto.texture.get_height(), 1.0)
	foto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	foto.no_depth_test = true
	foto.position = Vector3(-0.4, 2.35, 0)
	no.add_child(foto)
	var cliente := {"no": no, "doce": doce, "falta": quantos, "total": quantos, "estado": "chegando", "balao": balao, "foto": foto}
	clientes.append(cliente)
	_atualizar_balao(cliente)
	return cliente


func _atualizar_balao(cliente: Dictionary) -> void:
	cliente["balao"].text = "   x%d" % cliente["falta"]


func _lugar_na_fila(cliente: Dictionary) -> int:
	var i := 0
	for outro in clientes:
		if outro == cliente:
			return i
		if outro["estado"] != "saindo":
			i += 1
	return i


func _mover_cliente(cliente: Dictionary, delta: float) -> void:
	var no: DoceAndante = cliente["no"]
	var alvo: Vector3
	if cliente["estado"] == "saindo":
		alvo = Vector3(no.global_position.x, 0, MEIO_FUNDO + 3.0)
	else:
		alvo = FILA[mini(_lugar_na_fila(cliente), FILA.size() - 1)]
	var caminho := alvo - no.global_position
	caminho.y = 0.0
	if caminho.length() > 0.12:
		no.andar(caminho.normalized() * clampf(caminho.length(), 0.35, 0.6), delta)
	else:
		no.andar(Vector3.ZERO, delta)
		if cliente["estado"] == "chegando":
			cliente["estado"] = "esperando"
		no.olhar_para(no.global_position + Vector3(0, 0, -1))  # de frente para o balcão
	if cliente["estado"] == "saindo" and no.global_position.z > MEIO_FUNDO + 2.5:
		clientes.erase(cliente)
		no.queue_free()


## Atrás do balcão, entrega os doces ao primeiro da fila (se tiver o que ele quer).
func _entregar_no_balcao(delta: float) -> void:
	_relogio_entregar -= delta
	if _relogio_entregar > 0.0 or carregando.is_empty() or not _no_balcao():
		return
	var primeiro: Dictionary = {}
	for cliente in clientes:
		if cliente["estado"] != "saindo":
			primeiro = cliente
			break
	if primeiro.is_empty() or primeiro["estado"] != "esperando" or not primeiro["doce"] in carregando:
		return
	var saida := _desempilhar(primeiro["doce"])
	_voar_ate(CenarioCozinha.mini_doce(self, primeiro["doce"]), saida, primeiro["no"].global_position + Vector3(0, 1.2, 0))
	primeiro["falta"] -= 1
	Audio.tocar("estouro", 1.2, -6.0)
	_atualizar_balao(primeiro)
	_relogio_entregar = RITMO_ENTREGAR
	if primeiro["falta"] == 0:
		_pagar(primeiro)


func _no_balcao() -> bool:
	var p := jogador.global_position
	return absf(p.x - BALCAO.x) < LARGURA_BALCAO / 2.0 + 0.3 and p.z > BALCAO.z - 2.0 and p.z < BALCAO.z


## O cliente atendido paga (moedas vão para a mesinha do caixa) e vai embora.
func _pagar(cliente: Dictionary) -> void:
	var valor := Confeitaria.cobrar(cliente["doce"], cliente["total"])
	caixa += valor
	_atualizar_moedas_visiveis()
	cliente["estado"] = "saindo"
	cliente["balao"].text = "+%d" % valor
	cliente["foto"].visible = false
	cliente["no"].comemorar()
	Audio.tocar("moeda")


func _recolher_moedas() -> void:
	if caixa == 0 or not _perto(CAIXA, 1.4):
		return
	var ganho := caixa
	for moeda in _moedas_visiveis.get_children():
		_voar_ate(moeda, moeda.global_position, jogador.global_position + Vector3(0, 1.0, 0), 0.25)
	Confeitaria.receber(ganho)
	caixa = 0
	Audio.tocar("caixa")
	Telas.mostrar_aviso("+%d MOEDAS" % ganho)
	_atualizar_tudo()


func _atualizar_moedas_visiveis() -> void:
	var quantas := mini(caixa, 36)
	while _moedas_visiveis.get_child_count() < quantas:
		var moeda := CenarioCozinha.moeda(_moedas_visiveis)
		moeda.position = CenarioCozinha.lugar_da_moeda(_moedas_visiveis.get_child_count() - 1)


## Anima um nó voando de `de` até `ate` e some no fim.
func _voar_ate(no: Node3D, de: Vector3, ate: Vector3, duracao := 0.22) -> void:
	if no.get_parent() != self:
		no.reparent(self)
	no.global_position = de
	var tween := no.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(no, "global_position", ate, duracao)
	tween.parallel().tween_property(no, "scale", Vector3.ONE * 0.4, duracao)
	tween.tween_callback(no.queue_free)


# --- Círculos: construir e melhorar -----------------------------------------------------------

func _pisar_nos_circulos(delta: float) -> void:
	for chave in _circulos:
		var c: Dictionary = _circulos[chave]
		if not c["no"].visible:
			continue
		var custo := Confeitaria.preco_carregar() if chave == "carregar" else Confeitaria.preco(chave)
		var pode: bool = custo >= 0 and Progresso.moedas >= custo \
			and (chave == "carregar" or Confeitaria.liberada(chave))
		if pode and _perto(c["no"].global_position, 0.8):
			c["tempo"] += delta
		else:
			c["tempo"] = 0.0
		var cheio := clampf(c["tempo"] / TEMPO_CIRCULO, 0.001, 1.0)
		c["enchimento"].scale = Vector3(cheio, 1, cheio)
		if c["tempo"] >= TEMPO_CIRCULO:
			c["tempo"] = 0.0
			_comprar(chave)


func _comprar(chave: String) -> void:
	if chave == "carregar":
		if Confeitaria.aumentar_carregar():
			Telas.mostrar_aviso("AGORA CARREGA %d DOCES!" % Confeitaria.carregar())
	else:
		var nova := not Confeitaria.construida(chave)
		var presente_antes: bool = Progresso.confeitaria["presente"]
		if Confeitaria.construir_ou_melhorar(chave):
			var nome: String = Confeitaria.maquina(chave)["nome"]
			if nova and not presente_antes:
				Telas.mostrar_aviso("%s CONSTRUÍDA! PRESENTE: +%d DE AÇÚCAR" % [nome, Confeitaria.ACUCAR_PRESENTE])
			elif nova:
				Telas.mostrar_aviso("%s CONSTRUÍDA!" % nome)
			else:
				Telas.mostrar_aviso("%s: NÍVEL %d!" % [nome, Confeitaria.nivel(chave)])
			var no: Node3D = _maquinas[chave]["no"]
			no.scale = Vector3.ONE * 0.6
			no.create_tween().tween_property(no, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.tocar("construir")
	jogador.comemorar()
	_atualizar_tudo()


# --- Atualização visual ---------------------------------------------------------------------------

func _atualizar_tudo() -> void:
	_rotulo_acucar.text = Jogo.formatar(Confeitaria.acucar())
	_rotulo_moedas.text = Jogo.formatar(Progresso.moedas)
	_atualizar_maquinas()
	_atualizar_bandejas()
	_atualizar_circulos()


func _atualizar_maquinas() -> void:
	_rotulo_acucar.text = Jogo.formatar(Confeitaria.acucar())
	_rotulo_moedas.text = Jogo.formatar(Progresso.moedas)
	for m in Confeitaria.MAQUINAS:
		var id: String = m["id"]
		var dados: Dictionary = _maquinas[id]
		var construida := Confeitaria.construida(id)
		dados["no"].visible = construida
		var parada := Confeitaria.parada(id)
		dados["vapor"].emitting = construida and parada.is_empty()
		var placa: Label3D = dados["placa"]
		placa.visible = construida
		if construida:
			var nivel := "NÍVEL %d/%d" % [Confeitaria.nivel(id), Confeitaria.NIVEL_MAXIMO]
			placa.text = "%s\n%s" % [m["nome"], parada if not parada.is_empty() else nivel]
			placa.modulate = Color("#FF8A8A") if not parada.is_empty() else Color.WHITE


func _atualizar_bandejas() -> void:
	for m in Confeitaria.MAQUINAS:
		_atualizar_bandeja(m["id"])


## Mostra na mesa tantos doces quantos há na bandeja.
func _atualizar_bandeja(id: String) -> void:
	var doces: Node3D = _maquinas[id]["doces"]
	var quantos := Confeitaria.bandeja(id)
	while doces.get_child_count() > quantos:
		var ultimo := doces.get_child(doces.get_child_count() - 1)
		doces.remove_child(ultimo)
		ultimo.queue_free()
	while doces.get_child_count() < quantos:
		var mini := CenarioCozinha.mini_doce(doces, Confeitaria.maquina(id)["doce"])
		mini.position = CenarioCozinha.lugar_na_bandeja(doces.get_child_count() - 1)
		mini.scale = Vector3.ONE * 0.2
		mini.create_tween().tween_property(mini, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _atualizar_circulos() -> void:
	for chave in _circulos:
		var c: Dictionary = _circulos[chave]
		var texto: Label3D = c["texto"]
		var custo: int
		var titulo: String
		if chave == "carregar":
			custo = Confeitaria.preco_carregar()
			titulo = "CARREGAR MAIS (%d)" % Confeitaria.carregar()
		else:
			custo = Confeitaria.preco(chave)
			var m := Confeitaria.maquina(chave)
			titulo = ("CONSTRUIR " if not Confeitaria.construida(chave) else "MELHORAR ") \
				+ String(m["nome"]).get_slice(" DE ", 0)
			if not Confeitaria.liberada(chave):
				texto.text = "%s\nPASSE NO NÍVEL %s" % [m["nome"], NOMES_NIVEIS[m["nivel_quiz"]]]
				texto.modulate = Color("#D9C8F0")
				c["anel"].material_override = Pecas3D.material(Color("#A58AD0"), 0.5)
				continue
		c["no"].visible = custo >= 0
		if custo < 0:
			continue
		var preco_texto := "GRÁTIS" if custo == 0 else "%s MOEDAS" % Jogo.formatar(custo)
		texto.text = "%s\n%s" % [titulo, preco_texto]
		var tem := Progresso.moedas >= custo
		texto.modulate = Color.WHITE if tem else Color("#FF8A8A")
		c["anel"].material_override = Pecas3D.material(Color("#F4E038") if tem else Color("#E5484D"), 0.4)


func _girar_maquinas(delta: float) -> void:
	for id in _maquinas:
		if _maquinas[id]["vapor"].emitting:
			_maquinas[id]["gira"].rotation.y += delta * 2.0


## Dica do próximo passo (texto no alto e seta em cima do lugar).
func _mostrar_dica() -> void:
	var alvo := Vector3.INF
	var texto := ""
	if not Confeitaria.alguma_construida():
		alvo = _circulos["brigadeiro"]["no"].global_position
		texto = "PARE NO CÍRCULO PARA CONSTRUIR A PANELA DE BRIGADEIRO"
	elif caixa > 0 and carregando.is_empty():
		alvo = CAIXA
		texto = "PEGUE AS MOEDAS NA MESINHA DO CAIXA"
	elif not carregando.is_empty() and clientes.any(func(c): return c["estado"] == "esperando" and c["doce"] in carregando):
		alvo = BALCAO + Vector3(0, 0, -1.0)
		texto = "ATENDA OS CLIENTES ATRÁS DO BALCÃO"
	else:
		for m in Confeitaria.MAQUINAS:
			if Confeitaria.bandeja(m["id"]) > 0 and carregando.size() < Confeitaria.carregar():
				alvo = _maquinas[m["id"]]["mesa"] + Vector3(0, 0, 1.0)
				texto = "PEGUE OS DOCES NA BANDEJA"
				break
		if alvo == Vector3.INF and caixa > 0:
			alvo = CAIXA
			texto = "PEGUE AS MOEDAS NA MESINHA DO CAIXA"
		if alvo == Vector3.INF and carregando.is_empty():
			var tem_acucar := Confeitaria.MAQUINAS.any(func(m): return Confeitaria.construida(m["id"]) and Confeitaria.acucar() >= m["acucar"])
			if not tem_acucar:
				texto = "SEM AÇÚCAR! TOQUE EM \"JOGAR O QUIZ\": CADA ACERTO DÁ %d" % Confeitaria.ACUCAR_POR_ACERTO
	# sem açúcar: o botão do quiz pulsa, chamando para jogar
	var falta_acucar := texto.begins_with("SEM AÇÚCAR")
	_botao_quiz.pivot_offset = _botao_quiz.size / 2
	_botao_quiz.scale = Vector2.ONE * (1.0 + (0.06 * absf(sin(_tempo * 4.0)) if falta_acucar else 0.0))
	# a dica em texto some depois dos primeiros clientes (a do açúcar fica)
	var aprendeu := int(Progresso.confeitaria["atendidos"]) >= 3 and not texto.begins_with("SEM AÇÚCAR")
	_dica.get_parent().visible = not texto.is_empty() and not aprendeu
	_dica.text = texto
	_seta.visible = alvo != Vector3.INF
	if _seta.visible:
		_seta.global_position = alvo + Vector3(0, 1.6 + sin(_tempo * 5.0) * 0.15, 0)


# --- Montagem ---------------------------------------------------------------------------------------

func _criar_ambiente() -> void:
	var ambiente := Environment.new()
	# céu lilás (aparece fora da cozinha aberta e reflete no inox das panelas)
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("#4A2F75")
	ceu.sky_horizon_color = Color("#B79BE3")
	ceu.ground_horizon_color = Color("#B79BE3")
	ceu.ground_bottom_color = Color("#5E3D8E")
	var sky := Sky.new()
	sky.sky_material = ceu
	ambiente.background_mode = Environment.BG_SKY
	ambiente.sky = sky
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color.WHITE
	ambiente.ambient_light_energy = 0.35 if CenarioVila.modo_leve() else 0.5
	CenarioVila.acabamento(ambiente)
	var mundo := WorldEnvironment.new()
	mundo.environment = ambiente
	add_child(mundo)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-60, -25, 0)
	luz.light_energy = 0.3 if CenarioVila.modo_leve() else 0.55
	luz.shadow_enabled = Qualidade.sombras()
	luz.shadow_opacity = 0.5
	luz.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	luz.directional_shadow_max_distance = 30.0
	add_child(luz)


func _criar_maquina(m: Dictionary, x: float) -> void:
	var id: String = m["id"]
	var dados := CenarioCozinha.maquina(self, id, Vector3(x, 0, MAQUINA_Z))
	var mesa := Vector3(x, 0, MESA_Z)
	CenarioCozinha.mesa_bandeja(self, mesa)
	var doces := Node3D.new()
	doces.name = "Bandeja_" + id
	doces.position = mesa
	add_child(doces)
	dados["mesa"] = mesa
	dados["doces"] = doces
	dados["placa"] = CenarioCozinha.rotulo(self, "", Vector3(x, dados["topo"] + 0.9, MAQUINA_Z), 52)
	_maquinas[id] = dados
	var circulo := CenarioCozinha.circulo(self, Vector3(x + 2.3, 0, MESA_Z + 0.7))
	circulo["tempo"] = 0.0
	circulo["no"].name = "Circulo_" + id
	_circulos[id] = circulo


func _criar_jogador() -> void:
	jogador = DoceAndante.new()
	jogador.name = "Jogador"
	var id := Colecao.companheiro()
	jogador.id = id if not id.is_empty() else "brigadeiro"
	jogador.sombra_redonda = false
	jogador.com_som = true
	add_child(jogador)
	jogador.global_position = INICIO
	jogador.olhar_para(Vector3(0, 0, 0))


func _criar_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 46.0
	add_child(_camera)
	_camera.global_position = _alvo_da_camera() + CAMERA_DISTANCIA
	_camera.look_at(_alvo_da_camera())


func _alvo_da_camera() -> Vector3:
	var p := jogador.global_position
	return Vector3(clampf(p.x, -3.0, 3.0), 0.0, clampf(p.z, -2.0, 2.0) - 1.2)


func _seguir_com_camera(delta: float) -> void:
	var cabeca := jogador.global_position + Vector3(0, ALTURA_OLHOS, 0)
	match modo_camera:
		Camera.DE_CIMA:
			var alvo := _alvo_da_camera()
			_camera.global_position = _camera.global_position.lerp(alvo + CAMERA_DISTANCIA, minf(1.0, 5.0 * delta))
			_camera.look_at(_camera.global_position - CAMERA_DISTANCIA)
		Camera.PERTO:
			var raio := Vector2(PERTO_DISTANCIA, PERTO_ALTURA - ALTURA_OLHOS).length()
			var elevacao := clampf(atan2(PERTO_ALTURA - ALTURA_OLHOS, PERTO_DISTANCIA) - _inclinacao, -0.05, 1.35)
			var alvo := cabeca - _frente() * raio * cos(elevacao) + Vector3(0, raio * sin(elevacao), 0)
			alvo = _sem_atravessar_paredes(cabeca, alvo)
			if alvo.distance_to(cabeca) < _camera.global_position.distance_to(cabeca) - 0.05:
				_camera.global_position = alvo  # parede no meio: pula na hora
			else:
				_camera.global_position = _camera.global_position.lerp(alvo, minf(1.0, 8.0 * delta))
			_camera.look_at(cabeca + _frente() * 1.5 + Vector3(0, -0.4 + _inclinacao * 2.0, 0))
		Camera.PRIMEIRA_PESSOA:
			_camera.global_position = cabeca - _frente() * 0.35
			_camera.look_at(_camera.global_position + _frente() * cos(_inclinacao) + Vector3(0, sin(_inclinacao), 0))


## Direção "para frente" das câmeras de perto, no chão.
func _frente() -> Vector3:
	return Vector3(-sin(_giro), 0, -cos(_giro))


## Se uma parede ficar entre o doce e a câmera, a câmera chega mais perto.
func _sem_atravessar_paredes(de: Vector3, ate: Vector3) -> Vector3:
	return CenarioVila.camera_sem_parede(get_world_3d(), de, ate)


## Troca a câmera (e salva a escolha).
func usar_camera(modo: int) -> void:
	modo_camera = modo as Camera
	jogador.mostrar_modelo(modo_camera != Camera.PRIMEIRA_PESSOA)
	_inclinacao = INCLINACAO_INICIAL_1P if modo_camera == Camera.PRIMEIRA_PESSOA else 0.0
	_paredes_altas.visible = modo_camera != Camera.DE_CIMA
	_camera.fov = 46.0 if modo_camera == Camera.DE_CIMA else 64.0
	if modo_camera != Camera.DE_CIMA:
		_giro = atan2(-jogador.frente().x, -jogador.frente().z)  # olhando para onde o doce olha
		_camera.global_position = jogador.global_position + Vector3(0, PERTO_ALTURA, 0) - _frente() * PERTO_DISTANCIA
	if Progresso.config.get("camera_cozinha", -1) != modo:
		Progresso.config["camera_cozinha"] = modo
		Progresso.salvar()


func proxima_camera() -> void:
	usar_camera((modo_camera + 1) % NOMES_CAMERA.size())
	Telas.mostrar_aviso("CÂMERA: " + NOMES_CAMERA[modo_camera])


func _unhandled_input(evento: InputEvent) -> void:
	# arrastar um dedo (fora do joystick) gira a visão nas câmeras de perto
	if evento is InputEventScreenDrag and evento.index != _joystick.dedo:
		_girar_visao(evento.relative)
	elif evento is InputEventMouseMotion and evento.device != InputEvent.DEVICE_ID_EMULATION \
			and evento.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_girar_visao(evento.relative)
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_C:
		proxima_camera()


func _girar_visao(pixels: Vector2) -> void:
	if modo_camera == Camera.DE_CIMA:
		return
	_giro -= pixels.x * GIRO_ARRASTO
	var limites := INCLINACAO_1P if modo_camera == Camera.PRIMEIRA_PESSOA else INCLINACAO_PERTO
	_inclinacao = clampf(_inclinacao - pixels.y * GIRO_ARRASTO, limites.x, limites.y)
	_girou_ha = 0.0


func _criar_interface() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 28)
	camada.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 12)
	margem.add_child(coluna)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 14)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)
	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.theme_type_variation = &"BotaoIconeAmarelo"
	voltar.custom_minimum_size = Vector2(72, 72)
	voltar.icon = ICONE_CASA
	voltar.expand_icon = true
	voltar.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.pressed.connect(Telas.voltar)
	topo.add_child(voltar)
	var titulo := PanelContainer.new()
	titulo.theme_type_variation = &"EtiquetaAmarela"
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var texto := Label.new()
	texto.theme_type_variation = &"Titulo"
	texto.text = "MINHA CONFEITARIA"
	titulo.add_child(texto)
	topo.add_child(titulo)
	var espaco := Control.new()
	espaco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(espaco)
	_rotulo_acucar = _etiqueta(topo, ICONE_ACUCAR, Color.WHITE)
	_rotulo_moedas = _etiqueta(topo, ICONE_MOEDA, Cores.AMARELO)
	var camera := Button.new()
	camera.name = "Camera"
	camera.theme_type_variation = &"BotaoIconeAmarelo"
	camera.custom_minimum_size = Vector2(72, 72)
	camera.icon = ICONE_CAMERA
	camera.expand_icon = true
	camera.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camera.focus_mode = Control.FOCUS_NONE
	camera.tooltip_text = "Trocar a câmera (C)"
	camera.pressed.connect(proxima_camera)
	topo.add_child(camera)
	# dica do próximo passo
	var faixa := PanelContainer.new()
	faixa.name = "Dica"
	faixa.theme_type_variation = &"Etiqueta"
	faixa.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica = Label.new()
	_dica.theme_type_variation = &"SubtituloClaro"
	_dica.add_theme_font_size_override("font_size", 26)
	faixa.add_child(_dica)
	coluna.add_child(faixa)
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
	# atalho para o quiz: é lá que se ganha açúcar (e moedas)
	_botao_quiz = Button.new()
	_botao_quiz.name = "JogarQuiz"
	_botao_quiz.text = "JOGAR O QUIZ"
	_botao_quiz.icon = ICONE_ACUCAR
	_botao_quiz.expand_icon = true
	_botao_quiz.add_theme_constant_override("icon_max_width", 34)
	_botao_quiz.custom_minimum_size = Vector2(320, 90)
	_botao_quiz.size_flags_vertical = Control.SIZE_SHRINK_END
	_botao_quiz.focus_mode = Control.FOCUS_NONE
	_botao_quiz.pressed.connect(Telas.abrir.bind("niveis"))
	baixo.add_child(_botao_quiz)


func _etiqueta(pai: Control, icone: Texture2D, cor: Color) -> Label:
	var etiqueta := PanelContainer.new()
	etiqueta.theme_type_variation = &"Etiqueta"
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	etiqueta.add_child(linha)
	var imagem := TextureRect.new()
	imagem.texture = icone
	imagem.modulate = cor
	imagem.custom_minimum_size = Vector2(32, 32)
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(imagem)
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	linha.add_child(rotulo)
	pai.add_child(etiqueta)
	return rotulo
