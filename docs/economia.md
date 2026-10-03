# Economia do jogo (moedas e açúcar)

Regra de ouro (revista em 29/09, pedido do Sávio: "ganhar está difícil"):
**jogar dá recursos**. O quiz, o laboratório e os minigames (Doce Match,
Torre, Fábrica) DÃO moedas e açúcar, e são de graça; os gastos ficam na
vila (terrenos, construções, casa e expansões, móveis, coleção, máquinas). Valores no código: `scripts/jogo.gd`,
`scripts/confeitaria.gd`, `scripts/doce_match.gd`, `scripts/laboratorio.gd`, `scripts/colecao.gd`,
`scripts/conquistas.gd`.

## Entradas

| De onde | Moedas | Açúcar |
|---|---|---|
| Quiz fácil (por acerto) | 8 | 15 |
| Quiz médio (por acerto) | 12 | 15 |
| Quiz difícil (por acerto) | 16 | 15 |
| Quiz: por estrela | 15 | — |
| Revisão dos erros (por acerto) | 5 | 15 |
| Doce Match: toda vitória | 15 + 5 por estrela | 10 + 10 por estrela |
| Doce Match: 1ª vitória no nível / estrela nova | +20 / +10 cada | — |
| Doce Match: derrota | — | 5 |
| Torre de Doces (por andar) | 2 (+1 por perfeito) | 3 |
| Fábrica de Chocolate (por pedido) | 4 (+ pontos/30) | 5 |
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

Partidas típicas: fácil 7/10 com 1 estrela = 71 moedas + 105 de açúcar; médio
8/10 com 2 estrelas = 126 + 120; difícil 9/10 com 2 estrelas = 174 + 135.
Minigames: Doce Match vencido com 2 estrelas = 25 moedas + 30 açúcar; torre de
15 andares = ~35 moedas + 45 açúcar; turno de 8 pedidos na fábrica = ~40
moedas + 40 açúcar. Nenhum minigame custa açúcar.

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

## Minha Casa (desde a 0.13.0)

Casa na vila (ao sul da praça) com a sala para decorar. Vem com tapete,
poltrona, mesa e planta de presente. Móveis de 45 a 400 moedas; papel de
parede e piso de 80 a 150. Quatro móveis especiais não se compram: troféu
gigante (título Mestre), mini torre de bolo (20 andares na Torre), fliperama
de casa (10 níveis do Doce Match) e robô do Office (30 estrelas no Laboratório).

Conforto = soma dos móveis na sala (repetido vale metade) + parede + piso.
Prêmio uma vez por faixa: ACONCHEGANTE (60) 50 moedas, CHARMOSA (150) 100
moedas, LINDA (280) baú de doce, DOS SONHOS (450) 250 moedas, DE REVISTA (700)
baú de ouro.

### Aumentar a casa (desde a 0.14.0)

| Tamanho | Sala | Preço | Conforto | Precisa do quiz |
|---|---|---|---|---|
| CASINHA | 8 × 6 | — | — | — |
| CASA COM VARANDA | 10 × 7 | 400 moedas + 150 açúcar | +20 | título NOOB (fácil) |
| CASA GRANDE | 12 × 8 | 900 moedas + 300 açúcar | +45 | título PRO (médio) |
| CASARÃO | 14 × 9 | 1.800 moedas + 600 açúcar | +80 | título MESTRE (difícil) |

## O quiz continua sendo o caminho (desde a 0.14.0)

Os minigames dão açúcar e algumas moedas, mas o quiz segue no centro:
- é a maior fonte de moedas (uma partida boa rende 125 a 200);
- os tamanhos da casa e os desafiantes 4, 7 e 10 da Arena pedem os títulos do
  quiz (NOOB, PRO, MESTRE);
- a própria Arena é quiz: cada golpe é uma pergunta.

## Arena dos Doces (desde a 0.14.0)

Time de até 3 doces (vida e ataque pela raridade e +12% por nível). Acertou
= seu doce ataca; errou/tempo = apanha; em até 6 s = +25%; 3 acertos seguidos
= SUPER (dobro). Prêmio da primeira vitória: de 30 moedas + 20 açúcar (Seu
Milho) até 200 moedas + 100 açúcar + baú de ouro + Troféu da Arena (Rei do
Chocolate); revanche = 30% (mínimo 10); derrota = 5 açúcar.

## Chefão na vila (desde a 0.15.0)

O primeiro chefão aparece logo; depois, um a cada 2 dias do jogo (cada dia =
40 min), na praça. Vida 500 + 150 por chefão vencido (até 2000). 5 corações.
Acerto = dano do ataque do seu doce companheiro × 2,2, +25% por acerto
seguido (até +100%) e +25% se responder em até 6 s. Vencer: 60 moedas + 15
por chefão já vencido (até 150) + 50 açúcar + 30 XP + baú de doce (de ouro a
cada 3º chefão). Perder: 10 açúcar e pode tentar de novo.

## Regiões do mapa (desde a 0.15.0)

| Região | Portão abre com | Descobrir | Coisinhas por dia |
|---|---|---|---|
| Ilha do Algodão-Doce (oeste, lago e ponte) | nível 2 do jogador | 40 moedas + 30 açúcar | 5 conchas |
| Bosque de Pirulitos (sul, rio e ponte) | título NOOB (quiz fácil) | 40 moedas + 30 açúcar | 5 morangos |
| Montanha de Sorvete (leste) | título PRO (quiz médio) | 40 moedas + 30 açúcar | 5 cristais |

Cada coisinha dá 6 açúcar + 3 moedas (voltam a cada dia do jogo = 40 min).

## Batalha: força dos doces (desde a 0.15.0)

Vida +20% e ataque +12% por nível acima do 1 (antes +12% nos dois).

## Fotos e vistas bonitas (desde a 0.14.0; botão de foto na 0.15.0)

Botão de foto em qualquer lugar. 9 vistas bonitas escondidas (o botão pulsa
perto); a primeira foto em cada uma dá 20 moedas + 15 açúcar.

## Eventos da temporada (desde a 0.13.0)

Seis eventos por ano (Festival das Flores 20/09–14/10, Noite das Abóboras
15/10–10/11, Natal Doce 01/12–10/01, Carnaval de Confeitos 05/02–05/03, Caça
aos Ovos 20/03–25/04, Arraiá Doce 01/06–20/07). Fichas do evento: partida 5,
acerto 1, estrela 2, andar da torre 0,5, pedido da fábrica 2, partida do match
4, cliente 2, fase do laboratório 5, baú aberto 2, e 3 por objeto pego na vila
(8 por dia). Trilha: 20 → 30 moedas, 50 → 40 açúcar, 90 → baú de doce, 140 →
80 moedas, 200 → móvel exclusivo, 270 → 80 açúcar, 350 → doce exclusivo
(épico; não vem em baú antes de ser ganho). As fichas zeram a cada edição.

## Histórias da vila (desde a 0.13.0)

Cinco capítulos (níveis 1 a 5 do jogador). Prêmios: 40 moedas; 50 moedas + 40
açúcar; 80 moedas + banco da praça (móvel); 100 moedas + baú de doce; 150
moedas + 60 açúcar + retrato da vila (móvel). Um passo pede 50 de açúcar.
