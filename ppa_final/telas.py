"""Telas do jogo.

As telas principais retornam o nome da próxima tela (ver `main.py`).
Telas "de passagem" (dica, créditos, títulos, sobre) apenas retornam
quando fechadas, voltando para a tela que as abriu.
"""
import pygame

import config as c
from perguntas import NIVEIS


# --- Telas principais ---------------------------------------------------

def tela_inicial(jogo):
    while True:
        escolha = jogo.ui.tela_com_botoes("inicio", c.BOTOES_INICIO)
        if escolha == "jogar":
            return "niveis"
        if escolha == "creditos":
            tela_creditos(jogo)
        elif escolha == "dica":
            tela_dica(jogo)


def tela_niveis(jogo):
    ui = jogo.ui

    def desenhar_progresso():
        progresso = zip(jogo.salvamento.acertos_por_nivel, NIVEIS, c.POSICOES_PROGRESSO_NIVEIS)
        for acertos, perguntas, posicao in progresso:
            texto = ui.fonte.render(f"{acertos}/{len(perguntas)} ", True, c.AMARELO)
            ui.tela.blit(texto, posicao)

    while True:
        escolha = ui.tela_com_botoes("niveis", c.BOTOES_NIVEIS, desenhar_progresso)
        if escolha.startswith("nivel_"):
            jogo.nivel = int(escolha.removeprefix("nivel_")) - 1
            return "carregamento"
        if escolha == "inicio":
            return "inicio"
        if escolha == "titulos":
            tela_titulos(jogo)
        elif escolha == "dica":
            tela_dica(jogo)
        elif escolha == "creditos":
            tela_creditos(jogo)


def tela_carregamento(jogo):
    ui = jogo.ui
    fundo = ui.imagem("carregamento")
    barra = c.BARRA_CARREGAMENTO
    inicio = pygame.time.get_ticks()
    progresso = 0.0

    while progresso < 1.0:
        ui.eventos()
        progresso = min(1.0, (pygame.time.get_ticks() - inicio) / c.TEMPO_CARREGAMENTO_MS)
        ui.tela.blit(fundo, (0, 0))
        pygame.draw.rect(
            ui.tela, c.ROXO, (barra.x, barra.y, int(barra.width * progresso), barra.height),
            border_radius=10,
        )
        ui.atualizar()

    ui.esperar(c.PAUSA_APOS_CARREGAMENTO_MS)
    return "partida"


def tela_partida(jogo):
    """Joga as perguntas do nível escolhido e guarda o resultado de cada uma."""
    ui = jogo.ui
    perguntas = NIVEIS[jogo.nivel]
    areas_alternativas = [
        pygame.Rect(c.ALTERNATIVA_X, c.ALTERNATIVA_Y + i * c.ALTERNATIVA_ESPACO, *c.ALTERNATIVA_TAMANHO)
        for i in range(4)
    ]
    jogo.resultados = []

    for pergunta in perguntas:
        inicio = pygame.time.get_ticks()
        acertou = None  # None = ainda não respondeu

        while acertou is None:
            for pos in ui.cliques():
                if c.BOTAO_MUSICA.collidepoint(pos):
                    ui.alternar_musica()
                    continue
                for indice, area in enumerate(areas_alternativas):
                    if area.collidepoint(pos):
                        acertou = indice == pergunta.resposta
                        ui.tocar_som("acerto" if acertou else "erro")
                        break
                if acertou is not None:
                    break

            tempo_passado = pygame.time.get_ticks() - inicio
            if acertou is None and tempo_passado >= c.TEMPO_LIMITE_MS:
                acertou = False  # acabou o tempo

            desenhar_pergunta(ui, pergunta, areas_alternativas, tempo_passado)
            ui.atualizar()

        jogo.resultados.append(acertou)

    acertos = sum(jogo.resultados)
    jogo.salvamento.acertos_por_nivel[jogo.nivel] = acertos
    jogo.salvamento.salvar()
    return "aproveitamento"


def desenhar_pergunta(ui, pergunta, areas_alternativas, tempo_passado):
    ui.tela.blit(ui.imagem("jogo"), (0, 0))
    for tampa in c.TAMPAS_BOTOES_AJUDA:
        pygame.draw.rect(ui.tela, c.ROXO, tampa)

    for texto, area in zip(pergunta.alternativas, areas_alternativas):
        ui.texto_centralizado(texto, ui.fonte, c.ROXO, area.center)

    linhas = ui.quebrar_linhas(pergunta.enunciado, ui.fonte, c.PERGUNTA_LARGURA_MAX)
    for i, linha in enumerate(linhas):
        centro = (c.PERGUNTA_CENTRO_X, c.PERGUNTA_Y + i * c.PERGUNTA_ESPACO_LINHA)
        ui.texto_centralizado(linha, ui.fonte, c.ROXO, centro)

    segundos_restantes = max(0, (c.TEMPO_LIMITE_MS - tempo_passado) // 1000)
    cronometro = ui.fonte_pequena.render(f"{segundos_restantes} ", True, c.ROXO)
    ui.tela.blit(cronometro, c.POSICAO_CRONOMETRO)


def tela_aproveitamento(jogo):
    ui = jogo.ui
    aproveitamento = round(100 * sum(jogo.resultados) / len(jogo.resultados))

    def desenhar_resultados():
        texto = ui.fonte.render(f"Aproveitamento {aproveitamento}%", True, c.AMARELO)
        ui.tela.blit(texto, c.POSICAO_APROVEITAMENTO)
        for i, acertou in enumerate(jogo.resultados):
            centro = (c.RESULTADOS_CENTRO_X, c.RESULTADOS_Y + i * c.RESULTADOS_ESPACO)
            ui.texto_centralizado("Acertou" if acertou else "Errou", ui.fonte_resultados, c.ROXO, centro)

    ui.tela_com_botoes("aproveitamento", c.BOTOES_APROVEITAMENTO, desenhar_resultados)

    for limite, resultado, moedas in c.FAIXAS_RESULTADO:
        if aproveitamento <= limite:
            break
    jogo.resultado = resultado
    if resultado in jogo.salvamento.titulos:
        jogo.salvamento.titulos[resultado] += 1
    jogo.salvamento.moedas += moedas
    jogo.salvamento.salvar()
    return "resultado"


def tela_resultado(jogo):
    """Mostra o título conquistado (ou a tela de "tente novamente")."""
    jogo.ui.tela_com_botoes(jogo.resultado, c.BOTOES_RESULTADO[jogo.resultado])
    return "inicio"


# --- Telas de passagem --------------------------------------------------

def tela_dica(jogo):
    jogo.ui.tela_com_botoes("dica", c.BOTOES_DICA)


def tela_titulos(jogo):
    ui = jogo.ui

    def desenhar_titulos():
        for titulo, posicao in c.POSICOES_TITULOS.items():
            quantidade = jogo.salvamento.titulos[titulo]
            texto = ui.fonte.render(f"{quantidade}X {titulo.upper()}", True, c.ROXO)
            ui.tela.blit(texto, posicao)

    ui.tela_com_botoes("titulos", c.BOTOES_TITULOS, desenhar_titulos)


def tela_creditos(jogo):
    ui = jogo.ui
    while True:
        escolha = ui.tela_com_botoes("creditos", c.BOTOES_CREDITOS)
        if escolha == "voltar":
            return
        if escolha == "sobre":
            tela_sobre(jogo)
        elif escolha == "doe":
            ui.aviso_em_breve(c.POSICAO_AVISO_CREDITOS)


def tela_sobre(jogo):
    jogo.ui.tela_com_botoes("sobre", c.BOTOES_SOBRE)
