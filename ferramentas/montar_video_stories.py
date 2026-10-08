#!/usr/bin/env python3
"""Monta o vídeo vertical de divulgação (1080x1920) a partir das cenas
gravadas por ferramentas/gerar_video_stories.sh (pasta <saida>/cenas/*.avi).

- fundo roxo com granulado colorido descendo devagar;
- as cenas do jogo (1080x1560) no meio, com cantos arredondados e borda
  amarela, trocando com transições;
- uma legenda grande por cena (fonte do jogo, Bebas Neue) e a tela final com
  o logo, "JOGO GRÁTIS", as plataformas e o link;
- a música do jogo por baixo dos sons de cada cena.

Uso: python3 ferramentas/montar_video_stories.py build/stories
"""
import os
import random
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FONTE = os.path.join(RAIZ, "godot/assets/fontes/BebasNeue-Regular.ttf")
FONTE_LINK = os.path.join(RAIZ, "godot/assets/fontes/Nunito.ttf")  # tem minúsculas e o 0 diferente do O
LOGO = os.path.join(RAIZ, "godot/assets/abertura.png")
MUSICA = os.path.join(RAIZ, "godot/assets/sons/musica_2.ogg")
L, A = 1080, 1920
# a cena do jogo (gravada em 1080x1560) vira um cartão um pouco menor, com a
# legenda embaixo dele (sem cobrir o jogo) e o nome do jogo em cima
CENA_L, CENA_A = 900, 1300
CENA_X, CENA_Y = (L - CENA_L) // 2, 170
LEGENDA_Y = CENA_Y + CENA_A + 18
TRANSICAO = 0.35
AMARELO = (255, 210, 63, 255)
ROXO_ESCURO = (46, 29, 74, 255)
ROXO = (126, 87, 177, 255)

# cena, legenda grande, linha de baixo, transição para a próxima
CENAS = [
    ("1_vila", "APRENDA OFFICE JOGANDO!", "WORD · EXCEL · POWERPOINT", "circleopen"),
    ("2_corrida", "CORRIDA DE DOCES", "ACERTOU A PERGUNTA? TURBO!", "slideleft"),
    ("3_chefao", "ENFRENTE O CHEFÃO", "CADA ACERTO É UM GOLPE", "slideup"),
    ("4_batalha", "BATALHAS NA ARENA", "MONTE O SEU TIME DE DOCES", "wiperight"),
    ("5_casa", "DECORE A SUA CASA", "E COLECIONE MAIS DE 30 DOCES 3D", "fade"),
    ("6_final", None, None, None),
]


def fonte(tamanho):
    return ImageFont.truetype(FONTE, tamanho)


def texto_com_contorno(desenho, xy, texto, tamanho, cor, contorno=10, ancora="mm"):
    desenho.text(xy, texto, font=fonte(tamanho), fill=cor, anchor=ancora,
                 stroke_width=contorno, stroke_fill=ROXO_ESCURO, align="center", spacing=4)


def pilula(img, centro_y, texto, tamanho, fundo=ROXO, cor=(255, 255, 255, 255)):
    d = ImageDraw.Draw(img)
    f = fonte(tamanho)
    x0, y0, x1, y1 = d.textbbox((0, 0), texto, font=f)
    largura, altura = x1 - x0 + 70, y1 - y0 + 34
    caixa = (L // 2 - largura // 2, centro_y - altura // 2, L // 2 + largura // 2, centro_y + altura // 2)
    sombra = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sombra).rounded_rectangle([caixa[0], caixa[1] + 8, caixa[2], caixa[3] + 8], 999, fill=(30, 15, 50, 140))
    img.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(6)))
    d.rounded_rectangle(caixa, 999, fill=fundo, outline=(255, 255, 255, 230), width=4)
    d.text((L // 2, centro_y + 2), texto, font=f, fill=cor, anchor="mm")


def legenda(grande, pequena, caminho):
    """Legenda: texto grande amarelo com contorno e a linha de baixo numa pílula."""
    tamanho = 118
    altura = tamanho + 130
    img = Image.new("RGBA", (L, altura), (0, 0, 0, 0))
    sombra = Image.new("RGBA", img.size, (0, 0, 0, 0))
    texto_com_contorno(ImageDraw.Draw(sombra), (L // 2, 8 + tamanho // 2 + 4), grande, tamanho, (30, 15, 50, 160), 12)
    img.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(8)))
    texto_com_contorno(ImageDraw.Draw(img), (L // 2, tamanho // 2 + 4), grande, tamanho, AMARELO, 10)
    pilula(img, tamanho + 60, pequena, 46)
    img.save(caminho)
    return altura


def fundo(caminho):
    """Fundo roxo (o dobro da altura, para descer em loop) com granulado."""
    img = Image.new("RGBA", (L, A * 2))
    d = ImageDraw.Draw(img)
    for y in range(A * 2):
        t = abs((y % A) / A - 0.5) * 2  # claro no meio, escuro nas pontas (emenda sem corte)
        cor = tuple(int(a + (b - a) * t) for a, b in zip((154, 115, 208), (94, 61, 142)))
        d.line([(0, y), (L, y)], fill=cor + (255,))
    cores = [(255, 111, 174), (255, 210, 63), (111, 211, 255), (123, 224, 123), (255, 255, 255), (255, 138, 92)]
    sorteio = random.Random(7)
    for _ in range(520):
        x, y = sorteio.randrange(L), sorteio.randrange(A)
        comprimento, grossura = sorteio.randint(14, 30), sorteio.randint(6, 9)
        granulo = Image.new("RGBA", (comprimento + 4, comprimento + 4), (0, 0, 0, 0))
        ImageDraw.Draw(granulo).rounded_rectangle([2, (comprimento - grossura) // 2 + 2, comprimento + 2,
            (comprimento + grossura) // 2 + 2], 99, fill=sorteio.choice(cores) + (110,))
        granulo = granulo.rotate(sorteio.randrange(180), expand=True)
        for dy in (0, A):  # o mesmo desenho nas duas metades: o loop não emenda
            img.alpha_composite(granulo, (x, y + dy))
    img.convert("RGB").save(caminho)


def moldura(caminho_mascara, caminho_sombra, caminho_borda):
    """Cantos arredondados da cena e a borda amarela por cima."""
    raio = 44
    mascara = Image.new("L", (CENA_L, CENA_A), 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, CENA_L - 1, CENA_A - 1], raio, fill=255)
    mascara.save(caminho_mascara)
    sombra = Image.new("RGBA", (L, A), (0, 0, 0, 0))
    ImageDraw.Draw(sombra).rounded_rectangle([CENA_X, CENA_Y + 14, CENA_X + CENA_L, CENA_Y + CENA_A + 14], raio, fill=(30, 15, 50, 150))
    sombra.filter(ImageFilter.GaussianBlur(14)).save(caminho_sombra)  # vai embaixo da cena
    borda = Image.new("RGBA", (L, A), (0, 0, 0, 0))
    d = ImageDraw.Draw(borda)
    d.rounded_rectangle([CENA_X - 4, CENA_Y - 4, CENA_X + CENA_L + 3, CENA_Y + CENA_A + 3], raio + 4, outline=AMARELO, width=8)
    # topo: "DOCE TEXTO QUIZ" (embaixo do nome do Instagram) e o rodapé
    texto_com_contorno(d, (L // 2, 112), "DOCE TEXTO QUIZ", 70, AMARELO, 7)
    texto_com_contorno(d, (L // 2, 1830), "GRÁTIS PARA CELULAR E COMPUTADOR", 52, (255, 255, 255, 235), 6)
    borda.save(caminho_borda)


def tela_final(caminho):
    img = Image.new("RGBA", (L, A), (0, 0, 0, 0))
    escurece = Image.new("RGBA", (L, A), (0, 0, 0, 0))
    ImageDraw.Draw(escurece).rectangle([0, 1180, L, A], fill=(46, 29, 74, 120))
    img.alpha_composite(escurece.filter(ImageFilter.GaussianBlur(40)))
    logo = Image.open(LOGO).convert("RGBA")
    largura = 640
    logo = logo.resize((largura, int(logo.height * largura / logo.width)), Image.LANCZOS)
    sombra = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sombra.paste((30, 15, 50, 150), (L // 2 - largura // 2, 268), logo)
    img.alpha_composite(sombra.filter(ImageFilter.GaussianBlur(10)))
    img.alpha_composite(logo, (L // 2 - largura // 2, 250))
    d = ImageDraw.Draw(img)
    texto_com_contorno(d, (L // 2, 1300), "JOGO GRÁTIS!", 170, AMARELO, 14)
    pilula(img, 1440, "ANDROID · WINDOWS · NAVEGADOR", 56)
    link = ImageFont.truetype(FONTE_LINK, 40)
    try:
        link.set_variation_by_name("ExtraBold")
    except (OSError, ValueError):
        pass
    d.text((L // 2, 1545), "saviosant0s.github.io/Doce-Texto-Quiz", font=link, fill=(255, 255, 255, 255), anchor="mm",
           stroke_width=6, stroke_fill=ROXO_ESCURO)
    texto_com_contorno(d, (L // 2, 1615), "FEITO NO IFBA CAMPUS VALENÇA", 42, (255, 255, 255, 220), 5)
    img.save(caminho)


def duracao(caminho):
    saida = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", caminho],
                           capture_output=True, text=True, check=True).stdout
    return float(saida.strip())


def main():
    saida = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(RAIZ, "build/stories"))
    pecas = os.path.join(saida, "pecas")
    os.makedirs(pecas, exist_ok=True)
    fundo(os.path.join(pecas, "fundo.png"))
    moldura(os.path.join(pecas, "mascara.png"), os.path.join(pecas, "sombra.png"), os.path.join(pecas, "borda.png"))
    tela_final(os.path.join(pecas, "final.png"))

    entradas = []
    filtros = []
    duracoes = []
    for i, (nome, *_resto) in enumerate(CENAS):  # noqa: B007
        caminho = os.path.join(saida, "cenas", nome + ".avi")
        duracoes.append(duracao(caminho))
        entradas += ["-i", caminho]
    n = len(CENAS)
    # inícios de cada cena no vídeo (as transições sobrepõem um pedaço)
    inicios = [0.0]
    for d in duracoes[:-1]:
        inicios.append(inicios[-1] + d - TRANSICAO)
    total = inicios[-1] + duracoes[-1]
    # cenas: mesmo formato e ritmo, depois as transições
    for i in range(n):
        filtros.append(f"[{i}:v]scale={CENA_L}:{CENA_A},fps=30,format=yuv420p,setsar=1[v{i}]")
        filtros.append(f"[{i}:a]aformat=sample_rates=48000:channel_layouts=stereo[a{i}]")
    anterior_v, anterior_a = "v0", "a0"
    for i in range(1, n):
        transicao = CENAS[i - 1][3] or "fade"
        filtros.append(f"[{anterior_v}][v{i}]xfade=transition={transicao}:duration={TRANSICAO}:offset={inicios[i]:.3f}[x{i}]")
        filtros.append(f"[{anterior_a}][a{i}]acrossfade=d={TRANSICAO}[y{i}]")
        anterior_v, anterior_a = f"x{i}", f"y{i}"
    # cena com cantos arredondados em cima do fundo que desce devagar
    k = n
    entradas += ["-loop", "1", "-framerate", "30", "-i", os.path.join(pecas, "fundo.png")]
    entradas += ["-loop", "1", "-framerate", "30", "-i", os.path.join(pecas, "mascara.png")]
    entradas += ["-loop", "1", "-framerate", "30", "-i", os.path.join(pecas, "borda.png")]
    entradas += ["-loop", "1", "-framerate", "30", "-i", os.path.join(pecas, "sombra.png")]
    filtros.append(f"[{k}:v]crop={L}:{A}:0:'mod(t*40,{A})',trim=duration={total:.3f}[fundo]")
    filtros.append(f"[{k + 1}:v]format=gray,trim=duration={total:.3f}[mascara]")
    filtros.append(f"[{anterior_v}]format=rgba[cena_rgba]")
    filtros.append("[cena_rgba][mascara]alphamerge[cena]")
    # a moldura (sombra e borda) vai embaixo e em cima da cena
    filtros.append(f"[fundo][{k + 3}:v]overlay=0:0[c00]")
    filtros.append(f"[c00][cena]overlay={CENA_X}:{CENA_Y}:format=auto[c0]")
    filtros.append(f"[c0][{k + 2}:v]overlay=0:0[c1]")
    atual = "c1"
    proxima = k + 4
    # legendas: entram deslizando e somem antes da troca de cena
    for i, (nome, grande, pequena, _t) in enumerate(CENAS):
        if not grande:
            continue
        arquivo = os.path.join(pecas, f"legenda_{i}.png")
        legenda(grande, pequena, arquivo)
        comeco = inicios[i] + 0.3
        fim = inicios[i] + duracoes[i] - TRANSICAO - 0.15
        d = fim - comeco
        entradas += ["-loop", "1", "-framerate", "30", "-t", f"{d:.3f}", "-i", arquivo]
        filtros.append(f"[{proxima}:v]format=rgba,fade=t=in:st=0:d=0.3:alpha=1,fade=t=out:st={d - 0.3:.3f}:d=0.3:alpha=1,"
                       f"setpts=PTS-STARTPTS+{comeco:.3f}/TB[l{i}]")
        filtros.append(f"[{atual}][l{i}]overlay=x='if(lt(t-{comeco:.3f},0.3),-120+400*(t-{comeco:.3f}),0)':y={LEGENDA_Y}"
                       f":eof_action=pass:enable='between(t,{comeco:.3f},{fim:.3f})'[c{proxima}]")
        atual = f"c{proxima}"
        proxima += 1
    # tela final por cima da última cena
    comeco_final = inicios[-1] + 0.4
    entradas += ["-loop", "1", "-framerate", "30", "-t", f"{total - comeco_final:.3f}", "-i", os.path.join(pecas, "final.png")]
    filtros.append(f"[{proxima}:v]format=rgba,fade=t=in:st=0:d=0.5:alpha=1,setpts=PTS-STARTPTS+{comeco_final:.3f}/TB[fim]")
    filtros.append(f"[{atual}][fim]overlay=0:0:eof_action=pass:enable='gte(t,{comeco_final:.3f})',format=yuv420p[video]")
    proxima += 1
    # música do jogo por baixo dos sons das cenas
    entradas += ["-i", MUSICA]
    filtros.append(f"[{proxima}:a]atrim=duration={total:.3f},afade=t=in:d=0.4,afade=t=out:st={total - 2:.3f}:d=2,volume=0.55,"
                   f"aformat=sample_rates=48000:channel_layouts=stereo[musica]")
    filtros.append(f"[{anterior_a}]volume=0.9[sons]")
    filtros.append("[musica][sons]amix=inputs=2:duration=first:normalize=0[audio]")
    destino = os.path.join(saida, "doce_texto_stories.mp4")
    comando = ["ffmpeg", "-y", "-loglevel", "error"] + entradas + [
        "-filter_complex", ";".join(filtros), "-map", "[video]", "-map", "[audio]", "-t", f"{total:.3f}",
        "-c:v", "libx264", "-preset", "slow", "-crf", "20", "-profile:v", "high", "-pix_fmt", "yuv420p", "-r", "30",
        "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", destino]
    subprocess.run(comando, check=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", "1.5", "-i", destino, "-frames:v", "1", "-q:v", "2",
                    os.path.join(saida, "capa.jpg")], check=True)
    print(f"vídeo: {destino} ({total:.1f} s)")


if __name__ == "__main__":
    main()
