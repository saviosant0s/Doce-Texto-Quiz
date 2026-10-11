class_name Qualidade
## Qualidade dos gráficos 3D (Configurações > Gráficos): BAIXA, MÉDIA, ALTA ou
## ULTRA. Vale para a Vila dos Doces, a cozinha e a corrida. No celular começa
## em MÉDIA; no computador, em ALTA (MÉDIA em placa integrada). Salvo em
## Progresso.config["qualidade"].
## ULTRA (só em computador com placa de vídeo dedicada): o jogo reinicia no
## renderizador Forward+ do Godot, que tem sombra de contato (SSAO), luz
## rebatida (SSIL), reflexo dos prédios na água (SSR) e raios de luz na névoa
## (ver VisualRealista). As outras usam o renderizador Mobile, mais leve.

enum { BAIXA, MEDIA, ALTA, ULTRA }
const NOMES := ["BAIXA", "MÉDIA", "ALTA", "ULTRA"]

const GRAMA := [0, 1300, 2400, 3600]  # tufos de grama com volume na vila (menos: parecia mato)
const FLORES := [40, 90, 90, 130]
const SOMBRAS := [false, true, true, true]
const ESCALA_3D := [0.6, 0.8, 1.0, 1.0]  # tamanho do 3D em relação à tela
const ANTISSERRILHADO := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_4X]
## Argumento que marca que o jogo já reiniciou para o ULTRA (não tenta de novo).
const MARCA_REINICIO := "--reiniciou_ultra"

## A última tentativa de ULTRA não deu certo e voltou para o padrão (para avisar).
static var desistiu := false
static var _simples := -1  # computador_simples() guardado (nivel() é chamado muitas vezes)


## Começa em MÉDIA no celular e no navegador; no computador, ALTA só com placa
## de vídeo dedicada e mais de 8 GB de memória (placa integrada, como as Intel
## dos notebooks, ou pouca memória: MÉDIA).
static func padrao() -> int:
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return MEDIA
	return MEDIA if computador_simples() else ALTA


static func computador_simples() -> bool:
	if _simples < 0:
		_simples = 1 if _detectar_simples() else 0
	return _simples == 1



static func _detectar_simples() -> bool:
	var placa := RenderingServer.get_video_adapter_name().to_lower()
	if RenderingServer.get_video_adapter_type() == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU:
		return true
	for marca in ["intel", "llvmpipe", "swiftshader", "microsoft basic", "radeon(tm) graphics", "radeon graphics", "vega"]:
		if marca in placa:
			return true
	var memoria := int(OS.get_memory_info().get("physical", 0))
	return memoria > 0 and memoria <= 9 * 1024 * 1024 * 1024


## A tela 3D ficou lenta: desce um nível (até BAIXA). Retorna o nível novo.
static func baixar() -> int:
	var novo := maxi(BAIXA, nivel() - 1)
	escolher(novo)
	return novo


static func nivel() -> int:
	var n := escolhida()
	# ULTRA só vale com o Forward+ ligado (até o jogo reiniciar, é a ALTA)
	return n if n < ULTRA or ultra_ativo() else ALTA


## A qualidade escolhida (pode ser ULTRA esperando o reinício). ULTRA salvo num
## aparelho sem ULTRA vale como o padrão dele.
static func escolhida() -> int:
	var n := clampi(int(Progresso.config.get("qualidade", padrao())), BAIXA, ULTRA)
	return padrao() if n == ULTRA and not tem_ultra() else n


static func escolher(novo: int) -> void:
	Progresso.config["qualidade"] = clampi(novo, BAIXA, ULTRA if tem_ultra() else ALTA)
	Progresso.salvar()


## O ULTRA existe neste aparelho: computador com placa de vídeo dedicada e mais
## de 8 GB (no celular, no navegador e em notebook com placa integrada, não).
static func tem_ultra() -> bool:
	return OS.has_feature("pc") and not OS.has_feature("web") and DisplayServer.get_name() != "headless" \
		and not computador_simples()


## O jogo está rodando no Forward+ (o renderizador do ULTRA).
static func ultra_ativo() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


## Escolheu ULTRA e o jogo ainda está no renderizador leve: reinicia no Forward+.
## Antes de reiniciar, marca "ultra_testando" no salvamento; o jogo no Forward+
## desmarca depois de abrir direito (confirmar_ultra). Se a marca continua lá
## (o jogo no Forward+ fechou, travou ou nem abriu) ou se o Forward+ não ligou,
## desiste e volta para o padrão do aparelho, em vez de tentar de novo toda vez.
static func reiniciar_se_precisar(arvore: SceneTree) -> bool:
	if escolhida() != ULTRA or ultra_ativo() or Progresso.somente_memoria:
		return false
	if MARCA_REINICIO in OS.get_cmdline_user_args() or Progresso.config.get("ultra_testando", false):
		_desistir_do_ultra()
		return false
	Progresso.config["ultra_testando"] = true
	Progresso.salvar()
	if OS.create_process(OS.get_executable_path(), argumentos_ultra()) < 0:
		_desistir_do_ultra()
		return false
	arvore.quit()
	return true


## Os argumentos para abrir o jogo de novo no Forward+: os mesmos de agora
## (menos o renderizador) e a marca de que já reiniciou.
static func argumentos_ultra() -> PackedStringArray:
	var args := PackedStringArray()
	var pular := false
	for arg in OS.get_cmdline_args():
		if pular:
			pular = false
		elif arg == "--rendering-method":
			pular = true
		else:
			args.append(arg)
	args.append_array(PackedStringArray(["--rendering-method", "forward_plus", "--"]))
	args.append_array(OS.get_cmdline_user_args())
	args.append(MARCA_REINICIO)
	return args


## No Forward+: aberto há 12 s sem fechar nem travar, o ULTRA deu certo.
static func confirmar_ultra(arvore: SceneTree) -> void:
	if not ultra_ativo() or not Progresso.config.get("ultra_testando", false):
		return
	await arvore.create_timer(12.0).timeout
	Progresso.config.erase("ultra_testando")
	Progresso.salvar()


static func _desistir_do_ultra() -> void:
	Progresso.config.erase("ultra_testando")
	desistiu = true
	escolher(padrao())


static func grama() -> int:
	return GRAMA[nivel()]


static func flores() -> int:
	return FLORES[nivel()]


static func sombras() -> bool:
	return SOMBRAS[nivel()]
