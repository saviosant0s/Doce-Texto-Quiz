class_name PontosFoto
## FOTOS: o botão de foto da vila tira foto de qualquer lugar e guarda no
## ÁLBUM (user://fotos; no computador, também na pasta Imagens). Pela vila há
## VISTAS BONITAS escondidas (sem marca: é para descobrir; o botão pulsa perto
## delas): lá a câmera vai para o enquadramento da vista e a primeira foto de
## cada uma dá prêmio.
##
## Estado em Progresso.vila["fotos"] = {id do ponto: quantas fotos tirou}.

## "pe": onde o doce fica (a marca no chão); "camera" e "olhar": o
## enquadramento da foto (o doce aparece na frente da vista).
const PONTOS := [
	{"id": "praca", "nome": "PRAÇA DA FONTE", "pe": Vector3(1.6, 0, 6.2),
		"camera": Vector3(4.2, 2.6, 10.6), "olhar": Vector3(-0.6, 1.9, -3.0)},
	{"id": "casa", "nome": "MINHA CASA", "pe": Vector3(1.8, 0, 16.0),
		"camera": Vector3(5.2, 2.3, 11.2), "olhar": Vector3(-0.6, 2.2, 21.0)},
	{"id": "lago", "nome": "LAGO DE CHOCOLATE", "pe": Vector3(-23.6, 0, 12.0),
		"camera": Vector3(-19.4, 2.6, 14.8), "olhar": Vector3(-30.5, 0.8, 10.4)},
	{"id": "mirante", "nome": "MIRANTE DO SORVETE", "pe": Vector3(26.4, 0, 12.6),
		"camera": Vector3(31.6, 2.8, 13.5), "olhar": Vector3(8.0, 0.8, 10.0)},
	{"id": "terrenos", "nome": "BAIRRO DOS TERRENOS", "pe": Vector3(0.6, 0, -22.6),
		"camera": Vector3(3.0, 4.6, -18.4), "olhar": Vector3(-0.5, 0.6, -29.5)},
	{"id": "vista", "nome": "VISTA DA VILA", "pe": Vector3(-6.0, 0, -19.5),
		"camera": Vector3(-3.0, 11.0, -30.0), "olhar": Vector3(1.0, 0.0, 0.0)},  # (abaixo das nuvens)
	{"id": "ilha", "nome": "PONTE DA ILHA", "pe": Vector3(-50, 0, 2),
		"camera": Vector3(-44, 3.2, 7.5), "olhar": Vector3(-72, 3.0, -2.0)},
	{"id": "bosque", "nome": "CASA NA ÁRVORE", "pe": Vector3(1.5, 0, 62),
		"camera": Vector3(6.5, 3.0, 56.5), "olhar": Vector3(0, 5.0, 72.0)},
	{"id": "montanha", "nome": "VALE DO SORVETE", "pe": Vector3(62, 0, 6),
		"camera": Vector3(54.0, 3.5, 1.0), "olhar": Vector3(80, 6.0, 14.0)},
]
## Prêmio da primeira foto em cada ponto.
const PREMIO := {"moedas": 20, "acucar": 15}
const PASTA := "user://fotos"
const RAIO := 4.5  # distância da vista para valer
## Fotos guardadas no álbum (as mais antigas saem).
const MAXIMO_ALBUM := 40


static func ponto(id: String) -> Dictionary:
	for p in PONTOS:
		if p["id"] == id:
			return p
	return {}


## Id da vista bonita perto desse ponto ("" = nenhuma).
static func perto(posicao: Vector3) -> String:
	for p in PONTOS:
		if Vector2(posicao.x - p["pe"].x, posicao.z - p["pe"].z).length() < RAIO:
			return p["id"]
	return ""


static func _estado() -> Dictionary:
	if not Progresso.vila.has("fotos"):
		Progresso.vila["fotos"] = {}
	return Progresso.vila["fotos"]


static func fotos_em(id: String) -> int:
	return int(_estado().get(id, 0))


## Quantos pontos já têm foto.
static func pontos_com_foto() -> int:
	return PONTOS.filter(func(p): return fotos_em(p["id"]) > 0).size()


## Conta a foto; a primeira do ponto dá o PREMIO (retorna ele; {} se não).
static func registrar(id: String) -> Dictionary:
	if ponto(id).is_empty():
		return {}
	var primeira := fotos_em(id) == 0
	_estado()[id] = fotos_em(id) + 1
	if not primeira:
		Progresso.salvar()
		return {}
	Confeitaria.ganhar_acucar(int(PREMIO["acucar"]))
	Progresso.ganhar_moedas(int(PREMIO["moedas"]))  # também salva
	return PREMIO.duplicate()


## Guarda a foto no álbum (e, no computador, uma cópia na pasta Imagens).
## Retorna o caminho no álbum ("" se não deu para salvar).
static func salvar(imagem: Image, id: String) -> String:
	DirAccess.make_dir_recursive_absolute(PASTA)
	var nome := "foto_%s_%d.png" % [id, int(Time.get_unix_time_from_system() * 1000.0)]
	var caminho := PASTA + "/" + nome
	if imagem.save_png(caminho) != OK:
		return ""
	if OS.has_feature("pc"):
		var imagens := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
		if imagens != "" and DirAccess.dir_exists_absolute(imagens):
			DirAccess.make_dir_recursive_absolute(imagens.path_join("Doce Texto Quiz"))
			imagem.save_png(imagens.path_join("Doce Texto Quiz").path_join(nome))
	var todas := album()
	for i in range(MAXIMO_ALBUM, todas.size()):
		DirAccess.remove_absolute(todas[i])
	return caminho


## Fotos do álbum (caminhos), da mais nova para a mais antiga.
static func album() -> Array:
	var lista := []
	var pasta := DirAccess.open(PASTA)
	if pasta == null:
		return lista
	for arquivo in pasta.get_files():
		if arquivo.begins_with("foto_") and arquivo.ends_with(".png"):
			lista.append(PASTA + "/" + arquivo)
	lista.sort_custom(func(a, b): return _quando(a) > _quando(b))
	return lista


static func _quando(caminho: String) -> int:
	return int(caminho.get_file().get_basename().get_slice("_", caminho.get_file().get_basename().get_slice_count("_") - 1))


## Nome do ponto de uma foto do álbum (pelo nome do arquivo).
static func nome_da_foto(caminho: String) -> String:
	var partes := caminho.get_file().get_basename().split("_")
	return str(ponto("_".join(partes.slice(1, partes.size() - 1))).get("nome", "VILA DOS DOCES"))
