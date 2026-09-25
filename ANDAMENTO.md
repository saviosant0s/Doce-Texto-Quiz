# Andamento do projeto

Diário do que foi feito, do que falta e de onde parou, para qualquer pessoa (ou
uma nova sessão do Claude) continuar o trabalho sem depender da conversa.
**Atualize este arquivo a cada etapa concluída.**

- Código principal: branch `main` (trabalho novo em branches, com PR)
- Jogo no navegador: https://saviosant0s.github.io/Doce-Texto-Quiz/
- APK: https://saviosant0s.github.io/Doce-Texto-Quiz/apk/doce-texto-quiz.apk
- Versão atual: 0.8.0 (Android, Windows e navegador). O pacote do INPI
  (`/entrega/`, memorial) continua sendo o da 0.5.1.
- Pendências que dependem de pessoas (imagens, direitos, @ do Instagram,
  revisão das perguntas, testes no celular): `PENDENCIAS.md`

## Objetivo

Refazer o quiz de 2023 (pygame, pasta `ppa_final/`) no Godot 4 (pasta `godot/`),
para celular deitado, mantendo a autoria da equipe e o visual roxo/amarelo.
Metas: APK para Android e registro no INPI.

## Plano em 6 etapas (combinado com o Sávio)

| Etapa | O quê | Situação |
|---|---|---|
| 1 | Regras: passar com 6/10, estrelas, níveis liberados em ordem, sorteio sem repetir, save com versão e migração, confirmação ao sair | ✅ feito |
| 2 | Explicação em cada uma das 60 perguntas (aparece na revisão da partida) | ✅ feito |
| 3 | Tela de configurações: volume da música e dos efeitos, animações, apagar progresso | ✅ feito |
| 4 | Diversão: pontos por rapidez, combo, ajudas com moedas, revisão dos erros, 14 conquistas, estatísticas, tela de troféus com abas | ✅ feito |
| 5 | APK Android assinado, ícones, botão voltar do celular | ✅ feito (falta testar em celular de verdade) |
| 6 | Parte técnica: testes automáticos no GitHub (Actions), limpeza, juntar na `main` | ✅ feito |

## Etapa 6: o que fazer (em ordem)

1. **GitHub Actions** (`.github/workflows/testes.yml`): em cada push e pull
   request, instalar o Godot 4.7.2 (linux x86_64, headless) e rodar
   `godot/testes/rodar.sh`. Depois, se quiser, um segundo workflow para
   publicar a versão web no GitHub Pages sozinho quando a `main` mudar
   (hoje é manual: `ferramentas/publicar_web.sh`).
2. **Limpeza**:
   - `arquivos_nao_utilizados/` (~18 MB): conferir se algo ainda é usado e apagar.
   - `web/` e a versão pygame em `ppa_final/`: decidir com o Sávio se ficam
     (histórico do projeto de 2023) ou se vão para uma pasta `legado/`.
   - `requirements.txt` só serve para a versão pygame.
3. **Pull request** da branch de trabalho para a `main`, com resumo das etapas.
   Só abrir quando o Sávio pedir.
4. (Opcional) A branch `gh-pages` guarda cada APK publicado no histórico e está
   crescendo; dá para recriá-la sem histórico (branch órfã) de vez em quando.

## Pedido atual (24/09/2026) — concluído

1. ✅ Documento para o INPI: `docs/inpi/memorial_descritivo.pdf` (ver `docs/inpi/LEIA-ME.md`).
2. ✅ Etapa 6: testes no GitHub Actions, limpeza (pygame em `legado/`), PR para a
   `main` ([#1](https://github.com/saviosant0s/Doce-Texto-Quiz/pull/1), já juntado).
3. ✅ Rostos mais amigáveis e fantasma de chocolate branco refeito.
4. ✅ Executável para Windows (`ferramentas/gerar_exe.sh`), publicado em
   https://saviosant0s.github.io/Doce-Texto-Quiz/windows/DoceTextoQuiz.zip.
   Teste num Windows de verdade: GitHub > Actions > "Teste no Windows" > Run workflow.
5. ✅ Versão na tela só com o número (v0.5.0).

## Vila dos Doces (em andamento — pedido de 24/09/2026)

Um mundo 3D pequeno onde o jogador anda com o seu doce (o companheiro da
coleção) e entra nos lugares do jogo, no lugar dos menus. Plano por etapas:

1. ✅ **Vila andável (MVP)** — feito em 24/09/2026 — `godot/cenas/vila.*`: chão, caminhos e enfeites de
   doce; o doce anda (joystick na tela, teclado no computador) com animação de
   andar; câmera acompanhando; prédios com porta:
   - ESCOLA → níveis do quiz · CONFEITARIA → Minha Coleção ·
     TROFÉUS → troféus · FLIPERAMA → "em breve" (o Doce Match, abaixo).
   "JOGAR" na tela inicial leva à vila (aparelhos sem placa de vídeo vão direto
   para os níveis). Ao sair de um prédio, o doce aparece na porta dele.
2. ✅ **Melhorias pedidas (24/09)** — feitas em 24/09/2026:
   - Andar: acelera e freia aos poucos, inclina nas curvas, corre (joystick
     até o fim ou Shift) soltando poeira de açúcar, pula (botão PULAR ou
     Espaço) e "amassa" ao cair. Enter/E entra no prédio.
   - Gráfico de desenho: luz em degraus (toon), contorno escuro nas peças
     grandes (`tema/contorno.gdshader`, via `CenarioVila.estilo_desenho`),
     sombras de verdade, antisserrilhado 4x na vila, grama com manchas,
     florzinhas e tufos (MultiMesh), caminhos com biscoitos de gotas de
     chocolate, morros de sorvete no horizonte, nuvens de algodão-doce e
     névoa rosinha leve.
   - Casas diferentes (`cenario_vila.gd`): Escola de biscoito com telhado de
     duas águas e torre do sino; Confeitaria em forma de cupcake gigante;
     torre dos Troféus com colunas de bengala e cúpula dourada; Fliperama em
     forma de máquina (letreiro, tela e painel com botões).
3. Outros doces da coleção passeando pela vila; placas e detalhes.
4. Pequenas tarefas na vila (ex.: moedas espalhadas, missões curtas).

### Ideias do Sávio (25/09) — NÃO fazer ainda, só anotadas
- ✅ **Animação ao entrar num prédio** — feita em 25/09.
- ✅ **Jogo de confeitaria — 1ª versão feita (25/09, v0.6.0)**: "Minha
  Confeitaria" (`scripts/confeitaria.gd`, `cenas/confeitaria.*`). Açúcar vem
  dos acertos no quiz (10 por acerto, também na revisão); 3 máquinas
  (brigadeiro grátis; maçã do amor ao passar no fácil, 150 moedas; cupcake ao
  passar no médio, 300) com 3 níveis; estoque 30/60/120; vender ou entregar
  encomendas (2 abertas, pagam mais); fora do jogo produz no máximo 2 h.
  Próximos passos possíveis: mais máquinas para os outros doces da coleção,
  segunda confeitaria, interior 3D da confeitaria, conquistas da confeitaria.
- ✅ **Gráfico mais caprichado** (1ª parte, 25/09): renderizador Mobile e
  grama com volume. Falta (se quiser): casas com textura/cantos arredondados
  (modelos do Blender), árvores balançando, chocolate da fonte animado.
- **Mostrar quando o doce está correndo** no joystick (ainda sem escolha).
- Só gerar APK/executável quando o Sávio pedir (juntar vários pedidos).

### ✅ Doce Match (feito em 25/09)
`scripts/doce_match.gd` (regras, testável sem tela) e `cenas/doce_match.*`
(tela). Abre pelo FLIPERAMA da vila. Tabuleiro 8x8, 6 peças desenhadas por
nós (`assets/doce_match/*.svg`: folha com W, planilha com X, gráfico, célula,
tecla com Ctrl+Z, disquete — sem logos oficiais), arrastar ou tocar para
trocar, filas de 3+ somem, cascata com combo, 20 jogadas, estrelas em
1.200/2.400/3.600 pontos, moedas no fim, recorde em
`estatisticas.match_recorde`. Ideias: peças especiais (fila de 4/5), fases,
dar açúcar também. Sem placa de vídeo não há vila, então não há Doce Match
(o menu dos níveis está cheio; ver se cabe um botão).

### (antigo) Doce Match — plano original
Minijogo no estilo Candy Crush dentro do FLIPERAMA da vila: trocar peças
vizinhas para alinhar 3 iguais. No lugar dos doces, **símbolos de informática
feitos por nós** (folha com "W" azul, planilha com "X" verde, gráfico, célula,
atalho de teclado, disquete...). **Não usar os logos oficiais do Word/Excel**
(marcas registradas da Microsoft; atrapalharia o registro no INPI).

## Onde parou

- 25/09 (depois da 0.8.0): andar com as duas pernas (bug: só uma mexia),
  pé levantando e passos no ritmo do chão; jujubas/colunas sólidas, bonecos
  na camada 2 e câmera com "bolinha" para não entrar em paredes; botão
  JOGAR O QUIZ na cozinha (pulsa sem açúcar); câmera olha para cima/baixo;
  "carregando" com o doce; foto até o 3D aparecer; partes lisas com madeira
  pintada/metal reais; **Doce Match** no Fliperama. APK ainda não gerado.
- **Atenção (tamanho):** o APK da 0.8.0 tem ~92 MB e o GitHub recusa
  arquivos acima de 100 MB no gh-pages. Se crescer mais: publicar o APK como
  "Release" do GitHub (limite 2 GB) ou gerar APKs separados por arquitetura.
- 25/09: **Texturas reais (CC0)** no cenário: grama, areia, calçamento,
  reboco, tijolos, ardósia, madeira e piso (Poly Haven/ambientCG; lista e
  links em `godot/assets/texturas/reais/LEIA-ME.md`). `Texturas.real()` aplica
  cor + relevo + aspereza/AO por projeção triplanar; as fotos são clareadas
  por `ferramentas/preparar_texturas_reais.py` e pintadas com as cores do
  jogo. Materiais "reais" ficam com luz normal (sem degraus). A rede do
  ambiente foi liberada (acesso "Completo") para baixar. **Para o memorial do
  INPI (próxima versão): citar essas texturas de terceiros (CC0).**
- 25/09 (pedido depois de testar a 0.7.0 no celular):
  - **Desempenho**: `scripts/juntar_malhas.gd` junta as peças paradas do
    cenário em poucos blocos (um por material; contornos um por cor) e tira
    faces das formas pequenas; bonecos juntam as peças de cada parte que se
    mexe. Vila: 865 peças/1,2 mi triângulos -> 208/200 mil; cozinha 209 mil ->
    25 mil. 3D a 80% da tela + antisserrilhado 2x. **Shader Baker** ligado
    (Android/Windows) e exportação com Vulkan (`ferramentas/godot_exportar.sh`)
    para o jogo não engasgar ao abrir.
  - **Braços**: o braço do "oi" fica abaixado parado/andando e só sobe para
    acenar; os dois balançam ao andar.
  - **Cozinha com 3 câmeras** (de cima/padrão, perto, 1ª pessoa; botão ou C;
    salva em `config.camera_cozinha`); paredes altas e teto só nas de perto.
  - **Casas com textura de relevo** (`assets/texturas`, geradas por
    `scripts/ferramentas/gerar_texturas.gd`): biscoito, telhas, pedras,
    glacê (projeção triplanar pelo mundo).
- 25/09: **Animação de entrar nos prédios**: a porta tem dobradiça
  (`folha` em `CenarioVila.predio`), abre, o doce anda até o escuro de
  dentro e só então a tela do prédio abre (~1,5 s; um toque pula). Ao sair,
  a porta fecha atrás dele.
- 25/09: **Gráfico melhor**: APK e Windows usam o renderizador **Mobile**
  (Vulkan; cai para o modo leve se o aparelho não tiver Vulkan); o navegador
  continua no modo leve (Compatibility). As luzes mudam conforme o modo
  (`CenarioVila.modo_leve()`), mais um leve reforço de cor
  (`CenarioVila.acabamento`). Grama com volume balançando no vento
  (`tema/grama.gdshader`, MultiMesh com 5.000 tufos). Para os prints saírem
  iguais ao APK: `apt-get install mesa-vulkan-drivers` (o `capturar.sh` usa
  Vulkan por software se houver; `MODO=leve` força o modo leve).
- 25/09: **Cozinha 3D da Confeitaria** (estilo Pizza Ready, pedido do Sávio):
  `cenas/cozinha.*` + `componentes/cozinha/cenario_cozinha.gd`. O doce anda
  na cozinha; máquinas fazem doces na mesa-bandeja (com o açúcar do quiz);
  passando na bandeja ele pega (pilha nas mãos, `CARREGAR` 4/8/12); clientes
  (moradores) fazem fila no balcão pedindo doces; atrás do balcão entrega;
  moedas ficam na mesinha do caixa até recolher; círculos amarelos no chão
  constroem/melhoram (parar 1,2 s); seta e dica mostram o próximo passo;
  tapete SAIR volta à vila. Regras novas em `scripts/confeitaria.gd`
  (bandejas no lugar de estoque/encomendas). Sem placa de vídeo, abre o
  painel 2D simples (`cenas/confeitaria.*`).
- 25/09 (v0.6.0): **Minha Confeitaria** (1ª versão) — o prédio da
  Confeitaria na vila agora abre ela (a coleção fica no botão dentro dela e no
  menu dos níveis). APK e executável gerados.
- 25/09: placa da Confeitaria não atravessa mais o cupcake; no celular dá
  para andar no joystick e, com outro dedo, girar a visão ou apertar PULAR/
  ENTRAR/câmera ao mesmo tempo. (Gravado no GitHub; APK ainda não gerado.)
- Antes: **melhorias da Vila dos Doces** (andar com pulo e
  corrida, visual de desenho, casas diferentes) — item 2 da vila acima.
  Antes disso: câmeras aérea/perto/1ª pessoa (tecla C, escolha salva).
- Próximo passo da vila (quando o Sávio pedir): item 3 (outros doces
  passeando, placas e detalhes) ou item 4 (moedas espalhadas, missões).
- Futuro (não fazer agora): login com Google para guardar o progresso na
  nuvem; detalhes e cuidados em `PENDENCIAS.md` (seção "Futuro").
- Ideias para depois: companheiro comemorando na tela de resultado; trocar
  qualquer doce por um modelo .glb (basta salvar em `godot/assets/doces_3d/<id>.glb`).
- Nada pela metade. Próximo passo: item 1 da etapa 6.

## Como trabalhar no projeto

- **Testes:** `godot/testes/rodar.sh` (694 verificações; falha também em erro
  de script). Rode antes de cada commit.
- **Print de uma tela:** `ferramentas/capturar.sh niveis` → `build/prints/niveis.png`.
  Opções em `godot/scripts/ferramentas/captura.gd` (ex.: `--acertos=7`,
  `--liberar=2`, `--historico=6`, `--aba=2`).
- **Publicar no site:** `ferramentas/publicar_web.sh`. Com `KEYSTORE` e
  `KEYSTORE_SENHA` definidos, também gera e publica o APK.
- **Gerar só o APK:** `ferramentas/gerar_apk.sh`. A keystore **não** está no
  repositório; o Sávio tem uma cópia (`doce_texto_quiz.keystore` + senha).
- **Tema visual** (botões, painéis, fontes): gerado por
  `godot --headless --path godot --script res://scripts/ferramentas/gerar_tema.gd`.
- **Ambiente usado:** Godot 4.7.2 com modelos de exportação web e Android;
  JDK 21; `apksigner` (pacote apt) numa pasta de SDK mínima configurada nas
  Configurações do Editor do Godot (Exportar > Android).

## Mapa rápido do código (`godot/`)

- `scripts/jogo.gd`: regras, sorteio, partida atual, revisão, pontos, estatísticas
- `scripts/progresso.gd`: save (versão 2 + migração), níveis, moedas, histórico
- `scripts/conquistas.gd`: lista das 14 conquistas e quando cada uma é ganha
- `scripts/telas.gd`: navegação, avisos, confirmação, botão voltar
- `scripts/audio.gd`: música e efeitos em canais separados
- `cenas/`: uma tela por arquivo (inicio, niveis, partida, aproveitamento,
  resultado, titulos = troféus, configuracoes, carregamento, como_jogar,
  creditos, sobre)
- `dados/perguntas.json`: 60 perguntas (id, assunto, enunciado, alternativas,
  resposta, explicacao)
- `testes/`: testes automáticos

## Histórico resumido

- Refatoração da versão pygame e publicação web (pygbag). Depois, reconstrução
  no Godot 4 com telas novas, personagens gerados por IA (só doces) e mascote 3D.
- Correções de desempenho: animações contínuas desligadas em aparelhos sem
  placa de vídeo, decoração desenhada uma vez só.
- Etapas 1 a 5 acima (commits `3d04f15`, `74671c4`, `64a73a1`, `cf8abf2`,
  `83c4f4e`, `f618ce3`).
