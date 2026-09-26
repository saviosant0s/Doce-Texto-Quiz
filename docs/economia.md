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
| Presente de começo (e uma vez para quem já jogava) | — | 100 |
| Primeira máquina da cozinha | — | 50 (presente) |
| Vila: estrela cadente (uma por noite, pelo relógio) | 25 | 25 |
| Vila: gotas da chuva de granulado (12 por chuva; ~1 hora em 6) | — | 3 cada |
| Laboratório: fase feita (1ª vez) | 10 + 5 por estrela | 20 |
| Laboratório: chefe (1ª vez) | 30 + 5 por estrela | 50 |
| Laboratório: estrela nova ao repetir | 5 por estrela | — |
| Laboratório: baú do meio do capítulo (3) | 20 a 40 × (1 / 1,25 / 1,5) + 1 baú de PRATA | 20 a 40 × idem |
| Laboratório: baú do chefe (3) | 50 a 90 × idem + 1 baú de OURO | 50 a 80 × idem |

Baús: 15% de chance de "SORTE GRANDE" (tudo em dobro). O Laboratório inteiro
(40 fases, 120 estrelas, 10 baús; os números abaixo são dos 3 primeiros capítulos) dá cerca de 1.300 moedas e 1.000 de açúcar, só
uma vez: ele também é estudo (fórmulas e formatação na prática). Revisão de
27/09: os baús do laboratório dão menos moedas (cerca de 1.050 no total) e
trazem um baú surpresa (pedaços de doces).

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
outros podem ser pedaços (70%), moedas (18%: 10–25 / 25–50 / 50–100) ou açúcar
(12%). Chance de raridade (comum/raro/épico/lendário): doce 70/25/4,5/0,5;
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
| Doce Match (tentativa de um nível) | 30 | 1ª vitória: 10 + 5 por estrela (~15 a 25); estrela nova depois: 5 cada; baú de prata nos níveis 5, 10, 20, 25 e de ouro no 15 e 30 | 0 (perdeu) a 0,8 |

## Gastos

| No quê | Preço |
|---|---|
| Doces da coleção (21 à venda) | 100 a 800 (7.100 no total) |
| Ajudas no quiz | 20 (+10 s) e 30 (tirar 2 alternativas) |
| Máquinas da cozinha | brigadeiro grátis, maçã 150, cupcake 300 |
| Melhorias das máquinas | 100+250, 200+400, 300+600 (1.850 no total) |
| Carregar mais doces | 120 e 300 |

Para ter tudo: ~6.200 moedas, cerca de 45 partidas do quiz (contando o açúcar
virando moedas). Se ficar rápido ou lento demais, ajuste primeiro as moedas por
acerto do quiz (`Jogo.MOEDAS_POR_ACERTO`) — o resto acompanha.

## Ritmo (revisado em 27/09, com baús, missões e laboratório)

Jogador que entra todo dia e faz ~5 partidas: ~300 moedas do quiz + 60 das
missões do dia + ~25 das da semana + ~15 do prêmio por entrar + ~30 dos baús
≈ 430 moedas/dia. Gastos grandes: coleção 3.450, máquinas e melhorias ~2.300,
e melhorar os companheiros até o nível 5 (750 moedas + 110 pedaços cada, 13
doces ≈ 9.750 moedas). Coleção comprada em ~8 dias; tudo no máximo em ~5
semanas — bom para um bimestre de aulas. Se ficar rápido demais, baixe
`Missoes.PREMIO_DIA` e as moedas dos baús antes de mexer no quiz.

## Terrenos: evolução das construções (desde a 0.12.1)

Toda construção vai do nível 1 ao 5 e muda de forma a cada nível. Evoluir
custa moedas e leva tempo: 3 min (nível 2), 15 min (3), 1 h (4) e 4 h (5).
Um construtor só: uma obra por vez. Terminar já custa 1 açúcar por minuto
que falta.

| Construção | Construir | Evoluir (2 / 3 / 4 / 5) | Produz por hora (nível 1 a 5) | Guarda até |
|---|---|---|---|---|
| Moinho de açúcar | 80 | 150 / 300 / 550 / 900 | 6 / 10 / 15 / 21 / 28 açúcar | 30 / 50 / 80 / 120 / 170 |
| Cofre de moedas | 150 | 250 / 450 / 750 / 1.200 | 4 / 7 / 11 / 16 / 22 moedas | 20 / 35 / 55 / 85 / 120 |
| Casa de doce | 120 | 100 / 220 / 400 / 700 | — | — |
| Jardim de pirulitos | 60 | 60 / 150 / 300 / 500 | — | — |
| Fonte de morango | 100 | 90 / 200 / 380 / 650 | — | — |

Beleza da vila: cada nível de casa, jardim e fonte soma +5% na produção do
moinho e do cofre.
