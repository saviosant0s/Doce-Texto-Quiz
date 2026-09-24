"""Doce Texto Quiz — ponto de entrada.

O jogo é uma máquina de estados: cada tela principal roda até o jogador
sair dela e retorna o nome da próxima tela.
"""
from dataclasses import dataclass, field

import telas
from interface import Interface
from salvamento import Salvamento

TELAS = {
    "inicio": telas.tela_inicial,
    "niveis": telas.tela_niveis,
    "carregamento": telas.tela_carregamento,
    "partida": telas.tela_partida,
    "aproveitamento": telas.tela_aproveitamento,
    "resultado": telas.tela_resultado,
}


@dataclass
class Jogo:
    """Estado compartilhado entre as telas."""
    ui: Interface
    salvamento: Salvamento
    nivel: int = 0  # índice do nível escolhido
    resultados: list[bool] = field(default_factory=list)  # acertou/errou de cada pergunta
    resultado: str = ""  # faixa final: "nodoc", "noob", "pro" ou "mestre"


def main():
    jogo = Jogo(ui=Interface(), salvamento=Salvamento.carregar())
    jogo.ui.tocar_musica_fundo("musica_fundo")

    tela_atual = "inicio"
    while True:
        tela_atual = TELAS[tela_atual](jogo)


if __name__ == "__main__":
    main()
