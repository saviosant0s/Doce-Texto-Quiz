class_name Chefao
extends RefCounted
## CHEFÃO NA VILA: de tempos em tempos um doce GIGANTE invade a praça e senta
## em cima da fonte de chocolate (o Rei do Chocolate; durante um evento, o
## doce do evento gigante). O jogador vai até a praça e ENFRENTA: cada rodada
## é uma pergunta do quiz. Acertou, o seu doce joga um doce nele (respostas
## seguidas aumentam o COMBO e o estrago; rápido bate mais forte); errou ou
## acabou o tempo, o chefão joga chocolate no seu doce e você perde um
## coração. Com metade da vida o chefão fica BRAVO (tempo menor). Zerou a vida
## dele: a vila está salva (prêmio grande). Acabaram os corações: dá para
## tentar de novo na hora.
##
## Quando: a cada DIAS_ENTRE invasões (um dia do jogo = 40 min), o dia todo.
## O primeiro chefão aparece logo (para conhecer). Cada invasão só dá prêmio
## uma vez.
##
## Estado em Progresso.vila["chefao"] = {"vencidos": n, "ultima": id da última
## invasão vencida}.

const DIAS_ENTRE := 2
const CORACOES := 5
const TEMPO := 20.0
const TEMPO_BRAVO := 14.0
const VIDA_BASE := 500
const VIDA_POR_VITORIA := 150
const VIDA_MAXIMA := 2000
const COMBO_MAXIMO := 4  # +25% por acerto seguido, até +100%
const RAPIDO := 6.0
const ACUCAR_DERROTA := 10


static func _estado() -> Dictionary:
	if not Progresso.vila.has("chefao"):
		Progresso.vila["chefao"] = {"vencidos": 0, "ultima": ""}
	return Progresso.vila["chefao"]


static func vencidos() -> int:
	return int(_estado()["vencidos"])


## Id da invasão de agora ("" = a praça está em paz). O primeiro chefão vem
## logo; depois, um a cada DIAS_ENTRE dias do jogo.
static func invasao() -> String:
	if vencidos() == 0:
		return "chefao-primeiro"
	var dia := CicloDia.dia_jogo()
	return "chefao-%d" % dia if posmod(dia, DIAS_ENTRE) == 0 else ""


## Se tem chefão na praça agora (invasão que ainda não foi vencida).
static func na_praca() -> bool:
	var id := invasao()
	return id != "" and id != str(_estado()["ultima"])


## Horas de verdade (aproximadas) até a próxima invasão.
static func horas_ate_proxima() -> float:
	var dia := CicloDia.dia_jogo()
	var falta := DIAS_ENTRE - posmod(dia, DIAS_ENTRE)
	var horas_jogo := falta * 24.0 - CicloDia.hora()
	return horas_jogo / 24.0 * CicloDia.DURACAO_DIA / 3600.0


## Qual doce é o chefão: o doce do evento (gigante) ou o Rei do Chocolate.
static func doce() -> String:
	var do_evento := str(Eventos.dados().get("doce", ""))
	return do_evento if do_evento != "" and not Colecao.dados(do_evento).is_empty() else "chocolate"


static func nome() -> String:
	var id := doce()
	if id == "chocolate":
		return "REI DO CHOCOLATE"
	return "%s GIGANTE" % Colecao.dados(id)["nome"]


static func vida_maxima() -> int:
	return mini(VIDA_BASE + VIDA_POR_VITORIA * vencidos(), VIDA_MAXIMA)


## Prêmio de vencer (cresce com os chefões vencidos; a cada 3, baú de ouro).
static func premio() -> Dictionary:
	var n := vencidos()
	return {"moedas": mini(60 + 15 * n, 150), "acucar": 50, "xp": 30, "bau": "ouro" if (n + 1) % 3 == 0 else "doce"}


# --- A luta ---------------------------------------------------------------------------

var vida := 0
var vida_max := 0
var coracoes := CORACOES
var combo := 0
var acertos := 0
var rodadas := 0
var pergunta: Dictionary = {}
var _usadas: Array = []
var _sorteio := RandomNumberGenerator.new()
var _ataque := 34  # ataque do doce companheiro (Batalha)


func _init(semente := -1) -> void:
	vida_max = vida_maxima()
	vida = vida_max
	if semente >= 0:
		_sorteio.seed = semente
	else:
		_sorteio.randomize()
	var companheiro := Colecao.companheiro()
	if companheiro == "" or not Colecao.tem(companheiro):
		companheiro = "brigadeiro"
	_ataque = Batalha.ataque(companheiro, Companheiros.nivel(companheiro))


func bravo() -> bool:
	return vida <= vida_max / 2


func tempo() -> float:
	return TEMPO_BRAVO if bravo() else TEMPO


func venceu() -> bool:
	return vida <= 0


func perdeu() -> bool:
	return coracoes <= 0 and vida > 0


func acabou() -> bool:
	return venceu() or perdeu()


## Pergunta do quiz (fácil; médio e difícil entram com os títulos), sem repetir.
func proxima_pergunta() -> Dictionary:
	var niveis := [0]
	if Quiz.tem_titulo("noob"):
		niveis.append(1)
	if Quiz.tem_titulo("pro"):
		niveis.append(2)
	var banco := []
	for n in niveis:
		for p in Jogo.niveis[n]["perguntas"]:
			if not p["id"] in _usadas:
				banco.append(p)
	if banco.is_empty():
		_usadas.clear()
		for n in niveis:
			banco.append_array(Jogo.niveis[n]["perguntas"])
	var original: Dictionary = banco[_sorteio.randi() % banco.size()]
	_usadas.append(original["id"])
	var alternativas: Array = original["alternativas"].duplicate()
	var correta: String = alternativas[int(original["resposta"])]
	for i in range(alternativas.size() - 1, 0, -1):
		var j := _sorteio.randi() % (i + 1)
		var troca = alternativas[i]
		alternativas[i] = alternativas[j]
		alternativas[j] = troca
	pergunta = {"id": original["id"], "enunciado": original["enunciado"], "alternativas": alternativas,
		"resposta": alternativas.find(correta)}
	return pergunta


## Responde (-1 = acabou o tempo; `segundos` = quanto levou). Retorna
## {"acertou", "dano" (no chefão), "combo", "rapido", "ficou_bravo", "fim": ""|"venceu"|"perdeu"}.
func responder(escolha: int, segundos: float) -> Dictionary:
	if acabou() or pergunta.is_empty():
		return {}
	rodadas += 1
	var era_bravo := bravo()
	var r := {"acertou": escolha == int(pergunta["resposta"]), "dano": 0, "combo": 0, "rapido": false,
		"ficou_bravo": false, "fim": ""}
	if r["acertou"]:
		acertos += 1
		combo = mini(combo + 1, COMBO_MAXIMO + 1)
		var dano := _ataque * 2.2 * (1.0 + 0.25 * (combo - 1)) * _sorteio.randf_range(0.9, 1.1)
		if segundos <= RAPIDO:
			dano *= 1.25
			r["rapido"] = true
		r["dano"] = roundi(dano)
		vida = maxi(0, vida - int(r["dano"]))
		r["ficou_bravo"] = not era_bravo and bravo() and vida > 0
	else:
		combo = 0
		coracoes -= 1
	r["combo"] = combo
	if venceu():
		r["fim"] = "venceu"
	elif perdeu():
		r["fim"] = "perdeu"
	pergunta = {}
	return r


## Fim da luta: na vitória dá o prêmio e marca a invasão como vencida; na
## derrota, um pouco de açúcar. Retorna o que ganhou.
func concluir() -> Dictionary:
	if not acabou():
		return {}
	if perdeu():
		Confeitaria.ganhar_acucar(ACUCAR_DERROTA)
		return {"acucar": ACUCAR_DERROTA}
	var ganho := premio()
	var e := _estado()
	e["ultima"] = invasao()
	e["vencidos"] = vencidos() + 1
	Confeitaria.ganhar_acucar(int(ganho["acucar"]))
	Baus.ganhar(ganho["bau"])
	Experiencia.ganhar(int(ganho["xp"]))
	Missoes.registrar("chefao", 1)
	Progresso.ganhar_moedas(int(ganho["moedas"]))  # também salva
	return ganho
