class_name Personagens
## Personagens de doces do jogo. Os antigos são PNG (recortados das artes de
## 2023); os novos são SVG desenhados por código.

## Personagens que podem aparecer na tela de carregamento.
const CARREGAMENTO := [
	"fantasma_chocolate", "brigadeiro_feliz", "pirulito", "rosquinha", "sorvete",
	"picole", "macaron", "pudim", "jujuba", "bolo", "cupcake_pro", "maca_noob",
	"doce_facil", "doce_medio", "doce_dificil", "mascote_cereal",
]


static func textura(nome: String) -> Texture2D:
	for extensao in ["svg", "png"]:
		var caminho := "res://assets/personagens/%s.%s" % [nome, extensao]
		if ResourceLoader.exists(caminho):
			return load(caminho)
	push_error("Personagem não encontrado: " + nome)
	return null
