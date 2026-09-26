class_name Formulas
extends RefCounted
## Calcula fórmulas no jeito do Excel em português, para o Laboratório do
## Office. Uso: Formulas.calcular("=SOMA(B2:B6)", celulas), onde `celulas` é
## {"B2": 12, "A1": "Doce", ...} (célula que não está lá = vazia).
##
## - Argumentos separados por ; e vírgula como separador decimal (2,5). Por
##   ser um jogo, também aceita ponto (2.5) e nomes de função sem acento
##   (MEDIA = MÉDIA).
## - Contas: + - * / ^ %, & (junta textos), comparações = <> < > <= >=.
##   A ordem das contas é a do Excel.
## - Referências A1, $A$1, A$1 e intervalos A1:B5.
## - Resultado: número (float), texto (String), VERDADEIRO/FALSO (bool) ou um
##   Erro (#DIV/0!, #NOME?, #VALOR!) — mais os problemas que no Excel viram uma
##   janela de aviso (fórmula incompleta, vírgula no lugar de ;, número errado
##   de argumentos), com uma explicação para o jogador.

const DIV0 := "#DIV/0!"
const NOME := "#NOME?"
const VALOR := "#VALOR!"
const ND := "#N/D"
const INCOMPLETA := "INCOMPLETA"
const VIRGULA := "VIRGULA"
const ARGUMENTOS := "ARGUMENTOS"

## Explicações dos erros, em linguagem de aluno.
const EXPLICACOES := {
	DIV0: "#DIV/0! aparece quando a fórmula divide por zero (ou por uma célula vazia).",
	NOME: "#NOME? aparece quando o Excel não conhece um nome: confira como a função se escreve.",
	VALOR: "#VALOR! aparece quando a conta recebe o tipo errado, como texto numa soma com +.",
	ND: "#N/D aparece quando a busca (PROCV, CORRESP) não acha o valor procurado. Confira se ele está na primeira coluna.",
	INCOMPLETA: "A fórmula está incompleta: confira os parênteses, as aspas e se falta algum número ou célula.",
	VIRGULA: "No Excel em português, os argumentos são separados por ; (ponto e vírgula). A vírgula é das casas decimais.",
	ARGUMENTOS: "A função recebeu argumentos de menos ou de mais. Confira o que ela pede.",
}

## Funções conhecidas (nome sem acento) -> [mínimo, máximo] de argumentos
## (-1 = sem limite).
const FUNCOES := {
	"SOMA": [1, -1], "MEDIA": [1, -1], "MAXIMO": [1, -1], "MINIMO": [1, -1],
	"CONT.NUM": [1, -1], "CONT.VALORES": [1, -1], "CONTAR.VAZIO": [1, 1],
	"CONT.SE": [2, 2], "SOMASE": [2, 3], "MEDIASE": [2, 3],
	"SE": [2, 3], "E": [1, -1], "OU": [1, -1], "NAO": [1, 1],
	"ARRED": [2, 2], "ABS": [1, 1], "INT": [1, 1], "RAIZ": [1, 1],
	"CONCATENAR": [1, -1], "CONCAT": [1, -1], "MAIUSCULA": [1, 1], "MINUSCULA": [1, 1],
	"ESQUERDA": [1, 2], "DIREITA": [1, 2], "NUM.CARACT": [1, 1],
	"PROCV": [3, 4], "SEERRO": [2, 2], "SES": [2, -1], "CONT.SES": [2, -1], "SOMASES": [3, -1],
	"INDICE": [2, 3], "CORRESP": [2, 3],
}


class Erro:
	var codigo: String

	func _init(c: String) -> void:
		codigo = c

	func explicacao() -> String:
		return Formulas.EXPLICACOES.get(codigo, "")


## Valores de um intervalo (A1:B3), na ordem linha por linha.
class Intervalo:
	var valores: Array = []
	var linhas := 0
	var colunas := 0

	func em(linha: int, coluna: int) -> Variant:
		return valores[linha * colunas + coluna]


var _tokens: Array = []
var _i := 0
var _celulas: Dictionary
var _erro_leitura := ""


# --- Uso ---------------------------------------------------------------------

## Calcula a fórmula (com ou sem "=" na frente). Retorna float, String, bool
## ou Erro.
static func calcular(formula: String, celulas: Dictionary) -> Variant:
	var f := Formulas.new()
	return f._calcular(formula, celulas)


static func eh_erro(valor: Variant) -> bool:
	return valor is Erro


## Como o valor aparece na célula: 2,5 / 12 / VERDADEIRO / #DIV/0!.
static func texto(valor: Variant) -> String:
	if valor == null:
		return ""
	if valor is Erro:
		return valor.codigo if valor.codigo.begins_with("#") else "!"
	if valor is bool:
		return "VERDADEIRO" if valor else "FALSO"
	if valor is float or valor is int:
		var n := float(valor)
		if is_equal_approx(n, roundf(n)) and absf(n) < 1e15:
			return str(int(roundf(n)))
		var t := ("%.2f" % n).rstrip("0").rstrip(".")
		return t.replace(".", ",")
	return str(valor)


## Os dois resultados são iguais? (números com folga de arredondamento, textos
## sem diferenciar maiúsculas, como o = do Excel)
static func iguais(a: Variant, b: Variant) -> bool:
	if a is Erro or b is Erro:
		return a is Erro and b is Erro and a.codigo == b.codigo
	if (a is float or a is int) and (b is float or b is int):
		return absf(float(a) - float(b)) < 1e-6
	if a is String and b is String:
		return a.to_lower() == b.to_lower()
	if a is bool and b is bool:
		return a == b
	return false


## Nomes das funções usadas na fórmula (sem acento, em maiúsculas).
static func funcoes_usadas(formula: String) -> Array:
	var f := Formulas.new()
	f._ler(formula.trim_prefix("="))
	var nomes := []
	for i in f._tokens.size() - 1:
		if f._tokens[i][0] == "nome" and f._tokens[i + 1][0] == "(":
			nomes.append(f._tokens[i][1])
	return nomes


## Se a fórmula usa pelo menos uma célula (e não só números digitados).
static func usa_celulas(formula: String) -> bool:
	var f := Formulas.new()
	f._ler(formula.trim_prefix("="))
	return f._tokens.any(func(t): return t[0] == "ref")


## Tira acentos e deixa em maiúsculas: "Média" -> "MEDIA".
static func sem_acento(nome: String) -> String:
	var de := "ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ"
	var para := "AAAAAEEEEIIIIOOOOOUUUUC"
	var saida := ""
	for c in nome.to_upper():
		var i := de.find(c)
		saida += para[i] if i >= 0 else c
	return saida


## "B12" -> Vector2i(1, 11) (coluna, linha a partir de 0).
static func posicao(ref: String) -> Vector2i:
	var coluna := 0
	var i := 0
	while i < ref.length() and ref[i] >= "A" and ref[i] <= "Z":
		coluna = coluna * 26 + (ref.unicode_at(i) - 64)
		i += 1
	return Vector2i(coluna - 1, int(ref.substr(i)) - 1)


static func nome_celula(p: Vector2i) -> String:
	var letras := ""
	var c := p.x + 1
	while c > 0:
		var r := (c - 1) % 26
		letras = char(65 + r) + letras
		c = (c - 1) / 26
	return letras + str(p.y + 1)


# --- Leitura (tokens) --------------------------------------------------------

func _calcular(formula: String, celulas: Dictionary) -> Variant:
	_celulas = celulas
	_ler(formula.strip_edges().trim_prefix("="))
	if _erro_leitura != "":
		return Erro.new(_erro_leitura)
	if _tokens.size() <= 1:
		return Erro.new(INCOMPLETA)
	var v: Variant = _comparacao()
	if _erro_leitura != "":
		return Erro.new(_erro_leitura)
	if _tokens[_i][0] != "fim":
		# sobrou coisa: "=SOMA(A1;A2))" ou "=A1 A2"
		return Erro.new(VIRGULA if _tokens[_i][0] == "virgula" else INCOMPLETA)
	if v is Intervalo:
		return Erro.new(VALOR)
	return v


func _ler(texto_formula: String) -> void:
	_tokens = []
	_i = 0
	_erro_leitura = ""
	var s := texto_formula
	var i := 0
	var ref := RegEx.create_from_string("^\\$?([A-Za-z]{1,3})\\$?([0-9]+)$")
	while i < s.length():
		var c := s[i]
		if c == " ":
			i += 1
		elif c.is_valid_int() or ((c == "," or c == ".") and i + 1 < s.length() and s[i + 1].is_valid_int() \
				and (_tokens.is_empty() or _tokens[-1][0] in ["op", "(", ";", "virgula"])):
			var fim := i
			var ponto := false
			while fim < s.length() and (s[fim].is_valid_int() or (not ponto and (s[fim] == "," or s[fim] == ".") \
					and fim + 1 < s.length() and s[fim + 1].is_valid_int())):
				if s[fim] == "," or s[fim] == ".":
					ponto = true
				fim += 1
			_tokens.append(["num", s.substr(i, fim - i).replace(",", ".").to_float()])
			i = fim
		elif c == "\"":
			var fim := i + 1
			var t := ""
			while true:
				if fim >= s.length():
					_erro_leitura = INCOMPLETA
					return
				if s[fim] == "\"":
					if fim + 1 < s.length() and s[fim + 1] == "\"":
						t += "\""
						fim += 2
						continue
					break
				t += s[fim]
				fim += 1
			_tokens.append(["txt", t])
			i = fim + 1
		elif _letra(c) or c == "$":
			var fim := i
			while fim < s.length() and (_letra(s[fim]) or s[fim].is_valid_int() or s[fim] in [".", "_", "$"]):
				fim += 1
			var palavra := s.substr(i, fim - i)
			var achou := ref.search(palavra)
			if achou:
				_tokens.append(["ref", achou.get_string(1).to_upper() + achou.get_string(2)])
			elif sem_acento(palavra) in ["VERDADEIRO", "FALSO"]:
				_tokens.append(["bool", sem_acento(palavra) == "VERDADEIRO"])
			else:
				_tokens.append(["nome", sem_acento(palavra)])
			i = fim
		elif i + 1 < s.length() and s.substr(i, 2) in ["<=", ">=", "<>"]:
			_tokens.append(["op", s.substr(i, 2)])
			i += 2
		elif c in ["+", "-", "*", "/", "^", "&", "=", "<", ">", "%"]:
			_tokens.append(["op", c])
			i += 1
		elif c in ["(", ")", ";", ":"]:
			_tokens.append([c, c])
			i += 1
		elif c == ",":
			_tokens.append(["virgula", c])
			i += 1
		else:
			_erro_leitura = INCOMPLETA
			return
	_tokens.append(["fim", ""])


static func _letra(c: String) -> bool:
	return (c >= "A" and c <= "Z") or (c >= "a" and c <= "z") \
		or "ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ".contains(c.to_upper())


func _ver() -> Array:
	return _tokens[_i]


func _pular() -> Array:
	var t: Array = _tokens[_i]
	if t[0] != "fim":
		_i += 1
	return t


func _falhar(codigo: String) -> Variant:
	if _erro_leitura == "":
		_erro_leitura = codigo
	return null


# --- Contas (cada nível chama o de prioridade maior) -------------------------

func _comparacao() -> Variant:
	var a: Variant = _juntar()
	while _ver()[0] == "op" and _ver()[1] in ["=", "<>", "<", ">", "<=", ">="]:
		var op: String = _pular()[1]
		var b: Variant = _juntar()
		a = _comparar(a, b, op)
	return a


func _juntar() -> Variant:
	var a: Variant = _soma()
	while _ver()[0] == "op" and _ver()[1] == "&":
		_pular()
		var b: Variant = _soma()
		if a is Erro or b is Erro:
			a = a if a is Erro else b
		elif a is Intervalo or b is Intervalo:
			a = Erro.new(VALOR)
		else:
			a = _como_texto(a) + _como_texto(b)
	return a


func _soma() -> Variant:
	var a: Variant = _produto()
	while _ver()[0] == "op" and _ver()[1] in ["+", "-"]:
		var op: String = _pular()[1]
		var b: Variant = _produto()
		a = _conta(a, b, op)
	return a


func _produto() -> Variant:
	var a: Variant = _potencia()
	while _ver()[0] == "op" and _ver()[1] in ["*", "/"]:
		var op: String = _pular()[1]
		var b: Variant = _potencia()
		a = _conta(a, b, op)
	return a


func _potencia() -> Variant:
	var a: Variant = _unario()
	while _ver()[0] == "op" and _ver()[1] == "^":
		_pular()
		var b: Variant = _unario()
		a = _conta(a, b, "^")
	return a


func _unario() -> Variant:
	if _ver()[0] == "op" and _ver()[1] in ["-", "+"]:
		var op: String = _pular()[1]
		var v: Variant = _unario()
		return _conta(0.0, v, op)
	var v: Variant = _primario()
	while _ver()[0] == "op" and _ver()[1] == "%":
		_pular()
		v = _conta(v, 100.0, "/")
	return v


func _primario() -> Variant:
	var t := _pular()
	match t[0]:
		"num", "txt", "bool":
			return t[1]
		"ref":
			if _ver()[0] == ":":
				_pular()
				var fim := _pular()
				if fim[0] != "ref":
					return _falhar(INCOMPLETA)
				return _intervalo(t[1], fim[1])
			return _celulas.get(t[1])
		"(":
			var v: Variant = _comparacao()
			if _pular()[0] != ")":
				return _falhar(INCOMPLETA)
			return v
		"nome":
			if _ver()[0] != "(":
				return Erro.new(NOME)  # nome solto, como =SOMA sem parênteses
			_pular()
			var args := []
			if _ver()[0] != ")":
				while true:
					args.append(_comparacao())
					var sep := _pular()
					if sep[0] == ")":
						break
					if sep[0] == "virgula":
						return _falhar(VIRGULA)
					if sep[0] != ";":
						return _falhar(INCOMPLETA)
			else:
				_pular()
			return _funcao(t[1], args)
		"virgula":
			return _falhar(VIRGULA)
	return _falhar(INCOMPLETA)


func _intervalo(de: String, ate: String) -> Intervalo:
	var a := posicao(de)
	var b := posicao(ate)
	var saida := Intervalo.new()
	saida.linhas = absi(a.y - b.y) + 1
	saida.colunas = absi(a.x - b.x) + 1
	for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
		for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
			saida.valores.append(_celulas.get(nome_celula(Vector2i(x, y))))
	return saida


# --- Conversões --------------------------------------------------------------

## Número para contas com + - * /: vazio = 0, VERDADEIRO = 1, texto com número
## vira número; outro texto dá #VALOR!.
static func _numero(v: Variant) -> Variant:
	if v == null:
		return 0.0
	if v is Erro:
		return v
	if v is bool:
		return 1.0 if v else 0.0
	if v is float or v is int:
		return float(v)
	if v is String:
		var t: String = v.strip_edges().replace(",", ".")
		if t.is_valid_float():
			return t.to_float()
	return Erro.new(VALOR)


static func _como_texto(v: Variant) -> String:
	if v == null:
		return ""
	return texto(v)


func _conta(a: Variant, b: Variant, op: String) -> Variant:
	if a is Intervalo or b is Intervalo:
		return Erro.new(VALOR)
	var x: Variant = _numero(a)
	var y: Variant = _numero(b)
	if x is Erro:
		return x
	if y is Erro:
		return y
	match op:
		"+":
			return x + y
		"-":
			return x - y
		"*":
			return x * y
		"/":
			if y == 0.0:
				return Erro.new(DIV0)
			return x / y
		"^":
			return pow(x, y)
	return Erro.new(VALOR)


## Ordem do Excel entre tipos diferentes: números < textos < VERDADEIRO/FALSO.
static func _ordem(a: Variant, b: Variant) -> int:
	var ta := _tipo(a)
	var tb := _tipo(b)
	if ta != tb:
		return -1 if ta < tb else 1
	match ta:
		0:
			var x := float(a) if a != null else 0.0
			var y := float(b) if b != null else 0.0
			return 0 if absf(x - y) < 1e-9 else (-1 if x < y else 1)
		1:
			var x := str(a).to_lower()
			var y := str(b).to_lower()
			return 0 if x == y else (-1 if x < y else 1)
	return 0 if a == b else (-1 if not a else 1)


static func _tipo(v: Variant) -> int:
	if v == null or v is float or v is int:
		return 0
	if v is String:
		return 1
	return 2


func _comparar(a: Variant, b: Variant, op: String) -> Variant:
	if a is Erro:
		return a
	if b is Erro:
		return b
	if a is Intervalo or b is Intervalo:
		return Erro.new(VALOR)
	# célula vazia comparada com texto vale ""
	if a == null and b is String:
		a = ""
	if b == null and a is String:
		b = ""
	var o := _ordem(a, b)
	match op:
		"=":
			return o == 0
		"<>":
			return o != 0
		"<":
			return o < 0
		">":
			return o > 0
		"<=":
			return o <= 0
	return o >= 0


# --- Funções -----------------------------------------------------------------

## Todos os valores dos argumentos (intervalos abertos), separando os que vieram
## de intervalos (onde textos e vazios são ignorados pelas funções de soma).
static func _lista(args: Array) -> Array:
	var saida := []
	for a in args:
		if a is Intervalo:
			for v in a.valores:
				saida.append([v, true])
		else:
			saida.append([a, false])
	return saida


## Números para SOMA/MÉDIA/MÁXIMO/MÍNIMO. Retorna Array ou Erro.
static func _numeros(args: Array) -> Variant:
	var nums := []
	for par in _lista(args):
		var v: Variant = par[0]
		if v is Erro:
			return v
		if par[1]:
			if v is float or v is int:
				nums.append(float(v))
		else:
			var n: Variant = _numero(v)
			if n is Erro:
				return n
			nums.append(n)
	return nums


static func _verdade(v: Variant) -> Variant:
	if v is Erro:
		return v
	if v is bool:
		return v
	if v == null:
		return false
	if v is float or v is int:
		return float(v) != 0.0
	var t := sem_acento(str(v))
	if t == "VERDADEIRO" or t == "FALSO":
		return t == "VERDADEIRO"
	return Erro.new(VALOR)


## Critério do CONT.SE/SOMASE: 5, "Brigadeiro", ">=7", "<>0", "B*".
static func _atende(v: Variant, criterio: Variant) -> bool:
	if criterio is float or criterio is int:
		return (v is float or v is int) and absf(float(v) - float(criterio)) < 1e-9
	var c := str(criterio)
	var op := "="
	for o in ["<=", ">=", "<>", "<", ">", "="]:
		if c.begins_with(o):
			op = o
			c = c.substr(o.length())
			break
	var alvo: Variant = c
	var num := c.strip_edges().replace(",", ".")
	if num.is_valid_float():
		alvo = num.to_float()
		if not (v is float or v is int):
			return op == "<>"
	elif op == "=" or op == "<>":
		var bate := v != null and str(texto(v)).to_lower().match(c.to_lower())
		return bate if op == "=" else not bate
	var o := _ordem(v, alvo)
	match op:
		"=":
			return o == 0
		"<>":
			return o != 0
		"<":
			return o < 0
		">":
			return o > 0
		"<=":
			return o <= 0
	return o >= 0


func _funcao(nome: String, args: Array) -> Variant:
	if not FUNCOES.has(nome):
		return Erro.new(NOME)
	var limites: Array = FUNCOES[nome]
	if args.size() < limites[0] or (limites[1] >= 0 and args.size() > limites[1]):
		return _falhar(ARGUMENTOS)
	match nome:
		"SOMA", "MEDIA", "MAXIMO", "MINIMO":
			var nums: Variant = _numeros(args)
			if nums is Erro:
				return nums
			var lista: Array = nums
			match nome:
				"SOMA":
					return lista.reduce(func(s, n): return s + n, 0.0)
				"MEDIA":
					if lista.is_empty():
						return Erro.new(DIV0)
					return lista.reduce(func(s, n): return s + n, 0.0) / lista.size()
				"MAXIMO":
					return lista.max() if not lista.is_empty() else 0.0
				"MINIMO":
					return lista.min() if not lista.is_empty() else 0.0
		"CONT.NUM":
			return float(_lista(args).filter(func(p): return p[0] is float or p[0] is int).size())
		"CONT.VALORES":
			return float(_lista(args).filter(func(p): return p[0] != null and not (p[0] is String and p[0] == "")).size())
		"CONTAR.VAZIO":
			if not args[0] is Intervalo:
				return Erro.new(VALOR)
			return float(args[0].valores.filter(func(v): return v == null or (v is String and v == "")).size())
		"SEERRO":
			return args[1] if args[0] is Erro else args[0]
		"SES":
			if args.size() % 2 != 0:
				return _falhar(ARGUMENTOS)
			for i in range(0, args.size(), 2):
				var cond: Variant = _verdade(args[i])
				if cond is Erro:
					return cond
				if cond:
					return args[i + 1]
			return Erro.new(ND)
		"CONT.SES", "SOMASES":
			var inicio := 1 if nome == "SOMASES" else 0
			if (args.size() - inicio) % 2 != 0:
				return _falhar(ARGUMENTOS)
			for a in args:
				if a is Erro:
					return a
			var base: Intervalo = args[0] if args[0] is Intervalo else null
			if base == null:
				return Erro.new(VALOR)
			var total := 0.0
			var quantos := 0
			for i in base.valores.size():
				var todas := true
				for j in range(inicio, args.size(), 2):
					if not args[j] is Intervalo or args[j].valores.size() != base.valores.size():
						return Erro.new(VALOR)
					if not _atende(args[j].valores[i], args[j + 1]):
						todas = false
						break
				if todas:
					quantos += 1
					var v: Variant = base.valores[i]
					if v is float or v is int:
						total += float(v)
			return total if nome == "SOMASES" else float(quantos)
		"PROCV":
			if args[0] is Erro:
				return args[0]
			if not args[1] is Intervalo:
				return Erro.new(VALOR)
			var tabela: Intervalo = args[1]
			var coluna: Variant = _numero(args[2])
			if coluna is Erro:
				return coluna
			var c := int(coluna) - 1
			if c < 0 or c >= tabela.colunas:
				return Erro.new(VALOR)
			var aproximado: bool = args.size() < 4 or _verdade(args[3]) == true
			var achou := -1
			for linha in tabela.linhas:
				var chave: Variant = tabela.em(linha, 0)
				if chave == null:
					continue
				if not aproximado:
					if _ordem(chave, args[0]) == 0:
						achou = linha
						break
				elif _tipo(chave) == _tipo(args[0]) and _ordem(chave, args[0]) <= 0:
					achou = linha  # aproximado: o maior que não passa do valor
			if achou < 0:
				return Erro.new(ND)
			var achado: Variant = tabela.em(achou, c)
			return achado if achado != null else 0.0  # célula vazia volta como 0, como no Excel
		"INDICE":
			if not args[0] is Intervalo:
				return Erro.new(VALOR)
			var t: Intervalo = args[0]
			var l: Variant = _numero(args[1])
			var col: Variant = _numero(args[2]) if args.size() == 3 else 1.0
			if l is Erro or col is Erro:
				return l if l is Erro else col
			# numa linha só (A1:E1), o 2º argumento é a coluna
			if t.linhas == 1 and args.size() == 2:
				col = l
				l = 1.0
			if int(l) < 1 or int(l) > t.linhas or int(col) < 1 or int(col) > t.colunas:
				return Erro.new(VALOR)
			return t.em(int(l) - 1, int(col) - 1)
		"CORRESP":
			if args[0] is Erro:
				return args[0]
			if not args[1] is Intervalo:
				return Erro.new(VALOR)
			for i in args[1].valores.size():
				if args[1].valores[i] != null and _ordem(args[1].valores[i], args[0]) == 0:
					return float(i + 1)
			return Erro.new(ND)
		"CONT.SE", "SOMASE", "MEDIASE":
			if not args[0] is Intervalo or (args.size() == 3 and not args[2] is Intervalo):
				return Erro.new(VALOR)
			if args[1] is Erro:
				return args[1]
			var onde: Array = args[0].valores
			var somar: Array = args[2].valores if args.size() == 3 else onde
			var total := 0.0
			var quantos := 0
			for i in onde.size():
				if _atende(onde[i], args[1]):
					quantos += 1
					var n: Variant = somar[i] if i < somar.size() else null
					if n is float or n is int:
						total += float(n)
			if nome == "CONT.SE":
				return float(quantos)
			if nome == "SOMASE":
				return total
			if quantos == 0:
				return Erro.new(DIV0)
			var numeros := 0
			for i in onde.size():
				if _atende(onde[i], args[1]) and i < somar.size() and (somar[i] is float or somar[i] is int):
					numeros += 1
			return total / maxi(numeros, 1)
		"SE":
			var cond: Variant = _verdade(args[0])
			if cond is Erro:
				return cond
			if cond:
				return args[1]
			return args[2] if args.size() == 3 else false
		"E", "OU":
			var algum := false
			var todos := true
			for par in _lista(args):
				var v: Variant = par[0]
				if par[1] and (v == null or v is String):
					continue
				var b: Variant = _verdade(v)
				if b is Erro:
					return b
				algum = algum or b
				todos = todos and b
			return todos if nome == "E" else algum
		"NAO":
			var b: Variant = _verdade(args[0])
			return b if b is Erro else not b
		"ARRED", "ABS", "INT", "RAIZ":
			var n: Variant = _numero(args[0])
			if n is Erro:
				return n
			match nome:
				"ARRED":
					var casas: Variant = _numero(args[1])
					if casas is Erro:
						return casas
					var f := pow(10.0, int(casas))
					return signf(n) * floorf(absf(n) * f + 0.5) / f
				"ABS":
					return absf(n)
				"INT":
					return floorf(n)
				"RAIZ":
					return sqrt(n) if n >= 0.0 else Erro.new(VALOR)
		"CONCATENAR", "CONCAT":
			var t := ""
			for par in _lista(args):
				if par[0] is Erro:
					return par[0]
				t += _como_texto(par[0])
			return t
		"MAIUSCULA", "MINUSCULA", "NUM.CARACT", "ESQUERDA", "DIREITA":
			if args[0] is Erro:
				return args[0]
			if args[0] is Intervalo:
				return Erro.new(VALOR)
			var t := _como_texto(args[0])
			match nome:
				"MAIUSCULA":
					return t.to_upper()
				"MINUSCULA":
					return t.to_lower()
				"NUM.CARACT":
					return float(t.length())
			var n: Variant = _numero(args[1]) if args.size() == 2 else 1.0
			if n is Erro:
				return n
			if n < 0:
				return Erro.new(VALOR)
			return t.left(int(n)) if nome == "ESQUERDA" else t.right(int(n))
	return Erro.new(NOME)
