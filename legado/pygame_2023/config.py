"""Constantes do jogo: tamanhos, cores, caminhos e posições dos botões."""
import sys
from pathlib import Path

import pygame

# True quando o jogo roda no navegador (celular), compilado com pygbag
NO_NAVEGADOR = sys.platform == "emscripten"

# Caminhos (relativos a este arquivo, então o jogo roda de qualquer pasta)
PASTA_BASE = Path(__file__).resolve().parent
PASTA_IMAGENS = PASTA_BASE / "assets" / "imagens"
PASTA_SONS = PASTA_BASE / "assets" / "sons"
ARQUIVO_SALVAMENTO = PASTA_BASE / "salvamento.json"

# Janela
LARGURA_TELA = 1438
ALTURA_TELA = 720
TAMANHO_TELA = (LARGURA_TELA, ALTURA_TELA)
TITULO_JANELA = "Doce Texto Quiz"
FPS = 60

# Cores
AMARELO = "#F4E038"
ROXO = "#7E57B1"

# Regras
TEMPO_LIMITE_MS = 30_000  # tempo para responder cada pergunta
TEMPO_CARREGAMENTO_MS = 3_000
PAUSA_APOS_CARREGAMENTO_MS = 3_000
DURACAO_AVISO_MS = 500

# Recompensas por faixa de aproveitamento: (aproveitamento máximo %, resultado, moedas)
FAIXAS_RESULTADO = [
    (30, "nodoc", 0),
    (50, "noob", 40),
    (80, "pro", 60),
    (100, "mestre", 100),
]

# Botões (áreas clicáveis desenhadas nas imagens de fundo)
Rect = pygame.Rect

BOTOES_INICIO = {
    "jogar": Rect(315, 510, 263, 85),
    "creditos": Rect(590, 510, 110, 85),
    "dica": Rect(210, 510, 100, 85),
}

BOTOES_NIVEIS = {
    "inicio": Rect(135, 170, 80, 65),
    "titulos": Rect(135, 275, 80, 65),
    "dica": Rect(135, 380, 80, 65),
    "creditos": Rect(135, 485, 80, 65),
    "nivel_1": Rect(305, 345, 270, 155),
    "nivel_2": Rect(685, 345, 270, 155),
    "nivel_3": Rect(1065, 345, 270, 155),
}
POSICOES_PROGRESSO_NIVEIS = [(420, 510), (790, 510), (1170, 510)]

BOTOES_TITULOS = {"voltar": Rect(505, 110, 95, 95)}
POSICOES_TITULOS = {"noob": (180, 530), "pro": (665, 530), "mestre": (1120, 530)}

BOTOES_CREDITOS = {
    "voltar": Rect(185, 510, 95, 95),
    "sobre": Rect(690, 510, 345, 95),
    "doe": Rect(1075, 510, 175, 95),
}
POSICAO_AVISO_CREDITOS = (550, 630)

BOTOES_SOBRE = {"voltar": Rect(130, 110, 65, 65)}
BOTOES_DICA = {"proximo": Rect(680, 570, 85, 85)}
BOTOES_APROVEITAMENTO = {"proximo": Rect(1060, 320, 85, 85)}

BOTOES_RESULTADO = {
    "nodoc": {"inicio": Rect(420, 530, 600, 75)},
    "noob": {"inicio": Rect(885, 120, 65, 65)},
    "pro": {"inicio": Rect(885, 120, 65, 65)},
    "mestre": {"inicio": Rect(1095, 240, 75, 75)},
}

# Tela do jogo
BOTAO_MUSICA = Rect(840, 340, 70, 65)
# Botões de ajuda ainda não implementados: são cobertos com a cor de fundo
TAMPAS_BOTOES_AJUDA = [Rect(840, 270, 70, 65), Rect(840, 400, 70, 65)]
ALTERNATIVA_X, ALTERNATIVA_Y, ALTERNATIVA_ESPACO = 910, 163, 105
ALTERNATIVA_TAMANHO = (420, 80)
PERGUNTA_CENTRO_X, PERGUNTA_Y, PERGUNTA_ESPACO_LINHA = 480, 300, 50
PERGUNTA_LARGURA_MAX = 500
POSICAO_CRONOMETRO = (470, 210)

# Tela de carregamento
BARRA_CARREGAMENTO = Rect(360, 575, 720, 40)

# Tela de aproveitamento
POSICAO_APROVEITAMENTO = (550, 30)
RESULTADOS_CENTRO_X, RESULTADOS_Y, RESULTADOS_ESPACO = 830, 93, 64
