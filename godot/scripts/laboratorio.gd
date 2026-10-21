class_name Laboratorio
## Laboratório do Office: aventura de fases práticas de Excel e Word (dados em
## dados/laboratorio.json). Mapa em capítulos; cada capítulo tem 8 fases, a
## última é o CHEFE (várias tarefas seguidas). Fica na vila (prédio próprio)
## e no menu dos níveis.
##
## - As fases liberam em ordem (passar numa libera a próxima).
## - Estrelas: 3 sem errar e sem dica; 2 com até 2 erros (ou 1 dica); 1 nos
##   outros casos. Dá para jogar de novo para ganhar mais estrelas.
## - Recompensa só na primeira vez (açúcar + moedas) e por estrela nova, para
##   não virar um jeito de ganhar sem aprender. Chefe vale mais.
## - Baús no mapa: um no meio de cada capítulo (depois da 4ª fase) e um depois
##   do chefe. O conteúdo é sorteado (com chance de "SORTE GRANDE", em dobro).
##
## O progresso fica em Progresso.laboratorio ({"estrelas": {id: n},
## "baus": {id: true}}).

const CAMINHO := "res://dados/laboratorio.json"
const ACUCAR_FASE := 20
const MOEDAS_FASE := 10
const ACUCAR_CHEFE := 50
const MOEDAS_CHEFE := 30
const MOEDAS_POR_ESTRELA := 5
## Baús: [moedas mín, máx], [açúcar mín, máx]; o capítulo multiplica
## (1 + 0,25 × capítulo). SORTE_GRANDE = chance de vir em dobro.
const BAUS := {
	"meio": {"nome": "BAÚ DE MADEIRA", "moedas": [20, 40], "acucar": [20, 40], "surpresa": "prata"},
	"chefe": {"nome": "BAÚ DO CHEFE", "moedas": [50, 90], "acucar": [50, 80], "surpresa": "ouro"},
}
const SORTE_GRANDE := 0.15

## Fase aberta na tela da fase (cenas/lab_fase.*).
static var fase_atual := ""
## Fase que acabou de ser feita, para o mapa animar a próxima liberada.
static var recem_concluida := ""
static var _dados: Dictionary = {}


static func capitulos() -> Array:
	if _dados.is_empty():
		_dados = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO))
	return _dados["capitulos"]


## Todas as fases, na ordem, com o número do capítulo em "capitulo".
static func fases() -> Array:
	var lista := []
	for c in capitulos().size():
		for f in capitulos()[c]["fases"]:
			var copia: Dictionary = f.duplicate()
			copia["capitulo"] = c
			lista.append(copia)
	return lista


static func fase(id: String) -> Dictionary:
	for f in fases():
		if f["id"] == id:
			return f
	return {}


static func _estado() -> Dictionary:
	return Progresso.laboratorio


static func estrelas(id: String) -> int:
	return int(_estado()["estrelas"].get(id, 0))


static func concluida(id: String) -> bool:
	return estrelas(id) > 0


static func total_estrelas() -> int:
	var n := 0
	for id in _estado()["estrelas"]:
		n += int(_estado()["estrelas"][id])
	return n


static func estrelas_possiveis() -> int:
	return fases().size() * 3


static func liberada(id: String) -> bool:
	var lista := fases()
	for i in lista.size():
		if lista[i]["id"] == id:
			return i == 0 or concluida(lista[i - 1]["id"])
	return false


## Primeira fase liberada ainda não concluída ("" = terminou tudo).
static func proxima_fase() -> String:
	for f in fases():
		if not concluida(f["id"]):
			return f["id"] if liberada(f["id"]) else ""
	return ""


## Estrelas de uma tentativa, pelos erros e dicas usadas.
static func estrelas_por(erros: int, dicas: int) -> int:
	if erros == 0 and dicas == 0:
		return 3
	if erros + dicas * 2 <= 2:
		return 2
	return 1


## Registra a fase feita e dá a recompensa. Retorna {"estrelas", "novas",
## "primeira", "acucar", "moedas"}.
static func concluir(id: String, n_estrelas: int) -> Dictionary:
	var f := fase(id)
	var antes := estrelas(id)
	var primeira := antes == 0
	var novas := maxi(0, n_estrelas - antes)
	var acucar := 0
	var moedas := novas * MOEDAS_POR_ESTRELA
	if primeira:
		acucar = ACUCAR_CHEFE if f.get("chefe", false) else ACUCAR_FASE
		moedas += MOEDAS_CHEFE if f.get("chefe", false) else MOEDAS_FASE
	if n_estrelas > antes:
		_estado()["estrelas"][id] = n_estrelas
	Missoes.registrar("lab_fases", 1)
	if primeira:
		Experiencia.ganhar(Experiencia.XP_CHEFE if f.get("chefe", false) else Experiencia.XP_FASE)
	else:
		Experiencia.ganhar(Experiencia.XP_FASE_REPETIDA)
	if acucar > 0:
		Confeitaria.ganhar_acucar(acucar)  # também salva
	if moedas > 0:
		Progresso.ganhar_moedas(moedas)  # também salva
	Progresso.salvar()
	return {"estrelas": n_estrelas, "novas": novas, "primeira": primeira, "acucar": acucar, "moedas": moedas}


# --- Baús ------------------------------------------------------------------------

## Baús do mapa: {"id", "tipo" (meio/chefe), "capitulo", "depois_de" (id da fase)}.
static func baus() -> Array:
	var lista := []
	for c in capitulos().size():
		var fs: Array = capitulos()[c]["fases"]
		lista.append({"id": "c%d_meio" % (c + 1), "tipo": "meio", "capitulo": c, "depois_de": fs[3]["id"]})
		lista.append({"id": "c%d_chefe" % (c + 1), "tipo": "chefe", "capitulo": c, "depois_de": fs[-1]["id"]})
	return lista


static func bau(id: String) -> Dictionary:
	for b in baus():
		if b["id"] == id:
			return b
	return {}


static func bau_aberto(id: String) -> bool:
	return _estado()["baus"].has(id)


## Pronto para abrir: a fase de antes foi feita e ele ainda está fechado.
static func bau_pronto(id: String) -> bool:
	var b := bau(id)
	return not b.is_empty() and concluida(b["depois_de"]) and not bau_aberto(id)


static func baus_prontos() -> int:
	return baus().filter(func(b): return bau_pronto(b["id"])).size()


## Abre o baú e dá o conteúdo. Retorna {"nome", "moedas", "acucar", "sorte"}
## ou {} se não estava pronto.
static func abrir_bau(id: String, sorteio: RandomNumberGenerator = null) -> Dictionary:
	if not bau_pronto(id):
		return {}
	if sorteio == null:
		sorteio = RandomNumberGenerator.new()
		sorteio.randomize()
	var b := bau(id)
	var tabela: Dictionary = BAUS[b["tipo"]]
	var fator := 1.0 + 0.25 * int(b["capitulo"])
	var sorte := sorteio.randf() < SORTE_GRANDE
	var vezes := 2 if sorte else 1
	var moedas := roundi(sorteio.randi_range(tabela["moedas"][0], tabela["moedas"][1]) * fator) * vezes
	var acucar := roundi(sorteio.randi_range(tabela["acucar"][0], tabela["acucar"][1]) * fator) * vezes
	_estado()["baus"][id] = true
	Confeitaria.ganhar_acucar(acucar)
	Progresso.ganhar_moedas(moedas)
	# dentro vem também um baú surpresa (pedaços de doces): prata no meio do
	# capítulo, ouro no chefe
	Baus.ganhar(tabela["surpresa"])
	return {"nome": tabela["nome"], "moedas": moedas, "acucar": acucar, "sorte": sorte, "surpresa": tabela["surpresa"]}


# --- Conferir um passo de Excel --------------------------------------------------

## Confere a fórmula do jogador num passo de Excel. Retorna {"certo": bool,
## "valor": resultado, "mensagem": explicação do que está errado}.
static func conferir_excel(passo: Dictionary, formula: String, celulas: Dictionary) -> Dictionary:
	var texto_formula := formula.strip_edges()
	if not texto_formula.begins_with("="):
		return {"certo": false, "valor": null, "mensagem": "Toda fórmula começa com o sinal de igual (=)."}
	var valor: Variant = Formulas.calcular(texto_formula, celulas)
	if Formulas.eh_erro(valor):
		return {"certo": false, "valor": valor, "mensagem": valor.explicacao()}
	if not Formulas.usa_celulas(texto_formula):
		return {"certo": false, "valor": valor,
			"mensagem": "Use os endereços das células (como B2), não os números: assim a conta se atualiza sozinha."}
	var usadas := Formulas.funcoes_usadas(texto_formula)
	for exigida in passo.get("exige", []):
		if exigida == "$":
			if not texto_formula.contains("$"):
				return {"certo": false, "valor": valor, "mensagem": "Falta travar a célula com $ (por exemplo $E$2)."}
		elif not exigida in usadas:
			return {"certo": false, "valor": valor, "mensagem": "Nesta fase, use a função %s." % exigida}
	var esperado: Variant = Formulas.calcular(passo["resposta"], celulas)
	if not Formulas.iguais(valor, esperado):
		return {"certo": false, "valor": valor,
			"mensagem": "A fórmula funciona, mas deu %s. Confira as células que você usou." % Formulas.texto(valor)}
	return {"certo": true, "valor": valor, "mensagem": ""}


## Metas de um passo de Word somadas às dos passos anteriores (no chefe, o
## que já foi feito tem que continuar feito).
static func metas_ate(fase_dados: Dictionary, passo: int) -> Array:
	var metas := []
	for i in passo + 1:
		metas.append_array(fase_dados["passos"][i]["metas"])
	return metas
