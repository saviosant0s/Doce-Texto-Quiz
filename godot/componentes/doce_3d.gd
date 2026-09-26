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
	if not _animacao.is_inside_tree():
		add_child(_animacao)
	_animacao.configurar(pivo)


func _ao_tocar() -> void:
	comemorar()


## Pulinho com giro e aceno (ao tocar ou ao comprar).
func comemorar() -> void:
	_animacao.comemorar()
