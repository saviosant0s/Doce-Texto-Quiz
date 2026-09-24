"""Janela, recursos (imagens, sons, fontes) e utilidades de desenho/eventos."""
import sys
from functools import cache

import pygame

from config import (
    DURACAO_AVISO_MS, FPS, PASTA_IMAGENS, PASTA_SONS, TAMANHO_TELA, TITULO_JANELA, AMARELO,
)


class Interface:
    def __init__(self):
        pygame.init()
        pygame.mixer.init()
        pygame.display.set_caption(TITULO_JANELA)
        self.tela = pygame.display.set_mode(TAMANHO_TELA)
        self.relogio = pygame.time.Clock()
        self.fonte = pygame.font.Font(None, 46)
        self.fonte_pequena = pygame.font.Font(None, 32)
        self.fonte_resultados = pygame.font.Font(None, 42)

    # --- Recursos -------------------------------------------------------

    @cache
    def imagem(self, nome):
        imagem = pygame.image.load(PASTA_IMAGENS / f"{nome}.png").convert_alpha()
        return pygame.transform.scale(imagem, TAMANHO_TELA)

    @cache
    def som(self, nome):
        return pygame.mixer.Sound(PASTA_SONS / f"{nome}.mp3")

    def tocar_som(self, nome):
        self.som(nome).play()

    def tocar_musica_fundo(self, nome):
        pygame.mixer.music.load(PASTA_SONS / f"{nome}.mp3")
        pygame.mixer.music.play(-1)  # -1 = repetir para sempre

    def alternar_musica(self):
        if pygame.mixer.music.get_busy():
            pygame.mixer.music.pause()
        else:
            pygame.mixer.music.unpause()

    # --- Laço de cada quadro -------------------------------------------

    def eventos(self):
        """Retorna os eventos do quadro; fecha o jogo ao fechar a janela ou apertar ESC."""
        eventos = []
        for evento in pygame.event.get():
            fechar = evento.type == pygame.QUIT or (
                evento.type == pygame.KEYDOWN and evento.key == pygame.K_ESCAPE
            )
            if fechar:
                pygame.quit()
                sys.exit()
            eventos.append(evento)
        return eventos

    def cliques(self):
        """Posições clicadas com o mouse neste quadro."""
        return [e.pos for e in self.eventos() if e.type == pygame.MOUSEBUTTONDOWN]

    def atualizar(self):
        pygame.display.update()
        self.relogio.tick(FPS)

    def esperar(self, duracao_ms):
        """Espera sem travar a janela (continua processando eventos)."""
        fim = pygame.time.get_ticks() + duracao_ms
        while pygame.time.get_ticks() < fim:
            self.eventos()
            self.relogio.tick(FPS)

    def tela_com_botoes(self, fundo, botoes, desenhar_extra=None):
        """Mostra a imagem `fundo` até um dos `botoes` ser clicado.

        `botoes` é um dict {nome: Rect}; retorna o nome do botão clicado.
        `desenhar_extra`, se informado, é chamado a cada quadro após o fundo.
        """
        imagem = self.imagem(fundo)
        while True:
            for pos in self.cliques():
                for nome, area in botoes.items():
                    if area.collidepoint(pos):
                        return nome
            self.tela.blit(imagem, (0, 0))
            if desenhar_extra:
                desenhar_extra()
            self.atualizar()

    def aviso_em_breve(self, posicao):
        texto = self.fonte.render("Disponível em breve", True, AMARELO)
        self.tela.blit(texto, posicao)
        pygame.display.update()
        self.esperar(DURACAO_AVISO_MS)

    # --- Texto ----------------------------------------------------------

    @staticmethod
    def quebrar_linhas(texto, fonte, largura_max):
        """Divide `texto` em linhas que caibam em `largura_max` pixels."""
        linhas = []
        linha_atual = ""
        for palavra in texto.split(" "):
            tentativa = linha_atual + palavra + " "
            if fonte.size(tentativa)[0] <= largura_max or not linha_atual:
                linha_atual = tentativa
            else:
                linhas.append(linha_atual)
                linha_atual = palavra + " "
        linhas.append(linha_atual)
        return linhas

    def texto_centralizado(self, texto, fonte, cor, centro):
        superficie = fonte.render(texto, True, cor)
        self.tela.blit(superficie, superficie.get_rect(center=centro))
