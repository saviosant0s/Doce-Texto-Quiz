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


static func padrao() -> int:
	return MEDIA if OS.has_feature("mobile") else ALTA


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
