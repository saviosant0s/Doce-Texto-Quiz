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
