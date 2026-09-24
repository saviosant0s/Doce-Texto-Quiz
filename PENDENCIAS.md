# Pendências

Itens em aberto do projeto. Marque com [x] quando resolver.

## Conteúdo
- [x] Atualizar os @ do Instagram da tela "Sobre" (`godot/cenas/sobre.gd`,
      constante `PERFIS`): @naatyrch, @savio.rocha_, @ifba.valenca.
- [ ] Atualizar o @ da Thalita (ainda está o antigo, @thaly_gilmore).
- [ ] Confirmar o nome do orientador "Cristian Lins" (nos créditos antigos
      aparecia só "Cristian").
- [x] Reescrever o banco de perguntas: agora são 60 (20 por nível), cada partida
      sorteia 10 e embaralha as alternativas.
- [ ] Pedir para um(a) professor(a) revisar as 60 perguntas (`godot/dados/perguntas.json`)
      e as dicas da tela de carregamento (`godot/cenas/carregamento.gd`).

## Personagens
- [x] ~~Refazer as imagens 2D dos personagens em alta qualidade~~: não é mais
      necessário. Todos os doces agora são 3D feitos no próprio jogo
      (`godot/scripts/doces_3d.gd`); as telas usam fotos deles
      (`godot/assets/doces_3d/fotos`, geradas por `ferramentas/gerar_fotos_3d.sh`).
- [ ] Só o mascote (caixa de cereal) ainda usa imagens de IA nas faces
      (`godot/assets/mascote_3d`) e na tela "Sobre". Para trocar por um modelo 3D,
      salvar `godot/assets/mascote_3d/mascote.glb`.

## Direitos (antes do registro no INPI)
- [x] Trocar a imagem do brigadeiro triste (tinha marca d'água).
- [ ] Confirmar os termos de uso da ferramenta de IA usada nos personagens (uso
      comercial e titularidade) e anotar ferramenta + prompt de cada imagem.
- [ ] Confirmar a origem/licença das 3 músicas novas (`godot/assets/sons/musica_1..3.ogg`,
      enviadas em 24/09/2026) e dos sons de acerto/erro. Anotar autor e licença de cada uma.
- [ ] Confirmar a origem/licença dos personagens (vieram das imagens de 2023).

## Funcionalidades
- [ ] Botão "Apoie" nos créditos ainda mostra "Disponível em breve".
- [ ] Gerar o APK para Android.

## Android
- [ ] Testar o APK em celulares de verdade (um simples e um bom): instalação,
      tela deitada, botão voltar, som, desempenho e se o progresso fica salvo
      ao fechar e abrir. Download: https://saviosant0s.github.io/Doce-Texto-Quiz/apk/doce-texto-quiz.apk
- [ ] Guardar a keystore (`doce_texto_quiz.keystore`) e a senha em lugar seguro.
      Sem elas não dá para publicar atualizações na Play Store.
- [ ] Para a Play Store: conta de desenvolvedor, política de privacidade (o jogo
      não coleta dados), prints e formato AAB (exige o build com Gradle).
