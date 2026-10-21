"""Gera o carro de Fórmula 1 da Corrida de Doces no Blender (modelo original,
feito só por este script, sem peças de terceiros) e exporta em .glb para o Godot.

Formato de um F1 moderno (2022 em diante), com as medidas de um carro de
verdade reduzidas a 66% para caber nas faixas da pista do jogo: bico fino,
asa dianteira de quatro elementos, cockpit com o halo, sidepods com entrada de
ar, cobertura do motor com tomada de ar e barbatana, assoalho com difusor,
asa traseira com DRS e beam wing, luz de chuva, suspensão e rodas de 18" com a
faixa colorida no pneu.

Materiais (o Godot troca as cores pela equipe, ver Kart3D):
  Pintura   cor principal da equipe (o Godot pinta as faixas da equipe por cima)
  Destaque  segunda cor (peças inteiras)
  Detalhe   terceira cor (câmera em cima da tomada de ar)
  Carbono, Interior, Pneu, Faixa (do pneu), Aro, Luz, Escape, Espelho, AsaTexto

Frente do carro: +Y no Blender (vira -Z no Godot). Rodas em objetos separados
(Roda_FE, Roda_FD, Roda_TE, Roda_TD), com a origem no cubo da roda; o resto
fica junto em "Carroceria".

Com --detalhe ultra, gera a versão da qualidade ULTRA (carro_f1_ultra.glb): mais
lisa (mais subdivisão e rodas de 64 lados) e com mais peças (defletores em cima
das rodas da frente, dutos de freio, borda do assoalho, aletas de refrigeração
nos sidepods, câmeras e pitot no bico, atuador do DRS, porca colorida e letras
na lateral do pneu). Também desenha a folha de adesivos que o Godot cola no
carro no ULTRA (godot/assets/carros/f1_adesivos.png).

Uso:
  blender -b -P ferramentas/blender/carro_f1.py -- --saida godot/assets/carros/carro_f1.glb \
      [--detalhe ultra] [--previa build/prints/f1_previa]   (--previa: três fotos no Cycles)
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# --- Medidas (metros do jogo) ---------------------------------------------------------------
EIXO_FRENTE = 1.05
EIXO_TRAS = -1.33
RAIO_RODA = 0.24
RAIO_ARO = 0.155
RODA_FRENTE = (0.56, 0.20)  # (x do centro, largura do pneu)
RODA_TRAS = (0.53, 0.26)

CORES = {  # (cor sRGB, metálico, aspereza)
	"Pintura": ("#1B2650", 0.35, 0.42),
	"Destaque": ("#D51B2E", 0.3, 0.38),
	"Detalhe": ("#FFC726", 0.2, 0.35),
	"Carbono": ("#121316", 0.0, 0.3),
	"Interior": ("#070708", 0.0, 0.9),
	"Pneu": ("#141416", 0.0, 0.88),
	"Faixa": ("#E3141E", 0.0, 0.6),
	"Aro": ("#23252B", 0.85, 0.3),
	"Luz": ("#FF2020", 0.0, 0.4),
	"Escape": ("#B08A62", 1.0, 0.35),
	"Espelho": ("#D8DCE2", 1.0, 0.05),
	"AsaTexto": ("#FFFFFF", 0.3, 0.4),
	"PneuTexto": ("#FFFFFF", 0.0, 0.85),
}

ULTRA = False  # versão da qualidade ULTRA (--detalhe ultra)


def rgb(hexa: str) -> tuple:
	"""Cor sRGB "#RRGGBB" -> (r, g, b) de 0 a 255."""
	return tuple(int(hexa[i:i + 2], 16) for i in (1, 3, 5))


def linear(hexa: str) -> tuple:
	"""Cor sRGB -> linear (o que o Blender usa nos materiais)."""
	return tuple((c / 255) / 12.92 if c / 255 <= 0.04045 else ((c / 255 + 0.055) / 1.055) ** 2.4 for c in rgb(hexa))


def argumentos() -> dict:
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	saida = {}
	i = 0
	while i < len(args):
		if args[i].startswith("--"):
			saida[args[i][2:]] = args[i + 1] if i + 1 < len(args) and not args[i + 1].startswith("--") else ""
			i += 2 if saida[args[i][2:]] != "" else 1
		else:
			i += 1
	return saida


# --- Materiais ------------------------------------------------------------------------------

_materiais: dict = {}


def material(nome: str) -> bpy.types.Material:
	if nome in _materiais:
		return _materiais[nome]
	cor, metalico, aspereza = CORES[nome]
	mat = bpy.data.materials.new(nome)
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes["Principled BSDF"]
	bsdf.inputs["Base Color"].default_value = (*linear(cor), 1.0)
	bsdf.inputs["Metallic"].default_value = metalico
	bsdf.inputs["Roughness"].default_value = aspereza
	if nome == "Luz":
		bsdf.inputs["Emission Color"].default_value = (1.0, 0.05, 0.05, 1.0)
		bsdf.inputs["Emission Strength"].default_value = 4.0
	if nome in ("AsaTexto", "PneuTexto"):
		imagem = bpy.data.images.load(textura_asa() if nome == "AsaTexto" else textura_pneu())
		no = mat.node_tree.nodes.new("ShaderNodeTexImage")
		no.image = imagem
		mat.node_tree.links.new(no.outputs["Color"], bsdf.inputs["Base Color"])
	_materiais[nome] = mat
	return mat


def pil():
	"""Pillow (o Python do Blender não traz: usa o do sistema, que é da mesma versão)."""
	try:
		import PIL.Image
	except ImportError:
		sys.path.append(f"/usr/local/lib/python{sys.version_info.major}.{sys.version_info.minor}/dist-packages")
		sys.path.append("/usr/lib/python3/dist-packages")
	from PIL import Image, ImageDraw, ImageFont
	return Image, ImageDraw, ImageFont


def fonte(tamanho: int):
	return pil()[2].truetype(os.path.join(RAIZ, "godot", "assets", "fontes", "BebasNeue-Regular.ttf"), tamanho)


def textura_pneu() -> str:
	"""Letras brancas em volta da lateral do pneu (o anel dá a volta na roda: duas vezes o texto)."""
	Image, ImageDraw, _ = pil()
	caminho = os.path.join(RAIZ, "build", "f1_pneu.png")
	os.makedirs(os.path.dirname(caminho), exist_ok=True)
	largura, altura = 2048, 96
	img = Image.new("RGB", (largura, altura), rgb(CORES["Pneu"][0]))
	d = ImageDraw.Draw(img)
	letra = fonte(78)
	for metade in (0, 1):
		x = metade * largura / 2
		for texto, desloc in (("DOCE TEXTO", 60), ("MACIO", 560)):
			d.text((x + desloc, 6), texto, font=letra, fill=(236, 236, 236))
	img.save(caminho)
	return caminho


def adesivos() -> str:
	"""Folha de adesivos (patrocínios inventados) que o shader da pintura do ULTRA cola
	no carro: [0] DOCE TEXTO (cobertura do motor), [1] QUIZ (sidepod), [2] o número
	do bico. Letras brancas com contorno escuro, fundo transparente (ver
	godot/tema/pintura_f1_ultra.gdshader, ADESIVOS)."""
	Image, ImageDraw, _ = pil()
	caminho = os.path.join(RAIZ, "godot", "assets", "carros", "f1_adesivos.png")
	os.makedirs(os.path.dirname(caminho), exist_ok=True)
	img = Image.new("RGBA", (1024, 512), (255, 255, 255, 0))
	d = ImageDraw.Draw(img)
	def escrever(texto, caixa, tamanho):
		letra = fonte(tamanho)
		b = d.textbbox((0, 0), texto, font=letra, stroke_width=6)
		x = caixa[0] + (caixa[2] - caixa[0] - (b[2] - b[0])) / 2 - b[0]
		y = caixa[1] + (caixa[3] - caixa[1] - (b[3] - b[1])) / 2 - b[1]
		d.text((x, y), texto, font=letra, fill=(255, 255, 255, 255), stroke_width=6, stroke_fill=(20, 24, 48, 255))
	escrever("DOCE TEXTO", (0, 0, 1024, 256), 230)
	escrever("QUIZ", (0, 256, 512, 512), 220)
	escrever("1", (512, 256, 768, 512), 230)
	img.save(caminho)
	return caminho


def textura_asa() -> str:
	"""A faixa da aba de cima da asa traseira: fundo da cor da equipe e o nome do jogo."""
	Image, ImageDraw, ImageFont = pil()
	caminho = os.path.join(RAIZ, "build", "f1_asa.png")
	os.makedirs(os.path.dirname(caminho), exist_ok=True)
	largura, altura = 1024, 160
	cor = rgb(CORES["Pintura"][0])
	img = Image.new("RGB", (largura, altura), cor)
	d = ImageDraw.Draw(img)
	letra = fonte(92)
	texto = "DOCE TEXTO QUIZ"
	caixa = d.textbbox((0, 0), texto, font=letra)
	d.text(((largura - (caixa[2] - caixa[0])) / 2, 32 - caixa[1] + 16), texto, font=letra, fill=(255, 255, 255))
	vermelho = rgb(CORES["Destaque"][0])
	d.rectangle((0, altura - 22, largura, altura - 12), fill=vermelho)
	d.rectangle((0, 12, largura, 22), fill=vermelho)
	img.save(caminho)
	return caminho


# --- Construção de malhas -------------------------------------------------------------------

def objeto(nome: str, bm: bmesh.types.BMesh, mats: list, suave=True, angulo=40.0) -> bpy.types.Object:
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	malha = bpy.data.meshes.new(nome)
	bm.to_mesh(malha)
	bm.free()
	for m in mats:
		malha.materials.append(material(m))
	for p in malha.polygons:
		p.use_smooth = suave
	if suave and hasattr(malha, "set_sharp_from_angle"):
		malha.set_sharp_from_angle(angle=math.radians(angulo))
	obj = bpy.data.objects.new(nome, malha)
	bpy.context.collection.objects.link(obj)
	return obj


def superelipse(cx: float, cz: float, rx: float, rz: float, n: float, pontos: int) -> list:
	saida = []
	for i in range(pontos):
		t = 2 * math.pi * i / pontos
		c, s = math.cos(t), math.sin(t)
		x = cx + rx * math.copysign(abs(c) ** (2 / n), c)
		z = cz + rz * math.copysign(abs(s) ** (2 / n), s)
		saida.append((x, z))
	return saida


def loft(nome: str, secoes: list, pontos=28, mats=("Pintura",), tampa_frente=0, tampa_tras=0,
		subdividir=2) -> bpy.types.Object:
	"""Corpo liso a partir de cortes (y, centro x, meia largura, z de baixo, z de cima, n),
	da frente para trás; n = 2 é elipse, maior = mais quadrado. As tampas usam o
	material de índice tampa_frente / tampa_tras."""
	bm = bmesh.new()
	aneis = []
	for y, cx, mx, zb, zt, n in secoes:
		anel = [bm.verts.new((x, y, z)) for x, z in superelipse(cx, (zb + zt) / 2, mx, (zt - zb) / 2, n, pontos)]
		aneis.append(anel)
	for a, b in zip(aneis, aneis[1:]):
		for i in range(pontos):
			j = (i + 1) % pontos
			bm.faces.new((a[i], a[j], b[j], b[i]))
	for anel, indice, y in ((aneis[0], tampa_frente, secoes[0][0]), (aneis[-1], tampa_tras, secoes[-1][0])):
		centro = Vector((sum(v.co.x for v in anel) / pontos, y, sum(v.co.z for v in anel) / pontos))
		meio = bm.verts.new(centro)
		for i in range(pontos):
			f = bm.faces.new((anel[i], anel[(i + 1) % pontos], meio))
			f.material_index = indice
	obj = objeto(nome, bm, list(mats))
	if subdividir:
		mod = obj.modifiers.new("Subdividir", "SUBSURF")
		mod.levels = subdividir
		mod.render_levels = subdividir
		aplicar(obj, mod.name)
	return obj


def aplicar(obj: bpy.types.Object, modificador: str) -> None:
	bpy.context.view_layer.objects.active = obj
	obj.select_set(True)
	bpy.ops.object.modifier_apply(modifier=modificador)
	obj.select_set(False)


def perfil_asa(espessura: float, curvatura: float, pontos=12) -> list:
	"""Perfil NACA de 4 dígitos invertido (asa de carro empurra para baixo):
	lista fechada de (posição na corda 0-1, altura), do bordo de fuga por baixo
	até o bordo de ataque e de volta por cima. Também devolve, para cada ponto,
	se é da face de cima."""
	p = 0.4
	def camber(x):
		if x < p:
			return curvatura / p ** 2 * (2 * p * x - x * x)
		return curvatura / (1 - p) ** 2 * ((1 - 2 * p) + 2 * p * x - x * x)
	def meia(x):
		return 5 * espessura * (0.2969 * math.sqrt(x) - 0.1260 * x - 0.3516 * x ** 2 + 0.2843 * x ** 3 - 0.1036 * x ** 4)
	xs = [0.5 * (1 - math.cos(math.pi * i / pontos)) for i in range(pontos + 1)]  # 0..1, mais pontos nas pontas
	baixo = [(x, -camber(x) - meia(x), False) for x in reversed(xs)]  # (invertido: a barriga para baixo)
	cima = [(x, -camber(x) + meia(x), True) for x in xs[1:-1]]
	return baixo + cima


def asa(nome: str, de_x: float, ate_x: float, corda: float, y_ataque: float, z_ataque: float,
		angulo: float, espessura=0.1, curvatura=0.05, mat="Pintura", curva=None, estacoes=0,
		uv_texto=False) -> bpy.types.Object:
	"""Elemento de asa reto ao longo de x. angulo > 0: o bordo de fuga sobe (asa de
	downforce). curva(x) -> (dy, dz) entorta o elemento ao longo da envergadura."""
	estacoes = estacoes or (24 if ULTRA else 16)
	perfil = perfil_asa(espessura, curvatura)
	bm = bmesh.new()
	uv = bm.loops.layers.uv.new("UVMap")
	a = math.radians(angulo)
	estacoes_v = []
	for k in range(estacoes + 1):
		x = de_x + (ate_x - de_x) * k / estacoes
		dy, dz = curva(x) if curva else (0.0, 0.0)
		anel = []
		for s, h, _ in perfil:
			# ao longo da corda: para trás (-y) e subindo com o ângulo; espessura perpendicular
			y = y_ataque + dy - s * corda * math.cos(a) + h * corda * math.sin(a)
			z = z_ataque + dz + s * corda * math.sin(a) + h * corda * math.cos(a)
			anel.append(bm.verts.new((x, y, z)))
		estacoes_v.append(anel)
	n = len(perfil)
	for k in range(estacoes):
		a0, a1 = estacoes_v[k], estacoes_v[k + 1]
		for i in range(n):
			j = (i + 1) % n
			f = bm.faces.new((a0[i], a0[j], a1[j], a1[i]))
			for laco in f.loops:
				kk = k if laco.vert in a0 else k + 1
				ii = (a0 if laco.vert in a0 else a1).index(laco.vert)
				s, _, em_cima = perfil[ii]
				u = kk / estacoes
				v = 0.15 + 0.7 * s if em_cima else 0.04
				if uv_texto and ii == 0:
					v = 0.85
				laco[uv].uv = (u, v)
	for anel in (estacoes_v[0], estacoes_v[-1]):
		f = bm.faces.new(anel)
		for laco in f.loops:
			laco[uv].uv = (0.0, 0.04)
	return objeto(nome, bm, [mat], angulo=50.0)


def placa(nome: str, contorno: list, eixo: str, centro: float, espessura: float, mat="Pintura",
		suavizar=2) -> bpy.types.Object:
	"""Chapa reta com o contorno dado (pontos 2D), no plano perpendicular ao eixo
	('x': contorno em (y, z); 'z': contorno em (x, y)), com cantos arredondados."""
	for _ in range(suavizar):  # cantos arredondados (Chaikin)
		novo = []
		for i, p in enumerate(contorno):
			q = contorno[(i + 1) % len(contorno)]
			novo.append((0.75 * p[0] + 0.25 * q[0], 0.75 * p[1] + 0.25 * q[1]))
			novo.append((0.25 * p[0] + 0.75 * q[0], 0.25 * p[1] + 0.75 * q[1]))
		contorno = novo
	bm = bmesh.new()
	lados = []
	for desloc in (-espessura / 2, espessura / 2):
		if eixo == "x":
			lados.append([bm.verts.new((centro + desloc, a, b)) for a, b in contorno])
		else:
			lados.append([bm.verts.new((a, b, centro + desloc)) for a, b in contorno])
	bm.faces.new(lados[0])
	bm.faces.new(list(reversed(lados[1])))
	n = len(contorno)
	for i in range(n):
		j = (i + 1) % n
		bm.faces.new((lados[0][i], lados[0][j], lados[1][j], lados[1][i]))
	return objeto(nome, bm, [mat], angulo=35.0)


def tubo(nome: str, pontos: list, raio: float, mat="Pintura", lados=12, passos=8) -> bpy.types.Object:
	"""Tubo liso passando pelos pontos (Catmull-Rom)."""
	pts = [Vector(p) for p in pontos]
	caminho = []
	for i in range(len(pts) - 1):
		p0 = pts[max(i - 1, 0)]
		p1, p2 = pts[i], pts[i + 1]
		p3 = pts[min(i + 2, len(pts) - 1)]
		for k in range(passos):
			t = k / passos
			caminho.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
				+ (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t))
	caminho.append(pts[-1])
	bm = bmesh.new()
	aneis = []
	normal_ant = None
	for i, c in enumerate(caminho):
		frente = (caminho[min(i + 1, len(caminho) - 1)] - caminho[max(i - 1, 0)]).normalized()
		if normal_ant is None:
			normal_ant = frente.orthogonal().normalized()
		normal = (normal_ant - frente * normal_ant.dot(frente)).normalized()
		normal_ant = normal
		lado = frente.cross(normal)
		anel = []
		for k in range(lados):
			ang = 2 * math.pi * k / lados
			anel.append(bm.verts.new(c + (normal * math.cos(ang) + lado * math.sin(ang)) * raio))
		aneis.append(anel)
	for a, b in zip(aneis, aneis[1:]):
		for k in range(lados):
			j = (k + 1) % lados
			bm.faces.new((a[k], a[j], b[j], b[k]))
	bm.faces.new(aneis[0])
	bm.faces.new(list(reversed(aneis[-1])))
	return objeto(nome, bm, [mat])


def torno(bm: bmesh.types.BMesh, perfil: list, segmentos: int, sinal: float, indice: int,
		fechado=True) -> None:
	"""Gira o perfil [(raio, posição no eixo)] em volta do eixo X (rodas)."""
	aneis = []
	for k in range(segmentos):
		ang = 2 * math.pi * k / segmentos
		c, s = math.cos(ang), math.sin(ang)
		aneis.append([bm.verts.new((sinal * a, r * c, r * s)) for r, a in perfil])
	n = len(perfil)
	ultimo = n if fechado else n - 1
	for k in range(segmentos):
		a0, a1 = aneis[k], aneis[(k + 1) % segmentos]
		for i in range(ultimo):
			j = (i + 1) % n
			f = bm.faces.new((a0[i], a0[j], a1[j], a1[i]))
			f.material_index = indice


def anel_texto(bm: bmesh.types.BMesh, r1: float, r2: float, a: float, segmentos: int, sinal: float,
		indice: int) -> None:
	"""Anel chato na lateral do pneu (no plano x = a), com UV: u dá a volta na roda, v
	vai de dentro para fora (para as letras da textura do pneu)."""
	uv = bm.loops.layers.uv.verify()
	colunas = []
	for k in range(segmentos + 1):  # (a última coluna repete a primeira, com u = 1)
		ang = 2 * math.pi * k / segmentos
		c, s_ = math.cos(ang), math.sin(ang)
		colunas.append([bm.verts.new((sinal * a, r * c, r * s_)) for r in (r1, r2)])
	for k in range(segmentos):
		a0, a1 = colunas[k], colunas[k + 1]
		f = bm.faces.new((a0[0], a0[1], a1[1], a1[0]))
		f.material_index = indice
		for laco, (u, v) in zip(f.loops, ((k, 0), (k, 1), (k + 1, 1), (k + 1, 0))):
			# (vista de fora, as letras andam no sentido do relógio: nas rodas da
			# direita o ângulo cresce ao contrário, então o u é invertido)
			laco[uv].uv = (1.0 - u / segmentos if sinal > 0 else u / segmentos, v)


def roda(nome: str, centro: tuple, largura: float, sinal: float) -> bpy.types.Object:
	"""Pneu de perfil baixo (aro de 18") com a faixa colorida na lateral e a
	calota lisa por fora. sinal: +1 se o lado de fora é +x (direita)."""
	bm = bmesh.new()
	w = largura / 2
	rc = 0.04
	perfil = [(RAIO_ARO, -w + 0.003)]
	for k in range(7):  # ombro de dentro
		ang = math.pi / 2 * k / 6
		perfil.append((RAIO_RODA - rc + math.sin(ang) * rc, -w + rc - math.cos(ang) * rc))
	for k in range(7):  # ombro de fora
		ang = math.pi / 2 * k / 6
		perfil.append((RAIO_RODA - rc + math.cos(ang) * rc, w - rc + math.sin(ang) * rc))
	perfil.append((RAIO_ARO, w - 0.003))
	lados = 64 if ULTRA else 40
	torno(bm, perfil, lados, sinal, 0)
	# faixa colorida nos dois lados do pneu
	for lado in (-1, 1):
		a = lado * (w + 0.0015)
		torno(bm, [(0.188, a), (0.200, a), (0.200, a + lado * 0.002), (0.188, a + lado * 0.002)], lados, sinal, 1)
	# aro e calota (disco por fora, um pouco para dentro) e o miolo
	torno(bm, [(0.0, w - 0.004), (RAIO_ARO + 0.004, w - 0.004), (RAIO_ARO + 0.004, -w + 0.004), (0.0, -w + 0.004)],
		48 if ULTRA else 32, sinal, 2, fechado=False)
	mats = ["Pneu", "Faixa", "Aro"]
	if ULTRA:
		# letras na lateral de fora, a borda do aro (magnésio) e a porca colorida
		anel_texto(bm, 0.163, 0.186, w + 0.0012, 64, sinal, 3)
		torno(bm, [(RAIO_ARO - 0.012, w + 0.002), (RAIO_ARO + 0.006, w + 0.002), (RAIO_ARO + 0.006, w - 0.01),
			(RAIO_ARO - 0.012, w - 0.01)], 48, sinal, 2)
		torno(bm, [(0.0, w + 0.03), (0.022, w + 0.03), (0.03, w + 0.014), (0.03, w - 0.004)], 12, sinal, 4, fechado=False)
		mats += ["PneuTexto", "Destaque"]
	else:
		torno(bm, [(0.0, w + 0.012), (0.035, w + 0.012), (0.035, w - 0.004)], 16, sinal, 2, fechado=False)
	obj = objeto(nome, bm, mats, angulo=30.0)
	obj.location = centro
	return obj


def braco(bm: bmesh.types.BMesh, a: tuple, b: tuple, raio: float, lados=6) -> None:
	"""Haste da suspensão (cilindro fino de a até b) dentro de uma malha."""
	va, vb = Vector(a), Vector(b)
	eixo = (vb - va).normalized()
	n1 = eixo.orthogonal().normalized()
	n2 = eixo.cross(n1)
	anel_a, anel_b = [], []
	for k in range(lados):
		ang = 2 * math.pi * k / lados
		d = (n1 * math.cos(ang) + n2 * math.sin(ang)) * raio
		anel_a.append(bm.verts.new(va + d))
		anel_b.append(bm.verts.new(vb + d))
	for k in range(lados):
		j = (k + 1) % lados
		bm.faces.new((anel_a[k], anel_a[j], anel_b[j], anel_b[k]))
	bm.faces.new(anel_a)
	bm.faces.new(list(reversed(anel_b)))


def caixa(nome: str, centro: tuple, tamanho: tuple, mat: str, chanfro=0.006) -> bpy.types.Object:
	bm = bmesh.new()
	bmesh.ops.create_cube(bm, size=1.0)
	for v in bm.verts:
		v.co = Vector((centro[0] + v.co.x * tamanho[0], centro[1] + v.co.y * tamanho[1], centro[2] + v.co.z * tamanho[2]))
	if chanfro > 0:
		bmesh.ops.bevel(bm, geom=list(bm.edges), offset=chanfro, segments=2, affect="EDGES", profile=0.5)
	return objeto(nome, bm, [mat], angulo=30.0)


# --- O carro ----------------------------------------------------------------------------------

def montar() -> list:
	partes = []
	# monocoque: bico, cockpit e o corpo até a estrutura de batida traseira (luz de chuva)
	corpo = loft("Corpo", [
		(1.70, 0, 0.040, 0.100, 0.165, 2.4),
		(1.58, 0, 0.058, 0.098, 0.190, 2.6),
		(1.40, 0, 0.078, 0.100, 0.235, 2.8),
		(1.20, 0, 0.100, 0.110, 0.290, 3.0),
		(0.95, 0, 0.125, 0.120, 0.345, 3.2),
		(0.70, 0, 0.150, 0.090, 0.390, 3.4),
		(0.45, 0, 0.172, 0.055, 0.425, 3.6),
		(0.20, 0, 0.190, 0.045, 0.430, 3.8),
		(-0.05, 0, 0.200, 0.045, 0.440, 3.8),
		(-0.30, 0, 0.195, 0.045, 0.450, 3.6),
		(-0.60, 0, 0.175, 0.050, 0.430, 3.2),
		(-0.95, 0, 0.130, 0.070, 0.375, 2.8),
		(-1.25, 0, 0.090, 0.100, 0.315, 2.6),
		(-1.50, 0, 0.060, 0.130, 0.260, 2.4),
		(-1.70, 0, 0.040, 0.160, 0.225, 2.2),
		(-1.88, 0, 0.026, 0.172, 0.212, 2.2),
	], pontos=32 if ULTRA else 28, mats=("Pintura",))
	# cockpit: o buraco onde o doce senta (as paredes de dentro ficam escuras)
	cortador = loft("Cortador", [
		(0.36, 0, 0.06, 0.30, 0.75, 4),
		(0.30, 0, 0.13, 0.30, 0.75, 6),
		(0.00, 0, 0.15, 0.30, 0.75, 6),
		(-0.10, 0, 0.13, 0.30, 0.75, 6),
		(-0.13, 0, 0.06, 0.30, 0.75, 4),
	], pontos=20, mats=("Interior",), subdividir=0)
	bool_mod = corpo.modifiers.new("Cockpit", "BOOLEAN")
	bool_mod.operation = "DIFFERENCE"
	bool_mod.object = cortador
	bool_mod.solver = "EXACT"
	bool_mod.material_mode = "TRANSFER"
	aplicar(corpo, bool_mod.name)
	bpy.data.objects.remove(cortador)
	partes.append(corpo)
	partes.append(caixa("Banco", (0, 0.10, 0.31), (0.27, 0.42, 0.04), "Interior"))
	# cobertura do motor com a tomada de ar (a frente escura) e a barbatana
	partes.append(loft("Cobertura", [
		(-0.10, 0, 0.060, 0.400, 0.540, 2.6),
		(-0.20, 0, 0.080, 0.390, 0.630, 2.6),
		(-0.35, 0, 0.100, 0.380, 0.625, 2.8),
		(-0.60, 0, 0.115, 0.340, 0.560, 2.8),
		(-0.90, 0, 0.095, 0.290, 0.460, 2.6),
		(-1.20, 0, 0.068, 0.230, 0.370, 2.4),
		(-1.48, 0, 0.040, 0.190, 0.285, 2.2),
	], pontos=24, mats=("Pintura", "Interior"), tampa_frente=1, subdividir=2 if ULTRA else 1))
	partes.append(placa("Barbatana", [(-0.33, 0.615), (-1.08, 0.455), (-1.10, 0.40), (-0.36, 0.55)], "x", 0.0, 0.012))
	partes.append(caixa("Camera", (0, -0.13, 0.646), (0.07, 0.03, 0.022), "Detalhe", 0.005))
	# sidepods: entrada de ar larga e baixinha no alto (a parte de baixo da frente é
	# cavada, o "undercut") e a "garrafa de coca" estreitando para trás
	for lado in (-1, 1):
		partes.append(loft("Sidepod", [
			(0.32, lado * 0.360, 0.130, 0.200, 0.335, 5.0),
			(0.25, lado * 0.372, 0.148, 0.130, 0.348, 4.5),
			(0.12, lado * 0.378, 0.155, 0.070, 0.350, 4.0),
			(-0.10, lado * 0.368, 0.158, 0.062, 0.340, 3.5),
			(-0.40, lado * 0.330, 0.138, 0.062, 0.300, 3.0),
			(-0.70, lado * 0.272, 0.098, 0.064, 0.250, 2.8),
			(-0.95, lado * 0.215, 0.050, 0.070, 0.190, 2.5),
		], pontos=24, mats=("Pintura", "Interior"), tampa_frente=1, subdividir=2 if ULTRA else 1))
		# retrovisor na haste em cima do sidepod (com o espelho virado para trás)
		partes.append(tubo("Haste", [(lado * 0.27, 0.30, 0.345), (lado * 0.31, 0.31, 0.43), (lado * 0.34, 0.32, 0.47)],
			0.008, "Pintura", lados=6, passos=4))
		partes.append(caixa("Retrovisor", (lado * 0.345, 0.32, 0.49), (0.095, 0.035, 0.045), "Pintura", 0.01))
		partes.append(caixa("Espelho", (lado * 0.345, 0.302, 0.49), (0.08, 0.002, 0.034), "Espelho", 0.0))
	# halo (tubo em volta da cabeça) e a coluna da frente
	halo = [(-0.19, -0.17, 0.44), (-0.215, -0.07, 0.555), (-0.205, 0.07, 0.597), (-0.15, 0.19, 0.612),
		(-0.065, 0.265, 0.618), (0.0, 0.282, 0.619)]
	partes.append(tubo("Halo", halo + [(-x, y, z) for x, y, z in reversed(halo[:-1])], 0.017, "Pintura", passos=10))
	partes.append(tubo("Coluna", [(0, 0.282, 0.61), (0, 0.34, 0.54), (0, 0.40, 0.43)], 0.02, "Pintura"))
	# assoalho (visto de cima) e o difusor com as aletas
	contorno = [(0.0, 0.78), (0.20, 0.74), (0.30, 0.55), (0.52, 0.36), (0.555, 0.20), (0.555, -0.90),
		(0.48, -1.02), (0.385, -1.10), (0.385, -1.16)]
	contorno = contorno + [(-x, y) for x, y in reversed(contorno[1:])]
	contorno = [(x, y) for x, y in contorno if not (x == 0.0 and y == 0.78)] + [(0.0, 0.78)]
	partes.append(placa("Assoalho", contorno, "z", 0.035, 0.02, "Carbono", suavizar=1))
	bm = bmesh.new()
	pts = [(-0.385, -1.15, 0.03), (0.385, -1.15, 0.03), (0.385, -1.66, 0.205), (-0.385, -1.66, 0.205)]
	cima = [bm.verts.new(p) for p in pts]
	baixo = [bm.verts.new((x, y, z - 0.012)) for x, y, z in pts]
	bm.faces.new(cima)
	bm.faces.new(list(reversed(baixo)))
	for i in range(4):
		j = (i + 1) % 4
		bm.faces.new((cima[i], cima[j], baixo[j], baixo[i]))
	partes.append(objeto("Difusor", bm, ["Carbono"], angulo=30.0))
	for x in (-0.37, -0.25, -0.12, 0.12, 0.25, 0.37):
		partes.append(placa("Aleta", [(-1.15, 0.03), (-1.66, 0.205), (-1.66, 0.06), (-1.30, 0.03)], "x", x, 0.008,
			"Carbono", suavizar=1))
	# asa dianteira: quatro elementos que sobem para as pontas e passam por baixo do bico
	def frente_curva(alt):
		return lambda x: (-0.03 * (abs(x) / 0.6) ** 2, alt * (abs(x) / 0.6) ** 3 - 0.012 * max(0.0, 1 - abs(x) / 0.14))
	partes.append(asa("AsaFrente1", -0.60, 0.60, 0.15, 1.74, 0.062, 4, 0.09, 0.05, "Pintura", frente_curva(0.01)))
	partes.append(asa("AsaFrente2", -0.585, 0.585, 0.12, 1.635, 0.086, 13, 0.08, 0.05, "Pintura", frente_curva(0.02)))
	partes.append(asa("AsaFrente3", -0.585, 0.585, 0.10, 1.545, 0.113, 22, 0.08, 0.05, "Pintura", frente_curva(0.03)))
	partes.append(asa("AsaFrente4", -0.585, 0.585, 0.08, 1.465, 0.143, 31, 0.08, 0.04, "Destaque", frente_curva(0.035)))
	for lado in (-1, 1):
		partes.append(placa("PlacaFrente", [(1.76, 0.035), (1.76, 0.10), (1.62, 0.175), (1.42, 0.205), (1.36, 0.19),
			(1.36, 0.035)], "x", lado * 0.607, 0.012, "Pintura"))
	# asa traseira: plano principal, aba do DRS (com o nome do jogo), placas e beam wing
	partes.append(asa("AsaTras1", -0.345, 0.345, 0.17, -1.66, 0.50, 8, 0.10, 0.06, "Pintura",
		lambda x: (0.0, -0.012 * (1 - (x / 0.345) ** 2))))
	partes.append(asa("AsaTras2", -0.345, 0.345, 0.13, -1.80, 0.565, 32, 0.08, 0.05, "AsaTexto", uv_texto=True))
	partes.append(asa("BeamWing", -0.24, 0.24, 0.07, -1.70, 0.215, 15, 0.10, 0.05, "Carbono", estacoes=8))
	for lado in (-1, 1):
		partes.append(placa("PlacaTras", [(-1.62, 0.31), (-1.64, 0.56), (-1.71, 0.655), (-1.92, 0.66),
			(-1.945, 0.61), (-1.945, 0.28), (-1.78, 0.23)], "x", lado * 0.357, 0.012, "Pintura"))
	for x in (-0.05, 0.05):  # dois pilones, um de cada lado do escape
		partes.append(placa("Pilone", [(-1.42, 0.25), (-1.68, 0.505), (-1.75, 0.505), (-1.52, 0.22)], "x", x, 0.012,
			"Carbono"))
	partes.append(caixa("LuzChuva", (0, -1.905, 0.192), (0.05, 0.02, 0.03), "Luz", 0.004))
	partes.append(tubo("Escape", [(0, -1.45, 0.30), (0, -1.62, 0.305), (0, -1.68, 0.305)], 0.03, "Escape", lados=14,
		passos=3))
	# suspensão (braços em A, push/pullrod e barra de direção)
	bm = bmesh.new()
	for lado in (-1, 1):
		fx, tx = RODA_FRENTE[0] - RODA_FRENTE[1] / 2 - 0.01, RODA_TRAS[0] - RODA_TRAS[1] / 2 - 0.01
		for z_chassi, z_cubo in ((0.17, 0.16), (0.31, 0.32)):
			for dy in (0.13, -0.13):
				braco(bm, (lado * 0.11, EIXO_FRENTE + dy, z_chassi), (lado * fx, EIXO_FRENTE, z_cubo), 0.009)
				braco(bm, (lado * 0.08, EIXO_TRAS + dy, z_chassi), (lado * tx, EIXO_TRAS, z_cubo), 0.009)
		braco(bm, (lado * 0.11, EIXO_FRENTE - 0.06, 0.24), (lado * fx, EIXO_FRENTE - 0.06, 0.25), 0.008)
		braco(bm, (lado * fx, EIXO_FRENTE, 0.17), (lado * 0.13, EIXO_FRENTE - 0.05, 0.33), 0.009)
		braco(bm, (lado * tx, EIXO_TRAS, 0.31), (lado * 0.09, EIXO_TRAS + 0.08, 0.18), 0.009)
	partes.append(objeto("Suspensao", bm, ["Carbono"], angulo=30.0))
	if ULTRA:
		partes += detalhes_ultra()
	# juntar tudo (menos as rodas) numa malha só: menos desenhos por quadro no jogo
	bpy.ops.object.select_all(action="DESELECT")
	for p in partes:
		p.select_set(True)
	bpy.context.view_layer.objects.active = partes[0]
	bpy.ops.object.join()
	carroceria = bpy.context.view_layer.objects.active
	carroceria.name = "Carroceria"
	rodas = [
		roda("Roda_FE", (-RODA_FRENTE[0], EIXO_FRENTE, RAIO_RODA), RODA_FRENTE[1], -1),
		roda("Roda_FD", (RODA_FRENTE[0], EIXO_FRENTE, RAIO_RODA), RODA_FRENTE[1], 1),
		roda("Roda_TE", (-RODA_TRAS[0], EIXO_TRAS, RAIO_RODA), RODA_TRAS[1], -1),
		roda("Roda_TD", (RODA_TRAS[0], EIXO_TRAS, RAIO_RODA), RODA_TRAS[1], 1),
	]
	return [carroceria] + rodas


def detalhes_ultra() -> list:
	"""As peças a mais da versão ULTRA."""
	partes = []
	fx = RODA_FRENTE[0] - RODA_FRENTE[1] / 2  # lado de dentro dos pneus
	tx = RODA_TRAS[0] - RODA_TRAS[1] / 2
	bm = bmesh.new()
	for lado in (-1, 1):
		# dutos de freio (o tambor dentro de cada roda)
		braco(bm, (lado * (fx - 0.06), EIXO_FRENTE, RAIO_RODA), (lado * (fx - 0.008), EIXO_FRENTE, RAIO_RODA), 0.115, 24)
		braco(bm, (lado * (tx - 0.06), EIXO_TRAS, RAIO_RODA), (lado * (tx - 0.008), EIXO_TRAS, RAIO_RODA), 0.125, 24)
		# haste do defletor da roda da frente
		braco(bm, (lado * (fx - 0.03), EIXO_FRENTE + 0.02, RAIO_RODA + 0.1), (lado * (fx + 0.01), EIXO_FRENTE + 0.04,
			2 * RAIO_RODA + 0.018), 0.007)
		# antena e câmeras do bico
		partes.append(caixa("CameraBico", (lado * 0.105, 1.22, 0.272), (0.032, 0.065, 0.026), "Carbono", 0.006))
	braco(bm, (0, -0.55, 0.552), (0, -0.585, 0.625), 0.003)
	partes.append(objeto("Freios", bm, ["Carbono"], angulo=30.0))
	for lado in (-1, 1):
		# defletor em cima da roda da frente (desvia o ar que a roda joga)
		de, ate = (fx - 0.01, fx + RODA_FRENTE[1] + 0.01) if lado > 0 else (-fx - RODA_FRENTE[1] - 0.01, -fx + 0.01)
		partes.append(asa("Defletor", de, ate, 0.075, EIXO_FRENTE + 0.08, 2 * RAIO_RODA + 0.02, 22, 0.08, 0.05,
			"Carbono", lambda x: (0.0, -0.025 * ((x - (de + ate) / 2) / ((ate - de) / 2)) ** 2), estacoes=8))
		# borda do assoalho (lâmina que sobe um pouco para trás)
		partes.append(placa("BordaAssoalho", [(0.15, 0.045), (0.15, 0.07), (-0.85, 0.10), (-0.85, 0.045)], "x",
			lado * 0.548, 0.008, "Carbono", suavizar=1))
		# aletas de refrigeração em cima do sidepod
		for k in range(5):
			y = -0.16 - k * 0.06
			z = 0.340 + (y + 0.10) * (0.04 / 0.30) - 0.004
			x = 0.368 + (y + 0.10) * (0.038 / 0.30)
			partes.append(caixa("Guelra", (lado * x, y, z), (0.10, 0.012, 0.012), "Interior", 0.002))
	partes.append(tubo("Pitot", [(0, 1.69, 0.132), (0, 1.80, 0.135)], 0.004, "Carbono", lados=6, passos=2))
	partes.append(placa("AtuadorDRS", [(-1.69, 0.505), (-1.69, 0.585), (-1.79, 0.60), (-1.80, 0.55)], "x", 0.0, 0.022,
		"Carbono"))
	return partes


# --- Prévia (Cycles) -----------------------------------------------------------------------

def previa(caminho: str) -> None:
	cena = bpy.context.scene
	cena.render.engine = "CYCLES"
	cena.cycles.samples = 48
	cena.cycles.use_denoising = True
	cena.render.resolution_x = 1280
	cena.render.resolution_y = 720
	cena.view_settings.view_transform = "AgX"
	mundo = bpy.data.worlds.new("Ceu")
	mundo.use_nodes = True
	ceu = mundo.node_tree.nodes.new("ShaderNodeTexSky")
	ceu.sky_type = "NISHITA"
	ceu.sun_elevation = math.radians(35)
	ceu.sun_rotation = math.radians(200)
	mundo.node_tree.links.new(ceu.outputs["Color"], mundo.node_tree.nodes["Background"].inputs["Color"])
	mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.12
	cena.world = mundo
	sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
	sol.data.energy = 3.5
	sol.data.angle = math.radians(2)
	sol.rotation_euler = (math.radians(50), 0, math.radians(200))
	cena.collection.objects.link(sol)
	bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
	chao = bpy.context.active_object
	mat = bpy.data.materials.new("Asfalto")
	mat.use_nodes = True
	mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.08, 0.08, 0.085, 1)
	mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
	chao.data.materials.append(mat)
	camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
	camera.data.lens = 50
	cena.collection.objects.link(camera)
	cena.camera = camera
	for nome, pos in (("frente", (3.6, 3.4, 1.5)), ("tras", (-2.6, -5.2, 2.2)), ("lado", (5.2, 0.0, 0.9))):
		camera.location = pos
		direcao = Vector((0, -0.1 if nome != "tras" else 0.0, 0.3)) - Vector(pos)
		camera.rotation_euler = direcao.to_track_quat("-Z", "Y").to_euler()
		cena.render.filepath = f"{caminho}_{nome}.png"
		bpy.ops.render.render(write_still=True)


def main() -> None:
	global ULTRA
	args = argumentos()
	ULTRA = args.get("detalhe", "") == "ultra"
	bpy.ops.wm.read_factory_settings(use_empty=True)
	objetos = montar()
	if ULTRA:
		adesivos()
	saida = args.get("saida", os.path.join(RAIZ, "godot", "assets", "carros",
		"carro_f1_ultra.glb" if ULTRA else "carro_f1.glb"))
	os.makedirs(os.path.dirname(saida), exist_ok=True)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objetos:
		o.select_set(True)
	bpy.ops.export_scene.gltf(filepath=saida, export_format="GLB", use_selection=True, export_apply=True,
		export_yup=True, export_cameras=False, export_lights=False)
	triangulos = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objetos)
	print(f"CARRO_F1: {saida} ({triangulos} triângulos)")
	if "previa" in args:
		previa(args["previa"])


main()
