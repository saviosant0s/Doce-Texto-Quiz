class_name Quiz
## O que o resto do jogo pede do quiz: os títulos de passar nos níveis
## (NOOB = fácil, PRO = médio, MESTRE = difícil) liberam a casa maior e os
## desafiantes mais fortes da Arena. Assim o quiz continua sendo o caminho.

const NIVEIS := {"noob": "FÁCIL", "pro": "MÉDIO", "mestre": "DIFÍCIL"}


## Se tem o título ("" = não precisa de nenhum).
static func tem_titulo(titulo: String) -> bool:
	return titulo == "" or int(Progresso.titulos.get(titulo, 0)) > 0


## "PASSE NO NÍVEL MÉDIO DO QUIZ (TÍTULO PRO)"
static func como_ganhar(titulo: String) -> String:
	return "PASSE NO NÍVEL %s DO QUIZ (TÍTULO %s)" % [NIVEIS.get(titulo, "?"), Colecao.NOMES_TITULOS.get(titulo, titulo.to_upper())]
