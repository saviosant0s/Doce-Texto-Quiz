extends Control
## Ferramenta: mostra todos os doces 3D lado a lado (para conferir o visual).
## ferramentas/capturar.sh res://testes/vitrine_3d.tscn

func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = Cores.ROXO
	fundo.set_anchors_preset(PRESET_FULL_RECT)
	add_child(fundo)
	var grade := GridContainer.new()
	grade.columns = 6
	grade.set_anchors_preset(PRESET_FULL_RECT)
	add_child(grade)
	var ids: Array = Colecao.LISTA.map(func(d): return d["id"]) + Doces3D.PERSONAGENS
	for id in ids:
		var visor := Doce3D.new()
		visor.id = id
		visor.giravel = false
		visor.custom_minimum_size = Vector2(210, 200)
		grade.add_child(visor)
