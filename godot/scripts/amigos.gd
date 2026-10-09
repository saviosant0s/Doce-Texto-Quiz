class_name Amigos
extends RefCounted
## VILA DOS AMIGOS e RANKING DA SEMANA, sem servidor: cada jogador tem um
## CÓDIGO DA VILA (texto curto que dá para copiar ou mandar pelo WhatsApp)
## com o nome, o doce companheiro, o nível, os terrenos, a confeitaria, as
## regiões, a Minha Casa e os pontos da semana. Quem cola o código adiciona o
## amigo: pode VISITAR a vila dele (só olhando; ver Vila.visita) e comparar os
## pontos no ranking da semana. O código muda conforme a pessoa joga: para o
## ranking ficar em dia, o amigo manda o código de novo (o mesmo amigo é
## atualizado, não repete).
##
## PONTOS DA SEMANA (de segunda a domingo): quase tudo que se faz no jogo vale
## pontos (PONTOS, contados em Missoes.registrar); zeram toda segunda.
##
## Estado em Progresso.jogador: "id" (do jogador, sorteado uma vez), "nome",
## "semana" = {"id", "pontos"}, "amigos" = [dados de cada amigo (ver
## decodificar), com "recebido" = quando o código chegou] e "visita_dia".

const PREFIXO := "DTQ1-"
const SAL := "doce-texto-quiz-vila"
const NOME_MAXIMO := 14
const AMIGOS_MAXIMO := 30
## Pontos da semana por coisa feita (os eventos de Missoes.registrar).
const PONTOS := {
	"acertos": 10, "partidas": 5, "estrelas": 25, "lab_fases": 30, "clientes": 3, "match": 15,
	"torre": 2, "fabrica": 8, "corrida": 20, "chefao": 60,
}
## Visitar um amigo: um prêmio por dia (de verdade).
const PREMIO_VISITA := {"acucar": 10, "moedas": 5}


static func _eu() -> Dictionary:
	var j := Progresso.jogador
	if not j.has("id") or str(j["id"]) == "":
		var sorteio := RandomNumberGenerator.new()
		sorteio.randomize()
		j["id"] = "%08x" % sorteio.randi()
	if not j.has("amigos"):
		j["amigos"] = []
	return j


static func meu_id() -> String:
	return str(_eu()["id"])


static func nome() -> String:
	return str(_eu().get("nome", ""))


## Guarda o nome (letras, números e espaço; até NOME_MAXIMO). Retorna o nome final.
static func escolher_nome(texto: String) -> String:
	var limpo := ""
	for letra in texto.strip_edges().to_upper():
		if letra.is_valid_identifier() or letra in "0123456789 ÁÉÍÓÚÂÊÔÃÕÇÀÜ":
			limpo += letra
	limpo = limpo.strip_edges().substr(0, NOME_MAXIMO)
	_eu()["nome"] = limpo
	Progresso.salvar()
	return limpo


# --- Pontos da semana ---------------------------------------------------------------

## Número da semana (segunda a domingo) de um instante (segundos desde 1970).
static func semana(agora := -1.0) -> int:
	var t := agora if agora >= 0.0 else Terrenos.agora()
	t += int(Time.get_time_zone_from_system().get("bias", 0)) * 60.0  # vira à meia-noite do aparelho
	var dias := floori(t / 86400.0)
	return floori((dias + 3) / 7.0)  # 01/01/1970 foi quinta-feira


## Segunda-feira e domingo da semana, "06/10 a 12/10".
static func texto_semana(numero := -1) -> String:
	var n := numero if numero >= 0 else semana()
	var segunda := (n * 7 - 3) * 86400
	var inicio := Time.get_date_dict_from_unix_time(segunda)
	var fim := Time.get_date_dict_from_unix_time(segunda + 6 * 86400)
	return "%02d/%02d a %02d/%02d" % [inicio["day"], inicio["month"], fim["day"], fim["month"]]


static func pontos_da_semana() -> int:
	var s: Dictionary = _eu().get("semana", {})
	return int(s.get("pontos", 0)) if int(s.get("id", -1)) == semana() else 0


## Chamado por Missoes.registrar: soma os pontos da semana.
static func registrar(evento: String, quantidade: int) -> void:
	if not PONTOS.has(evento) or quantidade <= 0:
		return
	_eu()["semana"] = {"id": semana(), "pontos": pontos_da_semana() + int(PONTOS[evento]) * quantidade}


# --- Código da vila -----------------------------------------------------------------

## O que vai no código: tudo o que aparece numa visita e no ranking.
static func meus_dados() -> Dictionary:
	var doce := Colecao.companheiro()
	if doce == "" or not Colecao.tem(doce):
		doce = "brigadeiro"
	var lotes := {}
	for id in Progresso.vila.get("lotes", {}):
		lotes[id] = [Terrenos.construcao(id), Terrenos.nivel(id)]
	var maquinas := {}
	for m in Confeitaria.MAQUINAS:
		if Confeitaria.construida(m["id"]):
			maquinas[m["id"]] = Confeitaria.nivel(m["id"])
	var casa: Dictionary = Progresso.vila.get("casa", Casa.padrao())
	var moveis := []
	for c in casa.get("colocados", []):
		moveis.append([c["id"], int(c["x"]), int(c["z"]), int(c.get("giro", 0))])
	var titulos := ""
	for t in ["noob", "pro", "mestre"]:
		titulos += "1" if Quiz.tem_titulo(t) else "0"
	return {
		"v": 1, "i": meu_id(), "n": nome(), "d": doce, "dn": Companheiros.nivel(doce),
		"l": Experiencia.nivel(), "t": titulos, "q": Colecao.quantidade(), "lo": lotes, "m": maquinas,
		"r": Regioes._estado()["exploradas"].duplicate(), "a": Progresso.vila.get("arena", {}).get("vencidos", []).size(),
		"c": {"t": int(casa.get("tamanho", 0)), "p": str(casa.get("parede", "creme")), "pi": str(casa.get("piso", "madeira")), "o": moveis},
		"s": [semana(), pontos_da_semana()],
	}


static func _assinatura(texto: String) -> String:
	return (SAL + texto).sha256_text().substr(0, 6)


static func codificar(dados: Dictionary) -> String:
	var texto := JSON.stringify(dados)
	var bytes := texto.to_utf8_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	var base := Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")
	return PREFIXO + base + "." + _assinatura(base)


static func meu_codigo() -> String:
	return codificar(meus_dados())


## Lê um código (pode vir no meio de uma mensagem ou de um link). Vazio se
## não for um código válido (cortado, mexido ou de outra coisa).
static func decodificar(texto: String) -> Dictionary:
	var inicio := texto.find(PREFIXO)
	if inicio < 0:
		return {}
	var resto := texto.substr(inicio + PREFIXO.length())
	var fim := 0
	while fim < resto.length() and (resto[fim].is_valid_identifier() or resto[fim] in "0123456789-_."):
		fim += 1
	var partes := resto.substr(0, fim).split(".")
	if partes.size() != 2 or _assinatura(partes[0]) != partes[1]:
		return {}  # cortado ou mexido
	var base := partes[0].replace("-", "+").replace("_", "/")
	while base.length() % 4 != 0:
		base += "="
	var bytes := Marshalls.base64_to_raw(base)
	if bytes.is_empty():
		return {}
	var aberto := bytes.decompress_dynamic(64 * 1024, FileAccess.COMPRESSION_DEFLATE)
	if aberto.is_empty():
		return {}
	var dados = JSON.parse_string(aberto.get_string_from_utf8())
	if not dados is Dictionary or int(dados.get("v", 0)) != 1 or str(dados.get("i", "")) == "":
		return {}
	return dados


## Mensagem pronta para mandar (com o link do jogo no navegador, que já abre a visita).
static func mensagem() -> String:
	var codigo := meu_codigo()
	return "Visite a minha vila no Doce Texto Quiz! Abra o jogo, toque em AMIGOS e cole este código:\n%s\nOu jogue no navegador: https://saviosant0s.github.io/Doce-Texto-Quiz/?vila=%s" % [codigo, codigo]


# --- Amigos -------------------------------------------------------------------------

static func lista() -> Array:
	return _eu()["amigos"]


static func amigo(id: String) -> Dictionary:
	for a in lista():
		if str(a["i"]) == id:
			return a
	return {}


## Adiciona (ou atualiza) o amigo do código. Retorna {"ok": bool, "texto": aviso, "amigo": dados}.
static func adicionar(texto: String) -> Dictionary:
	var dados := decodificar(texto)
	if dados.is_empty():
		return {"ok": false, "texto": "CÓDIGO INVÁLIDO: COPIE O CÓDIGO INTEIRO (COMEÇA COM %s)" % PREFIXO}
	if str(dados["i"]) == meu_id():
		return {"ok": false, "texto": "ESSE É O SEU CÓDIGO! MANDE PARA OS SEUS AMIGOS"}
	if str(dados.get("n", "")) == "":
		dados["n"] = "AMIGO"
	dados["recebido"] = Terrenos.agora()
	var lista_amigos := lista()
	for k in lista_amigos.size():
		if str(lista_amigos[k]["i"]) == str(dados["i"]):
			lista_amigos[k] = dados
			Progresso.salvar()
			return {"ok": true, "texto": "%s ATUALIZADO!" % dados["n"], "amigo": dados}
	if lista_amigos.size() >= AMIGOS_MAXIMO:
		return {"ok": false, "texto": "VOCÊ JÁ TEM %d AMIGOS: REMOVA UM PARA ADICIONAR OUTRO" % AMIGOS_MAXIMO}
	lista_amigos.append(dados)
	Progresso.salvar()
	return {"ok": true, "texto": "%s ADICIONADO AOS AMIGOS!" % dados["n"], "amigo": dados}


static func remover(id: String) -> void:
	var lista_amigos := lista()
	for k in range(lista_amigos.size() - 1, -1, -1):
		if str(lista_amigos[k]["i"]) == id:
			lista_amigos.remove_at(k)
	Progresso.salvar()


## Pontos da semana de um amigo (0 se o código dele é de outra semana).
static func pontos_amigo(a: Dictionary) -> int:
	var s: Array = a.get("s", [0, 0])
	return int(s[1]) if s.size() == 2 and int(s[0]) == semana() else 0


## Ranking da semana: você e os amigos, do maior para o menor.
## [{"nome", "pontos", "eu", "doce", "atual" (o código é desta semana)}]
static func ranking() -> Array:
	var linhas := [{"nome": nome() if nome() != "" else "VOCÊ", "pontos": pontos_da_semana(), "eu": true,
		"doce": meus_dados()["d"], "atual": true}]
	for a in lista():
		var s: Array = a.get("s", [0, 0])
		linhas.append({"nome": str(a["n"]), "pontos": pontos_amigo(a), "eu": false, "doce": str(a.get("d", "brigadeiro")),
			"atual": s.size() == 2 and int(s[0]) == semana(), "i": str(a["i"])})
	linhas.sort_custom(func(x, y): return x["pontos"] > y["pontos"] or (x["pontos"] == y["pontos"] and x["eu"]))
	return linhas


## Prêmio de visitar (uma vez por dia). Retorna o prêmio ({} se já ganhou hoje).
static func premiar_visita() -> Dictionary:
	var hoje := floori(Terrenos.agora() / 86400.0)
	if int(_eu().get("visita_dia", -1)) == hoje:
		return {}
	_eu()["visita_dia"] = hoje
	Confeitaria.ganhar_acucar(int(PREMIO_VISITA["acucar"]))
	Progresso.ganhar_moedas(int(PREMIO_VISITA["moedas"]))  # também salva
	return PREMIO_VISITA


# --- Visita -------------------------------------------------------------------------

## O progresso "de mentira" de uma visita: a vila do amigo, montada a partir
## do código (o resto fica como num jogo novo). Ver Progresso.comecar_visita.
static func aplicar_visita(a: Dictionary) -> void:
	var lotes := {}
	var lo: Dictionary = a.get("lo", {})
	for id in lo:
		var par: Array = lo[id]
		lotes[id] = {"construcao": str(par[0]), "nivel": int(par[1]), "desde": 0.0}
	Progresso.vila["lotes"] = lotes
	var maquinas := {}
	var m: Dictionary = a.get("m", {})
	for id in m:
		maquinas[id] = {"nivel": int(m[id]), "progresso": 0.0, "bandeja": 0}
	Progresso.confeitaria["maquinas"] = maquinas
	Progresso.vila["regioes"] = {"exploradas": a.get("r", []).duplicate(), "coletados": {"dia": -1, "ids": []}}
	var vencidos := []
	for k in int(a.get("a", 0)):
		vencidos.append(k)
	Progresso.vila["arena"] = {"vencidos": vencidos, "time": [], "vitorias": vencidos.size()}
	var c: Dictionary = a.get("c", {})
	var casa := Casa.padrao()
	casa["tamanho"] = int(c.get("t", 0))
	casa["parede"] = str(c.get("p", "creme"))
	casa["piso"] = str(c.get("pi", "madeira"))
	var colocados := []
	var moveis := {}
	for o in c.get("o", []):
		colocados.append({"id": str(o[0]), "x": int(o[1]), "z": int(o[2]), "giro": int(o[3])})
		moveis[str(o[0])] = int(moveis.get(str(o[0]), 0)) + 1
	casa["colocados"] = colocados
	casa["moveis"] = moveis
	Progresso.vila["casa"] = casa
	# o chefão não invade a vila de visita (e nada de tutorial)
	Progresso.vila["chefao"] = {"vencidos": 1, "ultima": "visita"}
	var t := str(a.get("t", "000"))
	Progresso.titulos = {"noob": int(t[0] == "1"), "pro": int(t[1] == "1"), "mestre": int(t[2] == "1")}
	for i in Progresso.niveis.size():
		Progresso.niveis[i]["aprovado"] = true
		Progresso.niveis[i]["partidas"] = 1
	Progresso.jogador["nivel"] = int(a.get("l", 1))
	Progresso.jogador["xp"] = 0
	var doce := str(a.get("d", "brigadeiro"))
	if Colecao.dados(doce).is_empty():
		doce = "brigadeiro"
	Progresso.colecao["doces"] = [doce]
	Progresso.colecao["companheiro"] = doce
	Progresso.colecao["niveis"] = {doce: int(a.get("dn", 1))}
