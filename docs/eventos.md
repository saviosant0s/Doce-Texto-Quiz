# Eventos de calendário (sem atualizar o app)

O jogo decide o evento da vila assim (ver `godot/scripts/eventos.gd`):

1. **Calendário da internet**: o arquivo `eventos/eventos.json` deste
   repositório, publicado no site do jogo
   (`https://saviosant0s.github.io/Doce-Texto-Quiz/eventos.json`). O app baixa
   esse arquivo toda vez que abre (com internet) e guarda uma cópia; sem
   internet, usa a última cópia.
2. **Calendário do app**: datas que já vêm dentro do jogo (Semana das
   Crianças 6 a 19/10, Noite das Abóboras 25/10 a 2/11, Natal 10 a 31/12,
   Arraiá 1 a 30/6, Carnaval e Páscoa de 2027).
3. **A roda**: sem nenhum evento de data marcada, os temas trocam sozinhos a
   cada 30 dias do jogo (~20 horas).

## Como marcar um evento novo

1. Edite `eventos/eventos.json` (exemplo abaixo).
2. Rode `ferramentas/publicar_eventos.sh` (publica só esse arquivo, sem
   gerar APK).
3. Quem abrir o jogo com internet já recebe o evento.

```json
{
  "versao": 1,
  "eventos": [
    {
      "id": "aniversario_vila",
      "tema": "festa",
      "inicio": "2026-11-20",
      "fim": "2026-11-24",
      "nome": "Aniversário da Vila",
      "ficha": "Balões",
      "cor": "#B07CFF",
      "texto": "A vila está fazendo aniversário! Junte balões para ganhar prêmios."
    }
  ]
}
```

| Campo | Obrigatório | O que é |
|---|---|---|
| `id` | sim | letras minúsculas, números e `_` (sem hífen) |
| `inicio`, `fim` | sim | `AAAA-MM-DD` (um ano só) ou `MM-DD` (todo ano) |
| `tema` | não | decoração: `primavera`, `halloween`, `natal`, `carnaval`, `pascoa`, `junina`, `criancas`; qualquer outro vira `festa` (balões e varais na cor do evento) |
| `nome`, `ficha`, `texto` | não | nome do evento, nome das fichas e o texto de boas-vindas |
| `cor` | não | cor do evento (`#RRGGBB`) |
| `movel`, `doce` | não | prêmios da trilha; só valem se o app já tiver esse móvel/doce. Sem eles, a trilha dá 150 moedas e um baú de ouro no lugar |

Eventos do arquivo valem mais que os do app (se as datas se cruzarem, vale o
primeiro da lista). Decoração ou doce 3D realmente novos precisam de uma
versão nova do app; o resto (nome, datas, cor, texto) é só pelo arquivo.
