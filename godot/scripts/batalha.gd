class_name Batalha
extends RefCounted
## BATALHA DE DOCES (na Arena da vila): o seu time de até TAMANHO_TIME doces
## da coleção contra o time de um desafiante, numa LUTA DE VERDADE por turnos:
## - SEU TURNO: você escolhe o golpe nos botões (GOLPES): SOCO (médio, sem
##   risco), VOADORA (forte, mas fica sem guarda: errar a pergunta seguinte dói
##   SEM_GUARDA vezes mais) e PIRUETA (muito forte, com recarga de alguns turnos).
## - TURNO DO DESAFIANTE: entre os golpes vem a PERGUNTA RELÂMPAGO do quiz:
##   acertou, o seu doce DESVIA do golpe dele e ganha 1 de ENERGIA; errou (ou
##   acabou o tempo), leva o golpe.
## - GOLPE SUPREMO: com a energia cheia (SUPER_COM), o botão acende; usar faz
##   uma pergunta: acertou, o supremo ACERTA (DANO_SUPREMO, mais forte se
##   responder rápido); errou, ERRA. Gasta a energia de qualquer jeito (a mesma
##   ideia do turbo nos portais da corrida).
## Doce sem vida sai e entra o próximo do time. Ganha quem derrubar o time
## inteiro do outro.
##
## Vida e ataque vêm da raridade e do nível do doce (Companheiros): subir os
## doces de nível e ter doces raros deixa o time mais forte.
## DESAFIANTES: uma escada; vencer um libera o próximo (e os mais fortes
## pedem os títulos do quiz: NOOB, PRO e MESTRE). A primeira vitória
## contra cada um dá o prêmio; revanches dão uma parte dele. O último, o REI
## DO CHOCOLATE, dá também o TROFÉU DA ARENA para a Minha Casa.
##
## Estado em Progresso.vila["arena"] = {"vencidos": [índices], "time": [ids],
## "vitorias": total de vitórias}.

const VIDA_BASE := [100, 115, 130, 150]  # por raridade (COMUM a LENDÁRIO)
const ATAQUE_BASE := [34, 37, 40, 44]
const VIDA_POR_NIVEL := 0.2  # +20% de vida por nível acima do 1 (subir o doce faz diferença)
const ATAQUE_POR_NIVEL := 0.12  # +12% de ataque por nível
const TAMANHO_TIME := 3
const SUPER_COM := 3  # energia (desvios) para o GOLPE SUPREMO
const TEMPO := 20.0  # segundos por pergunta
const RAPIDO := 6.0  # respondeu o supremo em até 6 s: SUPREMO RÁPIDO (+25%)
## Golpes dos botões: "dano" (vezes o ataque do doce), "recarga" (turnos até
## poder usar de novo) e "aberto" (fica sem guarda até a próxima pergunta).
const GOLPES := {
	"soco": {"nome": "SOCO", "dano": 0.8, "recarga": 0, "aberto": false},
	"voadora": {"nome": "VOADORA", "dano": 1.15, "recarga": 0, "aberto": true},
	"pirueta": {"nome": "PIRUETA", "dano": 1.5, "recarga": 3, "aberto": false},
}
const DANO_SUPREMO := 2.6
const SEM_GUARDA := 1.5  # errou a pergunta depois da voadora: o golpe dele dói mais
const REVANCHE := 0.3  # parte do prêmio nas revanches
const ACUCAR_DERROTA := 5  # perdeu: um pouquinho de açúcar pelo esforço
## XP de cada doce do time no fim da luta (nível de luta, ver Companheiros.ganhar_xp).
const XP_LUTA_VITORIA := 30
const XP_LUTA_DERROTA := 10

## "time": [[id do doce, nível]]; "perguntas": nível do quiz (0 fácil, 1
## médio, 2 difícil); "premio": {"moedas", "acucar", "bau"?, "movel"?}.
const DESAFIANTES := [
	{"nome": "SEU MILHO", "time": [["milho_doce", 1]], "perguntas": 0,
		"fala": "Vamos ver se você sabe mesmo!", "premio": {"moedas": 30, "acucar": 20}},
	{"nome": "BALA VERDE", "time": [["bala_verde", 1], ["jujuba", 1]], "perguntas": 0,
		"fala": "Sou pequena, mas sou rápida!", "premio": {"moedas": 40, "acucar": 25}},
	{"nome": "TURMA DA PRAÇA", "time": [["pirulito", 2], ["marshmallow", 1]], "perguntas": 0,
		"fala": "A gente treina todo dia na fonte!", "premio": {"moedas": 50, "acucar": 30}},
	{"nome": "DONA PAÇOCA", "titulo": "noob", "time": [["pacoca", 2], ["beijinho", 2], ["cocada", 1]], "perguntas": 1,
		"fala": "Paçoca esfarela, mas não desiste!", "premio": {"moedas": 60, "acucar": 35, "bau": "doce"}},
	{"nome": "CAPITÃO CHURROS", "time": [["churros", 2], ["sorvete", 2]], "perguntas": 1,
		"fala": "Recheado de coragem!", "premio": {"moedas": 70, "acucar": 40}},
	{"nome": "DUPLA DO CONFEITO", "time": [["macaron", 3], ["cupcake_morango", 3]], "perguntas": 1,
		"fala": "Doce que é doce responde rápido!", "premio": {"moedas": 80, "acucar": 45}},
	{"nome": "MESTRE PUDIM", "titulo": "pro", "time": [["pudim", 3], ["quindim", 3], ["brownie", 2]], "perguntas": 1,
		"fala": "Balança, mas não cai!", "premio": {"moedas": 90, "acucar": 50, "bau": "doce"}},
	{"nome": "BARÃO DO BOLO", "time": [["bolo", 3], ["pao_de_mel", 3]], "perguntas": 2,
		"fala": "Camadas e mais camadas de sabedoria!", "premio": {"moedas": 110, "acucar": 60}},
	{"nome": "FADA DO ALGODÃO", "time": [["algodao_doce", 4], ["flor_de_acucar", 4], ["confete", 3]], "perguntas": 2,
		"fala": "Leve como uma nuvem, forte como um furacão!", "premio": {"moedas": 130, "acucar": 70}},
	{"nome": "REI DO CHOCOLATE", "titulo": "mestre", "time": [["bombom", 4], ["brownie", 4], ["chocolate", 5]], "perguntas": 2,
		"fala": "Ninguém derrete o Rei do Chocolate!", "premio": {"moedas": 200, "acucar": 100, "bau": "ouro", "movel": "trofeu_arena"}},
]

# --- Estado salvo (escada de desafiantes e time) --------------------------------

static func _estado() -> Dictionary:
	if not Progresso.vila.has("arena"):
		Progresso.vila["arena"] = {"vencidos": [], "time": [], "vitorias": 0}
	return Progresso.vila["arena"]


static func vencido(indice: int) -> bool:
	return indice in _estado()["vencidos"]


## O primeiro está sempre liberado; os outros, depois de vencer o anterior.
## Alguns ("titulo") também pedem um título do quiz (passar no nível).
static func liberado(indice: int) -> bool:
	if indice < 0 or indice >= DESAFIANTES.size():
		return false
	return (indice == 0 or vencido(indice - 1)) and Quiz.tem_titulo(str(DESAFIANTES[indice].get("titulo", "")))


static func vencidos() -> int:
	return _estado()["vencidos"].size()


## Prêmio de vencer o desafiante agora (inteiro na primeira vez; parte dele
## nas revanches, sem baú nem móvel).
static func premio(indice: int) -> Dictionary:
	var cheio: Dictionary = DESAFIANTES[indice]["premio"]
	if not vencido(indice):
		return cheio.duplicate()
	return {"moedas": maxi(10, roundi(int(cheio["moedas"]) * REVANCHE)),
		"acucar": maxi(10, roundi(int(cheio["acucar"]) * REVANCHE))}


## Time escolhido (só doces que o jogador tem), ou o padrão: o companheiro e os
## mais fortes da coleção.
static func time() -> Array:
	var salvo: Array = _estado()["time"].filter(func(id): return Colecao.tem(id))
	if not salvo.is_empty():
		return salvo.slice(0, TAMANHO_TIME)
	return time_padrao()


static func time_padrao() -> Array:
	var meus: Array = Colecao.LISTA.map(func(d): return d["id"]).filter(func(id): return Colecao.tem(id))
	meus.sort_custom(func(a, b): return minha_forca(a) > minha_forca(b))
	var lista := []
	var companheiro := Colecao.companheiro()
	if companheiro != "" and Colecao.tem(companheiro):
		lista.append(companheiro)
	for id in meus:
		if lista.size() >= TAMANHO_TIME:
			break
		if not id in lista:
			lista.append(id)
	return lista


## Guarda o time (até TAMANHO_TIME doces da coleção). Falso se vazio ou inválido.
static func escolher_time(ids: Array) -> bool:
	var validos := ids.filter(func(id): return Colecao.tem(id))
	if validos.is_empty() or validos.size() > TAMANHO_TIME or validos.size() != ids.size():
		return false
	_estado()["time"] = validos.duplicate()
	Progresso.salvar()
	return true


# --- Força dos doces ----------------------------------------------------------------

static func _raridade(id: String) -> int:
	return Companheiros.raridade(id)


## `extra` multiplica tudo: o nível de luta (XP) dos seus doces (Companheiros.forca_xp).
static func vida(id: String, nivel: int, extra := 1.0) -> int:
	return roundi(VIDA_BASE[_raridade(id)] * (1.0 + VIDA_POR_NIVEL * (maxi(1, nivel) - 1)) * extra)


static func ataque(id: String, nivel: int, extra := 1.0) -> int:
	return roundi(ATAQUE_BASE[_raridade(id)] * (1.0 + ATAQUE_POR_NIVEL * (maxi(1, nivel) - 1)) * extra)


## Força para comparar doces (vida + 3x ataque).
static func forca(id: String, nivel: int, extra := 1.0) -> int:
	return vida(id, nivel, extra) + ataque(id, nivel, extra) * 3


## Força de um doce seu (com o nível dos fragmentos e o nível de luta).
static func minha_forca(id: String) -> int:
	return forca(id, Companheiros.nivel(id), Companheiros.forca_xp(id))


static func nome_doce(id: String) -> String:
	var dados := Colecao.dados(id)
	if not dados.is_empty():
		return dados["nome"]
	return {"milho_doce": "SEU MILHO", "bala_verde": "BALA VERDE"}.get(id, id.to_upper())


static func _lutador(id: String, nivel: int, extra := 1.0) -> Dictionary:
	return {"id": id, "nivel": maxi(1, nivel), "vida": vida(id, nivel, extra), "vida_max": vida(id, nivel, extra),
		"ataque": ataque(id, nivel, extra)}


# --- A luta -------------------------------------------------------------------------

var indice := 0
var desafiante: Dictionary
var meu_time: Array = []  # [{"id", "nivel", "vida", "vida_max", "ataque"}]
var time_deles: Array = []
var meu_atual := 0
var deles_atual := 0
var energia := 0  # desvios guardados (o GOLPE SUPREMO pede SUPER_COM)
## "golpe" (sua vez de escolher), "defesa" (a pergunta relâmpago do golpe dele)
## ou "supremo" (a pergunta do seu golpe supremo).
var fase := "golpe"
var sem_guarda := false
var recargas := {}  # golpe -> turnos que faltam
var pergunta: Dictionary = {}
var rodadas := 0  # golpes seus (botões e supremos)
var respondidas := 0  # perguntas respondidas (relâmpago e supremo)
var acertos := 0
var _usadas: Array = []
var _sorteio := RandomNumberGenerator.new()


func _init(indice_desafiante := 0, ids_time: Array = [], semente := -1) -> void:
	indice = clampi(indice_desafiante, 0, DESAFIANTES.size() - 1)
	desafiante = DESAFIANTES[indice]
	if semente >= 0:
		_sorteio.seed = semente
	else:
		_sorteio.randomize()
	var ids := ids_time if not ids_time.is_empty() else time()
	for id in ids.slice(0, TAMANHO_TIME):
		meu_time.append(_lutador(id, Companheiros.nivel(id), Companheiros.forca_xp(id)))
	for par in desafiante["time"]:
		time_deles.append(_lutador(par[0], int(par[1])))


func meu() -> Dictionary:
	return meu_time[meu_atual] if meu_atual < meu_time.size() else {}


func deles() -> Dictionary:
	return time_deles[deles_atual] if deles_atual < time_deles.size() else {}


func venceu() -> bool:
	return deles_atual >= time_deles.size()


func perdeu() -> bool:
	return meu_atual >= meu_time.size()


func acabou() -> bool:
	return venceu() or perdeu()


## Sorteia a próxima pergunta (do nível do quiz do desafiante; sem repetir na
## mesma luta e variando de uma luta para outra, ver Jogo.perguntas_variadas), com
## as alternativas embaralhadas.
func proxima_pergunta() -> Dictionary:
	var nivel_quiz := int(desafiante["perguntas"])
	var banco: Array = Jogo.niveis[nivel_quiz]["perguntas"].filter(func(p): return not p["id"] in _usadas)
	if banco.is_empty():
		_usadas.clear()
		banco = Jogo.niveis[nivel_quiz]["perguntas"]
	var original: Dictionary = Jogo.perguntas_variadas(banco, 1, _sorteio)[0].duplicate()
	original["nivel"] = nivel_quiz
	_usadas.append(original["id"])
	var alternativas: Array = original["alternativas"].duplicate()
	var correta: String = alternativas[int(original["resposta"])]
	for i in range(alternativas.size() - 1, 0, -1):
		var j := _sorteio.randi() % (i + 1)
		var troca = alternativas[i]
		alternativas[i] = alternativas[j]
		alternativas[j] = troca
	pergunta = {"id": original["id"], "enunciado": original["enunciado"], "alternativas": alternativas,
		"resposta": alternativas.find(correta), "explicacao": original.get("explicacao", "")}
	return pergunta


# --- Turnos ---------------------------------------------------------------------------

## Turnos que faltam para poder usar o golpe de novo (0 = pode).
func recarga(tipo: String) -> int:
	return int(recargas.get(tipo, 0))


func pode_golpear(tipo: String) -> bool:
	return fase == "golpe" and not acabou() and GOLPES.has(tipo) and recarga(tipo) == 0


func pode_supremo() -> bool:
	return fase == "golpe" and not acabou() and energia >= SUPER_COM


## Seu golpe dos botões. Retorna {"atacante": "meu", "golpe", "dano", "nocaute",
## "entrou", "fim"} ({} se não pode). Depois dele vem a pergunta relâmpago
## (fase "defesa"), a não ser que a luta tenha acabado.
func golpear(tipo: String) -> Dictionary:
	if not pode_golpear(tipo):
		return {}
	rodadas += 1
	var dados: Dictionary = GOLPES[tipo]
	_passar_recargas()
	recargas[tipo] = int(dados["recarga"])
	sem_guarda = bool(dados["aberto"])
	var dano := roundi(int(meu()["ataque"]) * float(dados["dano"]) * _sorteio.randf_range(0.9, 1.1))
	var r := _bater_neles(dano)
	r["golpe"] = tipo
	fase = "golpe" if acabou() else "defesa"
	return r


## Usa o GOLPE SUPREMO: sorteia a pergunta dele (responder decide se acerta).
func pedir_supremo() -> Dictionary:
	if not pode_supremo():
		return {}
	rodadas += 1
	_passar_recargas()
	sem_guarda = false
	fase = "supremo"
	return proxima_pergunta()


## Responde a pergunta da vez (`escolha` -1 = acabou o tempo; `tempo` = segundos
## que levou):
## - fase "defesa" (o golpe dele): acertou, DESVIA ("esquivou", +1 de energia);
##   errou, leva o golpe (SEM_GUARDA vezes mais depois da voadora).
## - fase "supremo": acertou, o supremo acerta (+25% se rápido); errou, erra
##   ("errou"). A energia zera.
## Retorna {"acertou", "atacante": "meu"|"deles", "golpe", "dano", "esquivou",
##  "errou", "super", "rapido", "nocaute", "entrou", "fim"}.
func responder(escolha: int, tempo: float) -> Dictionary:
	if acabou() or pergunta.is_empty() or fase == "golpe":
		return {}
	var acertou := escolha == int(pergunta["resposta"])
	pergunta = {}
	respondidas += 1
	if acertou:
		acertos += 1
	var r: Dictionary
	if fase == "supremo":
		energia = 0
		if acertou:
			var dano := int(meu()["ataque"]) * DANO_SUPREMO * _sorteio.randf_range(0.95, 1.05)
			var rapido := tempo <= RAPIDO
			if rapido:
				dano *= 1.25
			r = _bater_neles(roundi(dano))
			r["rapido"] = rapido
		else:
			r = _resultado("meu", 0)
			r["errou"] = true
		r["golpe"] = "supremo"
		r["super"] = true
		fase = "golpe" if acabou() else "defesa"
	else:
		if acertou:
			energia = mini(SUPER_COM, energia + 1)
			r = _resultado("deles", 0)
			r["esquivou"] = true
		else:
			var dano := int(deles()["ataque"]) * _sorteio.randf_range(0.9, 1.1) * (SEM_GUARDA if sem_guarda else 1.0)
			r = _bater_em_mim(roundi(dano))
		r["golpe"] = "dele"
		sem_guarda = false
		fase = "golpe"
	r["acertou"] = acertou
	return r


func _passar_recargas() -> void:
	for tipo in recargas.keys():
		recargas[tipo] = maxi(0, int(recargas[tipo]) - 1)


func _resultado(atacante: String, dano: int) -> Dictionary:
	return {"atacante": atacante, "dano": dano, "esquivou": false, "errou": false, "super": false, "rapido": false,
		"nocaute": false, "entrou": "", "fim": "", "acertou": false}


func _bater_neles(dano: int) -> Dictionary:
	var r := _resultado("meu", dano)
	var alvo: Dictionary = deles()
	alvo["vida"] = maxi(0, int(alvo["vida"]) - dano)
	if int(alvo["vida"]) <= 0:
		r["nocaute"] = true
		deles_atual += 1
		r["entrou"] = deles().get("id", "")
	_fim(r)
	return r


func _bater_em_mim(dano: int) -> Dictionary:
	var r := _resultado("deles", dano)
	var alvo: Dictionary = meu()
	alvo["vida"] = maxi(0, int(alvo["vida"]) - dano)
	if int(alvo["vida"]) <= 0:
		r["nocaute"] = true
		meu_atual += 1
		r["entrou"] = meu().get("id", "")
	_fim(r)
	return r


func _fim(r: Dictionary) -> void:
	if venceu():
		r["fim"] = "venceu"
	elif perdeu():
		r["fim"] = "perdeu"


## Terminou a luta: dá o prêmio (vitória) ou o açúcar do esforço (derrota)
## e guarda o progresso. Retorna {"moedas", "acucar", "bau"?, "movel"?,
## "primeira": bool}.
func concluir() -> Dictionary:
	if not acabou():
		return {}
	# os doces do time aprendem lutando (mais na vitória)
	for lutador in meu_time:
		Companheiros.ganhar_xp(lutador["id"], XP_LUTA_DERROTA if perdeu() else XP_LUTA_VITORIA)
	if perdeu():
		Confeitaria.ganhar_acucar(ACUCAR_DERROTA)
		return {"moedas": 0, "acucar": ACUCAR_DERROTA, "primeira": false}
	var ganho := premio(indice)
	ganho["primeira"] = not vencido(indice)
	var e := _estado()
	if ganho["primeira"]:
		e["vencidos"].append(indice)
	e["vitorias"] = int(e["vitorias"]) + 1
	Confeitaria.ganhar_acucar(int(ganho["acucar"]))
	if ganho.has("bau"):
		Baus.ganhar(ganho["bau"])
	if ganho.has("movel"):
		Casa.ganhar_movel(ganho["movel"])
	Progresso.ganhar_moedas(int(ganho["moedas"]))  # também salva
	return ganho
