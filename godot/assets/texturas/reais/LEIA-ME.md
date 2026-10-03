# Texturas reais (fotos escaneadas) — licença CC0

Materiais de domínio público (CC0: uso livre, inclusive comercial, sem precisar
de atribuição). Resolução 1K. Cada material tem `_cor` (cor/detalhe),
`_relevo` (normal map, OpenGL) e `_arm` (R = sombreado dos cantos/AO,
G = aspereza, B = metal).

| Arquivo | Original | Fonte |
|---|---|---|
| grama | Grass001 | ambientCG — https://ambientcg.com/view?id=Grass001 |
| areia | coast_sand_01 | Poly Haven — https://polyhaven.com/a/coast_sand_01 |
| calcamento | patterned_paving | Poly Haven — https://polyhaven.com/a/patterned_paving |
| reboco_barro | clay_plaster | Poly Haven — https://polyhaven.com/a/clay_plaster |
| reboco | white_stucco | Poly Haven — https://polyhaven.com/a/white_stucco |
| tijolos | concrete_brick_wall_001 | Poly Haven — https://polyhaven.com/a/concrete_brick_wall_001 |
| ardosia | roof_slates_02 | Poly Haven — https://polyhaven.com/a/roof_slates_02 |
| madeira | kitchen_wood | Poly Haven — https://polyhaven.com/a/kitchen_wood |
| piso_cozinha | marble_tiles | Poly Haven — https://polyhaven.com/a/marble_tiles |
| metal | metal_plate | Poly Haven — https://polyhaven.com/a/metal_plate |
| madeira_pintada | fine_grained_wood | Poly Haven — https://polyhaven.com/a/fine_grained_wood |

As fotos de cor foram clareadas e, quase todas, passadas para tons de cinza
(`ferramentas/preparar_texturas_reais.py`), para a cor do jogo pintar por cima
(ex.: reboco branco vira a parede lilás). Uso no código: `scripts/texturas.gd`.
