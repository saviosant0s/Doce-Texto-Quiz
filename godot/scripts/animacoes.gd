class_name Animacoes
## Pequenas animações reutilizadas pelas telas.


## Dá um pulinho no nó (ex.: mascotes). Animação curta de propósito: animações
## que não param obrigam a tela a ser redesenhada o tempo todo e travam o celular.
static func pular(no: Control, altura := 18.0, atraso := 0.5) -> void:
	await no.get_tree().process_frame  # espera o container posicionar o nó
	var y := no.position.y
	var tween := no.create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(atraso)
	tween.tween_property(no, "position:y", y - altura, 0.18).set_ease(Tween.EASE_OUT)
	tween.tween_property(no, "position:y", y, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Faz o nó aparecer deslizando a partir de `deslocamento`.
static func entrar(no: Control, deslocamento := Vector2(0, 40), atraso := 0.0) -> void:
	no.modulate.a = 0.0
	await no.get_tree().process_frame
	var destino := no.position
	no.position += deslocamento
	var tween := no.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(no, "position", destino, 0.5).set_delay(atraso)
	tween.tween_property(no, "modulate:a", 1.0, 0.3).set_delay(atraso)


## Aumenta levemente o botão quando o mouse/dedo passa por cima.
static func destacar_ao_passar(botao: Control, escala := 1.05) -> void:
	botao.resized.connect(func(): botao.pivot_offset = botao.size / 2)
	botao.mouse_entered.connect(func(): botao.create_tween().tween_property(botao, "scale", Vector2.ONE * escala, 0.12))
	botao.mouse_exited.connect(func(): botao.create_tween().tween_property(botao, "scale", Vector2.ONE, 0.12))
