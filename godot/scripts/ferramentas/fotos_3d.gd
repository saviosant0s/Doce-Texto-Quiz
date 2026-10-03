extends Control
## Gera as "fotos" dos doces 3D (PNG transparente, 512x512) em
## assets/doces_3d/fotos/, usadas nas telas que mostram personagens parados
## (cartões dos níveis, pódio, resultado, miniaturas da coleção...).
## Rode de novo sempre que mudar um modelo em scripts/doces_3d.gd:
##   ferramentas/gerar_fotos_3d.sh

const PASTA := "res://assets/doces_3d/fotos/"
const TAMANHO := 512
const PASTA_ITENS := "res://assets/itens/"


func _ready() -> void:
	OS.low_processor_usage_mode = false  # redesenha sempre (senão espera para sempre)
	var ids: Array = Colecao.LISTA.map(func(d): return d["id"]) + Doces3D.PERSONAGENS
	var distancia := 4.3  # o doce ocupa a foto toda
	var pasta := PASTA
	var tamanho := TAMANHO
	if "--itens" in OS.get_cmdline_user_args():
		# moeda, açúcar, XP e baús (ferramentas/gerar_itens_3d.sh)
		ids = Itens3D.IDS
		pasta = PASTA_ITENS
		tamanho = 320
		distancia = 5.6  # sobra uma margem em volta
	var fotografo := Doce3D.new()
	fotografo.giravel = false
	fotografo.distancia = distancia
	fotografo.angulo_inicial = -0.3
	fotografo.custom_minimum_size = Vector2(tamanho, tamanho)
	fotografo.size = fotografo.custom_minimum_size
	add_child(fotografo)
	fotografo.set_process(false)  # parado: sem flutuar, piscar ou acenar
	fotografo._animacao.set_process(false)
	fotografo._viewport.size = Vector2i(tamanho, tamanho)
	fotografo._viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pasta))
	for id in ids:
		fotografo.mostrar(id)
		fotografo._viewport.size = Vector2i(tamanho, tamanho)
		await get_tree().create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		var foto := fotografo._viewport.get_texture().get_image()
		foto.save_png(ProjectSettings.globalize_path(pasta + id + ".png"))
		print("foto: ", id)
	get_tree().quit()
