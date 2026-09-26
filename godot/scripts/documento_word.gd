class_name DocumentoWord
extends RefCounted
## Um documento pequeno no jeito do Word, para as fases do Laboratório: textos
## em parágrafos, cada palavra com a sua formatação (negrito, itálico,
## sublinhado, cor, tamanho) e cada parágrafo com o seu alinhamento.
##
## Seleção como no Word: tocar numa palavra seleciona ela; tocar de novo na
## mesma seleciona o parágrafo; Shift+clique estende; Ctrl+T seleciona tudo.
## Os botões e atalhos (em português) mudam o que está selecionado.
## A tela (cenas/lab_fase.*) só desenha; tudo fica aqui para ser testado.

const ALINHAMENTOS := ["esquerda", "centro", "direita", "justificado"]
const TAMANHOS := [8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 36]
const TAMANHO_PADRAO := 12
const CORES := {
	"preto": "#222222", "vermelho": "#D7263D", "azul": "#1E6FD9", "verde": "#1B9E4B", "roxo": "#7E57B1",
}
const PROPRIEDADES := ["negrito", "italico", "sublinhado", "cor", "tamanho"]

## [{"alinhamento": String, "palavras": [{"texto", "negrito", "italico",
## "sublinhado", "cor", "tamanho"}]}]
var paragrafos: Array = []
## Seleção: índices (na ordem de leitura) da primeira e da última palavra.
var sel_inicio := -1
var sel_fim := -1
var _inicial: Array = []
var _desfazer: Array = []


## `dados`: [{"texto": "Festa do Brigadeiro", "alinhamento": "esquerda",
## "tamanho": 12, "negrito": false}, ...] (só "texto" é obrigatório).
func _init(dados: Array = []) -> void:
	for p in dados:
		var palavras := []
		for t in str(p["texto"]).split(" ", false):
			palavras.append({
				"texto": t, "negrito": bool(p.get("negrito", false)), "italico": bool(p.get("italico", false)),
				"sublinhado": bool(p.get("sublinhado", false)), "cor": str(p.get("cor", "preto")),
				"tamanho": int(p.get("tamanho", TAMANHO_PADRAO)), "realce": bool(p.get("realce", false)),
			})
		paragrafos.append({"alinhamento": str(p.get("alinhamento", "esquerda")), "palavras": palavras,
			"lista": str(p.get("lista", "")), "estilo": str(p.get("estilo", "normal"))})
	_inicial = paragrafos.duplicate(true)


# --- Endereços das palavras ----------------------------------------------------

func total_palavras() -> int:
	var n := 0
	for p in paragrafos:
		n += p["palavras"].size()
	return n


## Índice de leitura -> Vector2i(parágrafo, palavra).
func onde(indice: int) -> Vector2i:
	var resto := indice
	for i in paragrafos.size():
		var n: int = paragrafos[i]["palavras"].size()
		if resto < n:
			return Vector2i(i, resto)
		resto -= n
	return Vector2i(-1, -1)


func indice(paragrafo: int, palavra: int) -> int:
	var n := 0
	for i in paragrafo:
		n += paragrafos[i]["palavras"].size()
	return n + palavra


func palavra(indice_leitura: int) -> Dictionary:
	var p := onde(indice_leitura)
	return paragrafos[p.x]["palavras"][p.y]


# --- Seleção -------------------------------------------------------------------

func tem_selecao() -> bool:
	return sel_inicio >= 0


func selecionada(indice_leitura: int) -> bool:
	return tem_selecao() and indice_leitura >= sel_inicio and indice_leitura <= sel_fim


## Toque numa palavra. `estender` = Shift apertado.
func tocar(indice_leitura: int, estender := false) -> void:
	if estender and tem_selecao():
		sel_inicio = mini(sel_inicio, indice_leitura)
		sel_fim = maxi(sel_fim, indice_leitura)
		return
	if sel_inicio == indice_leitura and sel_fim == indice_leitura:
		selecionar_paragrafo(onde(indice_leitura).x)
		return
	sel_inicio = indice_leitura
	sel_fim = indice_leitura


func selecionar_paragrafo(p: int) -> void:
	sel_inicio = indice(p, 0)
	sel_fim = indice(p, paragrafos[p]["palavras"].size() - 1)


func selecionar_tudo() -> void:
	sel_inicio = 0
	sel_fim = total_palavras() - 1


func limpar_selecao() -> void:
	sel_inicio = -1
	sel_fim = -1


func _selecionadas() -> Array:
	var lista := []
	if tem_selecao():
		for i in range(sel_inicio, sel_fim + 1):
			lista.append(palavra(i))
	return lista


func _paragrafos_selecionados() -> Array:
	var lista := []
	if tem_selecao():
		for p in range(onde(sel_inicio).x, onde(sel_fim).x + 1):
			lista.append(paragrafos[p])
	return lista


# --- Formatação ------------------------------------------------------------------

func _guardar() -> void:
	_desfazer.append(paragrafos.duplicate(true))
	if _desfazer.size() > 50:
		_desfazer.pop_front()


## Ctrl+Z. Falso se não havia nada para desfazer.
func desfazer() -> bool:
	if _desfazer.is_empty():
		return false
	paragrafos = _desfazer.pop_back()
	return true


## Negrito, itálico e sublinhado ligam e desligam como no Word: se toda a
## seleção já tem, tira; senão, põe em tudo.
func alternar(propriedade: String) -> bool:
	var lista := _selecionadas()
	if lista.is_empty():
		return false
	_guardar()
	var todas := lista.all(func(w): return w[propriedade])
	for w in lista:
		w[propriedade] = not todas
	return true


## Estado de um botão (N, I, S): ligado se toda a seleção tem.
func ligado(propriedade: String) -> bool:
	var lista := _selecionadas()
	return not lista.is_empty() and lista.all(func(w): return w[propriedade])


func alinhar(alinhamento: String) -> bool:
	var lista := _paragrafos_selecionados()
	if lista.is_empty():
		return false
	_guardar()
	for p in lista:
		p["alinhamento"] = alinhamento
	return true


func alinhamento_atual() -> String:
	var lista := _paragrafos_selecionados()
	return lista[0]["alinhamento"] if not lista.is_empty() else ""


func pintar(cor: String) -> bool:
	var lista := _selecionadas()
	if lista.is_empty():
		return false
	_guardar()
	for w in lista:
		w["cor"] = cor
	return true


## Aumenta (+1) ou diminui (-1) a fonte um degrau da lista do Word.
func mudar_tamanho(passo: int) -> bool:
	var lista := _selecionadas()
	if lista.is_empty():
		return false
	_guardar()
	for w in lista:
		var i := TAMANHOS.find(int(w["tamanho"]))
		if i < 0:
			i = TAMANHOS.find(TAMANHO_PADRAO)
		w["tamanho"] = TAMANHOS[clampi(i + passo, 0, TAMANHOS.size() - 1)]
	return true


func tamanho_atual() -> int:
	var lista := _selecionadas()
	return int(lista[0]["tamanho"]) if not lista.is_empty() else 0


## Lista com marcadores (•) ou numerada (1. 2. 3.) nos parágrafos da seleção.
## Apertar de novo tira a lista, como no Word.
func mudar_lista(tipo: String) -> bool:
	var lista := _paragrafos_selecionados()
	if lista.is_empty():
		return false
	_guardar()
	var todos := lista.all(func(p): return p["lista"] == tipo)
	for p in lista:
		p["lista"] = "" if todos else tipo
	return true


## Estilo do parágrafo: "titulo1", "titulo2" ou "normal" (como a galeria de
## Estilos do Word: muda o jeito do parágrafo todo de uma vez).
func mudar_estilo(estilo: String) -> bool:
	var lista := _paragrafos_selecionados()
	if lista.is_empty():
		return false
	_guardar()
	for p in lista:
		p["estilo"] = estilo
	return true


func estilo_atual() -> String:
	var lista := _paragrafos_selecionados()
	return lista[0]["estilo"] if not lista.is_empty() else ""


func lista_atual() -> String:
	var lista := _paragrafos_selecionados()
	return lista[0]["lista"] if not lista.is_empty() else ""


## Atalhos do Word em português. Retorna o nome da ação ou "".
static func acao_do_atalho(tecla: Key, ctrl: bool, shift: bool, alt := false) -> String:
	if not ctrl:
		return ""
	if alt:
		match tecla:
			KEY_1: return "titulo1"
			KEY_2: return "titulo2"
		return ""
	if shift and tecla == KEY_L:
		return "marcadores"
	match tecla:
		KEY_N: return "negrito"
		KEY_I: return "italico"
		KEY_S: return "sublinhado"
		KEY_E: return "centro"
		KEY_Q: return "esquerda"
		KEY_G: return "direita"
		KEY_J: return "justificado"
		KEY_T: return "tudo"
		KEY_Z: return "desfazer"
		KEY_BRACKETRIGHT: return "maior"
		KEY_BRACKETLEFT: return "menor"
		KEY_PERIOD, KEY_GREATER: return "maior" if shift else ""
		KEY_COMMA, KEY_LESS: return "menor" if shift else ""
	return ""


## Faz uma ação pelo nome (botões e atalhos usam os mesmos nomes).
func fazer(acao: String) -> bool:
	match acao:
		"negrito", "italico", "sublinhado":
			return alternar(acao)
		"esquerda", "centro", "direita", "justificado":
			return alinhar(acao)
		"tudo":
			selecionar_tudo()
			return true
		"desfazer":
			return desfazer()
		"maior":
			return mudar_tamanho(1)
		"menor":
			return mudar_tamanho(-1)
		"realce":
			return alternar("realce")
		"marcadores", "numeros":
			return mudar_lista(acao)
		"titulo1", "titulo2", "normal":
			return mudar_estilo(acao)
	if acao.begins_with("cor_"):
		return pintar(acao.trim_prefix("cor_"))
	return false


# --- Conferir a tarefa ---------------------------------------------------------

## Palavras que uma meta aponta. Meta: {"paragrafo": n (-1 = todos),
## "palavras": ["Festa", ...] (sem = o parágrafo todo), ...}.
func _alvos(meta: Dictionary) -> Array:
	var lista := []
	var p := int(meta.get("paragrafo", -1))
	var varios: Array = meta.get("paragrafos", [])
	for i in paragrafos.size():
		if not varios.is_empty():
			if not float(i) in varios.map(func(x): return float(x)):
				continue
		elif p >= 0 and i != p:
			continue
		for j in paragrafos[i]["palavras"].size():
			var w: Dictionary = paragrafos[i]["palavras"][j]
			if not meta.has("palavras") or _limpa(w["texto"]) in meta["palavras"].map(func(t): return _limpa(t)):
				lista.append(Vector2i(i, j))
	return lista


static func _limpa(t: String) -> String:
	return t.to_lower().rstrip(".,!?:;")


## O que ainda falta para cumprir as metas (lista vazia = tarefa feita).
## Metas: negrito/italico/sublinhado (bool), cor (nome), tamanho_min,
## alinhamento. Além disso, as palavras que nenhuma meta aponta não podem ter
## mudado nas propriedades cobradas (negrito no título não vale deixando o
## texto todo em negrito).
func faltando(metas: Array) -> Array:
	var faltas := []
	# listas e estilos são sempre conferidos: só os parágrafos pedidos mudam
	var cobradas := {"lista": {}, "estilo": {}}  # propriedade -> {Vector2i: true}
	for meta in metas:
		var alvos := _alvos(meta)
		for prop in meta:
			if prop in ["paragrafo", "paragrafos", "palavras", "dica"]:
				continue
			var ok := true
			for a in alvos:
				var w: Dictionary = paragrafos[a.x]["palavras"][a.y]
				match prop:
					"alinhamento", "lista", "estilo":
						ok = ok and paragrafos[a.x][prop] == meta[prop]
					"tamanho_min":
						ok = ok and int(w["tamanho"]) >= int(meta[prop])
					_:
						ok = ok and w[prop] == meta[prop]
			if not ok:
				faltas.append(meta.get("dica", _descrever(meta, prop)))
				break
			var chave: String = "tamanho" if prop == "tamanho_min" else prop
			if not cobradas.has(chave):
				cobradas[chave] = {}
			for a in alvos:
				cobradas[chave][a] = true
	for prop in cobradas:
		if prop == "alinhamento":
			continue
		if prop in ["lista", "estilo"]:
			# listas e estilos só nos parágrafos pedidos
			for i in paragrafos.size():
				var pedido := false
				for a in cobradas[prop]:
					if a.x == i:
						pedido = true
						break
				if not pedido and paragrafos[i][prop] != _inicial[i][prop]:
					faltas.append("Só o que foi pedido deve mudar: confira o parágrafo %d." % (i + 1))
					return faltas
			continue
		for i in paragrafos.size():
			for j in paragrafos[i]["palavras"].size():
				if cobradas[prop].has(Vector2i(i, j)):
					continue
				if paragrafos[i]["palavras"][j][prop] != _inicial[i]["palavras"][j][prop]:
					faltas.append("Só o que foi pedido deve mudar: confira a palavra \"%s\"." % paragrafos[i]["palavras"][j]["texto"])
					return faltas
	return faltas


static func _descrever(meta: Dictionary, prop: String) -> String:
	var onde_texto := "o texto todo"
	if meta.has("palavras"):
		onde_texto = "\"" + " ".join(meta["palavras"]) + "\""
	elif meta.has("paragrafos"):
		onde_texto = "os parágrafos " + ", ".join(meta["paragrafos"].map(func(x): return str(int(x) + 1)))
	elif int(meta.get("paragrafo", -1)) >= 0:
		onde_texto = "o parágrafo %d" % (int(meta["paragrafo"]) + 1)
	match prop:
		"negrito":
			return "Falta deixar %s em negrito." % onde_texto if meta[prop] else "Tire o negrito de %s." % onde_texto
		"italico":
			return "Falta deixar %s em itálico." % onde_texto
		"sublinhado":
			return "Falta sublinhar %s." % onde_texto
		"cor":
			return "Falta pintar %s de %s." % [onde_texto, meta[prop]]
		"tamanho_min":
			return "Falta aumentar a fonte de %s (pelo menos %d)." % [onde_texto, int(meta[prop])]
		"alinhamento":
			return "Falta alinhar %s: %s." % [onde_texto, meta[prop]]
		"realce":
			return "Falta passar o marca-texto em %s." % onde_texto
		"lista":
			return "Falta pôr %s numa lista %s." % [onde_texto, "com marcadores" if meta[prop] == "marcadores" else "numerada"]
		"estilo":
			return "Falta aplicar o estilo %s em %s." % [{"titulo1": "Título 1", "titulo2": "Título 2", "normal": "Normal"}.get(meta[prop], meta[prop]), onde_texto]
	return "Ainda falta algo."


# --- Desenho -----------------------------------------------------------------

## BBCode de um parágrafo para um RichTextLabel (cada palavra é um [url] com o
## seu índice de leitura, para saber onde o jogador tocou).
func bbcode(p: int, escala := 2.0) -> String:
	var par: Dictionary = paragrafos[p]
	var alinhar_bb := {"esquerda": "left", "centro": "center", "direita": "right", "justificado": "fill"}
	var partes := []
	for j in par["palavras"].size():
		var w: Dictionary = par["palavras"][j]
		var i := indice(p, j)
		var t := str(w["texto"]).replace("[", "[lb]")
		if w["negrito"]:
			t = "[b]" + t + "[/b]"
		if w["italico"]:
			t = "[i]" + t + "[/i]"
		if w["sublinhado"]:
			t = "[u]" + t + "[/u]"
		var cor: String = CORES.get(w["cor"], "#222222")
		var tamanho := int(w["tamanho"])
		# estilos de título mudam o parágrafo todo (como no Word)
		if par["estilo"] == "titulo1":
			t = "[b]" + t + "[/b]"
			cor = "#1F4E9C"
			tamanho = maxi(tamanho, 20)
		elif par["estilo"] == "titulo2":
			t = "[b]" + t + "[/b]"
			cor = "#2F6FD0"
			tamanho = maxi(tamanho, 16)
		t = "[color=%s]%s[/color]" % [cor, t]
		t = "[font_size=%d]%s[/font_size]" % [roundi(tamanho * escala), t]
		if selecionada(i):
			t = "[bgcolor=#B9D7FF]%s[/bgcolor]" % t
		elif w["realce"]:
			t = "[bgcolor=#FFF06A]%s[/bgcolor]" % t
		partes.append("[url=%d]%s[/url]" % [i, t])
	var marcador := ""
	if par["lista"] == "marcadores":
		marcador = "[font_size=%d]•  [/font_size]" % roundi(TAMANHO_PADRAO * escala)
	elif par["lista"] == "numeros":
		var numero := 1
		var k := p - 1
		while k >= 0 and paragrafos[k]["lista"] == "numeros":
			numero += 1
			k -= 1
		marcador = "[font_size=%d]%d.  [/font_size]" % [roundi(TAMANHO_PADRAO * escala), numero]
	# recuo da lista com espaços largos (o [indent] do RichTextLabel pula linha)
	var recuo := "\u2003\u2003" if par["lista"] != "" else ""
	return "[p align=%s]%s%s%s[/p]" % [alinhar_bb.get(par["alinhamento"], "left"), recuo, marcador, " ".join(partes)]
