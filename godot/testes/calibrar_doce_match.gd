extends Node
## Robô que joga cada nível do Doce Match escolhendo a melhor troca do momento
## (guloso), para calibrar metas e estrelas. Uso:
##   godot --headless --path godot res://testes/calibrar_doce_match.tscn
## Imprime, por nível: vitórias, pontos ao vencer e quanto dos objetivos fez.

const PARTIDAS := 10


func _ready() -> void:
	for dados in DoceMatch.niveis():
		var vitorias := 0
		var pontos := []
		var feitos := []
		var sobras := []
		for semente in PARTIDAS:
			var jogo := DoceMatch.new(dados, 1000 + semente)
			while not jogo.acabou():
				var melhor := _melhor_troca(jogo)
				if melhor.is_empty():
					break
				jogo.trocar(melhor[0], melhor[1])
				jogo.resolver()
			var fracao := 1.0
			for obj in dados["objetivos"]:
				var p := jogo.progresso_objetivo(obj)
				fracao = minf(fracao, float(p[0]) / maxf(1.0, p[1]))
			feitos.append(fracao)
			if jogo.venceu():
				vitorias += 1
				sobras.append(jogo.jogadas)
				jogo.bonus_de_jogadas()
				pontos.append(jogo.pontos)
		pontos.sort()
		print("nivel %d: vitorias %d/%d  feito_medio %.2f  sobras %s  pontos %s" % [
			dados["numero"], vitorias, PARTIDAS, feitos.reduce(func(a, b): return a + b, 0.0) / PARTIDAS, sobras, pontos])
	get_tree().quit()


func _valor(jogo: DoceMatch) -> float:
	var v := 0.0
	for obj in jogo.nivel["objetivos"]:
		var p := jogo.progresso_objetivo(obj)
		v += float(p[0]) / maxf(1.0, p[1])
	return v * 1000.0 + jogo.pontos * 0.01


func _melhor_troca(jogo: DoceMatch) -> Array:
	var melhor := []
	var melhor_valor := -1.0
	for y in DoceMatch.ALTURA:
		for x in DoceMatch.LARGURA:
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var a := Vector2i(x, y)
				var b: Vector2i = a + d
				if not jogo.dentro(b):
					continue
				var c := jogo.copia()
				if not c.trocar(a, b):
					continue
				c.resolver()
				var v := _valor(c)
				if v > melhor_valor:
					melhor_valor = v
					melhor = [a, b]
	return melhor
