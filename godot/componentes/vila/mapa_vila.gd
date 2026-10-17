class_name MapaVila
extends Control
## O mapa da vila visto de cima, desenhado em 2D (leve para o celular): a vila
## com a praça, os caminhos e os prédios; o Lago de Morango com a ilha; o Rio
## de Calda e o bosque; a Montanha de Sorvete; os morros com sombra (relevo).
## Regiões ainda não exploradas ficam cobertas por névoa cinza ("?"); as
## trancadas, mais escuras, dizem o que falta.
## Uso: MINIMAPA (redondo, no canto; segue o doce) e o MAPA cheio (a vila
## inteira; aberto tocando no minimapa).

const FONTE := preload("res://assets/fontes/BebasNeue-Regular.ttf")
const GRAMA := Color("#86C96F")
const CAMINHO := Color("#F4C888")

## Ponto do mundo (x, z) no meio do controle e pixels por metro.
var centro := Vector2.ZERO
var escala := 3.0
## Mapa cheio: nomes, névoa com texto e sem seguir o doce.
var cheio := false
var jogador := Vector2.ZERO
var giro_jogador := 0.0  # para onde o doce olha (radianos, como no 3D)
## Desenha a setinha do doce (o minimapa usa uma imagem pronta e põe a seta por cima).
var mostrar_jogador := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


## Enquadra o mundo inteiro no tamanho do controle (mapa cheio).
func enquadrar_mundo() -> void:
	var m := Regioes.MUNDO.grow(6)
	centro = m.get_center()
	escala = minf(size.x / m.size.x, size.y / m.size.y)


func _p(ponto: Vector2) -> Vector2:
	return size / 2.0 + (ponto - centro) * escala


func _v(ponto: Vector3) -> Vector2:
	return _p(Vector2(ponto.x, ponto.z))


func _ret(r: Rect2) -> Rect2:
	return Rect2(_p(r.position), r.size * escala)


func _draw() -> void:
	var m := Regioes.MUNDO
	# fundo além da borda: morros de sorvete
	draw_rect(Rect2(Vector2.ZERO, size), Color("#F3D9E8"))
	draw_rect(_ret(m), GRAMA)
	_morros()
	_ilha()
	_bosque()
	_montanha()
	_vila()
	_nevoa()
	if mostrar_jogador:
		desenhar_seta(self, _p(jogador), giro_jogador, 11.0 if cheio else 9.0)


## A setinha do doce (vermelha com a bolinha branca), em qualquer CanvasItem.
static func desenhar_seta(onde: CanvasItem, p: Vector2, giro: float, tamanho: float) -> void:
	var frente := Vector2(sin(giro), cos(giro))
	var lado := Vector2(frente.y, -frente.x)
	onde.draw_colored_polygon(PackedVector2Array([p + frente * tamanho * 1.3, p - frente * tamanho * 0.7 + lado * tamanho * 0.8,
		p - frente * tamanho * 0.3, p - frente * tamanho * 0.7 - lado * tamanho * 0.8]), Color("#E8364F"))
	onde.draw_circle(p, tamanho * 0.35, Color.WHITE)


func _morros() -> void:
	var m := Regioes.MUNDO
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 99
	var cores := [Color("#FFC2DA"), Color("#C9B3EC"), Color("#A8E6C1"), Color("#FFE08A"), Color("#9FD4F7")]
	var pontos := []
	for x in range(int(m.position.x), int(m.end.x) + 1, 22):
		pontos.append(Vector2(x, m.position.y - 9))
		pontos.append(Vector2(x, m.end.y + 9))
	for z in range(int(m.position.y), int(m.end.y) + 1, 22):
		pontos.append(Vector2(m.position.x - 9, z))
		pontos.append(Vector2(m.end.x + 9, z))
	for i in pontos.size():
		_morro(pontos[i], 10.0, cores[i % cores.size()])


## Morro com relevo: sombra embaixo, o morro e um brilho em cima.
func _morro(onde: Vector2, raio: float, cor: Color) -> void:
	var p := _p(onde)
	draw_circle(p + Vector2(2, 3) * escala * 0.6, raio * escala, Color(0, 0, 0, 0.18))
	draw_circle(p, raio * escala, cor)
	draw_circle(p - Vector2(raio, raio) * escala * 0.25, raio * escala * 0.55, cor.lightened(0.35))


func _vila() -> void:
	var v := Regioes.VILA
	draw_rect(_ret(v), Color("#8FD179"))
	draw_rect(_ret(v), Color("#FF8FB8"), false, maxf(1.0, escala * 0.5))
	# caminhos
	var largura := maxf(2.0, 2.4 * escala)
	for dados in Vila.PREDIOS:
		var porta: Vector3 = dados["posicao"] - dados["posicao"].normalized() * 4.5
		draw_line(_v(porta.normalized() * 4.3), _v(porta), CAMINHO, largura)
	for c in Vila.CAMINHOS_EXTRA:
		draw_line(_v(c[0]), _v(c[1]), CAMINHO, largura)
	for c in Vila.CAMINHOS_REGIOES:
		draw_line(_v(c[0]), _v(c[1]), CAMINHO, largura)
	# praça e fonte
	draw_circle(_v(Vector3.ZERO), 4.2 * escala, Color("#FFF3E0"))
	draw_circle(_v(Vector3.ZERO), 2.0 * escala, Color("#5A2E17"))
	# lotes, lago de chocolate e mirante
	for l in Terrenos.LOTES:
		var p: Vector3 = l["posicao"]
		var cor := Color("#D9A35E") if Terrenos.comprado(l["id"]) else Color("#FFFFFF", 0.7)
		draw_rect(Rect2(_v(p) - Vector2.ONE * 3.0 * escala, Vector2.ONE * 6.0 * escala), cor)
	draw_circle(_v(Terrenos.LUGARES["lago"]["posicao"]), 6.5 * escala, Color("#5A2E17"))
	draw_circle(_v(Terrenos.LUGARES["mirante"]["posicao"]), 4.2 * escala, Color("#FFF3E0"))
	# prédios: quadradinho da cor do prédio com a sombra
	for dados in Vila.PREDIOS:
		var p := _v(dados["posicao"])
		var lado := 5.0 * escala
		draw_rect(Rect2(p - Vector2(lado, lado) / 2.0 + Vector2(2, 2), Vector2(lado, lado)), Color(0, 0, 0, 0.2))
		draw_rect(Rect2(p - Vector2(lado, lado) / 2.0, Vector2(lado, lado)), Color(dados["parede"]))
		draw_rect(Rect2(p - Vector2(lado, lado) / 2.0, Vector2(lado, lado * 0.35)), Color(dados["telhado"]))
		if cheio:
			_texto(str(dados["nome"]), p + Vector2(0, lado * 0.5 + 12), 13, Color("#3B2A5C"))


func _ilha() -> void:
	var lago := RegioesVila.LAGO_CENTRO
	var raios := RegioesVila.LAGO_RAIOS
	var pontos := PackedVector2Array()
	for i in 40:
		var a := i * TAU / 40.0
		pontos.append(_p(Vector2(lago.x + cos(a) * raios.x, lago.z + sin(a) * raios.y)))
	draw_colored_polygon(pontos, Color("#FF9EC7"))
	draw_circle(_v(RegioesVila.ILHA_CENTRO), (RegioesVila.ILHA_RAIO + 1.0) * escala, Color("#F6E3C6"))
	draw_circle(_v(RegioesVila.ILHA_CENTRO), RegioesVila.ILHA_RAIO * escala, GRAMA)
	var ponte_de := Vector2(lago.x + raios.x + 2.0, RegioesVila.ILHA_CENTRO.z)
	var ponte_ate := Vector2(RegioesVila.ILHA_CENTRO.x + RegioesVila.ILHA_RAIO, RegioesVila.ILHA_CENTRO.z)
	draw_line(_p(ponte_de), _p(ponte_ate), Color("#D9A35E"), 3.4 * escala)
	draw_line(_p(Vector2(Regioes.VILA.position.x, 2)), _p(ponte_de), CAMINHO, 2.4 * escala)
	draw_circle(_p(Vector2(-74, -4)), 1.4 * escala, Color("#E8364F"))


func _bosque() -> void:
	var v := Regioes.VILA
	var rio := RegioesVila.RIO_Z
	draw_rect(_ret(Rect2(v.position.x, rio.x, v.size.x, rio.y - rio.x)), Color("#C98A3A"))
	draw_line(_p(Vector2(RegioesVila.PONTE_SUL_X, rio.x - 1)), _p(Vector2(RegioesVila.PONTE_SUL_X, rio.y + 1)), Color("#D9A35E"), 3.4 * escala)
	var sorteio := RandomNumberGenerator.new()
	sorteio.seed = 12
	var cores := [Color("#FF6FAE"), Color("#6FD3FF"), Color("#FFD23F"), Color("#B07CFF")]
	for i in 40:
		var p := Vector2(sorteio.randf_range(v.position.x + 3, v.end.x - 3), sorteio.randf_range(rio.y + 4, 85))
		if p.distance_to(Vector2(0, 68)) < 9.0:
			continue
		draw_circle(_p(p), 1.2 * escala, cores[i % cores.size()])
	draw_circle(_p(Vector2(0, 70)), 3.2 * escala, Color("#D9A35E"))
	draw_circle(_p(Vector2(0, 70)), 1.6 * escala, Color("#7BE07B"))


func _montanha() -> void:
	var cores := [Color("#FFC2DA"), Color("#9FD4F7"), Color("#A8E6C1"), Color("#FFE08A"), Color("#C9B3EC"), Color("#FFB36B")]
	var montanhas := [[Vector2(74, -28), 13.0], [Vector2(90, 0), 12.0], [Vector2(84, 38), 14.0], [Vector2(62, 62), 12.0],
		[Vector2(88, 76), 11.0], [Vector2(52, -32), 8.0], [Vector2(46, 50), 8.0]]
	draw_line(_p(Vector2(Regioes.VILA.end.x, 2)), _p(Vector2(66, 6)), CAMINHO, 2.4 * escala)
	draw_line(_p(Vector2(66, 6)), _p(Vector2(62, 22)), CAMINHO, 2.4 * escala)
	draw_circle(_p(Vector2(60, 26)), 6.0 * escala, Color("#CDEBFF"))
	for i in montanhas.size():
		_morro(montanhas[i][0], montanhas[i][1], cores[i % cores.size()])
	draw_circle(_p(Vector2(72, 8)), 3.2 * escala, Color.WHITE)


## Névoa: região trancada (escura, com o que falta) ou não explorada ("?").
func _nevoa() -> void:
	for r in Regioes.LISTA:
		var area := _ret(r["area"])
		if Regioes.explorada(r["id"]):
			if cheio:
				_texto(str(r["nome"]), area.get_center(), 18, Color("#3B2A5C"))
			continue
		var aberta := Regioes.liberada(r["id"])
		draw_rect(area, Color(0.55, 0.53, 0.6, 0.82) if aberta else Color(0.3, 0.28, 0.36, 0.9))
		# nuvenzinhas na borda da névoa
		for k in int(area.size.y / 18.0):
			draw_circle(Vector2(area.position.x + (area.size.x if r["id"] == "ilha" else 0.0), area.position.y + k * 18.0 + 9.0),
				10.0, Color(0.7, 0.68, 0.75, 0.5))
		if cheio:
			var meio := area.get_center()
			_texto(str(r["nome"]), meio - Vector2(0, 16), 18, Color.WHITE)
			_texto("?  NÃO EXPLORADA" if aberta else "FECHADA: " + Regioes.texto_requisito(r["id"]), meio + Vector2(0, 8), 13,
				Color("#F4E038"), area.size.x - 10)
		else:
			_texto("?", area.get_center(), 22, Color.WHITE)


func _texto(texto: String, meio: Vector2, tamanho: int, cor: Color, largura := -1.0) -> void:
	var medida := FONTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, largura, tamanho)
	if largura > 0 and medida.x > largura:
		tamanho = int(tamanho * largura / medida.x)
		medida = FONTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, tamanho)
	var onde := meio - Vector2(medida.x / 2.0, -tamanho * 0.35)
	draw_string_outline(FONTE, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 4, Color(0.2, 0.1, 0.3, 0.8))
	draw_string(FONTE, onde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
