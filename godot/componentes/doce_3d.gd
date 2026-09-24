class_name Doce3D
extends Visor3D
## Um doce da coleção em 3D, vivo: respira, pisca, acena de vez em quando e
## pula quando é tocado. Gira com o dedo (ver Visor3D).

## Id do doce (ver Colecao.LISTA). Mude com `mostrar(id)`.
@export var id := "brigadeiro"

var _corpo: Node3D
var _olhos: Array[Node3D] = []
var _aceno: Node3D
var _proxima_piscada := 2.0
var _acenando_ate := 0.0
var _proximo_aceno := 4.0


func _init() -> void:
	angulo_inicial = -0.35
	distancia = 6.2


## Troca o doce mostrado.
func mostrar(novo_id: String) -> void:
	id = novo_id
	if is_node_ready():
		remontar()


func _montar(pivo: Node3D) -> void:
	Doces3D.montar(id, pivo)
	_corpo = pivo.get_node_or_null("Corpo")
	_olhos.assign(pivo.find_children("Olhos", "Node3D", true, false))
	_aceno = pivo.find_child("Aceno", true, false)


func _ao_tocar() -> void:
	comemorar()


## Pulinho com giro e aceno (ao tocar ou ao comprar).
func comemorar() -> void:
	if not _corpo:
		return
	_acenando_ate = _tempo + 1.2
	var tween := create_tween()
	tween.tween_property(_corpo, "position:y", 0.35, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_corpo, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)


func _process(delta: float) -> void:
	super(delta)
	if not _corpo or not Telas.animacoes_continuas:
		return
	# respira: estica e achata de leve
	var respiro := sin(_tempo * 2.6) * 0.025
	_corpo.scale = Vector3(1.0 - respiro * 0.5, 1.0 + respiro, 1.0 - respiro * 0.5)
	# pisca de vez em quando
	if _tempo > _proxima_piscada:
		for olhos in _olhos:
			var tween := create_tween()
			tween.tween_property(olhos, "scale:y", 0.1, 0.07)
			tween.tween_property(olhos, "scale:y", 1.0, 0.09)
		_proxima_piscada = _tempo + randf_range(2.0, 4.5)
	# acena de vez em quando (e quando é tocado)
	if _tempo > _proximo_aceno:
		_acenando_ate = _tempo + 1.2
		_proximo_aceno = _tempo + randf_range(5.0, 8.0)
	if _aceno:
		var alvo := sin(_tempo * 14.0) * 0.35 if _tempo < _acenando_ate else 0.0
		_aceno.rotation.z = lerpf(_aceno.rotation.z, alvo, minf(1.0, delta * 12.0))
