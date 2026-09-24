extends Button
## Cartão clicável de um nível na tela de níveis.


func configurar(indice: int, nivel: Dictionary, acertos: int) -> void:
	var total: int = nivel["perguntas"].size()
	%Personagem.texture = load("res://assets/personagens/%s.png" % nivel["personagem"])
	%Nome.text = nivel["nome"].to_upper()
	%Numero.text = "NÍVEL %d" % (indice + 1)
	%Progresso.max_value = total
	%Progresso.value = acertos
	%Acertos.text = "%d/%d acertos" % [acertos, total]
	pressed.connect(Jogo.iniciar_nivel.bind(indice))
	Animacoes.destacar_ao_passar(self)
