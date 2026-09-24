class_name AnimacaoDoce
extends Node
## Deixa um doce 3D vivo: respira, pisca, acena de vez em quando e, quando
## `andando`, balança pernas e braços e dá pulinhos a cada passo.
## Usado pelo visor (Doce3D) e pelos doces da Vila dos Doces.
## Procura no modelo os nós "Corpo", "Olhos", "Aceno", "Braco" e "Perna"
## (criados por Pecas3D).

## Liga a animação de andar (e a velocidade, 0 a 1, para o ritmo dos passos).
var andando := false
var ritmo := 1.0

var _corpo: Node3D
var _olhos: Array[Node3D] = []
var _aceno: Node3D
var _bracos: Array[Node3D] = []
var _pernas: Array[Node3D] = []
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
	_pernas.assign(modelo.find_children("Perna", "Node3D", true, false))


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
		var alvo := sin(_tempo * 12.0) * 0.6 if _tempo < _acenando_ate else 0.0
		_aceno.rotation.z = lerpf(_aceno.rotation.z, alvo, minf(1.0, delta * 12.0))


## Pernas para frente e para trás, braços ao contrário, pulinho a cada passo.
func _animar_passos(delta: float) -> void:
	_passo += delta * 9.0 * clampf(ritmo, 0.4, 1.3)
	var balanco := sin(_passo)
	for i in _pernas.size():
		_pernas[i].rotation.x = balanco * 0.6 * (1.0 if i % 2 == 0 else -1.0)
	var bracos: Array[Node3D] = _bracos.duplicate()
	if is_instance_valid(_aceno):
		bracos.append(_aceno)
	for i in bracos.size():
		bracos[i].rotation.x = -balanco * 0.5 * (1.0 if i % 2 == 0 else -1.0)
		bracos[i].rotation.z = lerpf(bracos[i].rotation.z, 0.0, minf(1.0, delta * 10.0))
	_corpo.position.y = absf(sin(_passo)) * 0.12
	_corpo.rotation.z = sin(_passo) * 0.06
	_corpo.scale = Vector3.ONE


func _parar_passos(delta: float) -> void:
	var suave := minf(1.0, delta * 10.0)
	for perna in _pernas:
		perna.rotation.x = lerpf(perna.rotation.x, 0.0, suave)
	for braco in _bracos:
		braco.rotation.x = lerpf(braco.rotation.x, 0.0, suave)
	if is_instance_valid(_aceno):
		_aceno.rotation.x = lerpf(_aceno.rotation.x, 0.0, suave)
	_corpo.rotation.z = lerpf(_corpo.rotation.z, 0.0, suave)
