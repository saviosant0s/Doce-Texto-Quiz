# Doce Texto Quiz

Quiz em Pygame sobre Word e Excel, com 3 níveis de 10 perguntas cada.

## Como rodar

```bash
pip install -r requirements.txt
python ppa_final/main.py
```

No Windows, se o comando `python` não for encontrado, use `py`
(ex.: `py -m pip install -r requirements.txt` e `py ppa_final/main.py`).

Usamos o [pygame-ce](https://pyga.me/), versão da comunidade do pygame,
compatível com o mesmo código (`import pygame`) e com instaladores
prontos para as versões novas do Python.

`ESC` fecha o jogo. O progresso fica salvo em `ppa_final/salvamento.json`.

## Estrutura

```
ppa_final/
├── main.py         # ponto de entrada e máquina de estados das telas
├── telas.py        # cada tela do jogo
├── interface.py    # janela, imagens/sons, laço de eventos e texto
├── perguntas.py    # banco de perguntas por nível
├── salvamento.py   # progresso do jogador (JSON)
├── config.py       # constantes: tamanhos, cores, tempos e posições dos botões
└── assets/
    ├── imagens/          # fundos de cada tela
    ├── sons/             # música de fundo e efeitos
    └── nao_utilizados/   # arquivos do projeto original que não são usados no código
```

Para adicionar perguntas, edite `perguntas.py`. Para ajustar a área
clicável de um botão, edite o `Rect` correspondente em `config.py`.
