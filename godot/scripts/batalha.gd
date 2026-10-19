class_name Batalha
extends RefCounted
## BATALHA DE DOCES (na Arena da vila): o seu time de até TAMANHO_TIME doces
## da coleção contra o time de um desafiante, numa LUTA EM TEMPO REAL (como os
## jogos de luta e de futebol do celular): o JOYSTICK anda para frente e para
## trás e os BOTÕES REDONDOS dão os golpes (GOLPES): SOCO (rápido), VOADORA
## (forte, mas fica sem guarda um instante) e PIRUETA (muito forte, com recarga).
## - DISTÂNCIA: de perto (até PERTO metros) o golpe é CERTO; de longe também dá
##   para bater (o doce dá um bote), mas a chance de acertar cai com a distância.
##   Golpe que acerta empurra o outro para trás.
## - O DESAFIANTE anda sozinho, se prepara (o aviso "!", telegrafo() segundos) e
##   ataca: dá tempo de se afastar para ele errar (os de cima avisam em cima da hora).
## - PERGUNTA RELÂMPAGO: de tempos em tempos (INTERVALO_PERGUNTA) a luta para e
##   vem uma pergunta do quiz: acertou, ganha 1 de ENERGIA e fica TURBINADO
##   (golpes mais fortes por TEMPO_TURBO s); errou, o desafiante bate de graça.
## - GOLPE SUPREMO: com a energia cheia (SUPER_COM), o botão acende; usar faz uma
##   pergunta: acertou, o supremo ACERTA (DANO_SUPREMO, mais forte se rápido);
##   errou, ERRA. A energia zera (a mesma ideia do turbo da corrida).
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
const SUPER_COM := 3  # energia (perguntas relâmpago certas) para o GOLPE SUPREMO
const TEMPO := 20.0  # segundos por pergunta
const RAPIDO := 6.0  # respondeu o supremo em até 6 s: SUPREMO RÁPIDO (+25%)
## Golpes dos botões: "dano" (vezes o ataque do doce), "recarga" (segundos até
## poder usar de novo), "duracao" (segundos do movimento: não anda nem bate
## outro), "aberto" (segundos sem guarda depois dele: o golpe do outro dói
## SEM_GUARDA vezes mais) e "empurra" (metros que o golpe certo empurra).
const GOLPES := {
	"soco": {"nome": "SOCO", "dano": 0.12, "recarga": 0.15, "duracao": 0.3, "aberto": 0.0, "empurra": 0.3},
	"voadora": {"nome": "VOADORA", "dano": 0.32, "recarga": 1.5, "duracao": 0.55, "aberto": 0.8, "empurra": 1.0},
	"pirueta": {"nome": "PIRUETA", "dano": 0.6, "recarga": 5.0, "duracao": 0.6, "aberto": 0.0, "empurra": 1.4},
}
const DANO_SUPREMO := 2.0
const EMPURRAO_SUPREMO := 2.0
const DURACAO_SUPREMO := 1.0  # o tornado (não anda nem bate enquanto gira)
const SEM_GUARDA := 1.5
## A arena tem ARENA metros; cada doce começa a INICIO metros da sua ponta.
const ARENA := 10.0
const INICIO := 2.5
const VELOCIDADE := 3.6  # metros por segundo
const SEPARACAO := 1.3  # um não atravessa o outro
const PERTO := 2.0  # até aqui o golpe é certo
const LONGE := 7.0  # daqui para lá, a menor chance (CHANCE_LONGE)
const CHANCE_LONGE := 0.2
## O desafiante: dano por golpe (vezes o ataque dele), até onde o golpe dele
## alcança (dá para fugir no aviso), o aviso antes de bater (ver telegrafo),
## quanto dura o golpe e a pausa entre um ataque e outro (encurta nos
## desafiantes mais fortes).
const DANO_DELES := 0.3
const ALCANCE_DELES := 3.5
const TELEGRAFO := 0.8  # o aviso do primeiro desafiante...
const TELEGRAFO_REI := 0.45  # ... e o do último (os de cima avisam mais em cima da hora)
const DURACAO_DELES := 0.5
const EMPURRAO_DELES := 0.9
const PAUSA_DELES := Vector2(1.2, 2.4)
const ENTRADA := 1.8  # nocaute: a luta espera o próximo do time entrar
## Perguntas relâmpago: a primeira e o intervalo (segundos de luta).
const PRIMEIRA_PERGUNTA := 4.0
const INTERVALO_PERGUNTA := 9.0
const TURBO := 1.3  # acertou a relâmpago: golpes mais fortes por TEMPO_TURBO s
const TEMPO_TURBO := 6.0
const DANO_DE_GRACA := 0.9  # errou a relâmpago: o golpe de graça dele (vezes o ataque)
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
var energia := 0  # perguntas relâmpago certas (o GOLPE SUPREMO pede SUPER_COM)
## "luta" (andando e batendo), "pergunta" (a relâmpago, com a luta parada) ou
## "supremo" (a pergunta do seu golpe supremo).
var fase := "luta"
var x_meu := INICIO
var x_deles := ARENA - INICIO
var tempo_luta := 0.0
var recargas := {}  # golpe -> segundos que faltam
var ocupado := 0.0  # segundos do seu golpe em andamento (não anda nem bate)
var sem_guarda := 0.0  # segundos sem guarda (depois da voadora)
var turbo := 0.0  # segundos de turbo (pergunta relâmpago certa)
var entrada := 0.0  # segundos até o próximo do time entrar (depois de um nocaute)
var proxima_pergunta_em := PRIMEIRA_PERGUNTA
## O desafiante: "andando" ou "preparando" (o aviso antes do golpe).
var estado_deles := "andando"
var _espera_deles := 1.5
var _prepara := 0.0
var _ocupado_deles := 0.0
var _distancia_preferida := 1.6
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


# --- A luta em tempo real ----------------------------------------------------------------

func distancia() -> float:
	return x_deles - x_meu


## Segundos entre o aviso ("!") e o golpe do desafiante: menos nos de cima da escada.
func telegrafo() -> float:
	return lerpf(TELEGRAFO, TELEGRAFO_REI, float(indice) / (DESAFIANTES.size() - 1))


## Chance do seu golpe acertar a esta distância: certo de perto, menor de longe.
static func chance(dist: float) -> float:
	if dist <= PERTO:
		return 1.0
	return lerpf(1.0, CHANCE_LONGE, clampf((dist - PERTO) / (LONGE - PERTO), 0.0, 1.0))


## Chance do golpe do desafiante: certo de perto, nenhuma a ALCANCE_DELES.
static func chance_deles(dist: float) -> float:
	if dist <= PERTO:
		return 1.0
	return clampf(1.0 - (dist - PERTO) / (ALCANCE_DELES - PERTO), 0.0, 1.0)


## Segundos que faltam para poder usar o golpe de novo (0 = pode).
func recarga(tipo: String) -> float:
	return float(recargas.get(tipo, 0.0))


## A luta está correndo (sem pergunta, sem nocaute esperando o próximo).
func correndo() -> bool:
	return fase == "luta" and not acabou() and entrada <= 0.0


func pode_golpear(tipo: String) -> bool:
	return correndo() and ocupado <= 0.0 and GOLPES.has(tipo) and recarga(tipo) <= 0.0


func pode_supremo() -> bool:
	return correndo() and ocupado <= 0.0 and energia >= SUPER_COM


## Avança a luta `delta` segundos com o joystick em `direcao` (-1 para trás, 1
## para frente): anda, o desafiante decide o que fazer e chegam as perguntas.
## Parada enquanto há pergunta (e um instante depois de um nocaute). Retorna os
## eventos: {"tipo": "prepara"} (o aviso: ele vai bater), {"tipo": "golpe", ...}
## (o golpe dele, como os de golpear, com "atacante": "deles") e {"tipo":
## "pergunta", "pergunta": {...}} (a relâmpago; responda com responder).
func avancar(delta: float, direcao: float) -> Array:
	var eventos := []
	if fase != "luta" or acabou():
		return eventos
	if entrada > 0.0:
		entrada = maxf(0.0, entrada - delta)
		return eventos
	tempo_luta += delta
	for tipo in recargas.keys():
		recargas[tipo] = maxf(0.0, float(recargas[tipo]) - delta)
	sem_guarda = maxf(0.0, sem_guarda - delta)
	turbo = maxf(0.0, turbo - delta)
	if ocupado > 0.0:
		ocupado = maxf(0.0, ocupado - delta)
	else:
		x_meu = clampf(x_meu + clampf(direcao, -1.0, 1.0) * VELOCIDADE * delta, 0.0, x_deles - SEPARACAO)
	_pensar_deles(delta, eventos)
	if tempo_luta >= proxima_pergunta_em and estado_deles == "andando" and ocupado <= 0.0 \
			and _ocupado_deles <= 0.0 and correndo():
		proxima_pergunta_em = tempo_luta + INTERVALO_PERGUNTA
		fase = "pergunta"
		eventos.append({"tipo": "pergunta", "pergunta": proxima_pergunta()})
	return eventos


## O desafiante chega perto (às vezes fica mais longe), avisa e bate.
func _pensar_deles(delta: float, eventos: Array) -> void:
	if _ocupado_deles > 0.0:
		_ocupado_deles = maxf(0.0, _ocupado_deles - delta)
		return
	var dist := distancia()
	if estado_deles == "andando":
		var vai := 0.0
		if dist > _distancia_preferida + 0.3:
			vai = -1.0
		elif dist < _distancia_preferida - 0.3:
			vai = 1.0
		x_deles = clampf(x_deles + vai * VELOCIDADE * 0.8 * delta, x_meu + SEPARACAO, ARENA)
		_espera_deles -= delta
		if _espera_deles <= 0.0 and dist <= ALCANCE_DELES:
			estado_deles = "preparando"
			_prepara = telegrafo()
			eventos.append({"tipo": "prepara"})
	else:
		_prepara -= delta
		if _prepara <= 0.0:
			estado_deles = "andando"
			var mais_rapido := 1.0 - 0.05 * indice  # os desafiantes de cima batem mais vezes
			_espera_deles = _sorteio.randf_range(PAUSA_DELES.x, PAUSA_DELES.y) * mais_rapido
			_distancia_preferida = _sorteio.randf_range(1.3, 2.8)
			eventos.append(_golpe_deles(DANO_DELES))


## O golpe do desafiante (`forca` vezes o ataque dele; `certo` = não dá para
## desviar, o de graça da pergunta errada).
func _golpe_deles(forca: float, certo := false) -> Dictionary:
	_ocupado_deles = DURACAO_DELES
	var dist := distancia()
	var acertou := certo or _sorteio.randf() < chance_deles(dist)
	var r: Dictionary
	if acertou:
		var dano := int(deles()["ataque"]) * forca * (SEM_GUARDA if sem_guarda > 0.0 else 1.0) * _sorteio.randf_range(0.9, 1.1)
		r = _bater_em_mim(maxi(1, roundi(dano)), EMPURRAO_DELES)
	else:
		r = _resultado("deles", 0)
		r["esquivou"] = true
	r["tipo"] = "golpe"
	r["golpe"] = "dele"
	r["acertou"] = acertou
	r["distancia"] = dist
	return r


## Seu golpe dos botões (de qualquer distância: de perto é certo, de longe pode
## errar). Retorna {"tipo": "golpe", "atacante": "meu", "golpe", "acertou",
## "errou", "dano", "nocaute", "entrou", "fim", "distancia"} ({} se não pode).
func golpear(tipo: String) -> Dictionary:
	if not pode_golpear(tipo):
		return {}
	rodadas += 1
	var dados: Dictionary = GOLPES[tipo]
	recargas[tipo] = float(dados["recarga"])
	ocupado = float(dados["duracao"])
	sem_guarda = maxf(sem_guarda, float(dados["aberto"]))
	var dist := distancia()
	var acertou := _sorteio.randf() < chance(dist)
	var r: Dictionary
	if acertou:
		var dano := int(meu()["ataque"]) * float(dados["dano"]) * (TURBO if turbo > 0.0 else 1.0) * _sorteio.randf_range(0.9, 1.1)
		r = _bater_neles(maxi(1, roundi(dano)), float(dados["empurra"]))
		r["turbo"] = turbo > 0.0
	else:
		r = _resultado("meu", 0)
		r["errou"] = true
	r["tipo"] = "golpe"
	r["golpe"] = tipo
	r["acertou"] = acertou
	r["distancia"] = dist
	return r


## Usa o GOLPE SUPREMO: a luta para e vem a pergunta dele (responder decide).
func pedir_supremo() -> Dictionary:
	if not pode_supremo():
		return {}
	rodadas += 1
	fase = "supremo"
	return proxima_pergunta()


## Responde a pergunta da vez (`escolha` -1 = acabou o tempo; `tempo` = segundos
## que levou), e a luta volta:
## - fase "pergunta" (relâmpago): acertou, +1 de energia e TURBO; errou, o
##   desafiante dá um golpe de graça (certo).
## - fase "supremo": acertou, o supremo acerta de qualquer distância (+25% se
##   rápido); errou, erra ("errou"). A energia zera.
## Retorna o golpe que aconteceu (como golpear; "atacante": "ninguem" se
## nenhum) com "acertou_pergunta" e "fase" (a pergunta respondida).
func responder(escolha: int, tempo: float) -> Dictionary:
	if acabou() or pergunta.is_empty() or fase == "luta":
		return {}
	var acertou := escolha == int(pergunta["resposta"])
	var de_onde := fase
	pergunta = {}
	respondidas += 1
	if acertou:
		acertos += 1
	fase = "luta"
	var r: Dictionary
	if de_onde == "supremo":
		energia = 0
		ocupado = DURACAO_SUPREMO
		if acertou:
			var dano := int(meu()["ataque"]) * DANO_SUPREMO * _sorteio.randf_range(0.95, 1.05)
			var rapido := tempo <= RAPIDO
			if rapido:
				dano *= 1.25
			r = _bater_neles(roundi(dano), EMPURRAO_SUPREMO)
			r["rapido"] = rapido
		else:
			r = _resultado("meu", 0)
			r["errou"] = true
		r["golpe"] = "supremo"
		r["super"] = true
		r["acertou"] = acertou
	elif acertou:
		energia = mini(SUPER_COM, energia + 1)
		turbo = TEMPO_TURBO
		r = _resultado("ninguem", 0)
	else:
		r = _golpe_deles(DANO_DE_GRACA, true)
	r["tipo"] = "golpe"
	r["acertou_pergunta"] = acertou
	r["fase"] = de_onde
	return r


func _resultado(atacante: String, dano: int) -> Dictionary:
	return {"atacante": atacante, "dano": dano, "esquivou": false, "errou": false, "super": false, "rapido": false,
		"turbo": false, "nocaute": false, "entrou": "", "fim": "", "acertou": false}


## Bate no doce deles (e empurra `empurra` metros para trás).
func _bater_neles(dano: int, empurra: float) -> Dictionary:
	var r := _resultado("meu", dano)
	var alvo: Dictionary = deles()
	alvo["vida"] = maxi(0, int(alvo["vida"]) - dano)
	x_deles = minf(ARENA, x_deles + empurra)
	if int(alvo["vida"]) <= 0:
		r["nocaute"] = true
		deles_atual += 1
		r["entrou"] = deles().get("id", "")
		_recomecar()
	_fim(r)
	return r


func _bater_em_mim(dano: int, empurra: float) -> Dictionary:
	var r := _resultado("deles", dano)
	var alvo: Dictionary = meu()
	alvo["vida"] = maxi(0, int(alvo["vida"]) - dano)
	x_meu = maxf(0.0, x_meu - empurra)
	if int(alvo["vida"]) <= 0:
		r["nocaute"] = true
		meu_atual += 1
		r["entrou"] = meu().get("id", "")
		_recomecar()
	_fim(r)
	return r


## Nocaute: cada um volta para o seu canto e a luta espera o próximo entrar.
func _recomecar() -> void:
	x_meu = INICIO
	x_deles = ARENA - INICIO
	estado_deles = "andando"
	_espera_deles = 1.2
	_ocupado_deles = 0.0
	ocupado = 0.0
	sem_guarda = 0.0
	entrada = ENTRADA


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
