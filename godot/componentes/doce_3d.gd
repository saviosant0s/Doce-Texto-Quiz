class_name Doce3D
extends Visor3D
## Um doce da coleção em 3D, vivo (ver AnimacaoDoce): respira, pisca, acena
## de vez em quando e pula quando é tocado. Gira com o dedo (ver Visor3D).

## Id do doce (ver Colecao.LISTA). Mude com `mostrar(id)`.
@export var id := "brigadeiro"
## Doce ainda não conquistado: aparece como silhueta de cor única (ainda se mexe).
@export var silhueta := false
## Cor da silhueta (escura em fundo amarelo, clara em fundo roxo).
@export var cor_silhueta := Color("#8C6BC0")
## Nível do doce (Companheiros.nivel): a partir do 2 ganha enfeites (brilhos,
## laço, coroa...). 0 = sem enfeites (personagens das telas do quiz).
@export var nivel := 0

const COR_SILHUETA := Color("#8C6BC0")

var _animacao := AnimacaoDoce.new()


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
	if not silhueta:
		Doces3D.enfeitar(pivo, id, nivel)
	if silhueta:
		var cor := StandardMaterial3D.new()
		cor.albedo_color = cor_silhueta
		if cor_silhueta.a < 1.0:
			cor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cor.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for malha in pivo.find_children("*", "MeshInstance3D", true, false):
			malha.material_override = cor
	# leve: as peças de cada parte (corpo, olhos, braços, granulado...) viram um
	# bloco só (antes cada granulado era um desenho; a batalha tem dois doces)
	JuntarMalhas.simplificar(pivo)
	JuntarMalhas.juntar_boneco(pivo)
	if not _animacao.is_inside_tree():
		add_child(_animacao)
	_animacao.configurar(pivo)


func _ao_tocar() -> void:
	comemorar()


## Pulinho com giro e aceno (ao tocar ou ao comprar).
func comemorar() -> void:
	_animacao.comemorar()


## BATALHA (ver AnimacaoDoce): prepara o golpe, apanha, desmaia e as poses de luta.
func preparar_golpe() -> void:
	_animacao.preparar_golpe()


func apanhar(forte := false) -> void:
	_animacao.apanhar(forte)


func desmaiar() -> void:
	_animacao.desmaiar()


func pose_luta(nome: String, segundos := 0.12) -> void:
	_animacao.pose_luta(nome, segundos)


## Evolução (ao melhorar na coleção): gira cada vez mais rápido brilhando até
## ficar branco, encolhe e, no clarão, aparece com o visual do nível novo,
## grande, e volta ao tamanho balançando.
func evoluir(novo_nivel: int) -> void:
	segurar_pose = true
	var gira := create_tween().set_parallel()
	gira.tween_property(_pivo, "rotation:y", _pivo.rotation.y + TAU * 3.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	gira.tween_property(self, "modulate", Color(3, 3, 3), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	gira.tween_property(_pivo, "scale", Vector3.ONE * 0.7, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await gira.finished
	if not is_inside_tree():
		return
	nivel = novo_nivel
	remontar()
	_pivo.scale = Vector3.ONE * 1.35
	var aparece := create_tween().set_parallel()
	aparece.tween_property(_pivo, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	aparece.tween_property(self, "modulate", Color.WHITE, 0.5)
	comemorar()
	await aparece.finished
	segurar_pose = false
