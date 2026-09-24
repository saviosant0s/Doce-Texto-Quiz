# Personagens com IA — guia e prompts

Como gerar personagens mais realistas (estilo do fantasma de chocolate branco
da tela de carregamento) e colocar no jogo.

## Como colocar no jogo

1. Gere a imagem (quadrada, 1024×1024 ou maior).
2. Fundo **transparente** (PNG). Se a ferramenta não fizer, use fundo
   **branco liso**: o Claude remove o fundo depois.
3. Salve com o **nome do arquivo** da tabela abaixo em
   `godot/assets/personagens/`. Um PNG com o mesmo nome substitui o desenho
   atual automaticamente (não precisa mexer no código).

> **Direitos (INPI):** antes de usar, confira nos termos da ferramenta se as
> imagens geradas podem ser usadas comercialmente e se os direitos ficam com
> vocês. Anote qual ferramenta e qual prompt geraram cada imagem.

## Refazer em alta qualidade (pendência atual)

Os personagens atuais foram recortados de uma prancha com todos juntos, então
cada um ficou pequeno (~300 px). Para ficar nítido, gere **um por imagem**:

1. Anexe a prancha "PERSONAGENS ORIGINAIS DO DOCE TEXTO QUIZ" (versão 3D) como referência.
2. Cole o prompt abaixo trocando `[NOME DO PERSONAGEM]`.
3. Um personagem por vez. Mande as imagens para o Claude (ele remove o fundo e
   coloca no jogo) ou salve com o nome da tabela em `godot/assets/personagens/`.

```
Using the attached image as reference, create a single high-resolution image
of ONLY the [NOME DO PERSONAGEM] character. Keep it exactly the same design,
colors, face, pose and 3D render style as in the reference.

Requirements:
- Square image, 2048x2048 pixels
- Only one character, centered, full body (head to shoes), filling about
  80% of the image height
- Plain solid white background (or transparent PNG if possible)
- No text, no labels, no frame, no card, no shadow on the background
- Sharp details, soft studio lighting, high quality 3D render
```

| `[NOME DO PERSONAGEM]` | Salvar como | Onde aparece |
|---|---|---|
| cereal box mascot (yellow and pink box with a bowl of cereal) | `mascote_cereal.png` | Tela inicial |
| green striped wrapped candy | `doce_facil.png` | Nível fácil |
| candy corn | `doce_medio.png` | Nível médio |
| red and white peppermint candy | `doce_dificil.png` | Nível difícil |
| red apple | `maca_noob.png` | Título Noob |
| pink frosting cupcake with yellow paper cup | `cupcake_pro.png` | Título Pro |
| chocolate bar with red shoes | `chocolate_mestre.png` | Título Mestre |
| sad brigadeiro (chocolate truffle with sprinkles) | `brigadeiro_triste.png` | "Você não é um doceiro" |
| white chocolate ghost | `fantasma_chocolate.png` | Carregamento |
| chocolate popsicle | `picole_chocolate.png` | Extra |
| strawberry cupcake with chocolate cup | `cupcake_morango.png` | Extra |

Dicas: se a IA mudar o personagem, acrescente "Do not change the character
design. Same proportions and colors as the reference."; se aparecer texto ou
moldura, gere de novo com "no text, no border".

## Prompt base para criar personagens novos (copie e troque só o `[PERSONAGEM]`)

Os geradores costumam entender melhor em inglês:

```
3D render of a cute anthropomorphic [PERSONAGEM], realistic food textures,
glossy and appetizing like professional food photography, big friendly eyes
and a small happy smile on the candy itself, thin arms with white cartoon
gloves, short legs with rounded purple sneakers, full body, standing, 3/4
view, centered, soft studio lighting, subtle soft shadow under the feet,
isolated on a plain white background, no text, no watermark, no logo,
high detail, square image
```

**Para manter todos com a mesma cara:** gere o primeiro, escolha o melhor e
use-o como **imagem de referência** nos próximos ("same style, lighting and
proportions as the reference image"). Mantenha o mesmo ângulo e a mesma luz.

## Personagens

| Arquivo | Onde aparece | `[PERSONAGEM]` |
|---|---|---|
| `doce_facil.png` | Nível fácil | green hard candy wrapped in shiny striped green cellophane, twisted wrapper on top |
| `doce_medio.png` | Nível médio | candy corn with white tip, yellow middle and orange base, sugary matte texture |
| `doce_dificil.png` | Nível difícil | round red and white peppermint swirl hard candy, glossy |
| `maca_noob.png` | Título Noob | shiny red candy apple (maçã do amor) with a green leaf |
| `cupcake_pro.png` | Título Pro | cupcake with swirled pink frosting, colorful sprinkles, a cherry on top, yellow paper cup |
| `chocolate_mestre.png` | Título Mestre | milk chocolate bar half unwrapped from a red wrapper, visible chocolate squares, proud confident pose |
| `brigadeiro_triste.png` | "Você não é um doceiro" | SAD brigadeiro (Brazilian chocolate truffle ball) covered in chocolate sprinkles, in a pink paper cup, teary eyes, arms down |
| `brigadeiro_feliz.png` | Extra | happy brigadeiro covered in chocolate sprinkles, in a pink paper cup, arms up celebrating |
| `pirulito.png` | Extra | pink and white swirl lollipop on a stick |
| `rosquinha.png` | Extra | donut with pink icing and rainbow sprinkles |
| `sorvete.png` | Extra | mint ice cream scoop on a waffle cone with a cherry |
| `picole.png` | Extra | orange and red popsicle on a wooden stick |
| `macaron.png` | Extra | lavender French macaron with cream filling |
| `pudim.png` | Extra | Brazilian caramel flan (pudim de leite) with dripping caramel, on a plate |
| `jujuba.png` | Extra | green gummy candy drop covered in sugar crystals |
| `bolo.png` | Extra | slice of layered strawberry cream cake with a strawberry on top |

Para o **brigadeiro triste**, troque no prompt base "small happy smile" por
"sad face, teary eyes, frowning mouth".

## Mascote da tela inicial em 3D (para girar com o dedo)

O jogo já está pronto para um modelo 3D: se existir o arquivo
`godot/assets/mascote_3d/mascote.glb`, a tela inicial troca a imagem pelo
modelo 3D, que gira ao arrastar o dedo.

1. **(Opcional, melhora o resultado)** Redesenhe o mascote original em 3D com
   IA, enviando a imagem `godot/assets/personagens/mascote_cereal.png` como
   referência e este prompt:

   ```
   Redraw this exact character as a 3D render: same cereal box body (yellow
   front, pink sides), same face, same bowl of colorful cereal rings, same
   white cartoon gloves, pink legs and purple sneakers. Glossy cardboard and
   plastic materials, soft studio lighting, full body, front view, isolated
   on a plain white background, no text, no watermark.
   ```

2. Leve essa imagem a uma ferramenta de **imagem → modelo 3D** (por exemplo
   Meshy, Tripo, Rodin/Hyper3D ou Hunyuan3D, que é gratuito e de código aberto).
   Imagem de frente e com fundo liso dá o melhor resultado.
3. Exporte em **GLB com texturas** (de preferência até ~20 MB).
4. Salve como `godot/assets/mascote_3d/mascote.glb` (ou mande no chat).

"Várias fotos de ângulos diferentes" também funciona em algumas dessas
ferramentas (entrada multi-vista), mas geradores de imagem comuns raramente
mantêm o personagem idêntico entre as fotos, então o caminho pelo modelo GLB
costuma ser melhor.
