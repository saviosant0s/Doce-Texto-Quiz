extends Node
## Estado compartilhado entre as telas, navegação e salvamento do progresso.
## Disponível em qualquer script como `Jogo` (autoload).

const CAMINHO_PERGUNTAS := "res://dados/perguntas.json"
const CAMINHO_SALVAMENTO := "user://salvamento.json"
## Gerado ao publicar (commit e data do build); não existe ao rodar pelo editor.
const CAMINHO_BUILD := "res://dados/build.json"
const TEMPO_POR_PERGUNTA := 30.0
const DURACAO_TRANSICAO := 0.25

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

## Resultado final conforme o aproveitamento (%): até `limite` → `id`.
const FAIXAS := [
	{"limite": 30, "id": "nodoc", "moedas": 0},
	{"limite": 50, "id": "noob", "moedas": 40},
	{"limite": 80, "id": "pro", "moedas": 60},
	{"limite": 100, "id": "mestre", "moedas": 100},
]

## Níveis e perguntas, lidos de dados/perguntas.json.
var niveis: Array = []

# Partida atual
var nivel_atual := 0
var resultados: Array[bool] = []  # acertou/errou de cada pergunta
var resultado := ""  # "nodoc", "noob", "pro" ou "mestre"

# Progresso salvo
var acertos_por_nivel: Array = [0, 0, 0]
var titulos := {"noob": 0, "pro": 0, "mestre": 0}
var moedas := 0
var musica_ligada := true

var _historico: Array[String] = []
var _modo_captura := false  # não salva nada ao gerar prints
var _cortina: ColorRect
var _trocando := false


func _ready() -> void:
	niveis = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_PERGUNTAS))["niveis"]
	carregar()
	_criar_cortina()
	_criar_aviso_girar()
	_verificar_captura()


# --- Navegação -------------------------------------------------------------

## Texto da versão, ex.: "v0.2.0 · 1c262ea · 24/09 15:10".
func versao() -> String:
	var texto := "v" + str(ProjectSettings.get_setting("application/config/version", "0"))
	if FileAccess.file_exists(CAMINHO_BUILD):
		var build = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_BUILD))
		if build is Dictionary:
			texto += " · %s · %s" % [build.get("commit", "?"), build.get("data", "?")]
	else:
		texto += " · dev"
	return texto


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


func _criar_cortina() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)
	_cortina = ColorRect.new()
	_cortina.color = Color(Cores.ROXO, 0.0)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(_cortina)


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


## Mostra uma mensagem curta na parte de baixo da tela.
func mostrar_aviso(texto: String) -> void:
	var aviso := PanelContainer.new()
	aviso.theme_type_variation = &"Etiqueta"
	var rotulo := Label.new()
	rotulo.theme_type_variation = &"TituloClaro"
	rotulo.text = texto
	aviso.add_child(rotulo)
	_cortina.get_parent().add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 40)
	aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	aviso.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(aviso, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.4)
	tween.tween_property(aviso, "modulate:a", 0.0, 0.3)
	tween.tween_callback(aviso.queue_free)


# --- Partida ---------------------------------------------------------------

func iniciar_nivel(indice: int) -> void:
	nivel_atual = indice
	resultados.clear()
	ir_para("carregamento")


func perguntas_do_nivel() -> Array:
	return niveis[nivel_atual]["perguntas"]


func aproveitamento() -> int:
	if resultados.is_empty():
		return 0
	return roundi(100.0 * resultados.count(true) / resultados.size())


## Registra o fim da partida: salva acertos, título e moedas.
func finalizar_partida() -> void:
	acertos_por_nivel[nivel_atual] = resultados.count(true)
	var nota := aproveitamento()
	for faixa in FAIXAS:
		if nota <= faixa["limite"]:
			resultado = faixa["id"]
			moedas += faixa["moedas"]
			break
	if titulos.has(resultado):
		titulos[resultado] += 1
	salvar()


# --- Salvamento ------------------------------------------------------------

func salvar() -> void:
	if _modo_captura:
		return
	var dados := {
		"acertos_por_nivel": acertos_por_nivel,
		"titulos": titulos,
		"moedas": moedas,
		"musica_ligada": musica_ligada,
	}
	var arquivo := FileAccess.open(CAMINHO_SALVAMENTO, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(dados, "  "))


func carregar() -> void:
	if not FileAccess.file_exists(CAMINHO_SALVAMENTO):
		return
	var dados = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO_SALVAMENTO))
	if not dados is Dictionary:
		return
	acertos_por_nivel = dados.get("acertos_por_nivel", acertos_por_nivel)
	titulos.merge(dados.get("titulos", {}), true)
	moedas = int(dados.get("moedas", 0))
	musica_ligada = dados.get("musica_ligada", true)


# --- Captura de tela (para gerar prints das telas) --------------------------
# Uso: godot --path godot -- --capturar=niveis --saida=/caminho/print.png
# Para telas que dependem de uma partida, simula um resultado: --acertos=7

func _verificar_captura() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.trim_prefix("--").split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	if not args.has("capturar"):
		return
	_modo_captura = true
	if args.has("acertos"):
		var acertos := int(args["acertos"])
		for i in 10:
			resultados.append(i < acertos)
		finalizar_partida()
	await get_tree().process_frame
	get_tree().change_scene_to_file(CENAS[args["capturar"]])
	await get_tree().create_timer(float(args.get("espera", "1.2"))).timeout
	var imagem := get_viewport().get_texture().get_image()
	imagem.save_png(args.get("saida", "user://captura.png"))
	get_tree().quit()
