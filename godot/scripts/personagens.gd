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


## Troca a imagem parada de um personagem (TextureRect) pelo doce 3D vivo, que
## gira com o dedo, pisca e acena. O TextureRect continua no lugar (tamanho e
## animações de entrada), só sem a imagem. Em aparelhos sem placa de vídeo, a
## foto parada continua (3D ali travaria). Retorna o Doce3D, ou null.
## Folga em volta do doce 3D (fração do tamanho da imagem, em cada lado).
const FOLGA_3D := 0.22


static func animar(imagem: TextureRect, nome: String, silhueta := false,
		cor_silhueta := Color(0.29, 0.19, 0.47, 0.9)) -> Doce3D:
	var id: String = FOTOS_3D.get(nome, nome)
	if not Telas.placa_rapida or not ResourceLoader.exists("res://assets/doces_3d/fotos/%s.png" % id):
		return null
	var doce := Doce3D.new()
	doce.name = "Doce3D"
	doce.id = id
	doce.silhueta = silhueta
	doce.cor_silhueta = cor_silhueta
	# Área de desenho maior que o espaço da imagem (folga em volta), para a mão
	# que acena e o pulinho não serem cortados pela borda; a câmera se afasta
	# na mesma proporção, então o doce continua do mesmo tamanho na tela.
	doce.distancia = 4.5 * (1.0 + 2.0 * FOLGA_3D)
	doce.anchor_left = -FOLGA_3D
	doce.anchor_top = -FOLGA_3D
	doce.anchor_right = 1.0 + FOLGA_3D
	doce.anchor_bottom = 1.0 + FOLGA_3D
	imagem.add_child(doce)
	imagem.move_child(doce, 0)  # atrás de cadeados e outros enfeites
	imagem.mouse_filter = Control.MOUSE_FILTER_PASS
	# a foto fica até o 3D aparecer (sem "buraco" roxo enquanto ele prepara)
	doce.pronto.connect(func():
		if is_instance_valid(imagem):
			imagem.texture = null
			imagem.material = null, CONNECT_ONE_SHOT)
	return doce
