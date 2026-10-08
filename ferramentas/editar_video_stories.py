#!/usr/bin/env python3
"""Editor do vídeo vertical de divulgação (stories/reels do Instagram,
1080x1920, 30 quadros por segundo, ~31 s).

Monta quadro a quadro (Pillow + numpy) as cenas que o próprio jogo gravou
(ferramentas/gerar_video_stories.sh → <saida>/cenas/*.avi):

- gancho: "VOCÊ SABE USAR WORD? EXCEL? POWERPOINT?" pulando na tela, com os
  personagens do jogo, e "E SE APRENDER FOSSE UM JOGO?!";
- o logo cai na virada da música, com flash, tremida e explosão de granulado;
- cortes no ritmo da música (155 batidas por minuto), com transições de
  chicote, zoom e flash;
- câmera lenta e zoom nos melhores momentos (portal da corrida, golpe no
  chefão e na batalha), adesivos de quadrinho (TURBO!, POW!, BOOM!) e a
  pergunta respondida saltando para fora da tela;
- legendas que entram palavra por palavra, moedas e açúcar voando (os ícones
  do jogo) e o baú abrindo;
- tela final com o logo, "JOGO GRÁTIS!" e o botão BAIXE AGORA pulsando;
- trilha: a música do jogo a partir da virada, com efeitos (vush, impacto,
  subida, sons do jogo) e volume nivelado para o Instagram.

Uso: python3 ferramentas/editar_video_stories.py [saida] [--quadros=1.0,3.2]
     (--quadros só desenha esses instantes em <saida>/previa_*.png)
Saída: <saida>/doce_texto_stories.mp4 e <saida>/capa.jpg
"""
import math
import multiprocessing
import os
import random
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import signal
from scipy.io import wavfile

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS = os.path.join(RAIZ, "godot/assets")
FONTE = os.path.join(ASSETS, "fontes/BebasNeue-Regular.ttf")
FONTE_LINK = os.path.join(ASSETS, "fontes/Nunito.ttf")  # tem minúsculas (para o link)
MUSICA = os.path.join(ASSETS, "sons/musica_2.ogg")

L, A, FPS = 1080, 1920, 30
TAXA = 48000  # áudio
BPM = 155.01
BATIDA = 60 / BPM
# a musica_2 tem uma pausa na batida 164 (63,77 s) e a virada na 165 (64,16 s):
# o vídeo começa 8 batidas antes, e o logo cai na virada (batida 8 do vídeo)
MUSICA_INICIO = 0.292 + 157 * BATIDA

# cenas gravadas (1080x1560) e o cartão onde elas aparecem
CENA_L, CENA_A = 1080, 1560
CARTAO_L, CARTAO_A = 900, 1300
CARTAO_X, CARTAO_Y = 90, 150
CENTRO = (540, 800)
RAIO_CARTAO = 46

BRANCO = (255, 255, 255, 255)
AMARELO = (255, 210, 63, 255)
ROXO_ESCURO = (46, 29, 74, 255)
ROXO = (126, 87, 177, 255)
ROSA = (255, 79, 140, 255)
VERDE = (76, 200, 92, 255)
CORES_GRANULADO = [(255, 111, 174), (255, 210, 63), (111, 211, 255), (123, 224, 123), (255, 255, 255), (255, 138, 92)]


def b(n):
    """Tempo (s) da batida n do vídeo."""
    return n * BATIDA


TOTAL = round(b(80) * FPS) / FPS


# ---------------------------------------------------------------- curvas
def limitar(x, a=0.0, c=1.0):
    return a if x < a else c if x > c else x


def suave(x):
    x = limitar(x)
    return x * x * (3 - 2 * x)


def sai(x):
    x = limitar(x)
    return 1 - (1 - x) ** 3


def entra(x):
    x = limitar(x)
    return x ** 3


def entra_sai(x):
    x = limitar(x)
    return 4 * x ** 3 if x < 0.5 else 1 - (-2 * x + 2) ** 3 / 2


def volta(x, s=2.2):
    """Passa do ponto e volta (o "pulo" dos elementos)."""
    x = limitar(x) - 1
    return 1 + (s + 1) * x ** 3 + s * x ** 2


def pulso_batida(t, desde=b(8)):
    """1 na batida, caindo até a próxima (só depois da virada da música)."""
    if t < desde:
        return 0.0
    return math.exp(-((t / BATIDA) % 1.0) * 5)


# ---------------------------------------------------------------- imagens
_fontes = {}


def fonte(tamanho, link=False):
    chave = (tamanho, link)
    if chave not in _fontes:
        if link:
            f = ImageFont.truetype(FONTE_LINK, tamanho)
            try:
                f.set_variation_by_name("ExtraBold")
            except (OSError, ValueError):
                pass
        else:
            f = ImageFont.truetype(FONTE, tamanho)
        _fontes[chave] = f
    return _fontes[chave]


def texto(txt, tamanho, cor=BRANCO, contorno=None, cor_contorno=ROXO_ESCURO, sombra=True, link=False):
    """Texto com contorno grosso e sombra (o estilo dos títulos do jogo)."""
    contorno = max(4, tamanho // 11) if contorno is None else contorno
    f = fonte(tamanho, link)
    x0, y0, x1, y1 = ImageDraw.Draw(Image.new("L", (1, 1))).textbbox((0, 0), txt, font=f, stroke_width=contorno)
    margem = contorno + 26
    img = Image.new("RGBA", (x1 - x0 + 2 * margem, y1 - y0 + 2 * margem), (0, 0, 0, 0))
    pos = (margem - x0, margem - y0)
    if sombra:
        camada = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(camada).text((pos[0], pos[1] + max(6, tamanho // 14)), txt, font=f, fill=(30, 15, 50, 170),
                                    stroke_width=contorno, stroke_fill=(30, 15, 50, 170))
        img = Image.alpha_composite(img, camada.filter(ImageFilter.GaussianBlur(6)))
    ImageDraw.Draw(img).text(pos, txt, font=f, fill=cor, stroke_width=contorno, stroke_fill=cor_contorno)
    return img


def sombra_de(img, raio=10, deslocamento=12, alfa=150):
    """A imagem com uma sombra roxa embaixo (para recortes e ícones)."""
    margem = raio * 2 + deslocamento
    saida = Image.new("RGBA", (img.width + 2 * margem, img.height + 2 * margem), (0, 0, 0, 0))
    sombra = Image.new("RGBA", saida.size, (0, 0, 0, 0))
    mascara = img.getchannel("A").point(lambda v: v * alfa // 255)
    sombra.paste((30, 15, 50, 255), (margem, margem + deslocamento), mascara)
    saida.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(raio)))
    saida.alpha_composite(img, (margem, margem))
    return saida


def etiqueta(txt, tamanho, fundo, cor=BRANCO):
    """Etiqueta com cara de botão do jogo (borda, sombra e lado de baixo mais escuro)."""
    f = fonte(tamanho)
    x0, y0, x1, y1 = ImageDraw.Draw(Image.new("L", (1, 1))).textbbox((0, 0), txt, font=f)
    w, h = x1 - x0 + int(tamanho * 0.9), y1 - y0 + int(tamanho * 0.5)
    img = Image.new("RGBA", (w + 16, h + 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    escuro = tuple(int(c * 0.65) for c in fundo[:3]) + (255,)
    d.rounded_rectangle([8, 18, w + 8, h + 18], h // 2, fill=escuro, outline=ROXO_ESCURO, width=6)
    d.rounded_rectangle([8, 6, w + 8, h + 6], h // 2, fill=fundo, outline=ROXO_ESCURO, width=6)
    d.rounded_rectangle([22, 14, w - 6, 14 + h // 3], h // 6, fill=(255, 255, 255, 60))
    d.text((w // 2 + 8, h // 2 + 7), txt, font=f, fill=cor, anchor="mm", stroke_width=max(3, tamanho // 22),
           stroke_fill=ROXO_ESCURO)
    return sombra_de(img, 8, 10, 120)


def pilula(txt, tamanho, fundo=ROXO, cor=BRANCO):
    f = fonte(tamanho)
    x0, y0, x1, y1 = ImageDraw.Draw(Image.new("L", (1, 1))).textbbox((0, 0), txt, font=f)
    w, h = x1 - x0 + 76, y1 - y0 + 36
    img = Image.new("RGBA", (w + 8, h + 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([4, 4, w + 4, h + 4], 999, fill=fundo, outline=(255, 255, 255, 235), width=5)
    d.text((w // 2 + 4, h // 2 + 6), txt, font=f, fill=cor, anchor="mm")
    return sombra_de(img, 7, 8, 140)


def adesivo(txt, tamanho=140, fundo=AMARELO, cor=ROSA, pontas=16, semente=1):
    """Estouro de história em quadrinhos com o texto no meio (POW!, BOOM!)."""
    rotulo = texto(txt, tamanho, cor, contorno=max(6, tamanho // 16), sombra=False)
    raio = max(rotulo.width, rotulo.height) / 2 + 40
    lado = int(raio * 2 + 60)
    img = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    sorteio = random.Random(semente)
    pontos = []
    for i in range(pontas * 2):
        ang = math.pi * i / pontas
        r = raio * (1.0 if i % 2 == 0 else 0.7) * sorteio.uniform(0.92, 1.06)
        pontos.append((lado / 2 + math.cos(ang) * r, lado / 2 + math.sin(ang) * r * 0.82))
    d = ImageDraw.Draw(img)
    d.polygon(pontos, fill=fundo, outline=ROXO_ESCURO, width=12)
    miolo = [(lado / 2 + (x - lado / 2) * 0.8, lado / 2 + (y - lado / 2) * 0.8) for x, y in pontos]
    d.polygon(miolo, fill=(255, 255, 255, 70))
    img.alpha_composite(rotulo, ((lado - rotulo.width) // 2, (lado - rotulo.height) // 2))
    return sombra_de(img, 10, 12, 150)


def carregar(caminho, altura=None, largura=None):
    img = Image.open(os.path.join(ASSETS, caminho)).convert("RGBA")
    if altura:
        img = img.resize((round(img.width * altura / img.height), altura), Image.LANCZOS)
    elif largura:
        img = img.resize((largura, round(img.height * largura / img.width)), Image.LANCZOS)
    return img


def ficha(icone, txt):
    """Fichinha de prêmio como as do jogo: o ícone e o número, lado a lado."""
    ic = carregar(icone, altura=112)
    rotulo = texto(txt, 104, BRANCO, contorno=8, sombra=False)
    w = ic.width + rotulo.width - 10 + 40
    h = 150
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([0, 0, w - 1, h - 1], 999, fill=(46, 29, 74, 215), outline=(255, 255, 255, 240),
                                          width=5)
    img.alpha_composite(ic, (22, (h - ic.height) // 2))
    img.alpha_composite(rotulo, (ic.width + 6, (h - rotulo.height) // 2 + 4))
    return sombra_de(img, 8, 10, 140)


def botao(txt):
    """Botão grande "BAIXE AGORA" (rosa, com o lado de baixo e uma seta)."""
    w, h = 720, 160
    img = Image.new("RGBA", (w + 20, h + 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([10, 26, w + 10, h + 26], 999, fill=(178, 40, 96, 255), outline=ROXO_ESCURO, width=8)
    d.rounded_rectangle([10, 8, w + 10, h + 8], 999, fill=ROSA, outline=ROXO_ESCURO, width=8)
    d.rounded_rectangle([40, 20, w - 20, 20 + h // 3], 999, fill=(255, 255, 255, 70))
    f = fonte(104)
    d.text((w // 2 + 50, h // 2 + 12), txt, font=f, fill=BRANCO, anchor="mm", stroke_width=6, stroke_fill=ROXO_ESCURO)
    # seta para baixo
    cx, cy = 118, h // 2 + 8
    seta = [(cx - 16, cy - 40), (cx + 16, cy - 40), (cx + 16, cy), (cx + 38, cy), (cx, cy + 40), (cx - 38, cy), (cx - 16, cy)]
    d.polygon(seta, fill=BRANCO, outline=ROXO_ESCURO, width=5)
    return img


def colar(quadro, img, x, y):
    """Cola img com o canto em (x, y), cortando o que sair do quadro."""
    x, y = int(round(x)), int(round(y))
    sx, sy = max(0, -x), max(0, -y)
    w = min(img.width - sx, quadro.width - max(x, 0))
    h = min(img.height - sy, quadro.height - max(y, 0))
    if w <= 0 or h <= 0:
        return
    if sx or sy or w < img.width or h < img.height:
        img = img.crop((sx, sy, sx + w, sy + h))
    quadro.alpha_composite(img, (max(x, 0), max(y, 0)))


def colar_centro(quadro, img, cx, cy):
    colar(quadro, img, cx - img.width / 2, cy - img.height / 2)


def com_alfa(img, a):
    if a >= 0.999:
        return img
    img = img.copy()
    img.putalpha(img.getchannel("A").point(lambda v: int(v * a)))
    return img


def escalar(img, sx, sy=None):
    sy = sx if sy is None else sy
    w, h = max(1, round(img.width * sx)), max(1, round(img.height * sy))
    if (w, h) == img.size:
        return img
    return img.resize((w, h), Image.BICUBIC)


# ---------------------------------------------------------------- elementos animados
def grupo_fixo(_t):
    return 1.0, 1.0


class Peca:
    """Imagem que entra (pulando, carimbando ou subindo), pode balançar e pulsar
    na batida, e sai encolhendo. Posição pelo centro."""

    def __init__(self, img, x, y, ini, fim=None, giro=0.0, estilo="pulo", entrada=0.24, saida=0.13, balanco=0.0,
                 pulso=0.0, grupo=grupo_fixo, centro_grupo=(540, 760)):
        self.img = img.rotate(giro, Image.BICUBIC, expand=True) if giro else img
        self.x, self.y, self.ini, self.fim = x, y, ini, fim
        self.estilo, self.entrada, self.saida = estilo, entrada, saida
        self.balanco, self.pulso, self.grupo, self.centro_grupo = balanco, pulso, grupo, centro_grupo

    def escala(self, t):
        p = (t - self.ini) / self.entrada
        if self.estilo == "carimbo":
            s = 1 + 1.4 * (1 - sai(p))
        elif self.estilo == "sobe":
            s = 1.0
        else:
            s = volta(p)
        if self.fim is not None and t > self.fim:
            s *= 1 - entra((t - self.fim) / self.saida)
        return s * (1 + self.pulso * pulso_batida(t))

    def desenhar(self, quadro, t):
        if t < self.ini or (self.fim is not None and t >= self.fim + self.saida):
            return
        s = self.escala(t)
        g, alfa = self.grupo(t)
        s *= g
        if s <= 0.02 or alfa <= 0.01:
            return
        img = escalar(self.img, s)
        if self.balanco:
            img = img.rotate(self.balanco * math.sin(t * 7.5), Image.BICUBIC, expand=True)
        p = (t - self.ini) / self.entrada
        if self.estilo == "carimbo":
            img = com_alfa(img, limitar(p * 2.5))
        img = com_alfa(img, alfa)
        y = self.y
        if self.estilo == "sobe":
            y += (1 - volta(p, 1.4)) * 90
            img = com_alfa(img, limitar(p * 2))
        cx = self.centro_grupo[0] + (self.x - self.centro_grupo[0]) * g
        cy = self.centro_grupo[1] + (y - self.centro_grupo[1]) * g
        colar_centro(quadro, img, cx, cy)


class Personagem:
    """Personagem do jogo que sobe de baixo da tela, pula e se espreme na batida."""

    def __init__(self, arquivo, x, base, altura, ini, fim=None, pulos=(), espelhar=False, fase=0.0, grupo=grupo_fixo,
                 saida=0.3):
        img = carregar(arquivo, altura=altura)
        if espelhar:
            img = img.transpose(Image.FLIP_LEFT_RIGHT)
        self.img = sombra_de(img, 8, 8, 110)
        self.x, self.base, self.ini, self.fim = x, base, ini, fim
        self.pulos, self.fase, self.grupo, self.saida = pulos, fase, grupo, saida

    def desenhar(self, quadro, t):
        if t < self.ini:
            return
        p = (t - self.ini) / 0.4
        dy = (1 - volta(p, 1.6)) * (self.img.height + 80)
        for tp in self.pulos:
            if 0 <= t - tp < 0.38:
                dy -= math.sin(math.pi * (t - tp) / 0.38) * 110
        if self.fim is not None and t >= self.fim:
            q = (t - self.fim) / self.saida if self.saida else 1
            if q >= 1:
                return
            dy += entra(q) * (self.img.height + 120)
        espreme = 0.06 * pulso_batida(t)
        g, alfa = self.grupo(t)
        img = escalar(self.img, (1 + espreme) * g, (1 - espreme) * g)
        img = img.rotate(3.5 * math.sin(t * 2.4 + self.fase), Image.BICUBIC, expand=True)
        img = com_alfa(img, alfa)
        cx = 540 + (self.x - 540) * g
        base = 760 + (self.base - 760) * g
        colar(quadro, img, cx - img.width / 2, base - img.height + dy)


class Legenda:
    """Duas linhas embaixo do cartão: a de cima branca, a de baixo grande e
    amarela; as palavras entram uma a uma, pulando."""

    Y1, Y2, GIRO = 1506, 1630, -3.0

    def __init__(self, ini, fim, linha1, linha2):
        self.ini, self.fim = ini, fim
        self.palavras = []
        t = ini
        for linha, tamanho, cor, y in ((linha1, 92, BRANCO, self.Y1), (linha2, 152, AMARELO, self.Y2)):
            while True:
                f = fonte(tamanho)
                espaco = f.getlength(" ")
                larguras = [f.getlength(p) for p in linha.split()]
                total = sum(larguras) + espaco * (len(larguras) - 1)
                if total < 960:
                    break
                tamanho -= 6
            x = 540 - total / 2
            for palavra, w in zip(linha.split(), larguras):
                cx = x + w / 2
                # girar a linha inteira em torno do centro da legenda
                ang = math.radians(-self.GIRO)
                meio = ((self.Y1 + self.Y2) / 2)
                rx = 540 + (cx - 540) * math.cos(ang) - (y - meio) * math.sin(ang)
                ry = meio + (cx - 540) * math.sin(ang) + (y - meio) * math.cos(ang)
                img = texto(palavra, tamanho, cor).rotate(self.GIRO, Image.BICUBIC, expand=True)
                self.palavras.append((img, rx, ry, t))
                x += w + espaco
                t += 0.075
            t += 0.06

    def desenhar(self, quadro, t):
        if t < self.ini or t > self.fim + 0.15:
            return
        for img, x, y, tp in self.palavras:
            if t < tp:
                continue
            p = (t - tp) / 0.22
            s = volta(p, 2.6)
            if t > self.fim:
                s *= 1 - entra((t - self.fim) / 0.13)
            if s <= 0.02:
                continue
            colar_centro(quadro, escalar(img, s), x, y + (1 - sai(p)) * 40)


class Explosao:
    """Granulado (e ícones) explodindo de um ponto, com gravidade."""

    def __init__(self, t0, cx, cy, n, icones=(), n_icones=0, vel=(700, 1700), gravidade=2600, vida=1.5, semente=3,
                 para_cima=False):
        self.t0, self.cx, self.cy, self.vida, self.g = t0, cx, cy, vida, gravidade
        sorteio = random.Random(semente)
        self.parts = []
        for i in range(n + n_icones):
            if para_cima:
                ang = -math.pi / 2 + sorteio.uniform(-0.75, 0.75)
            else:
                ang = sorteio.uniform(0, 2 * math.pi)
            v = sorteio.uniform(*vel)
            if i < n:
                comprimento = sorteio.randint(26, 44)
                img = Image.new("RGBA", (comprimento + 4, 16), (0, 0, 0, 0))
                ImageDraw.Draw(img).rounded_rectangle([2, 2, comprimento + 2, 13], 99,
                                                      fill=sorteio.choice(CORES_GRANULADO) + (255,), outline=(46, 29, 74, 160),
                                                      width=2)
                moeda = False
            else:
                img = icones[i % len(icones)]
                moeda = True
            self.parts.append((img, math.cos(ang) * v, math.sin(ang) * v, sorteio.uniform(0, 360),
                               sorteio.uniform(-720, 720), moeda, sorteio.uniform(0, 6)))

    def desenhar(self, quadro, t):
        dt = t - self.t0
        if dt < 0 or dt > self.vida:
            return
        fim = limitar((dt - self.vida * 0.7) / (self.vida * 0.3))
        for img, vx, vy, r0, giro, moeda, fase in self.parts:
            x = self.cx + vx * dt * (1 - 0.35 * dt)
            y = self.cy + vy * dt * (1 - 0.35 * dt) + 0.5 * self.g * dt * dt
            if not (-80 < x < L + 80 and -80 < y < A + 80):
                continue
            s = 1 - entra(fim)
            if moeda:  # ícones giram como moeda (achatando na horizontal)
                im = escalar(img, max(0.15, abs(math.cos(dt * 9 + fase))) * s, s)
            else:
                im = escalar(img, s).rotate(r0 + giro * dt, Image.BICUBIC, expand=True)
            colar_centro(quadro, im, x, y)


class LinhasVelocidade:
    """Riscos brancos saindo do centro do cartão (turbo)."""

    def __init__(self, ini, fim):
        self.ini, self.fim = ini, fim

    def desenhar(self, quadro, t):
        if not self.ini <= t < self.fim:
            return
        k = int(t * FPS)
        sorteio = random.Random(k)
        camada = Image.new("RGBA", (CARTAO_L, CARTAO_A), (0, 0, 0, 0))
        d = ImageDraw.Draw(camada)
        cx, cy = CARTAO_L / 2, CARTAO_A * 0.55
        forca = 1 - entra((t - self.ini) / (self.fim - self.ini))
        for _ in range(26):
            ang = sorteio.uniform(0, 2 * math.pi)
            r0 = sorteio.uniform(330, 520)
            r1 = r0 + sorteio.uniform(200, 420)
            larg = sorteio.randint(4, 11)
            d.line([(cx + math.cos(ang) * r0, cy + math.sin(ang) * r0), (cx + math.cos(ang) * r1, cy + math.sin(ang) * r1)],
                   fill=(255, 255, 255, int(170 * forca)), width=larg)
        camada.putalpha(Image.fromarray(np.minimum(np.asarray(camada.getchannel("A")), np.asarray(MASCARA))))
        quadro.alpha_composite(camada, (CARTAO_X, CARTAO_Y))


class Destaque:
    """A pergunta do jogo saltando para fora do cartão (recorte ao vivo da cena)."""

    Y = 1318

    def __init__(self, trecho, caixa, ini, fim):
        self.trecho, self.caixa, self.ini, self.fim = trecho, caixa, ini, fim

    def holofote(self, t):
        """Quanto escurecer o cartão atrás da pergunta (0 a 1)."""
        if not self.ini <= t < self.fim + 0.2:
            return 0.0
        return sai((t - self.ini) / 0.3) * (1 - sai((t - self.fim) / 0.2))

    def desenhar(self, quadro, t):
        if not self.ini <= t < self.fim + 0.2:
            return
        _, q = self.trecho.cena.quadro(self.trecho.origem(t - self.trecho.ini))
        x0, y0, x1, y1 = self.caixa
        larg = 1010
        img = Image.fromarray(q).crop(self.caixa).resize((larg, round((y1 - y0) * larg / (x1 - x0))), Image.BICUBIC)
        moldura = Image.new("RGBA", (img.width + 16, img.height + 16), (0, 0, 0, 0))
        mascara = Image.new("L", img.size, 0)
        ImageDraw.Draw(mascara).rounded_rectangle([0, 0, img.width - 1, img.height - 1], 30, fill=255)
        ImageDraw.Draw(moldura).rounded_rectangle([0, 0, moldura.width - 1, moldura.height - 1], 38, fill=BRANCO)
        moldura.paste(img, (8, 8), mascara)
        moldura = sombra_de(moldura, 14, 16, 170)
        # sai do lugar onde está no cartão e cresce
        escala_cartao = CARTAO_L / CENA_L
        y_cartao = CARTAO_Y + (y0 + y1) / 2 * escala_cartao
        p = (t - self.ini) / 0.3
        s0 = (x1 - x0) * escala_cartao / larg
        s = s0 + (1 - s0) * volta(p, 1.8)
        y = y_cartao + (self.Y - y_cartao) * sai(p)
        giro = -2.5 * sai(p)
        if t > self.fim:
            q2 = (t - self.fim) / 0.2
            s = 1 - (1 - s0) * sai(q2)
            y = self.Y + (y_cartao - self.Y) * sai(q2)
            giro = -2.5 * (1 - sai(q2))
            moldura = com_alfa(moldura, 1 - entra(q2))
        colar_centro(quadro, escalar(moldura, s).rotate(giro, Image.BICUBIC, expand=True), 540, y)


class Botao(Peca):
    """O botão BAIXE AGORA: pulsa na batida e um brilho passa por ele."""

    def desenhar(self, quadro, t):
        if t < self.ini:
            return
        base = self.img.copy()
        fase = ((t - self.ini) / (2 * BATIDA)) % 1.0
        if fase < 0.45:
            brilho = Image.new("RGBA", base.size, (0, 0, 0, 0))
            x = -200 + (base.width + 400) * fase / 0.45
            ImageDraw.Draw(brilho).polygon([(x, 0), (x + 70, 0), (x - 10, base.height), (x - 80, base.height)],
                                           fill=(255, 255, 255, 120))
            brilho.putalpha(Image.fromarray(np.minimum(np.asarray(brilho.getchannel("A")),
                                                       np.asarray(self.mascara))))
            base.alpha_composite(brilho)
        img_antiga, self.img = self.img, base
        Peca.desenhar(self, quadro, t)
        self.img = img_antiga


# ---------------------------------------------------------------- fundo
class Fundo:
    """Roxo do jogo com raios de luz girando e granulado descendo devagar."""

    def __init__(self):
        y = np.abs(np.linspace(0, 1, A, dtype=np.float32) - 0.5)[:, None, None] * 2
        meio, borda = np.array([150, 110, 206], np.float32), np.array([78, 48, 124], np.float32)
        self.base = np.broadcast_to(meio + (borda - meio) * y, (A, L, 3)).astype(np.float32)
        yy, xx = np.mgrid[0:A, 0:L].astype(np.float32)
        self.ang = np.arctan2(yy - 760, xx - 540)
        raio = np.hypot(yy - 760, xx - 540)
        self.queda = (np.clip(1 - raio / 1500, 0, 1) ** 0.8).astype(np.float32)
        self.granulado = Image.new("RGBA", (L, A * 2), (0, 0, 0, 0))
        sorteio = random.Random(7)
        for _ in range(420):
            x, yv = sorteio.randrange(L), sorteio.randrange(A)
            comprimento, grossura = sorteio.randint(16, 32), sorteio.randint(7, 10)
            g = Image.new("RGBA", (comprimento + 4, comprimento + 4), (0, 0, 0, 0))
            ImageDraw.Draw(g).rounded_rectangle([2, (comprimento - grossura) // 2 + 2, comprimento + 2,
                                                 (comprimento + grossura) // 2 + 2], 99,
                                                fill=sorteio.choice(CORES_GRANULADO) + (120,))
            g = g.rotate(sorteio.randrange(180), expand=True)
            for dy in (0, A):
                self.granulado.alpha_composite(g, (min(x, L - g.width), min(yv + dy, 2 * A - g.height)))

    def __call__(self, t):
        giro = 0.16 * t + 0.9 * sai((t - b(8)) / 1.2) + 0.9 * sai((t - b(66)) / 1.2)
        raios = np.clip(np.sin(16 * (self.ang - giro)) * 2.5 + 0.5, 0, 1)
        forca = 0.10 + 0.05 * pulso_batida(t)
        if b(8) <= t < b(12):
            forca += 0.12 * (1 - sai((t - b(8)) / 1.5))
        luz = (raios * self.queda * forca)[..., None]
        img = self.base + (255 - self.base) * luz
        quadro = Image.fromarray(img.astype(np.uint8)).convert("RGBA")
        desce = int(t * 55) % A
        quadro.alpha_composite(self.granulado.crop((0, A - desce, L, 2 * A - desce)))
        return quadro


# ---------------------------------------------------------------- cenas e trechos
class Cena:
    """Um vídeo gravado pelo jogo, inteiro na memória, com o ajuste de cor de cada quadro."""

    def __init__(self, pasta, nome):
        bruto = subprocess.run(["ffmpeg", "-v", "error", "-i", os.path.join(pasta, nome + ".avi"), "-f", "rawvideo",
                                "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
        self.quadros = np.frombuffer(bruto, np.uint8).reshape(-1, CENA_A, CENA_L, 3)
        self.n = len(self.quadros)
        self.duracao = self.n / FPS
        # tira a névoa: estica os tons de cada quadro (suavizado no tempo, sem piscar)
        amostra = self.quadros[:, ::16, ::16].astype(np.float32) @ np.array([0.299, 0.587, 0.114], np.float32)
        amostra = amostra.reshape(self.n, -1)
        baixo, alto = np.percentile(amostra, 1.0, axis=1), np.percentile(amostra, 99.6, axis=1)
        nucleo = np.ones(15) / 15
        baixo = np.convolve(np.pad(baixo, 7, mode="edge"), nucleo, "valid")
        alto = np.convolve(np.pad(alto, 7, mode="edge"), nucleo, "valid")
        baixo = np.minimum(baixo * 0.9, 120)
        alto = np.maximum(alto, 225)
        ganho = np.minimum(255 / (alto - baixo), 1.8)
        x = np.arange(256, dtype=np.float32)
        self.tabelas = []
        for lo, gn in zip(baixo, ganho):
            y = np.clip((x - lo) * gn, 0, 255) / 255
            y = y + 0.18 * (y * y * (3 - 2 * y) - y)  # curva em S leve (mais contraste)
            self.tabelas.append(np.clip(y * 255, 0, 255).astype(np.uint8))

    def quadro(self, t):
        i = int(limitar(round(t * FPS), 0, self.n - 1))
        return i, self.quadros[i]


def ajustar_cor(arr, tabela, saturacao=1.2):
    arr = tabela[arr].astype(np.int32)
    cinza = (arr[..., 0] * 77 + arr[..., 1] * 150 + arr[..., 2] * 29) >> 8
    arr = cinza[..., None] + (((arr - cinza[..., None]) * int(saturacao * 256)) >> 8)
    return np.clip(arr, 0, 255).astype(np.uint8)


class Trecho:
    """Pedaço de uma cena no vídeo: do começo ao fim (em batidas), com rampa de
    velocidade (câmera lenta/acelerada) e movimentos de câmera."""

    def __init__(self, cena, ini, fim, rampa, camera, socos=()):
        self.cena, self.ini, self.fim = cena, b(ini), b(fim)
        self.dur = self.fim - self.ini
        # rampa: [(segundo do trecho, segundo da cena)] → velocidade suavizada
        pts = [(self.dur if o == "FIM" else o, s) for o, s in rampa]
        self.ts = np.linspace(0, self.dur, int(self.dur * 240) + 1)
        src = np.interp(self.ts, [o for o, _ in pts], [s for _, s in pts])
        vel = np.gradient(src, self.ts)
        sigma = 0.07 * 240
        nucleo = np.exp(-0.5 * (np.arange(-int(3 * sigma), int(3 * sigma) + 1) / sigma) ** 2)
        nucleo /= nucleo.sum()
        vel = np.convolve(np.pad(vel, len(nucleo) // 2, mode="edge"), nucleo, "valid")
        acum = np.concatenate([[0], np.cumsum((vel[1:] + vel[:-1]) / 2 * np.diff(self.ts))])
        self.src = src[0] + acum * (src[-1] - src[0]) / acum[-1]
        self.v0, self.v1 = vel[0], vel[-1]
        self.camera_pts = [(self.dur if c[0] == "FIM" else c[0],) + tuple(c[1:]) for c in camera]
        self.socos = list(socos)

    def origem(self, t):
        """Segundo da cena mostrado no instante t do trecho (estende nas transições)."""
        if t < 0:
            s = self.src[0] + t * self.v0
        elif t > self.dur:
            s = self.src[-1] + (t - self.dur) * self.v1
        else:
            s = float(np.interp(t, self.ts, self.src))
        return limitar(s, 0, self.cena.duracao - 1 / FPS)

    def quando(self, s):
        """Instante do vídeo em que a cena chega ao segundo s."""
        return self.ini + float(np.interp(s, self.src, self.ts))

    def camera(self, t):
        pts = self.camera_pts
        if t <= pts[0][0]:
            return pts[0][1:]
        for a, c in zip(pts, pts[1:]):
            if t <= c[0]:
                k = suave((t - a[0]) / max(1e-6, c[0] - a[0]))
                return tuple(x + (y - x) * k for x, y in zip(a[1:], c[1:]))
        return pts[-1][1:]

    def caixa(self, t):
        zoom, cx, cy = self.camera(t)
        for ts, forca in self.socos:
            dt = t - (ts - self.ini)
            if dt >= 0:
                zoom *= 1 + forca * (sai(dt / 0.06) if dt < 0.06 else math.exp(-(dt - 0.06) * 6))
        cw, ch = CENA_L / zoom, CENA_A / zoom
        x0 = limitar(cx * CENA_L - cw / 2, 0, CENA_L - cw)
        y0 = limitar(cy * CENA_A - ch / 2, 0, CENA_A - ch)
        return x0, y0, cw, ch


def borrar(arr, dx, dy):
    """Borrão de movimento na direção do maior deslocamento (dx, dy) em pixels."""
    n = int(min(240, max(abs(dx), abs(dy))))
    if n < 3:
        return arr
    eixo = 1 if abs(dx) >= abs(dy) else 0
    pad = [(0, 0)] * 3
    pad[eixo] = (n // 2 + 1, n - n // 2)
    p = np.pad(arr, pad, mode="edge").astype(np.int32)
    c = np.cumsum(p, axis=eixo)
    tam = arr.shape[eixo]
    fim = np.take(c, range(n + 1, n + 1 + tam), axis=eixo)
    ini = np.take(c, range(1, 1 + tam), axis=eixo)
    return ((fim - ini) // n).astype(np.uint8)


def conteudo(trecho, t):
    """Quadro do trecho (no tamanho do cartão) no instante t (relativo ao trecho)."""
    _, q = trecho.cena.quadro(trecho.origem(t))
    i = int(limitar(round(trecho.origem(t) * FPS), 0, trecho.cena.n - 1))
    x0, y0, cw, ch = trecho.caixa(t)
    img = Image.fromarray(q).resize((CARTAO_L, CARTAO_A), Image.BICUBIC, box=(x0, y0, x0 + cw, y0 + ch))
    arr = ajustar_cor(np.asarray(img), trecho.cena.tabelas[i])
    # câmera correndo de um ponto a outro: borrão de movimento
    x1, y1, cw1, ch1 = trecho.caixa(t + 1 / FPS)
    dx = ((x1 + cw1 / 2) - (x0 + cw / 2)) * CARTAO_L / cw
    dy = ((y1 + ch1 / 2) - (y0 + ch / 2)) * CARTAO_A / ch
    return borrar(arr, dx * 0.8, dy * 0.8)


def zoom_borrado(arr, escala, rastro):
    """Aumenta a partir do centro com borrão radial (média de cópias em escalas vizinhas)."""
    img = Image.fromarray(arr)
    soma = np.zeros(arr.shape, np.float32)
    n = 6 if rastro > 0.02 else 1
    for k in range(n):
        s = escala * (1 + rastro * k / max(1, n - 1))
        cw, ch = CARTAO_L / s, CARTAO_A / s
        x0, y0 = (CARTAO_L - cw) / 2, (CARTAO_A - ch) / 2
        soma += np.asarray(img.resize((CARTAO_L, CARTAO_A), Image.BILINEAR, box=(x0, y0, x0 + cw, y0 + ch)), np.float32)
    return (soma / n).astype(np.uint8)


# ---------------------------------------------------------------- roteiro
CENAS = {}
TRECHOS = []
TRANSICOES = []  # (tempo, tipo, duração)
ATRAS, FRENTE = [], []  # elementos atrás e na frente do cartão
FLASHES = []  # (tempo, força, subida, descida)
TREMIDAS = []  # (tempo, força em pixels, amortecimento)
SONS = []  # (tempo, som, volume)
LEGENDAS = []
MASCARA = None


def flash(t, forca=1.0, subida=0.05, descida=0.35):
    FLASHES.append((t, forca, subida, descida))


def tremida(t, forca=26, amortece=7):
    TREMIDAS.append((t, forca, amortece))


def som(t, nome, volume=1.0):
    SONS.append((t, nome, volume))


def palavras(lista, frase, tamanho, cor, y, ini, passo, fim, grupo, som_nome=None, giro=-3):
    """Uma linha de texto centralizada cujas palavras entram uma a uma."""
    f = fonte(tamanho)
    espaco = f.getlength(" ") * 1.15
    larguras = [f.getlength(p) for p in frase.split()]
    x = 540 - (sum(larguras) + espaco * (len(larguras) - 1)) / 2
    for i, (palavra, w) in enumerate(zip(frase.split(), larguras)):
        lista.append(Peca(texto(palavra, tamanho, cor), x + w / 2, y + (x + w / 2 - 540) * math.tan(math.radians(-giro)),
                          ini + i * passo, fim, giro=giro, grupo=grupo))
        if som_nome:
            som(ini + i * passo, som_nome, 0.75)
        x += w + espaco


def montar_roteiro(pasta):
    global MASCARA
    MASCARA = Image.new("L", (CARTAO_L, CARTAO_A), 0)
    ImageDraw.Draw(MASCARA).rounded_rectangle([0, 0, CARTAO_L - 1, CARTAO_A - 1], RAIO_CARTAO, fill=255)
    for nome in ("1_vila", "2_corrida", "3_chefao", "4_batalha", "5_casa", "6_final"):
        CENAS[nome] = Cena(pasta, nome)

    # ---- gancho (batidas 0 a 8): perguntas pulando + personagens
    def grupo_gancho(t):
        if t >= b(8):
            return 1.0, 0.0
        return 1 + 0.12 * entra((t - b(7)) / BATIDA), 1.0

    fim_1 = b(4.5)
    palavras(FRENTE, "VOCÊ SABE USAR", 170, BRANCO, 420, -0.1, BATIDA / 2, fim_1, grupo_gancho, "estouro")
    for i, (nome, cor, x, y, giro) in enumerate((("WORD?", (43, 87, 154, 255), 360, 680, -6),
                                                 ("EXCEL?", (33, 135, 70, 255), 700, 890, 5),
                                                 ("POWERPOINT?", (215, 76, 40, 255), 520, 1100, -3))):
        FRENTE.append(Peca(etiqueta(nome, 150, cor), x, y, b(2 + i * 0.5), fim_1, giro=giro, balanco=1.5,
                           grupo=grupo_gancho))
        som(b(2 + i * 0.5), "pulo", 0.7)
    palavras(FRENTE, "E SE APRENDER", 160, BRANCO, 520, b(4.5), BATIDA / 4, b(8), grupo_gancho, "estouro")
    palavras(FRENTE, "FOSSE UM", 160, BRANCO, 700, b(5.5), BATIDA / 4, b(8), grupo_gancho, "estouro")
    FRENTE.append(Peca(texto("JOGO?!", 400, AMARELO), 540, 975, b(6), b(8), giro=-5, estilo="carimbo", entrada=0.16,
                       grupo=grupo_gancho))
    tremida(b(6), 18, 9)
    som(b(6), "impacto_leve", 0.9)
    som(b(4.5) - 0.2, "vush", 0.6)
    som(b(4.0), "subida", 0.75)
    ATRAS.append(Personagem("personagens/mascote_cereal.png", 820, 1960, 560, b(0.5), b(8), pulos=(b(6),), fase=1, saida=0))
    ATRAS.append(Personagem("personagens/maca_noob.png", 250, 1960, 500, b(1.5), b(8), pulos=(b(6) + 0.08,), fase=2.5, saida=0))
    som(b(0.5), "pulo", 0.5)
    som(b(1.5), "pulo", 0.5)

    # ---- logo na virada da música (batidas 8 a 12)
    def grupo_logo(t):
        q = (t - (b(12) - 0.22)) / 0.3
        if q <= 0:
            return 1.0, 1.0
        return 1 + 2.6 * entra(q), 1 - sai(q)

    logo = sombra_de(carregar("abertura.png", largura=840), 12, 14, 150)
    FRENTE.append(Peca(logo, 540, 640, b(8), b(12), estilo="carimbo", entrada=0.17, pulso=0.025, grupo=grupo_logo))
    flash(b(8), 1.0, 0.02, 0.4)
    tremida(b(8), 34, 6)
    icones = [carregar("itens/moeda.png", altura=74), carregar("itens/acucar.png", altura=78),
              carregar("itens/estrela.png", altura=74)]
    FRENTE.insert(0, Explosao(b(8), 540, 640, 110, icones, 12, semente=8))
    som(b(8), "impacto", 1.0)
    som(b(8), "explosao", 0.5)
    for i, (arq, x, base, alt, esp) in enumerate((("personagens/chocolate_mestre.png", 190, 1660, 440, False),
                                                  ("personagens/cupcake_pro.png", 890, 1660, 400, False),
                                                  ("personagens/maca_noob.png", 300, 1990, 430, False),
                                                  ("personagens/mascote_cereal.png", 780, 1990, 440, True))):
        ATRAS.append(Personagem(arq, x, base, alt, b(8.5 + i * 0.5), b(12), fase=i * 1.3, grupo=grupo_logo))
        som(b(8.5 + i * 0.5), "pulo", 0.45)
    FRENTE.append(Peca(pilula("APRENDA OFFICE JOGANDO!", 84), 540, 1130, b(10), b(12), giro=-2, grupo=grupo_logo))
    som(b(10), "estouro", 0.8)
    som(b(12) - 0.25, "vush", 0.9)
    flash(b(12), 0.55, 0.05, 0.25)

    # ---- cenas do jogo (batidas 12 a 66)
    c = CENAS
    vila = Trecho(c["1_vila"], 12, 20, [(0, 1.5), ("FIM", 4.6)], [(0, 1.0, .5, .5), ("FIM", 1.08, .5, .55)])
    corrida = Trecho(c["2_corrida"], 20, 32, [(0, 1.2), (1.95, 4.5), (3.35, 5.2), ("FIM", 6.5)],
                     [(0, 1.0, .5, .5), (1.95, 1.0, .5, .55), (3.3, 1.22, .5, .6), (3.48, 1.0, .5, .5), ("FIM", 1.0, .5, .5)])
    corrida.socos.append((corrida.quando(5.2), 0.1))
    chefao = Trecho(c["3_chefao"], 32, 44, [(0, 0.6), (1.2, 2.5), (2.0, 3.4), (2.6, 3.55), (2.82, 3.75), (3.95, 4.3),
                                            ("FIM", 5.0)],
                    [(0, 1.25, .5, .3), (0.95, 1.3, .5, .32), (1.22, 1.0, .5, .5), (2.6, 1.0, .5, .5),
                     (2.82, 1.45, .48, .28), (3.95, 1.55, .48, .27), (4.4, 1.05, .5, .45), ("FIM", 1.0, .5, .5)])
    chefao.socos.append((chefao.quando(4.0), 0.13))
    batalha = Trecho(c["4_batalha"], 44, 54, [(0, 0.7), (1.55, 3.7), (3.0, 4.45), ("FIM", 5.4)],
                     [(0, 1.0, .5, .5), (1.5, 1.0, .5, .5), (2.2, 1.3, .7, .42), (3.0, 1.3, .7, .42), (3.5, 1.0, .5, .5),
                      ("FIM", 1.0, .5, .5)])
    batalha.socos.append((batalha.quando(4.3), 0.12))
    casa = Trecho(c["5_casa"], 54, 60, [(0, 0.2), ("FIM", 3.8)], [(0, 1.0, .5, .45), ("FIM", 1.2, .5, .45)])
    premios = Trecho(c["6_final"], 60, 66, [(0, 0.0), ("FIM", 2.3)], [(0, 1.12, .5, .5), ("FIM", 1.2, .5, .48)])
    TRECHOS.extend([vila, corrida, chefao, batalha, casa, premios])
    TRANSICOES.extend([(b(20), "chicote_esq", 0.28), (b(32), "chicote_cima", 0.28), (b(44), "zoom", 0.36),
                       (b(54), "chicote_dir", 0.28), (b(60), "flash", 0)])
    for t, tipo, _d in TRANSICOES:
        if tipo == "flash":
            flash(t, 0.9, 0.06, 0.3)
            som(t, "especial", 0.8)
        else:
            som(t - 0.2, "vush", 0.8)
    flash(b(44), 0.6, 0.12, 0.2)

    LEGENDAS.extend([
        Legenda(b(12.4), b(19.6), "EXPLORE A", "VILA DOS DOCES"),
        Legenda(b(20.4), b(24.6), "CORRIDA", "DE DOCES"),
        Legenda(b(25.2), b(31.6), "ACERTOU?", "TURBO!"),
        Legenda(b(32.3), b(35.0), "ENFRENTE O", "CHEFÃO!"),
        Legenda(b(35.3), b(43.6), "ACERTE E", "ATAQUE!"),
        Legenda(b(44.4), b(53.6), "BATALHAS", "NA ARENA!"),
        Legenda(b(54.3), b(59.7), "DECORE A", "SUA CASA"),
        Legenda(b(60.3), b(65.7), "A CADA ACERTO", "GANHE PRÊMIOS!"),
    ])
    for leg in LEGENDAS:
        som(leg.ini, "estouro", 0.45)
    FRENTE.extend(LEGENDAS)

    # corrida: câmera lenta no portal, depois TURBO!
    t_lenta = corrida.ini + 1.95
    som(t_lenta - 0.1, "desce", 0.8)
    t_turbo = corrida.quando(5.2)
    som(t_turbo, "turbo", 1.0)
    som(t_turbo - 0.05, "vush", 0.7)
    tremida(t_turbo, 14, 8)
    FRENTE.append(LinhasVelocidade(t_turbo, b(32)))
    FRENTE.append(Peca(adesivo("TURBO!", 120, AMARELO, ROSA, semente=4), 780, 430, t_turbo, b(31.4), giro=-10,
                       balanco=3))
    # chefão: a pergunta salta do cartão, a resposta certa e o golpe
    t_pergunta = chefao.ini + 1.25
    t_certo = chefao.quando(3.42)
    FRENTE.append(Destaque(chefao, (20, 1330, 1060, 1547), t_pergunta, chefao.ini + 2.6))
    som(t_pergunta, "pulo", 0.6)
    FRENTE.append(Peca(adesivo("CERTO!", 118, VERDE, BRANCO, pontas=14, semente=2), 860, 1095, t_certo,
                       chefao.ini + 2.6, giro=8))
    som(t_certo, "acerto", 0.9)
    som(chefao.ini + 2.6, "vush", 0.7)
    som(chefao.ini + 2.82, "desce", 0.6)
    t_golpe = chefao.quando(4.0)
    tremida(t_golpe, 30, 6)
    flash(t_golpe, 0.35, 0.02, 0.15)
    som(t_golpe, "impacto", 0.9)
    som(t_golpe, "explosao", 0.8)
    FRENTE.append(Peca(adesivo("POW!", 150, AMARELO, ROSA, semente=6), 790, 470, t_golpe, b(43.4), giro=-12, balanco=2))
    FRENTE.append(Explosao(t_golpe, 520, 420, 40, semente=11, vel=(500, 1200), vida=1.1))
    # batalha: golpe no milho
    t_golpe2 = batalha.quando(4.3)
    tremida(t_golpe2, 26, 6)
    flash(t_golpe2, 0.3, 0.02, 0.15)
    som(t_golpe2 - 0.25, "desce", 0.5)
    som(t_golpe2, "impacto_leve", 1.0)
    som(t_golpe2, "chape", 0.8)
    FRENTE.append(Peca(adesivo("BOOM!", 140, (255, 138, 92, 255), BRANCO, semente=9), 300, 430, t_golpe2, b(53.4),
                       giro=9, balanco=2))
    # casa
    som(casa.ini + 0.15, "construir", 0.7)
    # prêmios: fichas com os ícones do jogo e o baú abrindo
    for i, (icone, valor, y, tp) in enumerate((("itens/moeda.png", "+20", 420, 60.5), ("itens/acucar.png", "+10", 590, 61.0),
                                               ("itens/xp.png", "+50", 760, 61.5))):
        FRENTE.append(Peca(ficha(icone, valor), 330, y, b(tp), b(65.6), giro=-3 + i * 2.5, pulso=0.03))
        som(b(tp), "moeda", 0.8)
    bau = sombra_de(carregar("itens/bau_ouro.png", altura=300), 10, 12, 140)
    bau_aberto = sombra_de(carregar("itens/bau_aberto_ouro.png", altura=330), 10, 12, 140)
    FRENTE.append(Peca(bau, 790, 760, b(62), b(63), giro=6, balanco=4, saida=0.01))
    FRENTE.append(Peca(bau_aberto, 790, 745, b(63), b(65.6), giro=6, entrada=0.2, pulso=0.03))
    FRENTE.append(Explosao(b(63), 790, 700, 30, icones, 14, semente=5, para_cima=True, vel=(900, 1700), vida=1.6))
    som(b(62), "caixa", 0.8)
    for k in range(4):
        som(b(63) + k * 0.09, "moeda", 0.6)
    som(b(63), "especial", 0.7)

    # ---- tela final (batidas 66 a 80)
    logo_final = sombra_de(carregar("abertura.png", largura=700), 12, 14, 150)
    FRENTE.append(Peca(logo_final, 540, 470, b(66), estilo="carimbo", entrada=0.17, pulso=0.025))
    FRENTE.insert(0, Explosao(b(66), 540, 470, 90, icones, 10, semente=21))
    flash(b(66), 0.8, 0.03, 0.35)
    tremida(b(66), 30, 6)
    som(b(66), "impacto", 1.0)
    som(b(66) - 0.25, "vush", 0.7)
    FRENTE.append(Peca(texto("JOGO GRÁTIS!", 176, AMARELO), 540, 885, b(67), estilo="carimbo", entrada=0.15, giro=-3,
                       pulso=0.02))
    tremida(b(67), 16, 8)
    som(b(67), "impacto_leve", 0.9)
    FRENTE.append(Peca(pilula("ANDROID · WINDOWS · NAVEGADOR", 54), 540, 1020, b(68)))
    som(b(68), "estouro", 0.7)
    bt = Botao(botao("BAIXE AGORA"), 540, 1185, b(69), pulso=0.06)
    bt.mascara = bt.img.getchannel("A")
    FRENTE.append(bt)
    som(b(69), "pulo", 0.8)
    FRENTE.append(Peca(texto("saviosant0s.github.io/Doce-Texto-Quiz", 42, BRANCO, contorno=6, link=True), 540, 1322,
                       b(70), estilo="sobe"))
    FRENTE.append(Peca(texto("FEITO NO IFBA CAMPUS VALENÇA", 46, (255, 255, 255, 230), contorno=5), 540, 1392, b(70.5),
                       estilo="sobe"))
    som(b(70), "vitoria", 0.6)
    for i, (arq, x, alt, esp) in enumerate((("personagens/mascote_cereal.png", 150, 400, False),
                                            ("personagens/chocolate_mestre.png", 395, 420, False),
                                            ("personagens/cupcake_pro.png", 685, 400, False),
                                            ("personagens/maca_noob.png", 935, 410, True))):
        ATRAS.append(Personagem(arq, x, 1975, alt, b(66.5 + i * 0.5), fase=i * 1.7, pulos=(b(72 + i * 0.25),),
                                espelhar=esp))
        som(b(66.5 + i * 0.5), "pulo", 0.45)


def trecho_em(t):
    for tr in TRECHOS:
        if tr.ini <= t < tr.fim:
            return tr
    return TRECHOS[-1] if t >= TRECHOS[-1].fim else TRECHOS[0]


def conteudo_em(t):
    for tt, tipo, d in TRANSICOES:
        if d and tt - d / 2 <= t < tt + d / 2:
            a, c = trecho_em(tt - 1e-6), trecho_em(tt)
            p = (t - (tt - d / 2)) / d
            if tipo == "zoom":
                if p < 0.5:
                    q = p * 2
                    return zoom_borrado(conteudo(a, t - a.ini), 1 + 1.6 * entra(q), 0.25 * q)
                q = (p - 0.5) * 2
                return zoom_borrado(conteudo(c, t - c.ini), 1 + 0.9 * (1 - sai(q)), 0.2 * (1 - q))
            va, vc = conteudo(a, t - a.ini), conteudo(c, t - c.ini)
            e = entra_sai(p)
            vel = (entra_sai(min(1, p + 1 / (d * FPS))) - e)
            if tipo == "chicote_cima":
                faixa = np.concatenate([va, vc], axis=0)
                k = int(e * CARTAO_A)
                return borrar(faixa[k:k + CARTAO_A], 0, vel * CARTAO_A * 0.7)
            if tipo == "chicote_dir":
                faixa = np.concatenate([vc, va], axis=1)
                k = int((1 - e) * CARTAO_L)
            else:
                faixa = np.concatenate([va, vc], axis=1)
                k = int(e * CARTAO_L)
            return borrar(faixa[:, k:k + CARTAO_L], vel * CARTAO_L * 0.7, 0)
    tr = trecho_em(t)
    return conteudo(tr, t - tr.ini)


class Cartao:
    """O cartão com a cena: entra girando depois do logo, pulsa na batida e sai
    para baixo na tela final."""

    def __init__(self):
        self.borda = Image.new("RGBA", (CARTAO_L, CARTAO_A), (0, 0, 0, 0))
        d = ImageDraw.Draw(self.borda)
        d.rounded_rectangle([0, 0, CARTAO_L - 1, CARTAO_A - 1], RAIO_CARTAO, outline=BRANCO, width=10)
        d.rounded_rectangle([10, 10, CARTAO_L - 11, CARTAO_A - 11], RAIO_CARTAO - 10, outline=(46, 29, 74, 70), width=4)
        sombra = Image.new("RGBA", (CARTAO_L + 120, CARTAO_A + 120), (0, 0, 0, 0))
        ImageDraw.Draw(sombra).rounded_rectangle([60, 78, CARTAO_L + 60, CARTAO_A + 78], RAIO_CARTAO, fill=(30, 15, 50, 160))
        self.sombra = sombra.filter(ImageFilter.GaussianBlur(18))

    def pose(self, t):
        """(escala, giro, deslocamento x, deslocamento y) ou None se escondido."""
        ini, fim = b(12) - 0.03, b(66)
        if t < ini or t > fim + 0.4:
            return None
        s, giro, dx, dy = 1.0, 0.0, 0.0, 0.0
        p = (t - ini) / 0.45
        if p < 1:
            s = 0.45 + 0.55 * volta(p, 1.5)
            giro = -14 * (1 - sai(p))
            dy = 260 * (1 - sai(p))
        if t > fim:
            q = (t - fim) / 0.4
            s *= 1 - 0.25 * entra(q)
            giro += 16 * entra(q)
            dy += 1500 * entra(q)
        s *= 1 + 0.012 * pulso_batida(t)
        return s, giro, dx, dy

    def desenhar(self, quadro, t):
        pose = self.pose(t)
        if pose is None:
            return
        s, giro, dx, dy = pose
        arr = conteudo_em(t)
        escuro = max([d.holofote(t) for d in FRENTE if isinstance(d, Destaque)] + [0.0])
        if escuro > 0.01:
            arr = (arr * (1 - 0.35 * escuro)).astype(np.uint8)
        img = Image.fromarray(arr).convert("RGBA")
        img.putalpha(MASCARA)
        img.alpha_composite(self.borda)
        sombra = self.sombra
        if abs(s - 1) > 0.002 or abs(giro) > 0.05:
            img = escalar(img, s)
            sombra = escalar(sombra, s)
            if abs(giro) > 0.05:
                img = img.rotate(giro, Image.BICUBIC, expand=True)
                sombra = sombra.rotate(giro, Image.BICUBIC, expand=True)
        colar_centro(quadro, sombra, CENTRO[0] + dx, CENTRO[1] + dy)
        colar_centro(quadro, img, CENTRO[0] + dx, CENTRO[1] + dy)


FUNDO = None
CARTAO = None


def desenhar(t):
    quadro = FUNDO(t)
    for el in ATRAS:
        el.desenhar(quadro, t)
    CARTAO.desenhar(quadro, t)
    for el in FRENTE:
        el.desenhar(quadro, t)
    arr = np.asarray(quadro.convert("RGB"))
    luz = 0.0
    for t0, forca, subida, descida in FLASHES:
        if t0 - subida <= t < t0:
            luz = max(luz, forca * (1 - (t0 - t) / subida))
        elif t0 <= t < t0 + descida:
            luz = max(luz, forca * (1 - sai((t - t0) / descida)))
    if luz > 0.01:
        arr = (arr + (255 - arr.astype(np.float32)) * luz).astype(np.uint8)
    dx = dy = 0.0
    for t0, forca, amortece in TREMIDAS:
        dt = t - t0
        if 0 <= dt < 1.0:
            a = forca * math.exp(-dt * amortece)
            dx += a * math.sin(dt * 71 + t0)
            dy += a * math.cos(dt * 57 + 2 * t0)
    if abs(dx) >= 1 or abs(dy) >= 1:
        m = 48
        p = np.pad(arr, ((m, m), (m, m), (0, 0)), mode="edge")
        ix, iy = m - int(limitar(dx, -m, m)), m - int(limitar(dy, -m, m))
        arr = p[iy:iy + A, ix:ix + L]
    return np.ascontiguousarray(arr)


def desenhar_bytes(k):
    return desenhar(k / FPS).tobytes()


# ---------------------------------------------------------------- som
def ler_som(caminho):
    bruto = subprocess.run(["ffmpeg", "-v", "error", "-i", caminho, "-ac", "2", "-ar", str(TAXA), "-f", "f32le", "-"],
                           capture_output=True, check=True).stdout
    return np.frombuffer(bruto, np.float32).reshape(-1, 2).copy()


def sintetizar(nome):
    """Efeitos feitos aqui mesmo: vush, impacto, subida e "desce" (câmera lenta)."""
    sorteio = np.random.default_rng(len(nome))
    if nome == "vush":
        n = int(0.5 * TAXA)
        t = np.arange(n) / TAXA
        ruido = sorteio.standard_normal(n)
        env = np.sin(np.pi * np.clip(t / 0.5, 0, 1)) ** 2 * np.exp(-((t - 0.3) ** 2) / 0.02)
        grave = signal.sosfilt(signal.butter(2, [300, 1800], "bandpass", fs=TAXA, output="sos"), ruido)
        agudo = signal.sosfilt(signal.butter(2, [1800, 7000], "bandpass", fs=TAXA, output="sos"), ruido)
        mistura = t / 0.5
        som_ = (grave * (1 - mistura) + agudo * mistura * 0.8) * env
        pan = np.clip(t / 0.5, 0, 1)
        return np.stack([som_ * (1 - pan * 0.7), som_ * (0.3 + pan * 0.7)], 1) * 0.9
    if nome in ("impacto", "impacto_leve"):
        dur = 1.4 if nome == "impacto" else 0.7
        n = int(dur * TAXA)
        t = np.arange(n) / TAXA
        freq = 38 + 90 * np.exp(-t * 14)
        sub = np.sin(2 * np.pi * np.cumsum(freq) / TAXA) * np.exp(-t * (3.2 if nome == "impacto" else 7))
        estalo = signal.sosfilt(signal.butter(2, 2500, "highpass", fs=TAXA, output="sos"),
                                sorteio.standard_normal(n)) * np.exp(-t * 60) * 0.5
        corpo = signal.sosfilt(signal.butter(2, 260, "lowpass", fs=TAXA, output="sos"),
                               sorteio.standard_normal(n)) * np.exp(-t * 9) * 2.5
        cauda = signal.sosfilt(signal.butter(2, [200, 3000], "bandpass", fs=TAXA, output="sos"),
                               sorteio.standard_normal(n)) * np.exp(-t * 4) * 0.12
        s = sub * 0.9 + estalo + corpo + cauda
        s = s / np.abs(s).max() * (0.95 if nome == "impacto" else 0.7)
        return np.stack([s, s], 1)
    if nome == "subida":
        dur = b(8) - b(4.0)
        n = int(dur * TAXA)
        t = np.arange(n) / TAXA
        x = t / dur
        ruido = signal.sosfilt(signal.butter(2, 1200, "highpass", fs=TAXA, output="sos"), sorteio.standard_normal(n))
        freq = 180 * (6 ** x)
        tom = np.sin(2 * np.pi * np.cumsum(freq) / TAXA)
        tremolo = 0.6 + 0.4 * np.sin(2 * np.pi * np.cumsum(6 + 22 * x) / TAXA)
        s = (ruido * 0.25 + tom * 0.25 * tremolo) * x ** 2.2
        s[-int(0.01 * TAXA):] *= np.linspace(1, 0, int(0.01 * TAXA))
        return np.stack([s, s], 1)
    if nome == "desce":
        n = int(0.55 * TAXA)
        t = np.arange(n) / TAXA
        freq = 520 * np.exp(-t * 4.5) + 50
        s = np.sin(2 * np.pi * np.cumsum(freq) / TAXA) * np.exp(-t * 3) * np.clip(t / 0.02, 0, 1) * 0.5
        return np.stack([s, s], 1)
    raise KeyError(nome)


def trilha(destino):
    total = int(TOTAL * TAXA)
    musica = ler_som(MUSICA)
    ini = int(MUSICA_INICIO * TAXA)
    musica = musica[ini:ini + total]
    musica = np.pad(musica, ((0, total - len(musica)), (0, 0)))
    t = np.arange(total) / TAXA
    # câmera lenta: a música fica abafada (filtro) e volta aberta no turbo/golpe
    abafada = signal.sosfilt(signal.butter(2, 480, "lowpass", fs=TAXA, output="sos"), musica, axis=0) * 1.3
    peso = np.zeros(total)
    for a, c in LENTAS:
        peso = np.maximum(peso, np.clip((t - a) / 0.08, 0, 1) * np.clip((c - t) / 0.06, 0, 1))
    musica = musica * (1 - peso[:, None]) + abafada * peso[:, None]
    env = np.clip(t / 0.05, 0, 1) * np.clip((TOTAL - t) / 1.6, 0, 1)
    musica *= env[:, None]

    efeitos = np.zeros((total, 2))
    cache = {}
    for t0, nome, volume in SONS:
        if nome not in cache:
            arquivo = None
            for ext in (".wav", ".ogg"):
                caminho = os.path.join(ASSETS, "sons", nome + ext)
                if os.path.exists(caminho):
                    arquivo = caminho
            som_ = ler_som(arquivo) if arquivo else sintetizar(nome)
            if nome == "acerto":
                som_ = som_[:int(1.4 * TAXA)] * np.linspace(1, 0, int(1.4 * TAXA))[:len(som_), None]
            cache[nome] = som_
        som_ = cache[nome] * volume
        i = int(t0 * TAXA)
        if i < 0:
            som_, i = som_[-i:], 0
        j = min(total, i + len(som_))
        efeitos[i:j] += som_[:j - i]
    # a música abaixa um pouco quando entra um efeito forte
    forca = np.abs(efeitos).max(1)
    janela = int(0.12 * TAXA)
    forca = np.convolve(forca, np.ones(janela) / janela, "same")
    abaixa = 1 - 0.35 * np.clip(forca / 0.25, 0, 1)
    mistura = musica * 0.8 * abaixa[:, None] + efeitos * 0.75
    mistura = np.tanh(mistura * 1.2) / np.tanh(1.2)
    wavfile.write(destino, TAXA, mistura.astype(np.float32))


LENTAS = []


# ---------------------------------------------------------------- principal
def iniciar(pasta):
    global FUNDO, CARTAO
    montar_roteiro(pasta)
    FUNDO = Fundo()
    CARTAO = Cartao()
    corrida, chefao, batalha = TRECHOS[1], TRECHOS[2], TRECHOS[3]
    LENTAS.extend([(corrida.ini + 1.95, corrida.quando(5.2)), (chefao.ini + 2.82, chefao.quando(4.0)),
                   (batalha.ini + 1.55, batalha.quando(4.3))])


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    saida = os.path.abspath(args[0] if args else os.path.join(RAIZ, "build/stories"))
    quadros = None
    for a in sys.argv[1:]:
        if a.startswith("--quadros="):
            quadros = [float(x) for x in a.split("=", 1)[1].split(",")]
    iniciar(os.path.join(saida, "cenas"))
    if quadros is not None:
        for t in quadros:
            Image.fromarray(desenhar(t)).save(os.path.join(saida, f"previa_{t:05.2f}.png"))
            print(f"prévia: {t:.2f} s")
        return
    audio = os.path.join(saida, "trilha.wav")
    trilha(audio)
    destino = os.path.join(saida, "doce_texto_stories.mp4")
    n = round(TOTAL * FPS)
    enc = subprocess.Popen(["ffmpeg", "-y", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{L}x{A}", "-r",
                            str(FPS), "-i", "-", "-i", audio, "-af", "loudnorm=I=-14:TP=-1.5:LRA=11", "-c:v", "libx264",
                            "-preset", "slow", "-crf", "19", "-maxrate", "7M", "-bufsize", "14M", "-profile:v", "high", "-pix_fmt", "yuv420p", "-c:a", "aac",
                            "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", "-shortest", destino],
                           stdin=subprocess.PIPE)
    with multiprocessing.get_context("fork").Pool(os.cpu_count()) as pool:
        for k, dados in enumerate(pool.imap(desenhar_bytes, range(n), chunksize=4)):
            enc.stdin.write(dados)
            if k % 60 == 0:
                print(f"  quadro {k}/{n}", flush=True)
    enc.stdin.close()
    if enc.wait() != 0:
        sys.exit("ffmpeg falhou")
    Image.fromarray(desenhar(b(10.5))).convert("RGB").save(os.path.join(saida, "capa.jpg"), quality=92)
    print(f"vídeo: {destino} ({TOTAL:.1f} s)")


if __name__ == "__main__":
    main()
