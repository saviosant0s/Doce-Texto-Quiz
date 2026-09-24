@tool
class_name AnelProgresso
extends Control
## Anel circular de progresso (0 a 100), desenhado por código.

@export_range(0.0, 100.0) var valor := 70.0:
	set(novo):
		valor = novo
		queue_redraw()
@export var espessura := 26.0
@export var cor := Cores.AMARELO
@export var cor_fundo := Color(Cores.ROXO_ESCURO, 0.9)


func _draw() -> void:
	var centro := size / 2.0
	var raio := minf(size.x, size.y) / 2.0 - espessura / 2.0
	draw_arc(centro, raio, 0.0, TAU, 96, cor_fundo, espessura, true)
	if valor <= 0.0:
		return
	var inicio := -PI / 2.0
	var fim := inicio + TAU * valor / 100.0
	draw_arc(centro, raio, inicio, fim, 96, cor, espessura, true)
	# pontas arredondadas
	for angulo in [inicio, fim]:
		draw_circle(centro + Vector2(cos(angulo), sin(angulo)) * raio, espessura / 2.0, cor, true, -1.0, true)
