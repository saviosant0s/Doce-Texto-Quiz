"""Progresso do jogador salvo em disco (JSON)."""
import json
from dataclasses import asdict, dataclass, field

from config import ARQUIVO_SALVAMENTO


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
            dados = json.loads(ARQUIVO_SALVAMENTO.read_text(encoding="utf-8"))
            return cls(**dados)
        except (FileNotFoundError, json.JSONDecodeError, TypeError):
            return cls()

    def salvar(self):
        ARQUIVO_SALVAMENTO.write_text(json.dumps(asdict(self), indent=2), encoding="utf-8")
