class_name AnimacaoDoce
extends Node
## Deixa um doce 3D vivo: respira, pisca, acena de vez em quando e, quando
## `andando`, balança pernas e braços e dá pulinhos a cada passo.
## Usado pelo visor (Doce3D) e pelos doces da Vila dos Doces.
## Procura no modelo os nós "Corpo", "Olhos", "Aceno", "Braco", "PernaE" e "PernaD"
## (criados por Pecas3D).

## O braço do "oi" (nó "Aceno") é modelado levantado; parado ou andando ele
## fica abaixado assim (giro no eixo z), e só sobe para acenar.
const BRACO_ABAIXADO := -1.3

## Um pé encostou no chão (a cada passo): para o som de passos.
signal pisou

## Liga a animação de andar (e a velocidade, 0 a 1, para o ritmo dos passos).
var andando := false
var ritmo := 1.0
## Velocidade no chão (m/s), para os passos acompanharem o chão sem o doce
## "patinar": cada passo avança PASSADA metros. -1 = usar só o `ritmo`.
var velocidade_chao := -1.0
## Metros que o pé percorre por radiano de balanço da perna (2 x comprimento
## da perna no mundo, ~0,29 m na vila): assim o pé de apoio fica parado no chão.
const PASSADA := 0.58
const ALTURA_DO_PE := 0.09  # quanto o pé sobe ao dar o passo

var _corpo: Node3D
var _olhos: Array[Node3D] = []
var _aceno: Node3D
var _bracos: Array[Node3D] = []
var _pernas: Array[Node3D] = []
var _orbita: Node3D  # brilhos dos doces de nível alto (Doces3D.enfeitar)
var _base_pernas: Array[Vector3] = []
var _tempo := 0.0
var _passo := 0.0
var _proxima_piscada := randf_range(0.8, 2.0)
var _acenando_ate := 0.0
var _proximo_aceno := randf_range(0.6, 1.8)  # acena logo que aparece
var _acao_ate := 0.0  # golpe ou pancada da batalha: o respiro e o aceno esperam


## Procura as partes animadas dentro de `modelo` (chame de novo ao trocar o doce).
func configurar(modelo: Node3D) -> void:
	_corpo = modelo.get_node_or_null("Corpo")
	_olhos.assign(modelo.find_children("Olhos", "Node3D", true, false))
	_aceno = modelo.find_child("Aceno", true, false)
	_bracos.assign(modelo.find_children("Braco", "Node3D", true, false))
	_pernas.assign(modelo.find_children("Perna?", "Node3D", true, false))  # PernaE e PernaD
	_base_pernas.assign(_pernas.map(func(p): return p.position))
	_orbita = modelo.find_child("Orbita", true, false)
	_acao_ate = 0.0


## Pulinho com aceno (ao tocar, ao comprar, ao chegar em algum lugar).
func comemorar() -> void:
	if not _corpo:
		return
	_acenando_ate = _tempo + 1.2
	var tween := create_tween()
	tween.tween_property(_corpo, "position:y", 0.35, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_corpo, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)


## BATALHA: se encolhe antes do pulo (os braços ficam com as poses de luta).
func preparar_golpe() -> void:
	if not _corpo:
		return
	_acao_ate = maxf(_acao_ate, _tempo + 0.6)
	var tween := create_tween()
	tween.tween_property(_corpo, "scale", Vector3(1.14, 0.84, 1.14), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_corpo, "scale", Vector3(0.88, 1.16, 0.88), 0.08)
	tween.tween_property(_corpo, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## BATALHA: apanhou (achata, aperta os olhos e balança até voltar).
func apanhar(forte := false) -> void:
	if not _corpo:
		return
	_acao_ate = maxf(_acao_ate, _tempo + 0.75)
	var tween := create_tween()
	tween.tween_property(_corpo, "scale", Vector3(1.3, 0.62 if forte else 0.76, 1.3), 0.06)
	tween.tween_property(_corpo, "scale", Vector3.ONE, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for olhos in _olhos:
		if is_instance_valid(olhos):
			var aperta := create_tween()
			aperta.tween_property(olhos, "scale:y", 0.12, 0.05)
			aperta.tween_interval(0.45 if forte else 0.28)
			aperta.tween_property(olhos, "scale:y", 1.0, 0.12)


## BATALHA: nocaute (olhos fechados; a queda é do visor).
func desmaiar() -> void:
	_acao_ate = maxf(_acao_ate, _tempo + 2.0)
	for olhos in _olhos:
		if is_instance_valid(olhos):
			create_tween().tween_property(olhos, "scale:y", 0.1, 0.08)


## BATALHA: poses de luta dos braços e pernas, em `segundos`. Poses: "guarda"
## (punhos para a frente), "soco_e"/"soco_d" (um braço esticado para a frente),
## "voadora" (uma perna esticada, a outra e os braços para trás), "aberto"
## (braços abertos, para a pirueta), "encolhido" (para a cambalhota),
## "uppercut" (um braço para o alto) e "vitoria" (os dois braços para o alto).
## "normal" volta tudo para o lugar. A pose fica até a próxima (ou "normal").
func pose_luta(nome: String, segundos := 0.12) -> void:
	if not _corpo:
		return
	var bracos := _bracos_em_ordem()
	var alvos := {}
	for b in bracos:
		alvos[b] = Vector3(0, 0, _z_baixo(b))
	for i in _pernas.size():
		alvos[_pernas[i]] = Vector3.ZERO
	var ultimo: Node3D = bracos[-1] if not bracos.is_empty() else null
	var primeiro: Node3D = bracos[0] if not bracos.is_empty() else null
	match nome:
		"guarda":
			for b in bracos:
				alvos[b] = Vector3(-1.0, 0, _z_baixo(b) * 0.7)
		"soco_e", "soco_d":
			for b in bracos:
				alvos[b] = Vector3(-0.9, 0, _z_baixo(b) * 0.7)
			var braco: Node3D = primeiro if nome == "soco_e" else ultimo
			if braco:
				alvos[braco] = Vector3(-1.6, 0, _z_baixo(braco) * 0.9)
		"voadora":
			for b in bracos:
				alvos[b] = Vector3(0.8, 0, _z_aberto(b) * 0.6)
			for i in _pernas.size():
				alvos[_pernas[i]] = Vector3(-1.4 if i == _pernas.size() - 1 else 0.6, 0, 0)
		"aberto":
			for b in bracos:
				alvos[b] = Vector3(0, 0, _z_aberto(b))
		"encolhido":
			for b in bracos:
				alvos[b] = Vector3(-1.1, 0, _z_baixo(b) * 0.6)
			for perna in _pernas:
				alvos[perna] = Vector3(-1.1, 0, 0)
		"uppercut":
			if ultimo:
				alvos[ultimo] = Vector3(-2.8, 0, _z_baixo(ultimo) * 0.5)
			if primeiro and primeiro != ultimo:
				alvos[primeiro] = Vector3(0.5, 0, _z_baixo(primeiro))
		"vitoria":
			for b in bracos:
				alvos[b] = Vector3(0, 0, _z_cima(b))
	_acao_ate = _tempo + (0.1 if nome == "normal" else 999.0) + segundos
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for no in alvos:
		if is_instance_valid(no):
			tween.tween_property(no, "rotation", alvos[no], segundos)
	if is_instance_valid(_corpo) and nome == "normal":
		tween.tween_property(_corpo, "scale", Vector3.ONE, segundos)


## Braços da esquerda para a direita (o do "oi" junto).
func _bracos_em_ordem() -> Array[Node3D]:
	var lista: Array[Node3D] = []
	for b in _bracos:
		if is_instance_valid(b):
			lista.append(b)
	if is_instance_valid(_aceno):
		lista.append(_aceno)
	lista.sort_custom(func(a: Node3D, b: Node3D): return a.position.x < b.position.x)
	return lista


## Giro no eixo z do braço abaixado, aberto para o lado e levantado (o do "oi"
## é modelado levantado; os outros, abaixados).
func _z_baixo(braco: Node3D) -> float:
	return BRACO_ABAIXADO if braco == _aceno else 0.0


func _z_aberto(braco: Node3D) -> float:
	return -0.55 if braco == _aceno else 0.9 * signf(braco.position.x)


func _z_cima(braco: Node3D) -> float:
	return 0.15 if braco == _aceno else 1.5 * signf(braco.position.x)


func _process(delta: float) -> void:
	_tempo += delta
	if not is_instance_valid(_corpo):
		return
	if is_instance_valid(_orbita) and Telas.animacoes_continuas:
		_orbita.rotation.y += delta * 1.3
	if _tempo < _acao_ate:
		return  # golpe, pancada ou pose de luta da batalha em andamento
	if andando:
		_animar_passos(delta)
	else:
		_parar_passos(delta)
	if not Telas.animacoes_continuas:
		return
	if not andando:
		# respira: estica e achata de leve
		var respiro := sin(_tempo * 2.6) * 0.025
		_corpo.scale = Vector3(1.0 - respiro * 0.5, 1.0 + respiro, 1.0 - respiro * 0.5)
	# pisca de vez em quando
	if _tempo > _proxima_piscada:
		for olhos in _olhos:
			if not is_instance_valid(olhos):
				continue
			var tween := create_tween()
			tween.tween_property(olhos, "scale:y", 0.08, 0.09)
			tween.tween_interval(0.05)
			tween.tween_property(olhos, "scale:y", 1.0, 0.12)
			if randf() < 0.3:  # às vezes pisca duas vezes
				tween.tween_property(olhos, "scale:y", 0.08, 0.09)
				tween.tween_property(olhos, "scale:y", 1.0, 0.12)
		_proxima_piscada = _tempo + randf_range(1.8, 3.5)
	# acena de vez em quando (parado)
	if _tempo > _proximo_aceno and not andando:
		_acenando_ate = _tempo + 1.6
		_proximo_aceno = _tempo + randf_range(3.5, 6.0)
	if is_instance_valid(_aceno) and not andando:
		var alvo := sin(_tempo * 12.0) * 0.5 if _tempo < _acenando_ate else BRACO_ABAIXADO
		_aceno.rotation.z = lerpf(_aceno.rotation.z, alvo, minf(1.0, delta * 8.0))


## Pernas para frente e para trás (o pé que vai para a frente sobe do chão),
## braços ao contrário, corpo sobe e desce e balança a cada passo.
func _animar_passos(delta: float) -> void:
	var amplitude := 0.6
	if velocidade_chao >= 0.0:
		# meio ciclo (PI) = um passo, de PASSADA * amplitude metros; mais rápido =
		# passos mais largos e mais rápidos
		amplitude = clampf(0.35 + velocidade_chao * 0.07, 0.4, 0.85)
		var antes := floori(_passo / PI)
		_passo += delta * PI * velocidade_chao / (PASSADA * amplitude)
		if floori(_passo / PI) != antes:
			pisou.emit()
	else:
		_passo += delta * 9.0 * clampf(ritmo, 0.4, 1.3)
	var balanco := sin(_passo)
	# duas subidinhas por ciclo (uma por passo) e o peso passando de um pé
	# para o outro
	_corpo.position.y = absf(sin(_passo)) * 0.1
	_corpo.rotation.z = sin(_passo) * 0.07
	_corpo.rotation.y = sin(_passo) * 0.05
	_corpo.scale = Vector3.ONE
	for i in _pernas.size():
		var lado := 1.0 if i % 2 == 0 else -1.0
		_pernas[i].rotation.x = balanco * amplitude * lado
		# o pé que está indo para a frente fica no ar; o outro fica apoiado no
		# chão (desconta a subida do corpo, já que as pernas estão presas nele)
		var no_ar := maxf(0.0, -cos(_passo) * lado)
		if i < _base_pernas.size():
			_pernas[i].position.y = _base_pernas[i].y - _corpo.position.y + no_ar * ALTURA_DO_PE
	var bracos: Array[Node3D] = _bracos.duplicate()
	if is_instance_valid(_aceno):
		bracos.append(_aceno)
	for i in bracos.size():
		# braços balançam para frente e para trás, ao contrário das pernas
		bracos[i].rotation.x = -balanco * (amplitude + 0.15) * (1.0 if i % 2 == 0 else -1.0)
		var abaixado := BRACO_ABAIXADO if bracos[i] == _aceno else 0.0
		bracos[i].rotation.z = lerpf(bracos[i].rotation.z, abaixado, minf(1.0, delta * 10.0))


func _parar_passos(delta: float) -> void:
	var suave := minf(1.0, delta * 10.0)
	for i in _pernas.size():
		_pernas[i].rotation.x = lerpf(_pernas[i].rotation.x, 0.0, suave)
		if i < _base_pernas.size():
			_pernas[i].position.y = lerpf(_pernas[i].position.y, _base_pernas[i].y, suave)
	for braco in _bracos:
		braco.rotation.x = lerpf(braco.rotation.x, 0.0, suave)
	if is_instance_valid(_aceno):
		_aceno.rotation.x = lerpf(_aceno.rotation.x, 0.0, suave)
	_corpo.rotation.z = lerpf(_corpo.rotation.z, 0.0, suave)
	_corpo.rotation.y = lerpf(_corpo.rotation.y, 0.0, suave)
