class_name Doce3D
extends Visor3D
## Um doce da coleção em 3D, vivo: respira, pisca, acena de vez em quando e
## pula quando é tocado. Gira com o dedo (ver Visor3D).

## Id do doce (ver Colecao.LISTA). Mude com `mostrar(id)`.
@export var id := "brigadeiro"
## Doce ainda não conquistado: aparece como silhueta de cor única (ainda se mexe).
@export var silhueta := false
## Cor da silhueta (escura em fundo amarelo, clara em fundo roxo).
@export var cor_silhueta := Color("#8C6BC0")

const COR_SILHUETA := Color("#8C6BC0")

var _corpo: Node3D
var _olhos: Array[Node3D] = []
var _aceno: Node3D
var _proxima_piscada := randf_range(0.8, 2.0)
var _acenando_ate := 0.0
var _proximo_aceno := randf_range(0.6, 1.8)  # acena logo que aparece


func _init() -> void:
	angulo_inicial = -0.35
	distancia = 6.2


## Troca o doce mostrado (e se aparece como silhueta).
func mostrar(novo_id: String, como_silhueta := false) -> void:
	id = novo_id
	silhueta = como_silhueta
	if is_node_ready():
		remontar()


func _montar(pivo: Node3D) -> void:
	Doces3D.montar(id, pivo)
	if silhueta:
		var cor := StandardMaterial3D.new()
		cor.albedo_color = cor_silhueta
		if cor_silhueta.a < 1.0:
			cor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cor.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for malha in pivo.find_children("*", "MeshInstance3D", true, false):
			malha.material_override = cor
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
			tween.tween_property(olhos, "scale:y", 0.08, 0.09)
			tween.tween_interval(0.05)
			tween.tween_property(olhos, "scale:y", 1.0, 0.12)
			if randf() < 0.3:  # às vezes pisca duas vezes
				tween.tween_property(olhos, "scale:y", 0.08, 0.09)
				tween.tween_property(olhos, "scale:y", 1.0, 0.12)
		_proxima_piscada = _tempo + randf_range(1.8, 3.5)
	# acena de vez em quando (e quando é tocado)
	if _tempo > _proximo_aceno:
		_acenando_ate = _tempo + 1.6
		_proximo_aceno = _tempo + randf_range(3.5, 6.0)
	if _aceno:
		var alvo := sin(_tempo * 12.0) * 0.6 if _tempo < _acenando_ate else 0.0
		_aceno.rotation.z = lerpf(_aceno.rotation.z, alvo, minf(1.0, delta * 12.0))
