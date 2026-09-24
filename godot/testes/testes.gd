extends Node
## Testes automáticos do jogo. Rodar (na pasta do repositório):
##     godot --headless --path godot --scene res://testes/testes.tscn
## Sai com código 0 se tudo passar e 1 se algo falhar. Não mexe no save do
## jogador (Progresso.somente_memoria).
##
## A cena de teste troca de tela durante o fluxo completo, então quem executa
## os testes é um nó separado, pendurado na raiz (sobrevive às trocas).

func _ready() -> void:
	var executor := Node.new()
	executor.set_script(preload("res://testes/executor.gd"))
	get_tree().root.add_child.call_deferred(executor)
