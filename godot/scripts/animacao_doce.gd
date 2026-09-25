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
var _base_pernas: Array[Vector3] = []
var _tempo := 0.0
var _passo := 0.0
var _proxima_piscada := randf_range(0.8, 2.0)
var _acenando_ate := 0.0
var _proximo_aceno := randf_range(0.6, 1.8)  # acena logo que aparece


## Procura as partes animadas dentro de `modelo` (chame de novo ao trocar o doce).
func configurar(modelo: Node3D) -> void:
	_corpo = modelo.get_node_or_null("Corpo")
	_olhos.assign(modelo.find_children("Olhos", "Node3D", true, false))
	_aceno = modelo.find_child("Aceno", true, false)
	_bracos.assign(modelo.find_children("Braco", "Node3D", true, false))
	_pernas.assign(modelo.find_children("Perna?", "Node3D", true, false))  # PernaE e PernaD
	_base_pernas.assign(_pernas.map(func(p): return p.position))


## Pulinho com aceno (ao tocar, ao comprar, ao chegar em algum lugar).
func comemorar() -> void:
	if not _corpo:
		return
	_acenando_ate = _tempo + 1.2
	var tween := create_tween()
	tween.tween_property(_corpo, "position:y", 0.35, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_corpo, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)


func _process(delta: float) -> void:
	_tempo += delta
	if not is_instance_valid(_corpo):
		return
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
		_passo += delta * PI * velocidade_chao / (PASSADA * amplitude)
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
