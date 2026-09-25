# Economia do jogo (moedas e açúcar)

Regra de ouro: **tudo começa no quiz**. O quiz dá moedas e açúcar; a
confeitaria e o Doce Match transformam açúcar em moedas, mais ou menos na
mesma taxa (0,4 a 1,4 moeda por açúcar), então nenhum minijogo vira atalho
para ganhar sem estudar. Valores no código: `scripts/jogo.gd`,
`scripts/confeitaria.gd`, `scripts/doce_match.gd`, `scripts/laboratorio.gd`, `scripts/colecao.gd`,
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
| Laboratório: fase feita (1ª vez) | 10 + 5 por estrela | 20 |
| Laboratório: chefe (1ª vez) | 30 + 5 por estrela | 50 |
| Laboratório: estrela nova ao repetir | 5 por estrela | — |
| Laboratório: baú do meio do capítulo (3) | 30 a 60 × (1 / 1,25 / 1,5) | 20 a 40 × idem |
| Laboratório: baú do chefe (3) | 80 a 150 × idem | 50 a 80 × idem |

Baús: 15% de chance de "SORTE GRANDE" (tudo em dobro). O Laboratório inteiro
(24 fases, 72 estrelas, 6 baús) dá cerca de 1.300 moedas e 1.000 de açúcar, só
uma vez: ele também é estudo (fórmulas e formatação na prática).

Partidas típicas: fácil 7/10 com 1 estrela = 45 moedas + 70 de açúcar; médio
8/10 com 2 estrelas = 84 + 80; difícil 9/10 com 2 estrelas = 128 + 90.

## Baús surpresa, missões e nível (tudo sem compra)

| De onde | O quê |
|---|---|
| Partida do quiz aprovada | 1 baú de DOCE (até 5 por dia) |
| Missão do dia (3 por dia) | 20 moedas + 25 XP; as 3 = baú de PRATA |
| Missão da semana (3 por semana) | 60 moedas + 80 XP; as 3 = baú de OURO |
| Prêmio por entrar (dias seguidos) | 20 moedas, 30 açúcar, 40 moedas, baú de doce, 60 moedas, 60 açúcar, baú de OURO |
| Subir de nível | baú de PRATA (a cada 5 níveis, OURO) |

Baús: doce 2 itens, prata 3, ouro 4. O 1º item é sempre pedaço de doce; os
outros podem ser pedaços (60%), moedas (25%: 10–25 / 25–50 / 50–100) ou açúcar
(15%). Chance de raridade (comum/raro/épico/lendário): doce 70/25/4,5/0,5;
prata 50/35/13/2; ouro 30/40/24/6. Garantia: épico ou lendário em até 10 baús.
10 pedaços = ganha o doce; melhorar: 10+50, 20+100, 30+200, 50+400 (pedaços +
moedas), até o nível 5.

XP: acerto no quiz 5 (revisão 3), fase do laboratório 30 (chefe 60, repetir
10), Doce Match 15, cliente na cozinha 2. Nível n → n+1: 100 + 40×(n−1) XP.

Bônus do companheiro (só o escolhido vale; raridade multiplica: 1 / 1,25 /
1,5 / 2): +10% a +30% de açúcar, de moedas no quiz, no Doce Match ou de XP;
+3 a +7 s por pergunta; +1 a +5 de gorjeta; 1 a 3 ajudas "tirar 2" grátis. Ver
`scripts/companheiros.gd`.

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
