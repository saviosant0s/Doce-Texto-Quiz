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
	"colecao": "res://cenas/colecao.tscn",
	"carregamento": "res://cenas/carregamento.tscn",
	"partida": "res://cenas/partida.tscn",
	"aproveitamento": "res://cenas/aproveitamento.tscn",
	"resultado": "res://cenas/resultado.tscn",
	"configuracoes": "res://cenas/configuracoes.tscn",
}

## Animações que não param (mascote flutuando, estrelas piscando...). Ficam
## desligadas se o jogador desligou nas configurações ou se o aparelho desenha
## sem placa de vídeo (renderização por software), onde elas travam o jogo.
var animacoes_continuas: bool:
	get:
		return placa_rapida and Progresso.config.get("animacoes", true)
## Falso quando o desenho é feito por software (sem aceleração de vídeo).
var placa_rapida := true

var _historico: Array[String] = []
var _cortina: ColorRect
var _camada_avisos: CanvasLayer
var _trocando := false


func _ready() -> void:
	_detectar_renderizacao()
	_criar_cortina()
	_criar_aviso_girar()
	_tirar_dicas.call_deferred()


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
	_tirar_dicas()
	tween = create_tween()
	tween.tween_property(_cortina, "color:a", 0.0, DURACAO_TRANSICAO)
	_trocando = false


## Botão "voltar" do Android (e Esc no computador). A caixa de confirmação
## aberta é cancelada; telas com `ao_voltar()` decidem sozinhas (ex.: partida
## pergunta se quer sair); no início, pergunta se quer fechar o jogo.
func voltar_pelo_botao() -> void:
	var caixas := _camada_avisos.find_children("Confirmacao", "Control", false, false)
	if not caixas.is_empty():
		caixas[0].cancelar()
		return
	var cena := get_tree().current_scene
	if _trocando or cena == null:
		return
	if cena.has_method("ao_voltar"):
		cena.ao_voltar()
	elif cena.name == "Inicio":
		if await confirmar("SAIR DO JOGO?", "Seu progresso fica salvo.", "SAIR", "FICAR"):
			get_tree().quit()
	elif not _historico.is_empty():
		voltar()
	else:
		ir_para("inicio" if cena.name == "Niveis" else "niveis")


func _notification(aviso: int) -> void:
	if aviso == NOTIFICATION_WM_GO_BACK_REQUEST:
		voltar_pelo_botao()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		voltar_pelo_botao()


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
	aviso.reset_size()
	var tela := get_viewport().get_visible_rect().size
	aviso.position = ((tela - aviso.size) * Vector2(0.5, 1.0) - Vector2(0, 40)).round()
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

## Em tela de toque, as dicas de botão (tooltips) aparecem ao segurar o dedo,
## escuras e sem sentido; ficam só no computador, onde aparecem com o mouse.
func _tirar_dicas() -> void:
	if not DisplayServer.is_touchscreen_available() or get_tree().current_scene == null:
		return
	for no in get_tree().current_scene.find_children("*", "Control", true, false):
		no.tooltip_text = ""


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
			placa_rapida = false
	print("Placa de vídeo: %s (aceleração: %s)" % [placa, placa_rapida])


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
