# Desempenho do Doce Texto Quiz (Godot 4.7)

Pesquisa de 08/10/2026 (documentação oficial do Godot e guias de otimização)
e o que foi aplicado no jogo. Para medir: indicador de desempenho nas
Configurações (FPS, memória, desenhos por quadro) e, no computador,
`--desempenho` e `--perfil=4` da ferramenta de captura
(`scripts/ferramentas/captura.gd`).

## O que pesa num jogo 3D em Godot (resumo da pesquisa)

1. **Desenhos por quadro (draw calls).** Cada peça com malha/material próprio
   é um desenho. Juntar peças paradas em blocos (o jogo faz isso com
   `JuntarMalhas`), usar MultiMesh para coisas repetidas e esconder o que está
   longe (`visibility_range_end`) são as maiores economias. Guias de celular
   falam em ~100 a ~500 desenhos por quadro como faixa segura.
2. **Luz e sombra em tempo real.** Sombra do sol com 4 divisões desenha a cena
   várias vezes; 2 divisões ou ortogonal e um mapa de sombra menor ajudam muito
   em placa integrada.
3. **Resolução e antisserrilhado.** Desenhar o 3D menor que a tela
   (`scaling_3d_scale`) e MSAA mais baixo são os ajustes mais diretos quando a
   placa de vídeo é o gargalo (o caso dos notebooks com placa Intel).
4. **Travadas de shader.** Desde o Godot 4.4 os shaders são compilados no
   carregamento (ubershaders); o que aparece pela primeira vez no meio do jogo
   ainda pode travar um instante. O jogo "aquece" a vila atrás da cortina.
5. **Física.** Física a 120 passos por segundo custa o dobro; quando o quadro
   atrasa, o Godot roda vários passos de física de uma vez (e atrasa mais).
6. **Scripts.** Tipar as variáveis, guardar nós em variáveis (não procurar a
   cada quadro) e não criar objetos a cada quadro.

## Medições (sem placa de vídeo, só processador)

Todas as telas ficam abaixo de ~7 ms de processador por quadro (scripts,
física e motor): o gargalo nos aparelhos fracos é a **placa de vídeo**.

Desenhos por quadro na qualidade MÉDIA (a de início em placa integrada ou com
até 8 GB), 1280x720, medidos com `--desempenho` em 09/10/2026:

| Tela | Desenhos | Triângulos | Observação |
|---|---|---|---|
| Vila (câmera de perto) | 638 | 520 mil | a mais pesada: blocos da vila (218 mil) e regiões (até 60 m) |
| Vila (de cima) | 571 | 491 mil | |
| Corrida | 303 | 189 mil | |
| Doce Match | 137 | 2 mil | 2D |
| Batalha | 92 | 15 mil | depois de juntar as peças dos doces (antes: centenas) |
| Fábrica | 48 | 3 mil | 2D |

## O que foi feito (0.16.0)

| Onde | Antes | Agora |
|---|---|---|
| Doces 3D da batalha, coleção, início e carregamento (`Visor3D`) | antisserrilhado 4x sempre, até 3x a resolução da tela, cada pedacinho do doce (cada granulado) um desenho | antisserrilhado e resolução pela qualidade escolhida; as peças de cada parte do doce juntadas em um bloco |
| Qualidade inicial no computador | sempre ALTA | MÉDIA em placa integrada (Intel, AMD "Graphics") ou com até 8 GB de memória |
| Vigia de lentidão | não havia | nas telas 3D, abaixo de ~33 FPS por uns segundos, os gráficos descem um nível sozinhos (com aviso) |
| Física | acompanhava telas de 90/120 Hz; até 4 passos por quadro | 60 por segundo fora da ALTA; no máximo 2 passos por quadro |
| Sombra do sol | mapa 4096 | 4096 na ALTA, 2048 nas outras |
| Brilho e ajuste de cor | sempre | desligados na BAIXA |
| Materiais "realistas" | relevo e verniz em tudo | BAIXA: sem relevo nem verniz; MÉDIA: relevo sem verniz; ALTA: tudo |
| Texturas | fotos de 1024 px | 512 px (as de aspereza, 256): ~24 MB a menos no APK |

## Lag na luta contra o chefão (09/10/2026)

O lag relatado era na luta contra o chefão, na praça da vila. A luta acrescenta pouco
desenho (~+10%: 632 → 699 desenhos), mas cada efeito criava materiais e
malhas novos (bolas de bala e de chocolate, faíscas, a chuva de doces do fim,
os pingos de chocolate do doce sujo), que a vila não tinha preparado no
carregamento: a placa de vídeo montava o shader na hora, e a tela parava um
instante. Medido com `--travadas` (conta as montagens de shader por quadro,
`RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_*`), numa luta de 20 s
com 2 erros:

| | Montagens no meio da luta | Que travam a tela ("desenho"/"superfície") |
|---|---|---|
| Antes | 51 shaders em 15 momentos (3 a cada ataque, 9 no primeiro erro) | sim |
| Depois | 5 "variações" (o Godot monta em segundo plano) | nenhuma |

O que mudou:
- Bolas, faíscas, chuva de doces e pingos usam malha e material criados uma vez
  só (antes, novos a cada ataque); as bolas têm 400 triângulos (eram 4 mil).
- A vila, atrás da cortina do carregamento, desenha uma vez cada efeito da luta,
  o doce sujo de chocolate e a luz vermelha do chefão (`Vila.aquecer`,
  `LutaChefao.aquecer_efeitos`).
- A luz vermelha do chefão ficava ligada (com força zero) o tempo todo na praça;
  agora só liga quando ele fica bravo.

## Gráficos mais realistas sem pesar (09/10/2026)

Pedido: "deixe super realista", num PC de 8 GB com placa integrada e sem
voltar o lag. A escolha foi gastar onde quase não custa (`scripts/visual_realista.gd`):

| O quê | Custo | Qualidade |
|---|---|---|
| Céu com sol, halo e nuvens (`tema/ceu_doce.gdshader`) | o céu já era desenhado; sem `TIME`, o reflexo do céu (luz ambiente) só é refeito quando a hora muda | MÉDIA e acima |
| Líquidos com ondinhas e céu refletido (`tema/liquido_doce.gdshader`) | 1 shader para os 5 líquidos; o reflexo é a cor do céu calculada no próprio shader (sem câmera extra nem SSR) | MÉDIA e acima |
| Sol que anda (baixo e dourado de manhã e no fim da tarde, sombras compridas) | nenhum: a luz já era atualizada a cada 2 s | todas |
| Sombra macia (filtro MEDIUM) e fundo longe desfocado | um passe de desfoque | ALTA |
| SSAO, SSIL, SSR, névoa volumétrica, sombra de 4 faixas | pesado (renderizador Forward+, o jogo reinicia) | ULTRA (só computador com placa dedicada e mais de 8 GB) |

Desenhos por quadro na vila: 632 → 636. O ULTRA não aparece no celular nem
no navegador, e sem o Forward+ ele vale como ALTA; se o jogo ficar lento no
ULTRA, o vigia de lentidão desce para ALTA e desliga os efeitos na hora.

Ficaram de fora a névoa com a cor do céu (`fog_aerial_perspective`) e o brilho
do sol na névoa (`fog_sun_scatter`): no renderizador Mobile, com qualquer uma
das duas ligada, os postes, as pedrinhas e a forminha do doce perdiam a luz do
sol e ficavam arroxeados (achado comparando pixels dos prints com cada ajuste
ligado e desligado).

## Carro de F1 na corrida (11/10/2026)

O carro do jogador virou um F1 feito no Blender (assets/carros/carro_f1.glb,
37,8 mil triângulos; o Godot gera versões mais leves para longe). Medido na
corrida com `--desempenho` (os números variam um pouco com a posição dos rivais):

| Qualidade | Kart (antes) | F1 |
|---|---|---|
| MÉDIA | 307 desenhos, 183 mil triângulos | 278 desenhos, 215 mil triângulos |
| ALTA | 303 desenhos, 265 mil triângulos | 284 desenhos, 290 mil triângulos |

Menos desenhos (o kart era feito de muitas peças; o F1 é uma malha com um
material por cor, mais as quatro rodas) e uns 30 mil triângulos a mais. A
primeira versão tinha 53,7 mil; os sidepods e a cobertura com menos subdivisão,
rodas de 40 lados e asas com menos segmentos baixaram para 37,8 mil quase sem
diferença na imagem.

## ULTRA no celular (11/10/2026)

No celular o ULTRA usa o mesmo renderizador (Mobile), com tudo no máximo e o F1
realista. Medido com `--ultra_celular --desempenho`:

| Tela | ALTA | ULTRA (celular) |
|---|---|---|
| Corrida | 278 desenhos, 279 mil triângulos | 292 desenhos, 382 mil triângulos |
| Vila (câmera perto) | 647 desenhos, 861 mil triângulos | 647 desenhos, 891 mil triângulos |

Na corrida, a diferença vem quase toda da sombra do sol: cada faixa de sombra
desenha a cena de novo. Com 4 faixas (como no ULTRA do computador), a corrida ia a
623 mil triângulos; com 2 faixas no celular, fica em 382 mil. O F1 do ULTRA tem 65
mil triângulos (o normal, 38 mil) e a sonda de reflexo é tirada uma vez só, na
largada. Se ficar lento, o vigia de lentidão desce para a ALTA.

## Carregamento mais rápido (17/10/2026)

Pedido: "a tela de carregamento demora muito e aparece várias vezes". Medido só
com o processador (`--headless`; sem placa de vídeo os quadros não contam), do
toque até a tela nova aberta:

| Troca | Antes | Agora |
|---|---|---|
| Prédio → vila (voltar) | 1,5 a 1,7 s + aquecer na placa | 0,3 s (só a cortina) |
| Vila → cozinha | 0,96 s | 0,57 s |
| Vila → corrida | 1,34 s | 0,94 s |
| Vila (primeira vez) | 1,5 a 1,7 s | igual |

- **A vila fica guardada** (`Telas._guardar_vila`): ao entrar num prédio, a vila
  montada sai da árvore e fica na memória (~15 a 30 MB); ao voltar, é a mesma
  vila, sem montar as peças, juntar as malhas nem "aquecer" os shaders de novo (no
  celular, era a parte mais demorada). O doce sai pela porta e o topo, os avisos,
  a história e o céu são atualizados (`Vila.reaparecer`). Se algo que a vila
  montou mudou desde a montagem (doce companheiro, nível dele, qualidade, também
  a que o vigia de lentidão baixou, evento, dia, tutorial, coleção, progresso
  apagado ou visita, animações), ela é montada de novo (`Vila.assinatura`). Não
  guarda no navegador nem em aparelhos com menos de 3,5 GB.
- **A barra de carregamento não espera mais à toa:** ela andava no mínimo 0,6 s
  mesmo com a cena já pronta; agora 0,2 s.

O que ainda pesa na primeira vez da vila (processador): juntar as malhas
(~0,2 a 0,8 s), as regiões (~0,1 a 0,3 s), o bairro e o evento.

## Próximos passos possíveis

- Vila: menos triângulos nos blocos da vila (versões simplificadas dos prédios
  de longe, com `visibility_range`) e sombra só dos objetos grandes na MÉDIA.

- Medir no aparelho de verdade com o indicador de desempenho ligado e anotar
  FPS e desenhos por tela (vila, corrida, batalha, Doce Match).
- Trocar as partículas de CPU (`CPUParticles3D`) por GPU onde houver muitas.
- Vila: guardar os blocos já juntados em disco (hoje a vila junta as peças a
  cada vez que abre; a cortina de carregamento esconde, mas demora).

## Fontes

- [Optimizing 3D performance (documentação do Godot)](https://docs.godotengine.org/en/latest/tutorials/performance/optimizing_3d_performance.html)
- [Reducing stutter from shader (pipeline) compilations (Godot 4.4+)](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
- [Visibility ranges (HLOD)](https://docs.godotengine.org/en/4.4/tutorials/3d/visibility_ranges.html)
- [Resolution scaling](https://docs.godotengine.org/en/4.2/tutorials/3d/resolution_scaling.html)
- [Godot 4.1 rendering priorities (sombras com divisões)](https://godotengine.org/article/rendering-priorities-4-1/)
- [Optimizing a 3D scene (GDQuest)](https://www.gdquest.com/tutorial/godot/3d/optimization-3d/)
- [Optimizing GDScript code (GDQuest)](https://www.gdquest.com/library/optimization_code)
- [Optimizing 3D scenes in Godot on Arm GPUs](https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/optimizing-3d-scenes-in-godot-on-arm-gpus-part-2)
- [Optimizing Godot for Mobile — A Field Guide](https://slicker.me/godot/mobile-optimization.html)
- [Godot 4.4 com Jolt Physics](https://gamefromscratch.com/godot-4-4-gets-native-jolt-physics-support/)
