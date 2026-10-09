class_name Historia
## HISTÓRIAS DA VILA: missões dos moradores contadas em capítulos. Cada
## capítulo é uma pequena aventura com falas e passos:
##   "falar"    – falar com um morador (chegue perto e toque em FALAR);
##   "ir"       – ir até um lugar da vila (ver LUGARES);
##   "pergunta" – o morador faz uma pergunta do quiz (errar pode tentar de novo);
##   "fazer"    – fazer algo nos jogos (mesmos eventos das missões diárias,
##                ver Missoes.registrar): "soma" junta várias vezes, "max"
##                precisa numa vez só (ex.: 10 andares numa torre);
##   "entregar" – dar açúcar ao morador.
## O capítulo seguinte abre quando o anterior acaba E o jogador chega ao
## nível pedido. Terminar dá o prêmio (moedas, açúcar, XP, baú e às vezes um
## móvel exclusivo para a Minha Casa).
##
## Estado em Progresso.vila["historia"] = {"capitulo", "passo", "progresso"}.

## Moradores da história: id do doce -> nome.
const MORADORES := {"milho_doce": "SEU MILHO", "bala_verde": "DONA BALA"}

## Lugares da vila para os passos "ir": [centro, raio, nome].
const LUGARES := {
	"praca": [Vector3(0, 0, 0), 5.5, "a fonte da praça"],
	"lago": [Vector3(-30, 0, 12), 8.0, "o Lago de Chocolate"],
	"mirante": [Vector3(30, 0, 12), 7.0, "o Mirante do Sorvete"],
	"terrenos": [Vector3(0, 0, -27), 9.0, "o Bairro dos Terrenos"],
	"fabrica": [Vector3(-10.3, 0, 5.4), 3.5, "a porta da Fábrica de Chocolate"],
	"torre": [Vector3(10.3, 0, 5.4), 3.5, "a porta da Torre de Doces"],
	"casa": [Vector3(0, 0, 17), 3.5, "a porta da sua casa"],
}

const CAPITULOS := [
	{"titulo": "O SUMIÇO DO GRANULADO", "nivel": 1,
		"premio": {"moedas": 40, "xp": 30},
		"passos": [
			{"tipo": "falar", "quem": "milho_doce", "meta_texto": "Fale com o Seu Milho na praça",
				"falas": ["Oi, oi! Que bom que você chegou!", "O granulado colorido da fonte da praça SUMIU! Sem ele a fonte fica tão sem graça...",
					"Você me ajuda a descobrir o que aconteceu? Comece olhando a fonte!"]},
			{"tipo": "ir", "onde": "praca", "meta_texto": "Examine a fonte da praça",
				"falas": ["Olhando bem, tem um rastro de granulado no chão...", "Ele vai para o oeste, na direção do Lago de Chocolate!"]},
			{"tipo": "ir", "onde": "lago", "meta_texto": "Siga o rastro até o Lago de Chocolate",
				"falas": ["Achou! Um potão de granulado na beira do lago.", "Um bilhete: \"Peguei emprestado para enfeitar o barquinho. Desculpa! – Sapinho de Goma\"",
					"Mistério resolvido! Leve o pote de volta para o Seu Milho."]},
			{"tipo": "falar", "quem": "milho_doce", "meta_texto": "Leve o granulado para o Seu Milho",
				"falas": ["O meu granulado! E ainda com um bilhete fofo...", "Obrigado, detetive! Tome uma recompensa. A vila tem sorte de ter você!"]},
		]},
	{"titulo": "AULA ESPECIAL", "nivel": 2,
		"premio": {"moedas": 50, "acucar": 40, "xp": 40},
		"passos": [
			{"tipo": "falar", "quem": "bala_verde", "meta_texto": "Fale com a Dona Bala",
				"falas": ["Olá, docinho! Sou a Dona Bala, professora aposentada da Escola.", "Estou montando um quiz para as crianças da vila. Me ajuda a testar as perguntas?"]},
			{"tipo": "pergunta", "quem": "bala_verde", "meta_texto": "Responda a pergunta da Dona Bala",
				"falas": ["Primeira pergunta! Vamos ver se está boa..."]},
			{"tipo": "pergunta", "quem": "bala_verde", "meta_texto": "Responda mais uma pergunta",
				"falas": ["Muito bem! Agora uma segunda..."]},
			{"tipo": "fazer", "evento": "partidas", "meta": 1, "meta_texto": "Jogue uma partida do quiz na Escola",
				"falas": ["Perguntas testadas! Agora vá jogar uma partida na Escola, para aquecer a cabeça."]},
			{"tipo": "falar", "quem": "bala_verde", "meta_texto": "Conte para a Dona Bala como foi",
				"falas": ["Jogou? Que orgulho! As crianças vão amar o quiz.", "Leve este açúcar. Professora que se preze sempre tem um docinho na bolsa!"]},
		]},
	{"titulo": "FESTA NA PRAÇA", "nivel": 3,
		"premio": {"moedas": 80, "xp": 50, "movel": "banco_praca"},
		"passos": [
			{"tipo": "falar", "quem": "bala_verde", "meta_texto": "Fale com a Dona Bala",
				"falas": ["Vai ter FESTA na praça! E eu fiquei com a parte dos doces...", "Você atende uns clientes na Confeitaria para a gente juntar doces?"]},
			{"tipo": "fazer", "evento": "clientes", "meta": 5, "meta_texto": "Atenda 5 clientes na Confeitaria",
				"falas": ["Cinco clientes felizes! A Confeitaria está bombando."]},
			{"tipo": "entregar", "quem": "bala_verde", "acucar": 50, "meta_texto": "Leve 50 de açúcar para a Dona Bala",
				"falas": ["Agora só falta açúcar para a calda da festa... Pode me dar 50?"]},
			{"tipo": "falar", "quem": "bala_verde", "meta_texto": "Fale com a Dona Bala",
				"falas": ["A festa vai ser um sucesso! Tome: um banco da praça para a sua casa.", "Assim você lembra da festa sempre que sentar nele!"]},
		]},
	{"titulo": "A TORRE MAIS ALTA", "nivel": 4,
		"premio": {"moedas": 100, "xp": 60, "bau": "doce"},
		"passos": [
			{"tipo": "falar", "quem": "milho_doce", "meta_texto": "Fale com o Seu Milho",
				"falas": ["Sabia que dá para ver a vila inteira do alto da Torre de Doces?", "Aposto que você não empilha 10 andares numa torre só!"]},
			{"tipo": "fazer", "evento": "torre", "meta": 10, "modo": "max", "meta_texto": "Empilhe 10 andares numa partida da Torre",
				"falas": ["Dez andares! O Seu Milho vai ficar de queixo caído."]},
			{"tipo": "ir", "onde": "mirante", "meta_texto": "Vá até o Mirante do Sorvete ver a vista",
				"falas": ["Do mirante dá para ver a torre que você fez lá longe. Que vista!", "Volte para a praça e conte para o Seu Milho."]},
			{"tipo": "falar", "quem": "milho_doce", "meta_texto": "Fale com o Seu Milho",
				"falas": ["DEZ ANDARES?! Perdi a aposta, justo...", "Tome o baú que eu tinha guardado. Você é o doce mais alto da vila!"]},
		]},
	{"titulo": "O SEGREDO DA FÁBRICA", "nivel": 5,
		"premio": {"moedas": 150, "acucar": 60, "xp": 80, "movel": "retrato_vila"},
		"passos": [
			{"tipo": "falar", "quem": "bala_verde", "meta_texto": "Fale com a Dona Bala",
				"falas": ["Psiu... dizem que a Fábrica de Chocolate tem uma receita secreta.", "Quem completar pedidos lá dentro ganha a confiança do mestre chocolateiro!"]},
			{"tipo": "fazer", "evento": "fabrica", "meta": 5, "meta_texto": "Complete 5 pedidos na Fábrica de Chocolate",
				"falas": ["O mestre chocolateiro gostou! Ele deixou um enigma na porta da fábrica."]},
			{"tipo": "ir", "onde": "fabrica", "meta_texto": "Vá até a porta da Fábrica",
				"falas": ["Na porta tem um papel: \"A receita secreta é só para quem sabe a resposta\"."]},
			{"tipo": "pergunta", "quem": "bala_verde", "meta_texto": "Resolva o enigma com a Dona Bala",
				"falas": ["Me mostra o enigma! Vamos pensar juntos..."]},
			{"tipo": "falar", "quem": "bala_verde", "meta_texto": "Fale com a Dona Bala",
				"falas": ["A receita secreta era... AMOR PELOS DOCES! Quem diria.", "Tome este retrato da vila para pendurar na sua casa. Você é parte da nossa história!"]},
		]},
]


static func _estado() -> Dictionary:
	if not Progresso.vila.has("historia"):
		Progresso.vila["historia"] = {"capitulo": 0, "passo": 0, "progresso": 0}
	return Progresso.vila["historia"]


static func capitulo() -> int:
	return int(_estado()["capitulo"])


static func terminou_tudo() -> bool:
	return capitulo() >= CAPITULOS.size()


## Se o capítulo atual já pode começar (nível do jogador).
static func liberado() -> bool:
	return not terminou_tudo() and Experiencia.nivel() >= int(CAPITULOS[capitulo()]["nivel"])


## O passo de agora ({} se acabou tudo ou o capítulo ainda está trancado).
static func passo_atual() -> Dictionary:
	if not liberado():
		return {}
	return CAPITULOS[capitulo()]["passos"][int(_estado()["passo"])]


static func progresso() -> int:
	return int(_estado()["progresso"])


## Texto do que fazer agora (para o quadro da história na vila).
static func texto_meta() -> String:
	if terminou_tudo():
		return "Você terminou todas as histórias da vila!"
	if not liberado():
		return "Próximo capítulo no nível %d do jogador." % int(CAPITULOS[capitulo()]["nivel"])
	var p := passo_atual()
	var texto: String = p["meta_texto"]
	if p["tipo"] == "fazer" and str(p.get("modo", "soma")) == "soma":
		texto += " (%d/%d)" % [progresso(), int(p["meta"])]
	return texto


## Morador que o jogador precisa procurar agora ("" = nenhum).
static func morador_da_vez() -> String:
	var p := passo_atual()
	return str(p.get("quem", "")) if p.get("tipo", "") in ["falar", "pergunta", "entregar"] else ""


## Lugar do passo "ir" de agora ("" = nenhum).
static func lugar_da_vez() -> String:
	var p := passo_atual()
	return str(p.get("onde", "")) if p.get("tipo", "") == "ir" else ""


## Chegou ao lugar do passo "ir"? Avança e retorna as falas (ou []).
static func chegou(posicao: Vector3) -> Array:
	var onde := lugar_da_vez()
	if onde == "":
		return []
	var l: Array = LUGARES[onde]
	if Vector2(posicao.x - l[0].x, posicao.z - l[0].z).length() > float(l[1]):
		return []
	var falas: Array = passo_atual()["falas"]
	avancar()
	return falas


## Eventos dos jogos (chamado por Missoes.registrar).
static func registrar(evento: String, quantidade: int) -> void:
	var p := passo_atual()
	if p.get("tipo", "") != "fazer" or p["evento"] != evento:
		return
	var e := _estado()
	if str(p.get("modo", "soma")) == "max":
		e["progresso"] = maxi(progresso(), quantidade)
	else:
		e["progresso"] = progresso() + quantidade
	if progresso() >= int(p["meta"]):
		e["pendente"] = p["falas"]  # a vila mostra as falas quando o jogador voltar
		avancar()


## Falas guardadas de um passo "fazer" que terminou fora da vila (e limpa).
static func falas_pendentes() -> Array:
	var falas: Array = _estado().get("pendente", [])
	_estado().erase("pendente")
	return falas


## Passo "entregar": dá o açúcar pedido. Falso se não tem.
static func entregar() -> bool:
	var p := passo_atual()
	if p.get("tipo", "") != "entregar" or not Confeitaria.gastar_acucar(int(p["acucar"])):
		return false
	avancar()
	return true


## Vai para o próximo passo; no fim do capítulo, dá o prêmio e retorna ele
## ({"moedas", "acucar", "xp", "bau", "movel", "capitulo"}), senão {}.
static func avancar() -> Dictionary:
	var e := _estado()
	e["progresso"] = 0
	e["passo"] = int(e["passo"]) + 1
	var premio := {}
	if int(e["passo"]) >= CAPITULOS[capitulo()]["passos"].size():
		premio = (CAPITULOS[capitulo()]["premio"] as Dictionary).duplicate()
		premio["capitulo"] = capitulo()
		e["capitulo"] = capitulo() + 1
		e["passo"] = 0
		e["premio"] = premio  # a vila mostra quando puder
		if premio.has("acucar"):
			Confeitaria.ganhar_acucar(int(premio["acucar"]))
		if premio.has("xp"):
			Experiencia.ganhar(int(premio["xp"]))
		if premio.has("bau"):
			Baus.ganhar(premio["bau"])
		if premio.has("movel"):
			Casa.ganhar_movel(premio["movel"])
		Progresso.ganhar_moedas(int(premio.get("moedas", 0)))  # também salva
	else:
		Progresso.salvar()
	return premio


## Prêmio de capítulo terminado que ainda não foi mostrado (e limpa).
static func premio_pendente() -> Dictionary:
	var premio: Dictionary = _estado().get("premio", {})
	_estado().erase("premio")
	return premio
