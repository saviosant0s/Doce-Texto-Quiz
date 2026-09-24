extends Control
## Caixa de confirmação modal. Use via Telas.confirmar(), que espera a resposta.

signal respondido(sim: bool)

var _respondeu := false


func configurar(titulo: String, texto: String, sim: String, nao: String) -> void:
	%Titulo.text = titulo
	%Texto.text = texto
	%Sim.text = sim
	%Nao.text = nao
	%Sim.pressed.connect(_responder.bind(true))
	%Nao.pressed.connect(_responder.bind(false))
	%Escurecer.gui_input.connect(func(evento):
		if evento is InputEventMouseButton and evento.pressed:
			_responder(false))  # tocar fora da caixa = cancelar
	modulate.a = 0.0
	%Cartao.resized.connect(func(): %Cartao.pivot_offset = %Cartao.size / 2)
	%Cartao.scale = Vector2.ONE * 0.85
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.tween_property(%Cartao, "scale", Vector2.ONE, 0.25)
	%Nao.grab_focus.call_deferred()


func _unhandled_input(evento: InputEvent) -> void:
	# botão "voltar" do Android e tecla Esc cancelam
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_responder(false)


func _responder(sim: bool) -> void:
	if _respondeu:
		return
	_respondeu = true
	respondido.emit(sim)


func fechar() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)
