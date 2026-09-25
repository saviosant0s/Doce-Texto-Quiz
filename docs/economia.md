# Economia do jogo (moedas e açúcar)

Regra de ouro: **tudo começa no quiz**. O quiz dá moedas e açúcar; a
confeitaria e o Doce Match transformam açúcar em moedas, mais ou menos na
mesma taxa (0,4 a 1,4 moeda por açúcar), então nenhum minijogo vira atalho
para ganhar sem estudar. Valores no código: `scripts/jogo.gd`,
`scripts/confeitaria.gd`, `scripts/doce_match.gd`, `scripts/colecao.gd`,
`scripts/conquistas.gd`.

## Entradas

| De onde | Moedas | Açúcar |
|---|---|---|
| Quiz fácil (por acerto) | 5 | 10 |
| Quiz médio (por acerto) | 8 | 10 |
| Quiz difícil (por acerto) | 12 | 10 |
| Quiz: por estrela | 10 | — |
| Revisão dos erros (por acerto) | 3 | 10 |
| Conquistas (16) | 10 a 150 cada (~600 no total) | — |
| Primeira máquina da cozinha | — | 50 (presente) |

Partidas típicas: fácil 7/10 com 1 estrela = 45 moedas + 70 de açúcar; médio
8/10 com 2 estrelas = 84 + 80; difícil 9/10 com 2 estrelas = 128 + 90.

## Transformar açúcar em moedas

| Onde | Custo em açúcar | Moedas | Moedas por açúcar |
|---|---|---|---|
| Brigadeiro (cozinha) | 5 por doce | 2 a 4 por doce + 2 de gorjeta por cliente | 0,4 a 1,2 |
| Maçã do amor | 8 | 4 a 8 + gorjeta | 0,5 a 1,1 |
| Cupcake | 12 | 7 a 13 + gorjeta | 0,6 a 1,2 |
| Doce Match (partida) | 40 | pontos/100 + 8 por estrela (~15 a 55) | 0,4 a 1,4 |

## Gastos

| No quê | Preço |
|---|---|
| Doces da coleção (9 à venda) | 100 a 600 (3.450 no total) |
| Ajudas no quiz | 20 (+10 s) e 30 (tirar 2 alternativas) |
| Máquinas da cozinha | brigadeiro grátis, maçã 150, cupcake 300 |
| Melhorias das máquinas | 100+250, 200+400, 300+600 (1.850 no total) |
| Carregar mais doces | 120 e 300 |

Para ter tudo: ~6.200 moedas, cerca de 45 partidas do quiz (contando o açúcar
virando moedas). Se ficar rápido ou lento demais, ajuste primeiro as moedas por
acerto do quiz (`Jogo.MOEDAS_POR_ACERTO`) — o resto acompanha.
