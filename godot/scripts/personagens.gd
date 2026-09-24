class_name Personagens
## Personagens de doces do jogo. Primeiro procura a foto do doce 3D
## (assets/doces_3d/fotos, gerada por ferramentas/gerar_fotos_3d.sh); se não
## houver, usa a imagem em assets/personagens (PNG ou SVG).

## Personagens do jogo agora em 3D: o nome antigo (imagem 2D) aponta para a
## foto do doce 3D equivalente (assets/doces_3d/fotos, ver Doces3D). Assim o
## jogo todo usa o mesmo visual.
const FOTOS_3D := {
	"maca_noob": "maca",
	"cupcake_pro": "cupcake",
	"chocolate_mestre": "chocolate",
	"brigadeiro_triste": "brigadeiro_triste",
	"doce_facil": "bala_verde",
	"doce_medio": "milho_doce",
	"doce_dificil": "bala",
	"fantasma_chocolate": "fantasma",
}


static func textura(nome: String) -> Texture2D:
	var foto := "res://assets/doces_3d/fotos/%s.png" % FOTOS_3D.get(nome, nome)
	if ResourceLoader.exists(foto):
		return load(foto)
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
