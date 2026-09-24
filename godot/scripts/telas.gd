extends Node
## Navegação entre telas (com transição), avisos, caixa de confirmação e ajustes
## de exibição. Disponível como `Telas` (autoload).

const DURACAO_TRANSICAO := 0.25
## Gerado ao publicar (commit e data do build); não existe ao rodar pelo editor.
const CAMINHO_BUILD := "res://dados/build.json"

const CENAS := {
	"inicio": "res://cenas/inicio.tscn",
	"niveis": "res://cenas/niveis.tscn",
	"como_jogar": "res://cenas/como_jogar.tscn",
	"creditos": "res://cenas/creditos.tscn",
	"sobre": "res://cenas/sobre.tscn",
	"titulos": "res://cenas/titulos.tscn",
	"carregamento": "res://cenas/carregamento.tscn",
	"partida": "res://cenas/partida.tscn",
	"aproveitamento": "res://cenas/aproveitamento.tscn",
	"resultado": "res://cenas/resultado.tscn",
}

## Falso quando o navegador desenha sem placa de vídeo (renderização por
## software): aí as animações contínuas travam o jogo e ficam desligadas.
var animacoes_continuas := true

var _historico: Array[String] = []
var _cortina: ColorRect
var _camada_avisos: CanvasLayer
var _trocando := false


func _ready() -> void:
	_detectar_renderizacao()
	_criar_cortina()
	_criar_aviso_girar()


# --- Navegação ---------------------------------------------------------------

## Troca para a tela `nome` (ver CENAS) com um fade.
func ir_para(nome: String) -> void:
	_historico.clear()
	_trocar_cena(CENAS[nome])


## Abre uma tela lembrando a atual, para `voltar()` retornar a ela.
func abrir(nome: String) -> void:
	_historico.push_back(get_tree().current_scene.scene_file_path)
	_trocar_cena(CENAS[nome])


func voltar() -> void:
	if _historico.is_empty():
		ir_para("inicio")
	else:
		_trocar_cena(_historico.pop_back())


func _trocar_cena(caminho: String) -> void:
	if _trocando:
		return
	_trocando = true
	var tween := create_tween()
	tween.tween_property(_cortina, "color:a", 1.0, DURACAO_TRANSICAO)
	await tween.finished
	get_tree().change_scene_to_file(caminho)
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_cortina, "color:a", 0.0, DURACAO_TRANSICAO)
	_trocando = false


# --- Avisos e confirmação ----------------------------------------------------

## Mostra uma mensagem curta na parte de baixo da tela.
func mostrar_aviso(texto: String) -> void:
	var aviso := PanelContainer.new()
	aviso.theme_type_variation = &"Etiqueta"
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.text = texto
	aviso.add_child(rotulo)
	_camada_avisos.add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 40)
	aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	aviso.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(aviso, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.6)
	tween.tween_property(aviso, "modulate:a", 0.0, 0.3)
	tween.tween_callback(aviso.queue_free)


## Pergunta algo ao jogador e espera a resposta. Uso:
##     if await Telas.confirmar("SAIR?", "Seu progresso será perdido.", "SAIR", "CONTINUAR"):
func confirmar(titulo: String, texto: String, sim := "SIM", nao := "NÃO") -> bool:
	var caixa := preload("res://componentes/confirmacao.tscn").instantiate()
	_camada_avisos.add_child(caixa)
	caixa.configurar(titulo, texto, sim, nao)
	var resposta: bool = await caixa.respondido
	caixa.fechar()
	return resposta


# --- Exibição ----------------------------------------------------------------

## Texto da versão, ex.: "v0.3.0 · 1c262ea · 24/09 15:10".
func versao() -> String:
	var texto := "v" + str(ProjectSettings.get_setting("application/config/version", "0"))
	if FileAccess.file_exists(CAMINHO_BUILD):
		var build = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_BUILD))
		if build is Dictionary:
			texto += " · %s · %s" % [build.get("commit", "?"), build.get("data", "?")]
	else:
		texto += " · dev"
	return texto


func _detectar_renderizacao() -> void:
	var placa := RenderingServer.get_video_adapter_name().to_lower()
	if OS.has_feature("web"):
		# No navegador o Godot só vê "WebGL"; o nome real vem da extensão de depuração
		placa = str(JavaScriptBridge.eval("""(function () {
			var gl = document.createElement('canvas').getContext('webgl2');
			if (!gl) return 'software';
			var info = gl.getExtension('WEBGL_debug_renderer_info');
			return info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
		})()""", true)).to_lower()
	for software in ["swiftshader", "llvmpipe", "software", "basic render"]:
		if software in placa:
			animacoes_continuas = false
	print("Placa de vídeo: %s (animações contínuas: %s)" % [placa, animacoes_continuas])


func _criar_cortina() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)
	_cortina = ColorRect.new()
	_cortina.color = Color(Cores.ROXO, 0.0)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(_cortina)
	_camada_avisos = CanvasLayer.new()
	_camada_avisos.layer = 90
	add_child(_camada_avisos)


## No navegador do celular, pede para girar o aparelho quando está em pé.
func _criar_aviso_girar() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 99
	add_child(camada)
	var aviso := ColorRect.new()
	aviso.color = Cores.ROXO
	aviso.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(aviso)
	var texto := Label.new()
	texto.theme_type_variation = &"TituloGrande"
	texto.add_theme_font_size_override("font_size", 150)
	texto.text = "GIRE O CELULAR\nPARA JOGAR DEITADO"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	aviso.add_child(texto)
	var atualizar := func():
		var tamanho := get_viewport().get_visible_rect().size
		aviso.visible = tamanho.y > tamanho.x
	get_viewport().size_changed.connect(atualizar)
	atualizar.call()
