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

## Versão para celular (navegador)

O jogo também roda no navegador de qualquer celular, na horizontal,
compilado com [pygbag](https://pygame-web.github.io/). Em pé, o jogo
pede para girar o aparelho. O progresso fica salvo no próprio navegador.

**Publicar:** a cada push na branch `main`, o GitHub Actions
(`.github/workflows/publicar-web.yml`) gera a versão web e publica no
GitHub Pages. Na primeira vez, ative em *Settings → Pages → Source:
GitHub Actions*. O link fica em `https://<usuario>.github.io/<repositorio>/`.

**Testar no computador antes de publicar:**

```bash
pip install pygbag==0.9.3
pygbag --template web/doce_texto.tmpl --icon web/favicon.png ppa_final
```

Abra http://localhost:8000 no navegador e toque/clique na tela para
começar (o navegador só libera o som depois de uma interação). Para ver
erros do Python, abra http://localhost:8000/#debug. Para testar no celular, deixe
o celular na mesma rede Wi-Fi e abra `http://<IP-do-computador>:8000`.

## Estrutura

```
ppa_final/
├── main.py         # ponto de entrada e máquina de estados das telas (async, para o pygbag)
├── telas.py        # cada tela do jogo
├── interface.py    # janela, imagens/sons, laço de eventos e texto
├── perguntas.py    # banco de perguntas por nível
├── salvamento.py   # progresso do jogador (JSON)
├── config.py       # constantes: tamanhos, cores, tempos e posições dos botões
└── assets/
    ├── imagens/          # fundos de cada tela
    └── sons/       # música de fundo e efeitos (.ogg, formato aceito no navegador)
web/                      # página (template do pygbag, em português) e ícone da versão web
arquivos_nao_utilizados/  # arquivos do projeto original que o código não usa
```

Para adicionar perguntas, edite `perguntas.py`. Para ajustar a área
clicável de um botão, edite o `Rect` correspondente em `config.py`.
