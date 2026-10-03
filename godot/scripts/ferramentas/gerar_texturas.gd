extends SceneTree
## Gera as texturas com relevo dos prédios da vila (assets/texturas/): para
## cada uma, um "detalhe" em tons de cinza (multiplica a cor do material) e um
## mapa de relevo (normal map). Rodar de novo só se mudar o desenho delas:
##   godot --headless --path godot --script res://scripts/ferramentas/gerar_texturas.gd

const PASTA := "res://assets/texturas/"
const TAMANHO := 256


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	_salvar("biscoito", _biscoito(), 5.0)
	_salvar("telhas", _telhas(), 7.0)
	_salvar("pedras", _pedras(), 6.0)
	_salvar("glace", _glace(), 4.0, 0.93)
	_salvar("pregas", _pregas(), 6.0)
	print("texturas geradas em ", PASTA)
	quit()


## Salva o detalhe (altura clareada) e o normal map a partir de uma altura 0..1.
## `claro` = tom mais escuro do detalhe (1 = sem escurecer; glacê é bem claro).
func _salvar(nome: String, altura: Image, forca: float, claro := 0.72) -> void:
	var detalhe := Image.create(TAMANHO, TAMANHO, false, Image.FORMAT_RGB8)
	for y in TAMANHO:
		for x in TAMANHO:
			var h := altura.get_pixel(x, y).r
			var tom := claro + h * (1.0 - claro)  # buracos e juntas mais escuros
			detalhe.set_pixel(x, y, Color(tom, tom, tom))
	detalhe.save_png(ProjectSettings.globalize_path(PASTA + nome + ".png"))
	var normal := altura.duplicate()
	normal.convert(Image.FORMAT_RGBA8)
	normal.bump_map_to_normal_map(forca)
	normal.save_png(ProjectSettings.globalize_path(PASTA + nome + "_relevo.png"))


func _ruido(semente: int, frequencia: float) -> FastNoiseLite:
	var ruido := FastNoiseLite.new()
	ruido.seed = semente
	ruido.frequency = frequencia
	return ruido


func _nova() -> Image:
	return Image.create(TAMANHO, TAMANHO, false, Image.FORMAT_RGB8)


## Distância "que dá a volta" (a textura se repete sem emenda).
func _dist(a: Vector2, b: Vector2) -> float:
	var d := (a - b).abs()
	d.x = minf(d.x, TAMANHO - d.x)
	d.y = minf(d.y, TAMANHO - d.y)
	return d.length()


## Biscoito de gengibre: massa com granulação e furinhos de garfo.
func _biscoito() -> Image:
	var img := _nova()
	var fino := _ruido(3, 0.09)
	var grosso := _ruido(4, 0.02)
	var furos := []
	for i in 6:
		for j in 6:
			furos.append(Vector2((i + 0.5 + (j % 2) * 0.5) * TAMANHO / 6.0, (j + 0.5) * TAMANHO / 6.0))
	for y in TAMANHO:
		for x in TAMANHO:
			var h := 0.6 + fino.get_noise_2d(x, y) * 0.15 + grosso.get_noise_2d(x, y) * 0.2
			for f in furos:
				var d := _dist(Vector2(x, y), f)
				if d < 5.0:
					h -= (1.0 - d / 5.0) * 0.5
			img.set_pixel(x, y, Color(h, h, h).clamp())
	return img


## Telhas em escama (fileiras de meias-luas deslocadas).
func _telhas() -> Image:
	var img := _nova()
	var linhas := 8
	var colunas := 8
	var alto := TAMANHO / float(linhas)
	var largo := TAMANHO / float(colunas)
	var ruido := _ruido(5, 0.08)
	for y in TAMANHO:
		for x in TAMANHO:
			var linha := int(y / alto)
			var desloca := largo * 0.5 * (linha % 2)
			var cx := fposmod(x + desloca, largo) - largo * 0.5
			var cy := fposmod(y, alto)
			# cada telha é uma meia-lua com a borda de baixo arredondada
			var d := Vector2(cx / (largo * 0.5), (cy - alto * 0.1) / alto).length()
			var h := clampf(1.0 - d, 0.0, 1.0) * 0.8 + 0.15
			if d > 1.0:
				h = 0.08
			h += ruido.get_noise_2d(x, y) * 0.05
			img.set_pixel(x, y, Color(h, h, h).clamp())
	return img


## Pedras em fileiras (tijolinhos de açúcar), com juntas fundas.
func _pedras() -> Image:
	var img := _nova()
	var linhas := 8
	var alto := TAMANHO / float(linhas)
	var largo := TAMANHO / 4.0
	var ruido := _ruido(6, 0.06)
	for y in TAMANHO:
		for x in TAMANHO:
			var linha := int(y / alto)
			var bx := fposmod(x + largo * 0.5 * (linha % 2), largo)
			var by := fposmod(y, alto)
			var borda := minf(minf(bx, largo - bx), minf(by, alto - by))
			var h := clampf(borda / 4.0, 0.0, 1.0) * 0.7 + 0.2 + ruido.get_noise_2d(x, y) * 0.1
			img.set_pixel(x, y, Color(h, h, h).clamp())
	return img


## Glacê: ondulações macias.
func _glace() -> Image:
	var img := _nova()
	var ruido := _ruido(7, 0.035)
	ruido.fractal_octaves = 2
	for y in TAMANHO:
		for x in TAMANHO:
			var h := 0.5 + ruido.get_noise_2d(x, y) * 0.5
			img.set_pixel(x, y, Color(h, h, h).clamp())
	return img


## Forminha de papel: pregas verticais.
func _pregas() -> Image:
	var img := _nova()
	var ruido := _ruido(8, 0.05)
	for y in TAMANHO:
		for x in TAMANHO:
			var h := 0.5 + 0.45 * sin(x * TAU * 8.0 / TAMANHO) + ruido.get_noise_2d(x, y) * 0.04
			img.set_pixel(x, y, Color(h, h, h).clamp())
	return img
