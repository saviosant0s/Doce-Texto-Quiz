# Andamento do projeto

Diário do que foi feito, do que falta e de onde parou, para qualquer pessoa (ou
uma nova sessão do Claude) continuar o trabalho sem depender da conversa.
**Atualize este arquivo a cada etapa concluída.**

- Código principal: branch `main` (trabalho novo em branches, com PR)
- Jogo no navegador: https://saviosant0s.github.io/Doce-Texto-Quiz/
- APK: https://saviosant0s.github.io/Doce-Texto-Quiz/apk/doce-texto-quiz.apk
- Versão atual: 0.5.0 (Android, Windows e navegador)
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

### Futuro: Doce Match (NÃO fazer agora)
Minijogo no estilo Candy Crush dentro do FLIPERAMA da vila: trocar peças
vizinhas para alinhar 3 iguais. No lugar dos doces, **símbolos de informática
feitos por nós** (folha com "W" azul, planilha com "X" verde, gráfico, célula,
atalho de teclado, disquete...). **Não usar os logos oficiais do Word/Excel**
(marcas registradas da Microsoft; atrapalharia o registro no INPI).

## Onde parou

- Última coisa feita: **melhorias da Vila dos Doces** (andar com pulo e
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

- **Testes:** `godot/testes/rodar.sh` (620 verificações; falha também em erro
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
