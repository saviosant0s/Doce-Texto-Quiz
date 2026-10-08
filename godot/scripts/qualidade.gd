class_name Qualidade
## Qualidade dos gráficos 3D (Configurações > Gráficos): BAIXA, MÉDIA ou ALTA.
## Vale para a Vila dos Doces e a cozinha. No celular começa em MÉDIA; no
## computador, em ALTA. Salvo em Progresso.config["qualidade"].

enum { BAIXA, MEDIA, ALTA }
const NOMES := ["BAIXA", "MÉDIA", "ALTA"]

const GRAMA := [0, 1300, 2400]  # tufos de grama com volume na vila (menos: parecia mato)
const FLORES := [40, 90, 90]
const SOMBRAS := [false, true, true]
const ESCALA_3D := [0.6, 0.8, 1.0]  # tamanho do 3D em relação à tela
const ANTISSERRILHADO := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]


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
	return clampi(int(Progresso.config.get("qualidade", padrao())), BAIXA, ALTA)


static func escolher(novo: int) -> void:
	Progresso.config["qualidade"] = clampi(novo, BAIXA, ALTA)
	Progresso.salvar()


static func grama() -> int:
	return GRAMA[nivel()]


static func flores() -> int:
	return FLORES[nivel()]


static func sombras() -> bool:
	return SOMBRAS[nivel()]
