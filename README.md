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
- Vila dos Doces: o "JOGAR" leva a uma vila 3D onde o jogador anda com o seu
  doce (joystick na tela ou setas/WASD) e entra na Escola (quiz), Confeitaria
  (Minha Confeitaria), Troféus e Fliperama (em breve). Em aparelhos sem placa
  de vídeo, vai direto para os níveis.
  Três câmeras (botão no topo ou tecla C): aérea, perto e primeira pessoa.
  O doce acelera e freia aos poucos, corre (joystick até o fim ou Shift) e
  pula (botão na tela ou Espaço); Enter/E entra. Visual de desenho animado
  (luz em degraus, contorno, sombras) e cada prédio tem o seu jeito: Escola
  de biscoito com torre do sino, Confeitaria-cupcake, torre dos Troféus e
  Fliperama em forma de máquina.
- Minha Confeitaria (`scripts/confeitaria.gd`, `cenas/confeitaria.*`): cada
  acerto no quiz dá 10 de açúcar; máquinas (panela de brigadeiro, tacho de maçã
  do amor e forno de cupcake, liberadas passando nos níveis) transformam açúcar
  em doces sozinhas. Os doces vão para o estoque (ampliável) e são vendidos ou
  entregues em encomendas dos moradores, que pagam mais. Moedas melhoram as
  máquinas (3 níveis). Com o jogo fechado, produz no máximo 2 horas.
  Entrada: prédio da Confeitaria na vila ou botão no menu dos níveis.
- Minha Coleção: 13 doces em 3D (giram com o dedo, piscam, acenam). O
  brigadeiro vem de graça, 3 vêm com os títulos e 9 são comprados com moedas
  (100 a 600). O doce escolhido como companheiro aparece no carregamento.
- Personagens: todos são 3D, montados por código (`scripts/doces_3d.gd`). As
  telas que mostram personagens parados usam fotos deles em
  `assets/doces_3d/fotos`. **Mudou um modelo? Rode `ferramentas/gerar_fotos_3d.sh`.**

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

### Gerar o executável para Windows

```bash
ferramentas/gerar_exe.sh
```

Gera `build/windows/DoceTextoQuiz.exe`, um arquivo só, com o jogo dentro: é só
abrir, sem instalar (Windows 64 bits). Precisa dos modelos de exportação do
Godot para Windows. Download publicado:
https://saviosant0s.github.io/Doce-Texto-Quiz/windows/DoceTextoQuiz.zip
(o fluxo "Teste no Windows" do GitHub Actions abre esse arquivo num Windows de verdade).

### Publicar a versão web

```bash
ferramentas/publicar_web.sh
```

Exporta a versão web e envia para a branch `gh-pages`, que o GitHub Pages
publica. Prints das telas: `ferramentas/capturar.sh <tela>`.

Andamento do projeto e próximos passos: **`ANDAMENTO.md`**.

## Versão original de 2023 (pygame, `legado/pygame_2023/`)

A primeira versão do jogo, feita pela turma em Python com pygame, fica guardada
como histórico. Para rodar no computador:

```bash
pip install -r legado/pygame_2023/requirements.txt
python legado/pygame_2023/main.py
```
