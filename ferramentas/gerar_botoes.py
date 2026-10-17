#!/usr/bin/env python3
"""Gera as texturas dos botões "de bala" (godot/assets/ui/botoes/*.png).

Cada botão tem cantos arredondados, borda de baixo mais escura (que afunda ao
apertar), um brilho em cima e listrinhas diagonais bem suaves, como papel de
bala. O tema (godot/scripts/ferramentas/gerar_tema.gd) usa estas imagens em
StyleBoxTexture (9 fatias: os cantos ficam do tamanho certo em qualquer botão).

Uso: python3 ferramentas/gerar_botoes.py  (depois gere o tema de novo)
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

PASTA = Path(__file__).resolve().parent.parent / "godot" / "assets" / "ui" / "botoes"
L, A = 96, 80  # tamanho da imagem (1x)
RAIO = 18
BORDA = 7

# nome: (cor, cor ao passar o mouse, cor da borda de baixo)
CORES = {
    "amarelo": ("#F4E038", "#FAEE84", "#CDB91E"),
    "roxo": ("#7E57B1", "#8F69C4", "#5E3D8E"),
    "creme": ("#FFF4E0", "#FFFAF0", "#D9C39E"),
    "menta": ("#4FC99A", "#6FD9AE", "#2E9A70"),
    "morango": ("#FF6FA8", "#FF8FBC", "#CF457D"),
    "ceu": ("#5CB8F0", "#7CC8F4", "#3A8CC4"),
    "vermelho": ("#E5484D", "#EE6B6F", "#B42F34"),
}


def cor(hexa, alfa=255):
    hexa = hexa.lstrip("#")
    return tuple(int(hexa[i:i + 2], 16) for i in (0, 2, 4)) + (alfa,)


def misturar(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def botao(base, borda, apertado=False, cinza=False):
    escala = 4  # desenha grande e reduz: bordas lisas
    w, h, r = L * escala, A * escala, RAIO * escala
    b = (2 if apertado else BORDA) * escala
    topo = (5 * escala) if apertado else 0
    base_c, borda_c = cor(base), cor(borda)
    if cinza:
        base_c = misturar(base_c, (128, 128, 128), 0.5)
        borda_c = misturar(borda_c, (110, 110, 110), 0.5)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, topo, w - 1, h - 1), r, fill=borda_c)  # borda de baixo
    d.rounded_rectangle((0, topo, w - 1, h - 1 - b), r, fill=base_c)
    # listrinhas diagonais (papel de bala), só dentro da face
    face = Image.new("L", (w, h), 0)
    ImageDraw.Draw(face).rounded_rectangle((0, topo, w - 1, h - 1 - b), r, fill=255)
    listras = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dl = ImageDraw.Draw(listras)
    passo = 22 * escala
    for x in range(-h, w + h, passo):
        dl.polygon([(x, h), (x + 8 * escala, h), (x + 8 * escala + h, 0), (x + h, 0)], fill=(255, 255, 255, 22))
    img = Image.alpha_composite(img, Image.composite(listras, Image.new("RGBA", (w, h)), face))
    # brilho em cima (faixa clara com a ponta suave)
    brilho = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    ImageDraw.Draw(brilho).rounded_rectangle((r * 0.5, topo + 4 * escala, w - r * 0.5, topo + 16 * escala),
                                             8 * escala, fill=(255, 255, 255, 70))
    brilho = brilho.filter(ImageFilter.GaussianBlur(2 * escala))
    img = Image.alpha_composite(img, brilho)
    return img.resize((L, A), Image.LANCZOS)


def main():
    PASTA.mkdir(parents=True, exist_ok=True)
    for nome, (base, hover, borda) in CORES.items():
        botao(base, borda).save(PASTA / f"{nome}.png")
        botao(hover, borda).save(PASTA / f"{nome}_hover.png")
        botao(base, borda, apertado=True).save(PASTA / f"{nome}_apertado.png")
        botao(base, borda, cinza=True).save(PASTA / f"{nome}_desativado.png")
    print("botões salvos em", PASTA)


if __name__ == "__main__":
    main()
