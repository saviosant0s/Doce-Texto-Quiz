"""Progresso do jogador, salvo em JSON.

No computador fica em um arquivo; no navegador, no `localStorage`
(o sistema de arquivos do navegador é apagado ao recarregar a página).
"""
import json
from dataclasses import asdict, dataclass, field

from config import ARQUIVO_SALVAMENTO, NO_NAVEGADOR

CHAVE_NAVEGADOR = "doce_texto_quiz_salvamento"

if NO_NAVEGADOR:
    from platform import window


def _ler():
    if NO_NAVEGADOR:
        return window.localStorage.getItem(CHAVE_NAVEGADOR)
    try:
        return ARQUIVO_SALVAMENTO.read_text(encoding="utf-8")
    except FileNotFoundError:
        return None


def _escrever(texto):
    if NO_NAVEGADOR:
        window.localStorage.setItem(CHAVE_NAVEGADOR, texto)
    else:
        ARQUIVO_SALVAMENTO.write_text(texto, encoding="utf-8")


@dataclass
class Salvamento:
    # Acertos da última partida de cada nível
    acertos_por_nivel: list[int] = field(default_factory=lambda: [0, 0, 0])
    # Quantas vezes cada título foi conquistado
    titulos: dict[str, int] = field(default_factory=lambda: {"noob": 0, "pro": 0, "mestre": 0})
    moedas: int = 0

    @classmethod
    def carregar(cls):
        try:
            return cls(**json.loads(_ler()))
        except (json.JSONDecodeError, TypeError):  # sem salvamento ou arquivo inválido
            return cls()

    def salvar(self):
        _escrever(json.dumps(asdict(self), indent=2))
