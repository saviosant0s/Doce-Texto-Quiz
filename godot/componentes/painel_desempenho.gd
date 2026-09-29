class_name PainelDesempenho
extends CanvasLayer
## Indicador de desempenho (liga nas Configurações): FPS, tempo de cada
## quadro, memória que o jogo usa, memória livre do aparelho, memória de vídeo
## e quanto a tela desenha por quadro. Fica por cima de tudo, pequeno, no
## canto esquerdo; atualiza duas vezes por segundo. Para testes.

var _texto: Label
var _tempo := 0.0


func _ready() -> void:
	layer = 120
	name = "PainelDesempenho"
	var fundo := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.04, 0.16, 0.72)
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	fundo.add_theme_stylebox_override("panel", estilo)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.anchor_top = 0.37  # abaixo do quadro da história da vila
	fundo.anchor_bottom = 0.37
	fundo.offset_left = 8
	add_child(fundo)
	_texto = Label.new()
	_texto.name = "TextoDesempenho"
	_texto.add_theme_font_size_override("font_size", 15)
	_texto.add_theme_color_override("font_color", Color("#B8FFB8"))
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(_texto)
	atualizar()


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= 0.5:
		_tempo = 0.0
		atualizar()


func atualizar() -> void:
	var fps := Engine.get_frames_per_second()
	var linhas := ["FPS %d  (%.1f ms)" % [fps, 1000.0 / maxf(1.0, fps)]]
	linhas.append("MEMÓRIA DO JOGO %s" % _mb(Performance.get_monitor(Performance.MEMORY_STATIC)))
	var memoria := OS.get_memory_info()
	if int(memoria.get("physical", -1)) > 0:
		linhas.append("APARELHO %s LIVRES DE %s" % [_mb(memoria.get("available", memoria.get("free", 0))), _mb(memoria["physical"])])
	linhas.append("VÍDEO %s" % _mb(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))
	linhas.append("DESENHOS %d · OBJETOS %d" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
	linhas.append("TRIÂNGULOS %dk" % int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000))
	_texto.text = "\n".join(linhas)


static func _mb(bytes: float) -> String:
	return "%d MB" % roundi(bytes / 1048576.0) if bytes < 1073741824.0 else "%.1f GB" % (bytes / 1073741824.0)
