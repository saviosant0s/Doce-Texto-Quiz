class_name Personagens
## Personagens de doces do jogo. Os antigos são PNG (recortados das artes de
## 2023); os novos são SVG desenhados por código.

static func textura(nome: String) -> Texture2D:
	for extensao in ["svg", "png"]:
		var caminho := "res://assets/personagens/%s.%s" % [nome, extensao]
		if ResourceLoader.exists(caminho):
			return load(caminho)
	push_error("Personagem não encontrado: " + nome)
	return null
