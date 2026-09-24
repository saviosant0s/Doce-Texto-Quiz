# Doce Texto Quiz

Quiz sobre Word e Excel, com 3 níveis de 10 perguntas cada. Projeto
desenvolvido em 2023 por alunos do IFBA Campus Valença.

**Jogar no navegador (celular ou computador):** https://saviosant0s.github.io/Doce-Texto-Quiz/

## Versão atual: Godot (`godot/`)

O jogo foi refeito no [Godot 4](https://godotengine.org/) com as telas
montadas por código/cenas em vez de imagens com texto. A estética (cores,
personagens, fontes) é a mesma da versão original.

### Como abrir

1. Instale o Godot 4.7 ou mais novo.
2. No Godot, clique em **Importar** e escolha `godot/project.godot`.
3. Aperte **F5** para rodar.

### Estrutura

```
godot/
├── project.godot        # configuração (resolução 1280x720, horizontal)
├── cenas/               # uma cena (.tscn) + script (.gd) por tela
├── componentes/         # peças reutilizáveis: fundo animado, cartão de nível
├── scripts/
│   ├── jogo.gd          # estado da partida, navegação entre telas, salvamento
│   ├── audio.gd         # música de fundo e efeitos
│   ├── cores.gd         # paleta de cores
│   └── animacoes.gd     # animações simples (entrar, flutuar, destacar)
├── tema/tema.tres       # visual dos botões, painéis e textos (editável no Godot)
├── dados/perguntas.json # perguntas de cada nível
└── assets/              # personagens, ícones (SVG), fontes (OFL) e sons
```

- **Perguntas:** edite `godot/dados/perguntas.json`. `resposta` é o índice
  (começando em 0) da alternativa correta.
- **Cores e estilos:** abra `tema/tema.tres` no Godot; as variações
  (`Titulo`, `BotaoRoxo`, `PainelRoxo`, …) são usadas nas cenas.
- **Gerar prints de uma tela:**
  `godot --path godot -- --capturar=niveis --saida=print.png`
  (para telas de resultado, acrescente `--acertos=7`).

### Publicar a versão web

No Godot: **Projeto → Exportar → Web → Exportar projeto**, salvando em
`build/web/index.html`. Os arquivos gerados vão para a branch `gh-pages`,
que o GitHub Pages publica.

## Versão original (pygame, `ppa_final/`)

Mantida como referência. Para rodar:

```bash
pip install -r requirements.txt
python ppa_final/main.py
```
