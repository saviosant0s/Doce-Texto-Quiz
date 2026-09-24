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

### Regras

- Cada partida sorteia 10 das 20 perguntas do nível (primeiro as nunca vistas
  e as erradas da última vez) e embaralha as alternativas.
- Com 6 acertos ou mais, você passa no nível: ganha o título dele (Fácil →
  Noob, Médio → Pro, Difícil → Mestre) e libera o próximo.
- Estrelas: 6 acertos = 1, 8 = 2, 10 = 3. Moedas por acerto e por estrela.
- Pontos: cada acerto vale de 100 a 200 conforme a rapidez; 3 acertos seguidos
  multiplicam por 1,5 e 5 seguidos por 2 (combo). Recorde de pontos por nível.
- Ajudas pagas com moedas, uma de cada por pergunta: eliminar 2 alternativas
  erradas (30 moedas) e +10 segundos (20 moedas).
- Revisão: na tela de níveis, "REVISAR ERROS" joga as perguntas que você errou
  da última vez (de todos os níveis). Não muda os níveis, mas dá moedas.
- Troféus: títulos, 16 conquistas com recompensa em moedas
  (`scripts/conquistas.gd`) e estatísticas (acerto por assunto, mais erradas).
- Minha Coleção: 13 doces em 3D (giram com o dedo, piscam, acenam). O
  brigadeiro vem de graça, 3 vêm com os títulos e 9 são comprados com moedas
  (100 a 600). O doce escolhido como companheiro aparece no carregamento.

### Testes

```bash
godot/testes/rodar.sh
```

Confere regras, sorteio, progresso, migração de saves antigos, revisão,
conquistas, estatísticas e uma partida completa passando pelas telas. Rode antes de publicar qualquer mudança.

### Estrutura

```
godot/
├── project.godot        # configuração (resolução 1280x720, horizontal)
├── cenas/               # uma cena (.tscn) + script (.gd) por tela
├── componentes/         # peças reutilizáveis: fundo animado, cartão de nível
├── scripts/
│   ├── jogo.gd          # regras e partida atual (sorteio, estrelas, títulos)
│   ├── progresso.gd     # salvamento (com versão/migração), recordes, histórico
│   ├── conquistas.gd    # lista de conquistas e quando cada uma é desbloqueada
│   ├── colecao.gd       # catálogo da coleção: preços, compras, companheiro
│   ├── doces_3d.gd      # os 13 doces 3D, montados por código
│   ├── pecas_3d.gd      # peças 3D: formas, materiais, rosto, braços e pernas
│   ├── telas.gd         # navegação, avisos, caixa de confirmação
│   ├── audio.gd         # música e efeitos em canais separados
│   ├── ferramentas/captura.gd  # gera prints das telas pela linha de comando
│   ├── cores.gd         # paleta de cores
│   └── animacoes.gd     # animações simples (entrar, flutuar, destacar)
├── tema/tema.tres       # visual dos botões, painéis e textos (editável no Godot)
├── dados/perguntas.json # perguntas de cada nível (com id fixo)
├── testes/              # testes automáticos (rodar.sh) e vitrine_3d.tscn
│                        # (todos os doces 3D lado a lado, para conferir)
└── assets/              # personagens, ícones (SVG), fontes (OFL) e sons
```

- **Perguntas:** edite `godot/dados/perguntas.json`. `resposta` é o índice
  (começando em 0) da alternativa correta; `assunto` é `word`, `excel` ou `geral`.
- **Cores e estilos:** abra `tema/tema.tres` no Godot; as variações
  (`Titulo`, `BotaoRoxo`, `PainelRoxo`, …) são usadas nas cenas.
- **Gerar prints de uma tela:**
  `godot --path godot -- --capturar=niveis --saida=print.png`
  (para telas de resultado, acrescente `--acertos=7`; veja as outras opções em
  `scripts/ferramentas/captura.gd`).

### Gerar o APK (Android)

```bash
KEYSTORE=/caminho/doce_texto_quiz.keystore KEYSTORE_SENHA=... ferramentas/gerar_apk.sh
```

Gera `build/android/doce-texto-quiz.apk` (Android 7 ou mais novo, celulares
32 e 64 bits, sempre deitado, sem nenhuma permissão). O script explica o que
precisa estar instalado. A keystore e a senha **não ficam no repositório**:
guarde-as em lugar seguro, porque toda atualização do app precisa ser assinada
com a mesma chave. Os ícones do app ficam em `godot/assets/android/`.

### Publicar a versão web

```bash
ferramentas/publicar_web.sh
```

Exporta a versão web e envia para a branch `gh-pages`, que o GitHub Pages
publica. Prints das telas: `ferramentas/capturar.sh <tela>`.

Andamento do projeto e próximos passos: **`ANDAMENTO.md`**.

## Versão original (pygame, `ppa_final/`)

Mantida como referência. Para rodar:

```bash
pip install -r requirements.txt
python ppa_final/main.py
```
