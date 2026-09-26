# Andamento do projeto

Diário do que foi feito, do que falta e de onde parou, para qualquer pessoa (ou
uma nova sessão do Claude) continuar o trabalho sem depender da conversa.
**Atualize este arquivo a cada etapa concluída.**

- Código principal: branch `main` (trabalho novo em branches, com PR)
- Jogo no navegador: https://saviosant0s.github.io/Doce-Texto-Quiz/
- APK: https://saviosant0s.github.io/Doce-Texto-Quiz/apk/doce-texto-quiz.apk
- Versão atual: 0.12.0 (Android 64 e 32 bits, Windows e navegador). O pacote do INPI
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

### ✅ Doce Match (feito em 25/09; níveis em 28/09, ver "Onde parou")
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

- 29/09 (pedidos do Sávio depois de jogar a 0.12.0), **ainda sem APK**:
  - Sem a borda escura em volta dos personagens (o contorno de desenho saiu
    também dos bonecos; `CenarioVila.estilo_desenho` só aplica o realismo).
  - Câmera aérea gira: arrastar o dedo gira em volta do doce (só para os lados).
  - Correr sem tremer: o modelo do doce é desenhado entre os dois últimos
    passos da física (a tela do celular desenha 90/120 por segundo) e a
    velocidade passa de andar para correr aos poucos (antes pulava em 0,85
    do joystick e o dedo no limite fazia acelerar e frear sem parar).
  - Telhado da Fábrica de Chocolate refeito (dentes de serra em prisma com
    vidro; os cones antigos tinham a base no mesmo plano da fachada e a tela
    "tremia" ali).
  - Prédios mais reais: janelas com vidro que reflete, peitoril, verga e
    venezianas; todas as entradas com degraus de pedra, capacho, arbustos
    com flores e luminárias acesas; Escola com base de pedra e chaminé.
  - 100 de açúcar de presente para quem começa (quem já jogava ganha uma vez).
  - **Evolução das construções** (estilo Viking Rise): todas as 5
    construções vão até o nível 5 e mudam de forma a cada nível; a obra leva
    tempo (3 min, 15 min, 1 h, 4 h) com andaime e relógio em cima do lote;
    um construtor (uma obra por vez); "TERMINAR JÁ" por 1 açúcar/minuto;
    beleza da vila (casa, jardim e fonte) dá +5% por nível no moinho e no
    cofre. Tabela em `docs/economia.md`. Print: `capturar.sh vila --terrenos=5`.
  - Como jogar: as 10 abas quebram em duas linhas (numa só, ficavam mais
    largas que a tela e cortavam os lados); letras menores nas abas com 6 cartões.

- 28/09 (pedidos do Sávio depois de jogar a 0.10.2), **publicado na 0.11.0**:
  - Feito antes (commit `edb8b1c`): câmera da vila e da cozinha sem tremer
    (posição suavizada entre os passos da física, física no ritmo da tela),
    açúcar visível na vila e "-X AÇÚCAR" nas máquinas da cozinha (o açúcar
    do laboratório entrava, mas as máquinas gastavam sem mostrar), tela
    inicial só com JOGAR, "Como jogar" com abas para cada parte do jogo.
  - **Doce Match com 30 níveis** (como no Candy Crush): mapa de níveis com
    estrelas, cadeados, o doce do jogador no nível atual e baús nos níveis 5,
    10, 15... (prata; 15 e 30 de ouro). Cada nível tem jogadas e objetivos:
    pontos, juntar peças de um tipo ou limpar a **gelatina** rosa. Peças
    especiais: fila de 4 = LISTRADA (explode linha/coluna), L ou T =
    EMBRULHADA (explode em volta), fila de 5 = BOMBA de confeito (leva todas
    as peças de um tipo); reação em cadeia. Efeitos: raios, ondas, confete,
    tabuleiro tremendo, palavras DOCE!/DELICIOSO!/INCRÍVEL!/DIVINO!, peças
    voando até o objetivo, jogadas que sobram viram pontos. Sons novos
    (explosão, especial, vitória). Tentativa custa 30 de açúcar (era 40).
  - Níveis em `godot/dados/doce_match.json`, gerados por
    `ferramentas/gerar_niveis_match.py` e calibrados com um robô
    (`godot/testes/calibrar_doce_match.tscn`: joga cada nível 10 vezes e
    mostra vitórias e pontos). Estrelas em `ferramentas/doce_match_estrelas.json`.
  - **Visual dos doces por nível** (`Doces3D.enfeitar`): nível 2 ganha
    brilhos girando (cor da raridade), 3 um laço, 4 uma coroa de ouro e 5
    (máximo) coroa com joias, brilhos dourados e círculo de luz no chão.
    Aparece na coleção, no carregamento, no pódio e no boneco da vila e da
    cozinha. Ao melhorar, o aviso diz o que o doce ganhou.
  - **Pódio** (Troféus > Títulos): continua o de 2023 (Doceiro Noob, Pro e
    Mestre, ganhos passando nos níveis do quiz), com uma frase explicando por
    que a Maçã, o Cupcake e o Chocolate estão ali (vêm com cada título).
    Depois de ganhar o título, tocar no degrau abre a escolha de qualquer
    doce da coleção para ficar nele (`Colecao.doce_do_podio`).
  - **Carregamento da vila e da cozinha** igual ao da partida (cartão com
    "VILA DOS DOCES"/"MINHA COZINHA", o doce companheiro, VOCÊ SABIA?/DICA e
    a barra enchendo de verdade: a cena carrega em segundo plano). Antes era
    só "CARREGANDO..." com uma foto.
  - **Missões, Baús (e a Coleção aberta por eles) abrem POR CIMA da vila**,
    na hora (`Telas.abrir_rapido` / `abrir_por_cima`): a vila fica parada
    atrás e, ao voltar, continua de onde estava, sem tela de carregamento.
  - **12 doces novos** (catálogo com 25): jujuba, beijinho, marshmallow,
    paçoca (comuns), cocada, pé de moleque, sorvete, pão de mel (raros),
    quindim, churros, brownie (épicos) e bolo de aniversário (lendário), em
    3D no mesmo estilo, com curiosidade, preço (120 a 800) e bônus. Também
    caem nos baús surpresa.
  - **Travada ao abrir o jogo**: o mascote 3D era montado durante a animação
    de entrada (a primeira imagem 3D trava o celular um instante e, com a
    tela ainda transparente, o boneco parecia apagado). Agora a entrada usa
    a imagem e o 3D entra depois, com um esmaecer suave.
  - **Vila maior** (mapa cerca de 3x maior, `scripts/terrenos.gd`,
    `componentes/vila/bairro_vila.gd`):
    - **Bairro dos Terrenos** atrás da Escola: 6 lotes à venda (100 a 900
      moedas). No lote comprado se constrói MOINHO DE AÇÚCAR ou COFRE DE
      MOEDAS (produzem sozinhos até encher; passar lá e coletar; sobem até o
      nível 3), CASA DE DOCE (chega um vizinho passeando), JARDIM ou FONTE.
    - **Lago de Chocolate** (oeste) e **Mirante do Sorvete** (leste), com um
      presente por dia (20 de açúcar + 15 moedas) para quem anda até lá.
      Placa de direções no cruzamento ao sul da praça.
    - **Confeitaria cresce por fora** com as máquinas da cozinha: terraço com
      mesinhas e guarda-sóis e depois uma segunda torre-cupcake.
    - Câmera aérea sobe e olha de cima quando um prédio tapa o doce; lotes e
      presentes longe não são desenhados (leve no celular).
    - Estado salvo em `Progresso.vila`. Print: `--terrenos --vila_pos=0,-29`.
  - **Acabamento de imagem (pedido do Sávio)**: renderizador Mobile (Vulkan) e
    compressão ASTC/ETC2 já estavam ligados. Agora a vila e a cozinha usam
    tonemap ACES, brilho (glow) só no que emite luz (limite HDR 1, sem bloom
    geral) e SSAO/SSIL/SDFGI desligados; peças lisas e metais ganharam
    reflexo de desenho (especular toon), as ásperas continuam foscas.
    LightmapGI não foi usado: o cenário é montado por código quando a tela
    abre (e os terrenos mudam), e o "bake" só funciona no editor, em cena
    salva, parada, com UV2 — ver a resposta na conversa de 28/09.
  - **Menu dos níveis mais limpo**: com a vila, o menu da esquerda fica só
    com voltar e os outros jogos (Confeitaria, Doce Match, Laboratório).
    Troféus e coleção ficam na vila; como jogar, créditos e ajustes, no
    início. Sem placa de vídeo (sem vila) o menu continua completo.
  - **Carregamento da vila/cozinha**: a linha de cima tem a mesma largura da
    caixa de baixo ("VILA DOS / DOCES", "COZINHA DA / CONFEITARIA") e a
    barra enche aos poucos, quadro a quadro (antes aparecia já no fim).
  - **Visual realista (vila e cozinha)**: sai a luz "em degraus" de desenho
    (toon) e o contorno escuro do cenário (os bonecos mantêm o contorno).
    Luz física (Burley + GGX), sol quente mais forte, luz ambiente vinda do
    céu, sombras mais marcadas e macias (2 cascatas na qualidade ALTA).
    Todo material de cor lisa ganha relevo gerado por ruído conforme o tipo
    (`scripts/realismo.gd`): LISO (calda, bala: micro-imperfeições + verniz),
    ACETINADO (chocolate, massa) e POROSO (açúcar, biscoito, algodão: poros
    + brilho aveludado de borda). Reflexo do céu desligado: com a luz
    realista ele deixava as cores lavadas.
  - **Vida na vila**: borboletas coloridas voando pelo gramado (10 na
    qualidade MÉDIA, 18 na ALTA), pingos de chocolate caindo da fonte e
    faíscas douradas nos presentes do dia ainda não abertos. Só com as
    animações ligadas e placa de vídeo (print: `--animacoes`).
  - **Baús novos** (`Itens3D._bau`, fotos refeitas): tábuas, cantoneiras e
    faixas de metal com rebites, alças, fechadura em coração, joia na frente
    (safira na prata, rubi no ouro, ametista no chefe), coroinha no ouro e no
    chefe, laço e listras no de doce, e luz dourada escapando pela fresta.
    Aberto: luz forte, moedas e joias. **Abertura com suspense**
    (`cenas/baus.gd`): toque no baú (ou espere, ele abre sozinho), ele treme
    mais forte a cada toque, raios de luz NA COR DO MELHOR PRÊMIO crescem
    atrás, clarão, faíscas e "ÉPICO!"/"UAU! LENDÁRIO!".
  - **Grama mais baixa e menos densa** (1.300/2.400 tufos em vez de
    2.500/5.000; parecia mato).
  - **Minigame novo: TORRE DE DOCES** (escolhido pelo Sávio): prédio de bolo
    de 6 andares com vela acesa, ao lado da praça (`CenarioVila._torre_doces`).
    Dentro (`cenas/torre.*`, regras em `scripts/torre.gd`): um andar de bolo
    passa de um lado para o outro, toque para soltar; a sobra cai girando;
    PERFEITO mantém a largura (3 seguidos alargam); a cada 10 andares uma
    pergunta do quiz (12 s) dá pontos e o andar largo de novo. O céu vai do
    dia à noite estrelada conforme sobe. Custa 20 de açúcar; 1 moeda por
    andar + 1 por perfeito; baú de doce a cada nova dezena acima do recorde;
    missão nova "SUBA N ANDARES NA TORRE". Também no menu dos níveis e no
    "Como jogar". Print: `ferramentas/capturar.sh torre --torre=14`.
  - **Sombras e chão limpo** (pedido do Sávio): o sol já tinha sombra ligada
    (qualidades MÉDIA e ALTA). Descoberta: o Vulkan por software dos prints
    (lavapipe) NÃO desenha a sombra do sol no renderizador Mobile — no modo
    de compatibilidade a mesma cena mostra (ver `MODO=leve
    ferramentas/capturar.sh vila`). No celular (placa de vídeo) ela é
    desenhada. SSAO não existe no renderizador Mobile (só no Forward+); no
    lugar, **sombras de contato** (`CenarioVila.sombra_contato`: manchas
    macias no chão) embaixo de prédios, fonte, árvores, bengalas, jujubas,
    construções dos lotes e de todos os bonecos (vila e cozinha). Chão: sai a
    foto de grama "ruidosa", entra verde suave e liso (`CenarioVila.gramado`);
    tufos com a cor do chão e iluminados por igual dos dois lados (o verso
    ficava escuro no modo de compatibilidade).
  - **Minigame novo: FÁBRICA DE CHOCOLATE** (escolhido pelo Sávio): galpão
    de tijolos com telhado em serra, chaminés soltando fumaça de chocolate e
    cano de chocolate, do lado oeste da praça (`CenarioVila._fabrica_chocolate`).
    Dentro (`cenas/fabrica.*`, regras em `scripts/fabrica.gd`): o pedido fica
    no alto (bombons, trufas, barras, corações); toque nos chocolates certos
    da esteira e eles voam para a caixa; queimados/quebrados ou fora do pedido
    tiram 3 s; pedido pronto dá +6 s e acelera a esteira; a cada 3 pedidos, um
    PEDIDO ESPECIAL (pergunta do quiz, +8 s). Turno de 60 s, 20 de açúcar;
    moedas por pedido; baú de doce a cada nova marca de 5 pedidos; missão
    nova "COMPLETE N PEDIDOS NA FÁBRICA". Menu dos níveis e "Como jogar".
    Print: `ferramentas/capturar.sh fabrica --fabrica=4`.
  - **Publicado na 0.12.0** (APK 64 e 32 bits, Windows e navegador): terrenos,
    12 doces novos, baús novos, Torre de Doces, Fábrica de Chocolate e o visual novo.

- 27/09: **telas conferidas em 20:9 (celular comprido), 16:10 e 4:3
  (tablets)**, além do 16:9 de sempre. Ajustes: mapa do laboratório usa a
  altura toda; cartões de baús e painéis de missões não esticam vazios; tela
  "Sobre" mostra o total de perguntas de verdade (estava "60"). Para repetir
  o teste: `RES=1280x960 ferramentas/capturar.sh <tela>` (ou 1600x720,
  1280x800).
- 27/09: **Laboratório com 5 capítulos (40 fases)**. Novos: cap. 4
  "Planilhas de verdade" (SEERRO, PROCV, CONT.SES, SOMASES, marcadores,
  estilos de título, marca-texto; chefe "o caixa inteligente") e cap. 5
  "Mestre do Office" (porcentagem, SES, ÍNDICE+CORRESP, texto com &, lista
  numerada, capa de trabalho; chefe final "o jornal da escola", 5 tarefas).
  O motor de fórmulas ganhou PROCV, SEERRO, SES, CONT.SES, SOMASES, ÍNDICE,
  CORRESP e o erro #N/D; o Word ganhou listas (• e 1.), estilos Título 1/2
  e marca-texto, com botões e atalhos (Ctrl+Shift+L, Ctrl+Alt+1/2).
- 27/09 (pedido "pode fazer tudo" antes da 0.10.1):
  - **Dois APKs**: 64 bits (principal) e 32 bits (celulares antigos), cada
    um com cerca de metade do tamanho; página de download em `apk/index.html`
    (gerada pelo `publicar_web.sh`).
  - **Fases de Excel sem o teclado do celular**: o teclado do aparelho só
    abre pelo botão TECLADO; botões para as funções, os textos da tarefa
    ("Aprovado", ">6"...), os símbolos e os números (botão 123). Tocar numa
    célula fecha o teclado.
  - **Estrela 3D** de ouro (`Itens.ESTRELA`; apagada = `Itens.ESTRELA_APAGADA`)
    em todas as telas.
  - **Economia revista** (`docs/economia.md`): baús do laboratório com menos
    moedas e um baú surpresa dentro; baús surpresa com mais pedaços (70%) e
    menos moedas (18%).
  - **Explicação de primeira vez** (`Telas.dica_primeira_vez`) nos baús,
    companheiros, missões e laboratório.
  - Aviso "leaked at exit" resolvido (estrelas das fases trancadas do mapa
    ficavam soltas na memória).
- 26/09: **itens com identidade própria**. Moeda (de ouro com uma bala em
  relevo), açúcar (cubinhos com cristais), XP (estrela de bala roxa) e os
  baús (doce, prata, ouro, madeira, chefe e abertos) agora são 3D no mesmo
  estilo dos doces personagens (`scripts/itens_3d.gd`; fotos em
  `assets/itens/`, geradas por `ferramentas/gerar_itens_3d.sh`). As telas
  usam só `Itens.MOEDA`, `Itens.ACUCAR`, `Itens.XP`, `Itens.bau(tipo)`, sem
  pintar por cima (`Itens.sem_tinta` nos botões). Os ícones antigos (SVG de
  linha) foram apagados. APK ainda não gerado com isso.
- 26/09 (pedido do Sávio vendo os prints): **telas mais limpas**. Resultado do
  quiz: uma frase com acertos e pontos e uma linha só de prêmios (moedas,
  açúcar, baú, XP), sem as etiquetas coloridas (o "nível liberado" já é o
  botão). Vila e cozinha: sem a faixa com o nome, topo numa linha só (casa,
  nível/missões/baús, moedas, câmera) com botões menores; ENTRAR, PULAR e
  JOGAR O QUIZ menores. Laboratório, fases, baús, missões e Doce Match com
  voltar e título menores. **APK ainda não gerado com isso** (está na 0.10.0).
- 26/09 (noite, pedido "pode fazer tudo"; partes 2 e 3 do plano "estilo
  Vikings Rise"), **v0.10.0 publicada (APK ~94 MB e Windows)**:
  - **Baús surpresa** (`scripts/baus.gd`, tela `cenas/baus.*`): DOCE (partida
    aprovada, até 5/dia), PRATA e OURO. Abrem tremendo e mostram cartas na cor
    da raridade. Garantia de épico/lendário em 10 baús.
  - **Companheiros com raridade, nível e bônus** (`scripts/companheiros.gd`):
    pedaços dos baús (10 = ganha o doce; mais pedaços + moedas = nível até 5).
    Só o companheiro escolhido dá bônus (açúcar, moedas, tempo, ajuda grátis,
    Doce Match, gorjeta, XP). A coleção mostra raridade (borda colorida),
    nível, bônus, pedaços e o botão MELHORAR.
  - **Missões** (`scripts/missoes.gd`, tela `cenas/missoes.*`): 3 do dia e 3 da
    semana (sorteadas pela data), RESGATAR dá moedas + XP, as 3 dão baú;
    prêmio por entrar em 7 dias seguidos (7º = baú de ouro).
  - **Nível do jogador** (`scripts/experiencia.gd`): XP de tudo; subir de
    nível dá baú. Resultado do quiz mostra "+1 BAÚ" e "+XP".
  - **Na tela inicial e na vila**: nível + botões MISSÕES e BAÚS com bolinha
    vermelha (`componentes/botoes_progresso.gd`). Na vila, "!" pulando em
    cima do Laboratório (baú pronto) e da Confeitaria (bandeja cheia).
  - Tabelas em `docs/economia.md`. Ideias para depois: eventos temporários
    (semana do Excel), mais fases no laboratório, conquistas dos baús.
- 26/09: **Laboratório do Office** (pedido do Sávio, primeira parte do plano
  "estilo Vikings Rise": aventura + recompensas). Prédio novo na vila (um
  computador gigante com teclado de degrau e frasco no telhado) e botão no
  menu dos níveis. Tutorial da vila: Escola → Laboratório → Confeitaria →
  Fliperama.
  - Mapa de aventura (`cenas/laboratorio.*`): 3 capítulos × 8 fases (a 8ª é
    o CHEFE, com várias tarefas e corações), 3 estrelas por fase, baú no
    meio e no fim de cada capítulo (abre tremendo; 15% de SORTE GRANDE).
  - Fases práticas (`cenas/lab_fase.*`): **Excel** com planilha e barra de
    fórmulas (tocar nas células escreve o endereço; tocar em duas seguidas
    vira intervalo; botões para = ; : $ etc.) e **Word** com página e fita
    (N/I/S, alinhamentos, A-/A+, cores, TUDO, desfazer; atalhos do Word em
    português no computador).
  - `scripts/formulas.gd`: calcula fórmulas como o Excel em português
    (; entre argumentos, vírgula decimal, SOMA, MÉDIA, MÁXIMO, MÍNIMO, SE,
    CONT.SE, SOMASE, MÉDIASE, E, OU, ARRED, CONCATENAR, &, $...) e os erros
    #DIV/0!, #NOME?, #VALOR!, explicados para o aluno.
  - `scripts/documento_word.gd`: o documento (seleção, formatação, conferir
    tarefa; formatar a mais não vale). Fases em `dados/laboratorio.json`
    (a resposta certa é uma fórmula; o jogo calcula o valor esperado).
  - Um teste resolve as 24 fases sozinho (nenhuma fica impossível).
  - Obs.: o teste das telas do laboratório deixa um aviso "1 RID ... leaked
    at exit" no fim (inofensivo; investigar se incomodar).
  - **Próximos passos combinados:** (2) baú surpresa com raridades e
    companheiros com bônus (fragmentos, garantia de épico); (3) missões do
    dia/semana, nível do jogador e avisos na vila. APK ainda não gerado.
- 25/09 (pedido "pode fazer tudo, só não vamos colocar na Play Store ainda"),
  tudo gravado no GitHub; **APK e executável da 0.9.0 publicados** (APK ~94 MB, perto do limite de 100 MB do GitHub):
  - **Doce Match custa 40 de açúcar** por partida (sem açúcar, manda para o
    quiz) e tem botão no menu dos níveis; placar com recorde e açúcar.
  - **Qualidade gráfica** em Configurações (BAIXA/MÉDIA/ALTA,
    `scripts/qualidade.gd`): grama, flores, sombras, escala do 3D e
    antisserrilhado. Padrão: MÉDIA no celular, ALTA no computador.
  - **Sons novos** sintetizados por nós (`ferramentas/gerar_sons.py`):
    moeda, estouro, porta, passo, pulo, construir, caixa; até 8 efeitos ao
    mesmo tempo.
  - **Economia balanceada**: `docs/economia.md`.
  - **Tutorial de primeira vez na vila**: seta amarela na porta do próximo
    prédio + dica no topo (Escola se nunca jogou o quiz -> Confeitaria se
    não construiu máquina -> Fliperama se nunca jogou o Doce Match; some
    depois). `Vila.proximo_passo()`.
  - **150 perguntas** (eram 60): 30 novas por nível, ids f21–f50, m21–m50,
    d21–d50, com explicação. **Pedir para a equipe/professor revisar as
    novas**, principalmente os atalhos do Office em português (Ctrl+N
    negrito, Ctrl+B salvar, Ctrl+T selecionar tudo, Ctrl+E/J/G/Q
    alinhamentos, Ctrl+U substituir).
  - Fora por enquanto (pedido do Sávio): publicar na Play Store (AAB, página
    da loja, política de privacidade).
- 25/09 (depois da 0.8.0): andar com as duas pernas (bug: só uma mexia),
  pé levantando e passos no ritmo do chão; jujubas/colunas sólidas, bonecos
  na camada 2 e câmera com "bolinha" para não entrar em paredes; botão
  JOGAR O QUIZ na cozinha (pulsa sem açúcar); câmera olha para cima/baixo;
  "carregando" com o doce; foto até o 3D aparecer; partes lisas com madeira
  pintada/metal reais; **Doce Match** no Fliperama. APK ainda não gerado.
- **Economia**: tabela de ganhos e preços em `docs/economia.md` (tudo começa
  no quiz; cozinha e Doce Match trocam açúcar por moedas na mesma faixa).
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

- **Testes:** `godot/testes/rodar.sh` (1.724 verificações; falha também em erro
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
- `dados/perguntas.json`: 150 perguntas (id, assunto, enunciado, alternativas,
  resposta, explicacao)
- `testes/`: testes automáticos

## Histórico resumido

- Refatoração da versão pygame e publicação web (pygbag). Depois, reconstrução
  no Godot 4 com telas novas, personagens gerados por IA (só doces) e mascote 3D.
- Correções de desempenho: animações contínuas desligadas em aparelhos sem
  placa de vídeo, decoração desenhada uma vez só.
- Etapas 1 a 5 acima (commits `3d04f15`, `74671c4`, `64a73a1`, `cf8abf2`,
  `83c4f4e`, `f618ce3`).
