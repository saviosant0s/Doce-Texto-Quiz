class_name Itens
## Imagens dos itens do jogo (moeda, açúcar, XP e baús), todas no mesmo estilo
## 3D dos doces (ver Itens3D e ferramentas/gerar_itens_3d.sh). Use sempre
## estas, sem pintar por cima (modulate): assim o jogo tem uma cara só.

const MOEDA := preload("res://assets/itens/moeda.png")
const ACUCAR := preload("res://assets/itens/acucar.png")
const XP := preload("res://assets/itens/xp.png")
const ESTRELA := preload("res://assets/itens/estrela.png")
## Estrela ainda não ganha: a mesma estrela, apagada.
const ESTRELA_APAGADA := Color(0.28, 0.18, 0.45, 0.4)
const BAU_DOCE := preload("res://assets/itens/bau_doce.png")
const BAU_PRATA := preload("res://assets/itens/bau_prata.png")
const BAU_OURO := preload("res://assets/itens/bau_ouro.png")
const BAU_MADEIRA := preload("res://assets/itens/bau_madeira.png")
const BAU_CHEFE := preload("res://assets/itens/bau_chefe.png")
const BAU_ABERTO := preload("res://assets/itens/bau_aberto.png")
const BAU_ABERTO_DOCE := preload("res://assets/itens/bau_aberto_doce.png")
const BAU_ABERTO_PRATA := preload("res://assets/itens/bau_aberto_prata.png")
const BAU_ABERTO_OURO := preload("res://assets/itens/bau_aberto_ouro.png")


static func bau(tipo: String) -> Texture2D:
	return {"doce": BAU_DOCE, "prata": BAU_PRATA, "ouro": BAU_OURO}.get(tipo, BAU_DOCE)


static func bau_aberto(tipo: String) -> Texture2D:
	return {"doce": BAU_ABERTO_DOCE, "prata": BAU_ABERTO_PRATA, "ouro": BAU_ABERTO_OURO}.get(tipo, BAU_ABERTO)


## Botão com a imagem de um item: tira a tinta do tema (senão o item fica roxo).
static func sem_tinta(botao: Button) -> void:
	for estado in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color",
			"icon_hover_pressed_color", "icon_disabled_color"]:
		botao.add_theme_color_override(estado, Color.WHITE if estado != "icon_disabled_color" else Color(1, 1, 1, 0.5))
