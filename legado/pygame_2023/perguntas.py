"""Banco de perguntas, separado por nível.

Cada pergunta tem o enunciado, 4 alternativas e o índice (começando em 0)
da alternativa correta.
"""
from dataclasses import dataclass


@dataclass(frozen=True)
class Pergunta:
    enunciado: str
    alternativas: tuple[str, ...]
    resposta: int


NIVEL_1 = [
    Pergunta("Qual software é comumente usado para criar documentos de texto?",
             ("Word", "Excel", "PowerPoint", "Paint"), 0),
    Pergunta("Qual é a extensão de arquivo padrão de um documento do Word?",
             ("pptx", "xlsx", "docx", "png"), 2),
    Pergunta("Qual opção permite verificar a ortografia em um documento do Word?",
             ("Layout", "Formatar", "Inserir", "Revisar"), 3),
    Pergunta("O que é um 'documento' em um processador de texto?",
             ("Célula de dados", "Arquivo de imagem", "Arquivo de texto", "Pasta de texto"), 2),
    Pergunta("No Word, qual guia permite formatar o texto, como fonte e tamanho?",
             ("Revisar", "Página Inicial", "Layout da Página", "Inserir"), 1),
    Pergunta("Qual tecla de atalho comum é usada para copiar texto no Word?",
             ("Ctrl + C", "Ctrl + X", "Ctrl + V", "Ctrl + Z"), 0),
    Pergunta("Para que serve o software Excel?",
             ("Criar apresentações", "Criar códigos", "Criar planilhas", "Criar design"), 2),
    Pergunta("No Excel, qual termo é usado para se referir a uma interseção de uma linha e uma coluna?",
             ("Planilhas", "Cédulas", "Linhunas", "Célula"), 3),
    Pergunta("Qual função do Excel é usada para somar um intervalo de valores?",
             ("=MÉDIA()", "=SOMA()", "=CONTAR()", "=SE()"), 1),
    Pergunta("Qual termo é usado para referenciar um conjunto de células adjacentes em uma planilha do Excel?",
             ("Intervalo", "Linha", "Coluna", "Fórmula"), 0),
]

NIVEL_2 = [
    Pergunta("Qual recurso do Word permite criar uma lista numerada automaticamente?",
             ("Esquema", "Numeração", "Índice", "Marcadores"), 1),
    Pergunta("No Excel, o que é uma função condicional usada para verificar se uma condição é verdadeira ou falsa?",
             ("=CONTAR()", "=MÉDIA()", "=SE()", "=SOMA()"), 2),
    Pergunta("Qual comando no Excel permite dividir o conteúdo de uma célula em várias colunas com base em um separador?",
             ("Divisão de Colunas", "Dividir Células", "Mesclar Células", "Separar Texto"), 0),
    Pergunta("O que significa a sigla 'CSV' quando se trata de formatos de arquivo?",
             ("C... Spreadsheet Value", "C... Standard View", "C... Some Values", "C... Separated Values"), 3),
    Pergunta("No Word, qual recurso é usado para criar uma cópia idêntica de um texto ou objeto em um documento?",
             ("Clonar", "Duplicar", "Copiar", "Repetir"), 2),
    Pergunta("Qual função do Excel é usada para encontrar o valor máximo em um intervalo de células?",
             ("=MAX()", "=MÁXIMO()", "=CONTAR.MAX()", "=MX()"), 1),
    Pergunta("Qual extensão de arquivo é comumente associada a planilhas do Excel?",
             ("xcl", "xwp", "xltx", "xlsx"), 3),
    Pergunta("No Word, qual recurso permite criar uma tabela a partir de texto existente em um documento?",
             ("Converter texto - tabela", "Converter texto - gráfico", "Formatar tabela", "Criar tabela"), 0),
    Pergunta("Qual recurso do Microsoft Word permite ajustar a margem de um documento?",
             ("Estilo da página", "Numeração de página", "Configuração de página", "Espaçamento"), 2),
    Pergunta("Qual é a função do Excel usada para contar o número de células não vazias em um intervalo?",
             ("=CONT.VALOR()", "=CONT.NÃO.VAZIO()", "=SOMASE()", "=CONTAR.SE()"), 1),
]

NIVEL_3 = [
    Pergunta("No Excel, qual função é usada para encontrar a média ponderada de um conjunto de valores?",
             ("MÉDIA", "MÉDIAHARM", "MÉDIAEX", "MÉDIASE"), 3),
    Pergunta("O que é ou para que serve uma 'macro' no Excel?",
             ("Automação de tarefas", "Tipo de gráfico", "Fórmula complexa", "Tipo de célula"), 0),
    Pergunta("Qual é a função do Excel que retorna o valor absoluto de um número?",
             ("MOD", "SQRT", "ABS", "INT"), 2),
    Pergunta("No Excel, qual função é usada para calcular a taxa interna de retorno de um investimento?",
             ("NPV", "IRR", "MÉDIA", "TAXA"), 1),
    Pergunta("Como você pode inserir uma quebra de página manual em um documento do Word?",
             ("Ctrl + Enter", "Alt + Enter", "Shift + Enter", "F12"), 0),
    Pergunta("No Word, qual recurso é usado para criar um índice automático com base nos títulos e subtítulos do documento?",
             ("Sumário", "Numeração", "Bibliografia", "Índice"), 3),
    Pergunta("Qual extensão de arquivo é usada para MODELOS de documentos do Word?",
             ("docx", "xlsx", "dotx", "pptx"), 2),
    Pergunta("No Excel, qual função é usada para encontrar o maior valor em um intervalo que atende a um critério específico?",
             ("MÁXIMO", "PROC", "PROCV", "MAXSE"), 1),
    Pergunta("Qual é a fórmula do Excel que retorna o valor mínimo de um intervalo de células?",
             ("MIN", "MÍNIMO", "MÍN", "MENOR"), 0),
    Pergunta("No Word, qual recurso permite criar um documento com um layout de duas ou mais colunas?",
             ("Quebra de Página", "Inserir Tabela", "Margens", "Colunas"), 3),
]

NIVEIS = [NIVEL_1, NIVEL_2, NIVEL_3]
