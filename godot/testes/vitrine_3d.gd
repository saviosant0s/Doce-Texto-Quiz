extends Control
## Ferramenta: mostra todos os doces 3D lado a lado (para conferir o visual).
## ferramentas/capturar.sh res://testes/vitrine_3d.tscn

func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = Cores.ROXO
	fundo.set_anchors_preset(PRESET_FULL_RECT)
	add_child(fundo)
	var grade := GridContainer.new()
	grade.columns = 5
	grade.set_anchors_preset(PRESET_FULL_RECT)
	add_child(grade)
	for doce in Colecao.LISTA:
		var visor := Doce3D.new()
		visor.id = doce["id"]
		visor.giravel = false
		visor.custom_minimum_size = Vector2(250, 235)
		grade.add_child(visor)
