# Andamento do projeto

Diário do que foi feito, do que falta e de onde parou, para qualquer pessoa (ou
uma nova sessão do Claude) continuar o trabalho sem depender da conversa.
**Atualize este arquivo a cada etapa concluída.**

- Branch de trabalho: `claude/amazing-hamilton-322u3n` (ainda não juntada na `main`)
- Jogo no navegador: https://saviosant0s.github.io/Doce-Texto-Quiz/
- APK: https://saviosant0s.github.io/Doce-Texto-Quiz/apk/doce-texto-quiz.apk
- Versão atual: 0.4.0
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
| 6 | Parte técnica: testes automáticos no GitHub (Actions), limpeza, juntar na `main` | ⏳ **próxima** |

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

## Onde parou

- Última coisa feita: nitidez no celular (filtro de textura era "Nearest
  Mipmap", agora "Linear Mipmap"; mascote 3D desenhado na resolução real da
  tela), cartão de nível bloqueado com o mesmo tamanho dos outros, sem a dica
  "arraste para girar" na tela inicial. APK e site publicados.
- Nada pela metade. Próximo passo: item 1 da etapa 6.

## Como trabalhar no projeto

- **Testes:** `godot/testes/rodar.sh` (487 verificações; falha também em erro
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
