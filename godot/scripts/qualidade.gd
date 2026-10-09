class_name Qualidade
## Qualidade dos gráficos 3D (Configurações > Gráficos): BAIXA, MÉDIA, ALTA ou
## ULTRA. Vale para a Vila dos Doces, a cozinha e a corrida. No celular começa
## em MÉDIA; no computador, em ALTA (MÉDIA em placa integrada). Salvo em
## Progresso.config["qualidade"].
## ULTRA (só no computador, para placa de vídeo forte): o jogo reinicia no
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


## Começa em MÉDIA no celular e no navegador; no computador, ALTA só com placa
## de vídeo dedicada e mais de 8 GB de memória (placa integrada, como as Intel
## dos notebooks, ou pouca memória: MÉDIA).
static func padrao() -> int:
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return MEDIA
	return MEDIA if computador_simples() else ALTA


static func computador_simples() -> bool:
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
	var n := clampi(int(Progresso.config.get("qualidade", padrao())), BAIXA, ULTRA)
	# ULTRA só vale com o Forward+ ligado (até o jogo reiniciar, é a ALTA)
	return n if n < ULTRA or ultra_ativo() else ALTA


## A qualidade escolhida (pode ser ULTRA esperando o reinício).
static func escolhida() -> int:
	return clampi(int(Progresso.config.get("qualidade", padrao())), BAIXA, ULTRA if tem_ultra() else ALTA)


static func escolher(novo: int) -> void:
	Progresso.config["qualidade"] = clampi(novo, BAIXA, ULTRA if tem_ultra() else ALTA)
	Progresso.salvar()


## O ULTRA existe neste aparelho (computador; no celular e no navegador, não).
static func tem_ultra() -> bool:
	return OS.has_feature("pc") and not OS.has_feature("web") and DisplayServer.get_name() != "headless"


## O jogo está rodando no Forward+ (o renderizador do ULTRA).
static func ultra_ativo() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


## Escolheu ULTRA e o jogo ainda está no renderizador leve: reinicia no Forward+.
## Se já tentou (a placa não aceitou o Forward+), volta para a ALTA.
static func reiniciar_se_precisar(arvore: SceneTree) -> bool:
	if escolhida() != ULTRA or ultra_ativo() or Progresso.somente_memoria:
		return false
	if MARCA_REINICIO in OS.get_cmdline_user_args():
		escolher(ALTA)
		return false
	var args: Array[String] = []
	var pular := 0
	for arg in OS.get_cmdline_args():
		if pular > 0:
			pular -= 1
		elif arg in ["--rendering-method", "--rendering-driver"]:
			pular = 1
		else:
			args.append(arg)
	args.append_array(["--rendering-method", "forward_plus", "--rendering-driver", "vulkan", "--"])
	args.append_array(Array(OS.get_cmdline_user_args(), TYPE_STRING, "", null))
	args.append(MARCA_REINICIO)
	OS.create_process(OS.get_executable_path(), args)
	arvore.quit()
	return true


static func grama() -> int:
	return GRAMA[nivel()]


static func flores() -> int:
	return FLORES[nivel()]


static func sombras() -> bool:
	return SOMBRAS[nivel()]
