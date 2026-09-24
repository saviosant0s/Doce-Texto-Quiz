@tool
class_name Fundo
extends Control
## Fundo roxo das telas, com decoração desenhada por código (sem imagens).

enum Decoracao { NENHUMA, ESTRELAS, CONFETE, BALAS }

@export var decoracao := Decoracao.NENHUMA:
	set(valor):
		decoracao = valor
		_gerar()
@export var quantidade := 60:
	set(valor):
		quantidade = valor
		_gerar()
## Anima a decoração: confete caindo, estrelas piscando, balas deslizando.
## Desligado sozinho em aparelhos sem aceleração de vídeo.
@export var animar := true

const CORES_CONFETE := [Cores.AMARELO, Cores.ROSA, Cores.AZUL, Cores.VERDE, Cores.CREME]

var _itens: Array[Dictionary] = []
var _tempo := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	resized.connect(_gerar)
	_gerar()


func _gerar() -> void:
	_itens.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2023
	var area := size if size != Vector2.ZERO else Vector2(1280, 720)
	for i in quantidade:
		_itens.append({
			"pos": Vector2(rng.randf() * area.x, rng.randf() * area.y),
			"tamanho": rng.randf_range(3.0, 9.0),
			"fase": rng.randf() * TAU,
			"giro": rng.randf_range(-2.0, 2.0),
			"velocidade": rng.randf_range(30.0, 80.0),
			"cor": CORES_CONFETE[rng.randi() % CORES_CONFETE.size()],
		})
	queue_redraw()


func _process(delta: float) -> void:
	if not animar or decoracao == Decoracao.NENHUMA or Engine.is_editor_hint():
		return
	# O confete é a animação principal da tela de resultado: mantém sempre
	if decoracao != Decoracao.CONFETE and not Jogo.animacoes_continuas:
		return
	_tempo += delta
	if decoracao == Decoracao.CONFETE:
		for item in _itens:
			item["pos"].y += item["velocidade"] * delta
			item["pos"].x += sin(_tempo + item["fase"]) * 20.0 * delta
			if item["pos"].y > size.y + 10:
				item["pos"].y = -10
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Cores.ROXO)
	match decoracao:
		Decoracao.ESTRELAS:
			for item in _itens:
				var brilho := 0.55 + 0.45 * sin(_tempo * 1.5 + item["fase"])
				_estrela(item["pos"], item["tamanho"], Color(Cores.AMARELO, brilho))
		Decoracao.BALAS:
			_desenhar_estampa_balas()
		Decoracao.CONFETE:
			for item in _itens:
				var angulo: float = item["fase"] + _tempo * item["giro"]
				draw_set_transform(item["pos"], angulo)
				var t: float = item["tamanho"]
				draw_rect(Rect2(-t, -t * 0.4, t * 2.0, t * 0.8), item["cor"])
			draw_set_transform(Vector2.ZERO)


## Estampa discreta: silhuetas de balas espalhadas, quase da cor do fundo.
func _desenhar_estampa_balas() -> void:
	var cor := Color(Cores.ROXO_ESCURO, 0.45)
	var espaco := Vector2(150, 120)
	# a estampa desliza devagar na diagonal
	var movimento := Vector2(fposmod(_tempo * 12.0, espaco.x), fposmod(_tempo * 6.0, espaco.y * 2.0))
	var linhas := int(size.y / espaco.y) + 3
	var colunas := int(size.x / espaco.x) + 3
	for l in linhas:
		for c in colunas:
			var deslocamento := espaco.x / 2.0 if l % 2 == 1 else 0.0
			var centro := Vector2(c * espaco.x + deslocamento, l * espaco.y + 40) + movimento - espaco * Vector2(1, 2)
			var angulo := deg_to_rad(-25.0 if (l + c) % 2 == 0 else 20.0)
			draw_set_transform(centro, angulo)
			draw_colored_polygon(_elipse(Vector2.ZERO, Vector2(15, 10)), cor)
			for lado in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([
					Vector2(lado * 12, 0), Vector2(lado * 25, -9), Vector2(lado * 25, 9),
				]), cor)
	draw_set_transform(Vector2.ZERO)


func _elipse(centro: Vector2, raio: Vector2) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20
		pontos.append(centro + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	return pontos


func _estrela(centro: Vector2, raio: float, cor: Color) -> void:
	var pontos := PackedVector2Array()
	for i in 10:
		var r := raio if i % 2 == 0 else raio * 0.45
		var a := -PI / 2 + i * PI / 5
		pontos.append(centro + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pontos, cor)
