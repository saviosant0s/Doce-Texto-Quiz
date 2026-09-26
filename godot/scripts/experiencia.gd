class_name Experiencia
## Nível do jogador: tudo o que ele faz dá experiência (XP) e, ao juntar o
## bastante, sobe de nível e ganha um baú (PRATA; a cada 5 níveis, OURO).
##
## XP: acerto no quiz 5 (revisão 3), fase do laboratório 30 (chefe 60; repetir
## 10), partida do Doce Match 15, cliente na cozinha 2, missões (ver Missoes).
## O companheiro com bônus "xp" aumenta tudo isso.
##
## Estado em Progresso.jogador ({"xp": total no nível atual, "nivel": n}).

const XP_ACERTO := 5
const XP_ACERTO_REVISAO := 3
const XP_FASE := 30
const XP_CHEFE := 60
const XP_FASE_REPETIDA := 10
const XP_MATCH := 15
const XP_CLIENTE := 2

## Subidas de nível que ainda não foram mostradas ao jogador (a tela avisa).
static var subidas_pendentes: Array = []


static func nivel() -> int:
	return maxi(1, int(Progresso.jogador.get("nivel", 1)))


static func xp() -> int:
	return int(Progresso.jogador.get("xp", 0))


## XP para passar do nível n para o n+1.
static func xp_para(n: int) -> int:
	return 100 + 40 * (n - 1)


static func progresso() -> float:
	return clampf(float(xp()) / xp_para(nivel()), 0.0, 1.0)


## Dá experiência (com o bônus do companheiro). Retorna quantos níveis subiu.
static func ganhar(quantidade: int) -> int:
	if quantidade <= 0:
		return 0
	quantidade = Companheiros.com_bonus("xp", quantidade)
	var j := Progresso.jogador
	j["xp"] = xp() + quantidade
	j["nivel"] = nivel()
	var subiu := 0
	while int(j["xp"]) >= xp_para(int(j["nivel"])):
		j["xp"] = int(j["xp"]) - xp_para(int(j["nivel"]))
		j["nivel"] = int(j["nivel"]) + 1
		subiu += 1
		var bau := "ouro" if int(j["nivel"]) % 5 == 0 else "prata"
		Baus.ganhar(bau)
		subidas_pendentes.append({"nivel": int(j["nivel"]), "bau": bau})
	Progresso.salvar()
	return subiu


## Mostra (uma vez) os avisos de nível novo.
static func anunciar() -> void:
	for s in subidas_pendentes:
		Audio.tocar("construir")
		Telas.mostrar_aviso("NÍVEL %d! GANHOU UM %s" % [s["nivel"], Baus.NOMES[s["bau"]]])
	subidas_pendentes.clear()
