#!/usr/bin/env python3
"""Prepara as texturas reais (fotos CC0) para o jogo: clareia a foto e, na
maioria, deixa em tons de cinza, para a cor do jogo pintar por cima (o detalhe
real continua: grãos, rachaduras). A grama e a madeira mantêm a cor da foto.
Uso: ferramentas/preparar_texturas_reais.py <pasta com os *_cor.jpg originais>
Salva em godot/assets/texturas/reais/<nome>_cor.jpg."""
import sys, os
from PIL import Image, ImageStat, ImageEnhance

DESTINO = os.path.join(os.path.dirname(__file__), "..", "godot", "assets", "texturas", "reais")
# nome: (modo, brilho médio desejado 0..1, contraste desejado = desvio padrão 0..1)
AJUSTES = {
    "grama": ("cor", 0.50, 0.14),
    "areia": ("cinza", 0.86, 0.08),
    "calcamento": ("cinza", 0.80, 0.12),
    "reboco_barro": ("cinza", 0.80, 0.12),
    "reboco": ("cinza", 0.88, 0.10),
    "tijolos": ("cinza", 0.80, 0.12),
    "ardosia": ("cinza", 0.78, 0.13),
    "madeira": ("cor", 0.62, 0.10),
    "piso_cozinha": ("cinza", 0.90, 0.06),
    "metal": ("cinza", 0.85, 0.10),
    "madeira_pintada": ("cinza", 0.84, 0.14),
}

origem = sys.argv[1]
for nome, (modo, alvo, desvio) in AJUSTES.items():
    foto = Image.open(os.path.join(origem, nome + "_cor.jpg")).convert("RGB")
    cinza = foto.convert("L")
    est = ImageStat.Stat(cinza)
    media, dp = est.mean[0] / 255.0, max(est.stddev[0] / 255.0, 0.01)
    k = desvio / dp
    def ajuste(v):  # v em 0..255: centraliza, muda o contraste e o brilho
        return max(0, min(255, int(round(((v / 255.0 - media) * k + alvo) * 255))))
    if modo == "cinza":
        saida = cinza.point(ajuste).convert("RGB")
    else:
        # mantém a cor: aplica o mesmo ajuste em cada canal (sobe o brilho, preserva o tom)
        saida = Image.merge("RGB", [c.point(ajuste) for c in foto.split()])
        saida = ImageEnhance.Color(saida).enhance(1.15)
    saida.save(os.path.join(DESTINO, nome + "_cor.jpg"), quality=90)
    print(nome, modo, "ok")
