class_name Interface
## Ajudas pequenas de interface usadas por várias telas.


## Faz os cartões dentro de uma rolagem deixarem o toque passar, para o dedo
## rolar a lista em qualquer ponto (e não só nos espaços entre os cartões).
## Botões continuam recebendo o toque normalmente.
static func deixar_rolar(conteudo: Control) -> void:
	for no in conteudo.find_children("*", "Control", true, false):
		if not no is BaseButton and not no is ScrollContainer:
			no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
