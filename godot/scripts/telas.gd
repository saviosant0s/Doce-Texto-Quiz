extends Node
## Navegação entre telas (com transição), avisos, caixa de confirmação e ajustes
## de exibição. Disponível como `Telas` (autoload).

const DURACAO_TRANSICAO := 0.25

const CENAS := {
	"inicio": "res://cenas/inicio.tscn",
	"niveis": "res://cenas/niveis.tscn",
	"como_jogar": "res://cenas/como_jogar.tscn",
	"creditos": "res://cenas/creditos.tscn",
	"sobre": "res://cenas/sobre.tscn",
	"titulos": "res://cenas/titulos.tscn",
	"colecao": "res://cenas/colecao.tscn",
	"confeitaria": "res://cenas/confeitaria.tscn",
	"cozinha": "res://cenas/cozinha.tscn",
	"doce_match": "res://cenas/doce_match.tscn",
	"laboratorio": "res://cenas/laboratorio.tscn",
	"lab_fase": "res://cenas/lab_fase.tscn",
	"baus": "res://cenas/baus.tscn",
	"missoes": "res://cenas/missoes.tscn",
	"vila": "res://cenas/vila.tscn",
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
var _carregando: VBoxContainer
var _destino := ""
var _pendente := ""
var _camada_avisos: CanvasLayer
var _trocando := false


func _ready() -> void:
	_ajustar_fisica()
	_detectar_renderizacao()
	_criar_cortina()
	_criar_aviso_girar()
	_tirar_dicas.call_deferred()


## A física (o andar dos doces) roda no ritmo da tela do aparelho (60, 90 ou
## 120 Hz), para o movimento não "dar degraus" em telas mais rápidas.
func _ajustar_fisica() -> void:
	var hz := roundi(DisplayServer.screen_get_refresh_rate())
	if hz >= 60:
		Engine.physics_ticks_per_second = clampi(hz, 60, 120)
		Engine.max_physics_steps_per_frame = 4


# --- Navegação ---------------------------------------------------------------

## Troca para a tela `nome` (ver CENAS) com um fade.
func ir_para(nome: String) -> void:
	_historico.clear()
	_trocar_cena(CENAS[nome])


## Abre uma tela lembrando a atual, para `voltar()` retornar a ela.
func abrir(nome: String) -> void:
	_historico.push_back(get_tree().current_scene.scene_file_path)
	_trocar_cena(CENAS[nome])


## "Casa" do jogador: a Vila dos Doces (ou os níveis, em aparelhos sem placa
## de vídeo, onde a vila em 3D travaria).
func ir_para_casa() -> void:
	ir_para("vila" if placa_rapida else "niveis")


## Minha Confeitaria: a cozinha 3D ou, sem placa de vídeo, o painel simples.
func abrir_confeitaria() -> void:
	abrir("cozinha" if placa_rapida else "confeitaria")


func voltar() -> void:
	if _historico.is_empty():
		ir_para("inicio")
	else:
		_trocar_cena(_historico.pop_back())


func _trocar_cena(caminho: String) -> void:
	if _trocando:
		# pedido no meio de uma troca (ex.: o carregamento indo para a partida):
		# fica na fila; toque repetido para a mesma tela é ignorado
		if caminho != _destino:
			_pendente = caminho
		return
	_trocando = true
	_destino = caminho
	var tween := create_tween()
	tween.tween_property(_cortina, "color:a", 1.0, DURACAO_TRANSICAO)
	await tween.finished
	# telas 3D demoram um pouco para montar: mostra "carregando" com o doce
	# companheiro (já desenhado antes de a montagem começar)
	var pesada := caminho in [CENAS["vila"], CENAS["cozinha"]]
	if pesada:
		_mostrar_carregando()
		await quadro_desenhado()
	get_tree().change_scene_to_file(caminho)
	await get_tree().process_frame
	# só abre a cortina depois de a tela nova ter sido desenhada (a primeira
	# imagem de uma cena 3D é a mais demorada)
	for i in 2:
		await quadro_desenhado()
	_carregando.visible = false
	_tirar_dicas()
	_trocando = false
	if not _pendente.is_empty():
		var proxima := _pendente
		_pendente = ""
		_trocar_cena(proxima)  # a cortina continua fechada
		return
	tween = create_tween()
	tween.tween_property(_cortina, "color:a", 0.0, DURACAO_TRANSICAO)


## Espera a tela ser desenhada (sem tela, nos testes, espera um quadro).
func quadro_desenhado() -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw


func _mostrar_carregando() -> void:
	var id := Colecao.companheiro()
	(_carregando.get_node("Doce") as TextureRect).texture = Personagens.textura(id if not id.is_empty() else "brigadeiro")
	_carregando.visible = true


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


## Explicação curta que aparece só na primeira vez que o jogador abre uma
## tela nova (baús, coleção, missões, laboratório). Fica marcada em
## Progresso.config["dicas_vistas"]. Nos prints e testes (somente_memoria) não
## aparece, a não ser com `forcar`.
func dica_primeira_vez(id: String, titulo: String, texto: String, forcar := false) -> void:
	var vistas: Array = Progresso.config.get("dicas_vistas", [])
	if id in vistas or (Progresso.somente_memoria and not forcar):
		return
	vistas.append(id)
	Progresso.config["dicas_vistas"] = vistas
	Progresso.salvar()
	var caixa := preload("res://componentes/confirmacao.tscn").instantiate()
	caixa.name = "DicaPrimeiraVez"
	_camada_avisos.add_child(caixa)
	caixa.configurar(titulo, texto, "ENTENDI!", "")
	caixa.get_node("%Nao").visible = false
	await caixa.respondido
	caixa.fechar()


# --- Exibição ----------------------------------------------------------------

## Em tela de toque, as dicas de botão (tooltips) aparecem ao segurar o dedo,
## escuras e sem sentido; ficam só no computador, onde aparecem com o mouse.
func _tirar_dicas() -> void:
	if not DisplayServer.is_touchscreen_available() or get_tree().current_scene == null:
		return
	for no in get_tree().current_scene.find_children("*", "Control", true, false):
		no.tooltip_text = ""


## Texto da versão mostrado nas telas, ex.: "v0.4.0".
func versao() -> String:
	return "v" + str(ProjectSettings.get_setting("application/config/version", "0"))


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
	# "CARREGANDO..." com o doce companheiro, no meio da cortina
	_carregando = VBoxContainer.new()
	_carregando.name = "Carregando"
	_carregando.visible = false
	_carregando.alignment = BoxContainer.ALIGNMENT_CENTER
	_carregando.set_anchors_preset(Control.PRESET_FULL_RECT)
	_carregando.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.add_child(_carregando)
	var doce := TextureRect.new()
	doce.name = "Doce"
	doce.custom_minimum_size = Vector2(0, 180)
	doce.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	doce.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_carregando.add_child(doce)
	var texto := Label.new()
	texto.theme_type_variation = &"TituloClaro"
	texto.text = "CARREGANDO..."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_carregando.add_child(texto)
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
