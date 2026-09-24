class_name Personagens
## Personagens de doces do jogo, carregados pelo nome do arquivo em
## assets/personagens. Se existir um PNG com o mesmo nome de um SVG, o PNG é
## usado: para trocar um personagem por uma imagem nova, basta salvar o PNG lá.

static func textura(nome: String) -> Texture2D:
	for extensao in ["png", "svg"]:
		var caminho := "res://assets/personagens/%s.%s" % [nome, extensao]
		if ResourceLoader.exists(caminho):
			return load(caminho)
	push_error("Personagem não encontrado: " + nome)
	return null


## Material que desenha o personagem como silhueta de cor única (bloqueado).
## Em fundo claro use a cor padrão (roxo escuro); em fundo roxo, uma cor clara.
static func material_silhueta(cor := Color(0.29, 0.19, 0.47, 0.9)) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://tema/silhueta.gdshader")
	material.set_shader_parameter("cor", cor)
	return material
