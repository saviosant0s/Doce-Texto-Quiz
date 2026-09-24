import pygame
import sys
import pygame.time
import pickle

pygame.init()
pygame.mixer.init()
AMARELO = ("#F4E038")
ROXO = ("#7E57B1")
tempo_inicial = pygame.time.get_ticks()
tempo_limite = 30000 # tempo das perguntas
font = pygame.font.Font(None, 46)
font2 = pygame.font.Font(None, 32)

res = []
score = 0
coins = 0

perguntas = [
    {
        "pergunta": "Qual software é comumente usado para criar documentos de texto?",
        "alternativas": ["Word", "Excel", "PowerPoint", "Paint"],
        "resposta": 0  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": " Qual é a extensão de arquivo padrão de um documento do Word?",
        "alternativas": ["pptx", "xlsx", "docx", "png"],
        "resposta": 2  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual opção permite verificar a ortografia em um documento do Word?",
        "alternativas": ["Layout", "Formatar", "Inserir", "Revisar"],
        "resposta": 3  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "O que é um 'documento' em um processador de texto?",
        "alternativas": ["Célula de dados", "Arquivo de imagem", "Arquivo de texto", "Pasta de texto"],
        "resposta": 2  # Índice da resposta correta (começando em 0)
    },
{
        "pergunta": "No Word, qual guia permite formatar o texto, como fonte e tamanho?",
        "alternativas": ["Revisar", "Página Inicial", "Layout da Página", "Inserir"],
        "resposta": 1 # Índice da resposta correta (começando em 0)
    },    
    {
        "pergunta": "Qual tecla de atalho comum é usada para copiar texto no Word?",
        "alternativas": ["Ctrl + C", "Ctrl + X","Ctrl + V", "Ctrl + Z"],
        "resposta": 0  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Para que serve o software Excel?",
        "alternativas": [ "Criar apresentações", "Criar códigos","Criar planilhas","Criar design"],
        "resposta": 2  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "No Excel, qual termo é usado para se referir a uma interseção de uma linha e uma coluna?",
        "alternativas": ["Planilhas", "Cédulas", "Linhunas", "Célula"],
        "resposta": 3  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual função do Excel é usada para somar um intervalo de valores?",
        "alternativas": ["=MÉDIA()", "=SOMA()", "=CONTAR()", "=SE()"],
        "resposta": 1  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual termo é usado para referenciar um conjunto de células adjacentes em uma planilha do Excel?",
        "alternativas": ["Intervalo", "Linha", "Coluna", "Fórmula"],
        "resposta": 0  # Índice da resposta correta (começando em 0)
    },

    # Adicione mais perguntas da mesma forma
]

perguntas2 = [
    {
        "pergunta": "Qual recurso do Word permite criar uma lista numerada automaticamente?",
        "alternativas": ["Esquema", "Numeração", "Índice", "Marcadores"],
        "resposta": 1  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": " No Excel, o que é uma função condicional usada para verificar se uma condição é verdadeira ou falsa?",
        "alternativas": ["=CONTAR()", "=MÉDIA()", "=SE()", "=SOMA()"],
        "resposta": 2 # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual comando no Excel permite dividir o conteúdo de uma célula em várias colunas com base em um separador?",
        "alternativas": ["Divisão de Colunas", "Dividir Células", "Mesclar Células", "Separar Texto"],
        "resposta": 0 # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "O que significa a sigla 'CSV' quando se trata de formatos de arquivo?",
        "alternativas": ["C... Spreadsheet Value", "C... Standard View", "C... Some Values", "C... Separated Values"],
        "resposta": 3  # Índice da resposta correta (começando em 0)
    },
{
        "pergunta": "No Word, qual recurso é usado para criar uma cópia idêntica de um texto ou objeto em um documento?",
        "alternativas": ["Clonar", "Duplicar", "Copiar", "Repetir"],
        "resposta": 2 # Índice da resposta correta (começando em 0)
    },    
    {
        "pergunta": "Qual função do Excel é usada para encontrar o valor máximo em um intervalo de células?",
        "alternativas": ["=MAX()", "=MÁXIMO()","=CONTAR.MAX()", "=MX()"],
        "resposta": 1  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual extensão de arquivo é comumente associada a planilhas do Excel?",
        "alternativas": [ "xcl", "xwp","xltx","xlsx"],
        "resposta": 3  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "No Word, qual recurso permite criar uma tabela a partir de texto existente em um documento?",
        "alternativas": ["Converter texto - tabela", "Converter texto - gráfico", "Formatar tabela", "Criar tabela"],
        "resposta": 0  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual recurso do Microsoft Word permite ajustar a margem de um documento?",
        "alternativas": ["Estilo da página", "Numeração de página", "Configuração de página", "Espaçamento"],
        "resposta": 2  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual é a função do Excel usada para contar o número de células não vazias em um intervalo?",
        "alternativas": ["=CONT.VALOR()", "=CONT.NÃO.VAZIO()", "=SOMASE()", "=CONTAR.SE()"],
        "resposta": 1  # Índice da resposta correta (começando em 0)
    },

    # Adicione mais perguntas da mesma forma
]

perguntas3 = [
    {
        "pergunta": "No Excel, qual função é usada para encontrar a média ponderada de um conjunto de valores?",
        "alternativas": ["MÉDIA", "MÉDIAHARM", "MÉDIAEX", "MÉDIASE"],
        "resposta": 3  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": " O que é ou para que serve uma 'macro'' no Excel?",
        "alternativas": ["Automação de tarefas", "Tipo de gráfico", "Fórmula complexa", "Tipo de célula"],
        "resposta": 0 # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual é a função do Excel que retorna o valor absoluto de um número?",
        "alternativas": ["MOD", "SQRT", "ABS", "INT"],
        "resposta": 2 # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "No Excel, qual função é usada para calcular a taxa interna de retorno de um investimento?",
        "alternativas": ["NPV", "IRR", "MÉDIA", "TAXA"],
        "resposta": 1  # Índice da resposta correta (começando em 0)
    },
{
        "pergunta": "Como você pode inserir uma quebra de página manual em um documento do Word?",
        "alternativas": ["Ctrl + Enter", "Alt + Enter", "Shift + Enter", "F12"],
        "resposta": 0 # Índice da resposta correta (começando em 0)
    },    
    {
        "pergunta": "No Word, qual recurso é usado para criar um índice automático com base nos títulos e subtítulos do documento?",
        "alternativas": ["Sumário", "Numeração","Bibliografia", "Índice"],
        "resposta": 3  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual extensão de arquivo é usada para MODELOS de documentos do Word?",
        "alternativas": [ "docx", "xlsx","dotx","pptx"],
        "resposta": 2  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "No Excel, qual função é usada para encontrar o maior valor em um intervalo que atende a um critério específico?",
        "alternativas": ["MÁXIMO", "PROC", "PROCV", "MAXSE"],
        "resposta": 1  # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "Qual é a fórmula do Excel que retorna o valor mínimo de um intervalo de células?",
        "alternativas": ["MIN", "MÍNIMO", " MÍN", "MENOR"],
        "resposta": 0 # Índice da resposta correta (começando em 0)
    },
    {
        "pergunta": "No Word, qual recurso permite criar um documento com um layout de duas ou mais colunas?",
        "alternativas": ["Quebra de Página", "Inserir Tabela", "Margens", "Colunas"],
        "resposta": 3  # Índice da resposta correta (começando em 0)
    },

    # Adicione mais perguntas da mesma forma
]

#quantidade de perguntas acertadas
qtdperguntas = 10
qtdacertadas = 0
qtdacertadas2 = 0
qtdacertadas3 = 0

def carregar_dados2():
    try:
        with open("pontuacoes.pkl", "rb") as arquivo:
            dados_pontuacao = pickle.load(arquivo)
        print("Pontuações carregadas com sucesso!")
        return dados_pontuacao
    except FileNotFoundError:
        print("Arquivo não encontrado. Iniciando com valores padrão.")
        return {"qtdacertadas": 0, "qtdacertadas2": 0, "qtdacertadas3": 0}

def salvar_dados2(dados_pontuacao):
    with open("pontuacoes.pkl", "wb") as arquivo:
        pickle.dump(dados_pontuacao, arquivo)
    print("Pontuações salvas com sucesso!")

dados_pontuacao = carregar_dados2()
qtdacertadas = dados_pontuacao["qtdacertadas"]
qtdacertadas2 = dados_pontuacao["qtdacertadas2"]
qtdacertadas3 = dados_pontuacao["qtdacertadas3"]

#quantidade de titulos
titulo_noob = 0
titulo_pro = 0
titulo_mestre = 0

def carregar_dados3():
    try:
        with open("titulos.pkl", "rb") as arquivo:
            dados_titulos = pickle.load(arquivo)
        print("Pontuações carregadas com sucesso!")
        return dados_titulos
    except FileNotFoundError:
        print("Arquivo não encontrado. Iniciando com valores padrão.")
        return {"titulo_noob": 0, "titulo_pro": 0, "titulo_mestre": 0}

def salvar_dados3(dados_titulos):
    with open("titulos.pkl", "wb") as arquivo:
        pickle.dump(dados_titulos, arquivo)
    print("Pontuações salvas com sucesso!")

dados_titulos = carregar_dados3()
titulo_noob = dados_titulos["titulo_noob"]
titulo_pro = dados_titulos["titulo_pro"]
titulo_mestre = dados_titulos["titulo_mestre"]

#salvar quantidade de coins
save_file2 = 'save_file2'
def salvar_dados5():
    with open(save_file2, "wb") as f:
        pickle.dump(coins, f)
    print("Dados salvos!")

try:
    with open(save_file2, "rb") as f:
         coins = pickle.load(f)
except FileNotFoundError:
    pass

#sons
musica1 = 'musica1.mp3'
musica2 = 'musica2.mp3'
musica3 = 'music_main.mp3'
acerto_song = 'acerto.mp3'
erro_song = 'erro.mp3'

#telas
tela2 = False
tela3 = False
tela4 = False
tela5 = False
tela6 = False
tela7 = False
tela8 = False
tela9 = False
tela10 = False
tela20 = False
tela21 = False

largura = 720
altura = 1438

#transparencia de retangulo
transparente = pygame.Surface((100, 100), pygame.SRCALPHA)
transparente.fill((0, 0, 0, 0))

#tela inicial
tela = pygame.display.set_mode((altura, largura))
tela_width = tela.get_width()
tela_height = tela.get_height()
print(tela_width, tela_height)

home = pygame.image.load("1.png")
home = pygame.transform.scale(home, (altura, largura))

# botoes tela inicial
start = pygame.Rect(315, 510, 263, 85)
credits_btt = pygame.Rect(590, 510, 110, 85)
dica_btt1 = pygame.Rect(210, 510, 100, 85)

niveis_tela = pygame.display.set_mode((altura, largura))
niveis_img = pygame.image.load("17.png")
niveis_img = pygame.transform.scale(niveis_img, (altura, largura))
home_btt4 = pygame.Rect(135, 170, 80, 65)
titulos_btt4 = pygame.Rect(135, 275, 80, 65)
dica_btt4 = pygame.Rect(135, 380, 80, 65)
compras_btt4 = pygame.Rect(135, 485, 80, 65)
nivel1_btt = pygame.Rect(305, 345, 270, 155)
nivel2_btt = pygame.Rect(685, 345, 270, 155)
nivel3_btt = pygame.Rect(1065, 345, 270, 155)

def abrir_niveis():
    tela1 = False
    tela10 = True
    global qtdacertadas, qtdacertadas2, qtdacertadas3
    texto_qtd = font.render(f"{qtdacertadas}/{qtdperguntas} ", True, (AMARELO))
    texto_qtd2 = font.render(f"{qtdacertadas2}/{qtdperguntas} ", True, (AMARELO))
    texto_qtd3 = font.render(f"{qtdacertadas3}/{qtdperguntas} ", True, (AMARELO))
    while tela10:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if nivel1_btt.collidepoint(event.pos):
                    tela10 = False
                    qtdacertadas = 0
                    tela_de_carregamento()
                    abrir_game()
                if nivel2_btt.collidepoint(event.pos):
                    tela10 = False
                    qtdacertadas2 = 0
                    tela_de_carregamento()
                    abrir_game2()
                    
                    exibir_texto_temporario((550, 630))
                if nivel3_btt.collidepoint(event.pos):
                    tela10 = False
                    qtdacertadas3 = 0
                    tela_de_carregamento()
                    abrir_game3()
                    
                if home_btt4.collidepoint(event.pos):
                    tela10 = False
                    tela_inicial()
                if dica_btt4.collidepoint(event.pos):

                    abrir_dica()
                if compras_btt4.collidepoint(event.pos):
                    abrir_creditos()
                if titulos_btt4.collidepoint(event.pos):
                    abrir_titulos()

        niveis_tela.blit(niveis_img, (0, 0))
        niveis_tela.blit(texto_qtd, (420,510))
        niveis_tela.blit(texto_qtd2, (790, 510))
        niveis_tela.blit(texto_qtd3, (1170, 510))
        pygame.draw.rect(transparente, (0, 0, 0), dica_btt4)
        pygame.draw.rect(transparente, (0, 0, 0), home_btt4)
        pygame.draw.rect(transparente, (0, 0, 0), titulos_btt4)
        pygame.draw.rect(transparente, (0, 0, 0), compras_btt4)
        pygame.draw.rect(transparente, (0, 0, 0), nivel1_btt)
        pygame.draw.rect(transparente, (0, 0, 0), nivel2_btt)
        pygame.draw.rect(transparente, (0, 0, 0), nivel3_btt)

        pygame.display.update()

titulos_tela = pygame.display.set_mode((altura, largura))
titulos_img = pygame.image.load("30.png")
titulos_img = pygame.transform.scale(titulos_img, (altura, largura))
back_btt5 = pygame.Rect(505, 110, 95, 95)
def abrir_titulos():
    
    tela10 = False
    tela21 = True

    while tela21:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if back_btt5.collidepoint(event.pos):
                    tela21 = False
                    tela10 = True
                    
                

        titulos_tela.blit(titulos_img, (0, 0))
        pygame.draw.rect(transparente, (0, 0, 0), back_btt5)
        titulo_noob_text = font.render(f"{titulo_noob}X NOOB", True, (ROXO))
        titulo_pro_text = font.render(f"{titulo_pro}X PRO", True, (ROXO))
        titulo_mestre_text= font.render(f"{titulo_mestre}X MESTRE", True, (ROXO))
        tela.blit(titulo_noob_text, (180, 530))
        tela.blit(titulo_pro_text, (665,530))
        tela.blit(titulo_mestre_text, (1120,530))
        
        pygame.display.update()

def tela_de_carregamento():
    global largura, altura, tela20
    tela20 = True
    tela_loading = pygame.display.set_mode((altura, largura))

    # Adicione aqui quaisquer elementos visuais que você deseja exibir na tela de carregamento
    loading = pygame.image.load("loading.png")
    loading = pygame.transform.scale(loading, (altura, largura))

    # Crie uma superfície transparente para o efeito de fade-in e fade-out
    # Inicie com transparência total

    # Carregue um arquivo de som para o carregamento
    sound = pygame.mixer.Sound("musica2.mp3")

    # Crie uma fonte para o contador de FPS
    fonte = pygame.font.SysFont("Arial", 32)

    # Defina as dimensões da barra de carregamento
    barra_x = 360  # Posição X inicial da barra de carregamento
    barra_y = 575  # Posição Y da barra de carregamento
    barra_largura = 0  # Largura inicial da barra de carregamento
    barra_altura = 40  # Altura da barra de carregamento
    barra_cor = (ROXO)  # Cor da barra de carregamento (verde)

    # Defina o tempo de carregamento em milissegundos (por exemplo, 3000 ms = 3 segundos)
    tempo_de_carregamento = 3000

    # Inicie o relógio

    carregamento_completo = False

    tempo_inicial1 = pygame.time.get_ticks()

    # Toque o som de carregamento uma vez
    # sound.play()

    while tela20:
        while not carregamento_completo:

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()

            # Atualize a barra de carregamento
            tempo_atual1 = pygame.time.get_ticks()
            tempo_passado1 = tempo_atual1 - tempo_inicial1
            progresso = min(1.0, tempo_passado1 / tempo_de_carregamento)  # Garanta que o progresso não exceda 1.0

            # Calcule a largura atual da barra de carregamento
            barra_largura = int(largura * progresso)

            # Verifique se o carregamento está completo
            if progresso >= 1.0:
                carregamento_completo = True
                tela20 = False
                #abrir_game()

            # Calcule a transparência atual da superfície de fade-in e fade-out
            # Aplique a transparência na superfície

            # Obtenha a taxa de quadros atual do relógio

            tela_loading.blit(loading, (0, 0))

            # Desenhe a barra de carregamento
            pygame.draw.rect(tela_loading, barra_cor, (barra_x, barra_y, barra_largura, barra_altura), border_radius=10)

            # Desenhe a superfície de fade-in e fade-out sobre a imagem de carregamento

            # Desenhe o texto do contador de FPS no canto superior esquerdo da tela

            pygame.display.update()

        # Adicione um atraso de alguns segundos (por exemplo, 3 segundos)
        pygame.time.delay(3000)  # 3000 milissegundos = 3 segundos

game_tela = pygame.display.set_mode((largura, altura))
game = pygame.image.load("4.png")
game = pygame.transform.scale(game, (altura, largura))
song_btt = pygame.Rect(840, 340, 70, 65)
search_btt = pygame.Rect(840, 270, 70, 65)
eliminar_btt = pygame.Rect(840, 410, 70, 65)
font3 = pygame.font.Font(None, 46)
tampa_btt1 = pygame.Rect(840, 270, 70, 65)
tampa_btt2 = pygame.Rect(840, 400, 70, 65)

def abrir_game():
    global font3, qtdacertadas, quantidades
    global tempo_inicial, tampa_btt1, tampa_btt2, ROXO  # Declare tempo_pausado como global
    tempo_inicial = pygame.time.get_ticks()
    global score

    score = 0
    res.clear()

    tela1 = False
    tela2 = True
    pergunta_atual = 0  # Índice da pergunta atual
    mensagens = []
    # Define the mensagens list here

    while tela2:
        game_tela.fill(ROXO)
        resposta_selecionada = -1  # Inicializa a variável aqui
        mensagens = []
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if song_btt.collidepoint(event.pos):
                    alternar_musica()
                # if search_btt.collidepoint(event.pos):
                #
                #
                #     exibir_texto_temporario((550, 350))
                # if eliminar_btt.collidepoint(event.pos):
                #     exibir_texto_temporario((550, 350))
                else:
                    for i, rect in enumerate(alternativa_rects):
                        if rect.collidepoint(event.pos):
                            resposta_selecionada = i
                            break

        if resposta_selecionada != -1:
            if resposta_selecionada == perguntas[pergunta_atual]["resposta"]:
                mensagem = "Acertou"
                tocar_musica(acerto_song)
                print("acertou")
                qtdacertadas += 1

                score += 10

                res.append(mensagem)  # Armazena mensagem e cor
            else:
                print("errou")
                mensagem = "Errou"
                tocar_musica(erro_song)

                res.append(mensagem)

            pergunta_atual += 1
            tempo_inicial = pygame.time.get_ticks()

        if pergunta_atual < len(perguntas):
            game_tela.blit(game, (0, 0))
            pygame.draw.rect(transparente, (0, 0, 0), song_btt)
            pygame.draw.rect(transparente, (0, 0, 0), eliminar_btt)
            pygame.draw.rect(tela, ("#7E57B1"), tampa_btt1)
            pygame.draw.rect(tela, ("#7E57B1"), tampa_btt2)
            pygame.draw.rect(transparente, (0, 0, 0), search_btt)

            alternativa_rects = []
            for i, alternativa in enumerate(perguntas[pergunta_atual]["alternativas"]):
                # Crie um retângulo maior
                alternativa_rect = pygame.Rect(910, 163 + i * 105, 420, 80)  # Ajuste as dimensões conforme necessário
                alternativa_rects.append(alternativa_rect)

            for i, alternativa in enumerate(perguntas[pergunta_atual]["alternativas"]):
                alternativa_texto = font.render(alternativa, True, (ROXO))
                alternativa_rect = alternativa_texto.get_rect(center=alternativa_rects[i].center)
                game_tela.blit(alternativa_texto, alternativa_rect)

            # Restante do seu código...

            tempo_passado = pygame.time.get_ticks() - tempo_inicial
            if tempo_passado >= tempo_limite:
                res.append("Errou")
                pergunta_atual += 1
                tempo_inicial = pygame.time.get_ticks()

            tempo_restante = max(0, (tempo_limite - tempo_passado) // 1000)  # Calculate remaining time in seconds
            tempo_texto = font2.render(f"{tempo_restante} ", True, (ROXO))
            max_width = 500

            def render_text_with_line_breaks(text, font, max_width):
                words = text.split(" ")
                lines = []
                current_line = ""

                for word in words:
                    test_line = current_line + word + " "
                    test_size = font.size(test_line)

                    if test_size[0] <= max_width:
                        current_line = test_line
                    else:
                        lines.append(current_line)
                        current_line = word + " "

                lines.append(current_line)

                return lines

            # Use a função render_text_with_line_breaks para renderizar o texto com quebras de linha
            pergunta_text = perguntas[pergunta_atual]["pergunta"]
            pergunta_lines = render_text_with_line_breaks(pergunta_text, font, max_width)
            y_offset = 300

            for line in pergunta_lines:
                pergunta_surface = font.render(line, True, (ROXO))
                pergunta_rect = pergunta_surface.get_rect(center=(480, y_offset))
                game_tela.blit(pergunta_surface, pergunta_rect)
                y_offset += 50  # Espaçamento entre linhas

                game_tela.blit(tempo_texto, (470, 210))

            pygame.display.update()

        else:
            aprv1()
            tela2 = False

def abrir_game2():
    global font3, qtdacertadas2
    global tempo_inicial  # Declare tempo_pausado como global
    tempo_inicial = pygame.time.get_ticks()
    global score

    score = 0
    res.clear()

    tela1 = False
    tela2 = True
    pergunta_atual = 0  # Índice da pergunta atual
    mensagens = []
    # Define the mensagens list here

    while tela2:
        game_tela.fill(ROXO)
        resposta_selecionada = -1  # Inicializa a variável aqui
        mensagens = []
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if song_btt.collidepoint(event.pos):
                    alternar_musica()
                # if search_btt.collidepoint(event.pos):
                #     exibir_texto_temporario((550, 350))
                # if eliminar_btt.collidepoint(event.pos):
                #     exibir_texto_temporario((550, 350))
                else:
                    for i, rect in enumerate(alternativa_rects):
                        if rect.collidepoint(event.pos):
                            resposta_selecionada = i
                            break

        if resposta_selecionada != -1:
            if resposta_selecionada == perguntas2[pergunta_atual]["resposta"]:
                mensagem = "Acertou"
                print("acertou")
                qtdacertadas2 += 1
                tocar_musica(acerto_song)
                score += 10

                res.append(mensagem)  # Armazena mensagem e cor
            else:
                print("errou")
                mensagem = "Errou"
                tocar_musica(erro_song)
                res.append(mensagem)

            pergunta_atual += 1
            tempo_inicial = pygame.time.get_ticks()

        if pergunta_atual < len(perguntas2):
            game_tela.blit(game, (0, 0))
            pygame.draw.rect(transparente, (0, 0, 0), song_btt)
            pygame.draw.rect(transparente, (0, 0, 0), eliminar_btt)
            pygame.draw.rect(transparente, (0, 0, 0), search_btt)
            pygame.draw.rect(tela, ("#7E57B1"), tampa_btt1)
            pygame.draw.rect(tela, ("#7E57B1"), tampa_btt2)

            alternativa_rects = []
            for i, alternativa in enumerate(perguntas2[pergunta_atual]["alternativas"]):
                # Crie um retângulo maior
                alternativa_rect = pygame.Rect(910, 163 + i * 105, 420, 80)  # Ajuste as dimensões conforme necessário
                alternativa_rects.append(alternativa_rect)

            for i, alternativa in enumerate(perguntas2[pergunta_atual]["alternativas"]):
                alternativa_texto = font.render(alternativa, True, (ROXO))
                alternativa_rect = alternativa_texto.get_rect(center=alternativa_rects[i].center)
                game_tela.blit(alternativa_texto, alternativa_rect)

            # Restante do seu código...

            tempo_passado = pygame.time.get_ticks() - tempo_inicial
            if tempo_passado >= tempo_limite:
                res.append("Errou")
                pergunta_atual += 1
                tempo_inicial = pygame.time.get_ticks()

            tempo_restante = max(0, (tempo_limite - tempo_passado) // 1000)  # Calculate remaining time in seconds
            tempo_texto = font2.render(f"{tempo_restante} ", True, (ROXO))
            max_width = 500

            def render_text_with_line_breaks(text, font, max_width):
                words = text.split(" ")
                lines = []
                current_line = ""

                for word in words:
                    test_line = current_line + word + " "
                    test_size = font.size(test_line)

                    if test_size[0] <= max_width:
                        current_line = test_line
                    else:
                        lines.append(current_line)
                        current_line = word + " "

                lines.append(current_line)

                return lines

            # Use a função render_text_with_line_breaks para renderizar o texto com quebras de linha
            pergunta_text = perguntas2[pergunta_atual]["pergunta"]
            pergunta_lines = render_text_with_line_breaks(pergunta_text, font, max_width)
            y_offset = 300

            for line in pergunta_lines:
                pergunta_surface = font.render(line, True, (ROXO))
                pergunta_rect = pergunta_surface.get_rect(center=(480, y_offset))
                game_tela.blit(pergunta_surface, pergunta_rect)
                y_offset += 50  # Espaçamento entre linhas

                game_tela.blit(tempo_texto, (470, 210))

            pygame.display.update()

        else:
            aprv1()
            tela2 = False

def abrir_game3():
    global font3, qtdacertadas3
    global tempo_inicial  # Declare tempo_pausado como global
    tempo_inicial = pygame.time.get_ticks()
    global score

    score = 0
    res.clear()

    tela1 = False
    tela2 = True
    pergunta_atual = 0  # Índice da pergunta atual
    mensagens = []
    # Define the mensagens list here

    while tela2:
        game_tela.fill(ROXO)
        resposta_selecionada = -1  # Inicializa a variável aqui
        mensagens = []
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if song_btt.collidepoint(event.pos):
                    alternar_musica()
                # if search_btt.collidepoint(event.pos):
                #     exibir_texto_temporario((550, 350))
                # if eliminar_btt.collidepoint(event.pos):
                #     exibir_texto_temporario((550, 350))
                else:
                    for i, rect in enumerate(alternativa_rects):
                        if rect.collidepoint(event.pos):
                            resposta_selecionada = i
                            break

        if resposta_selecionada != -1:
            if resposta_selecionada == perguntas3[pergunta_atual]["resposta"]:
                mensagem = "Acertou"
                tocar_musica(acerto_song)
                print("acertou")
                qtdacertadas3 += 1

                score += 10

                res.append(mensagem)  # Armazena mensagem e cor
            else:
                print("errou")
                mensagem = "Errou"
                tocar_musica(erro_song)

                res.append(mensagem)

            pergunta_atual += 1
            tempo_inicial = pygame.time.get_ticks()

        if pergunta_atual < len(perguntas3):
            game_tela.blit(game, (0, 0))
            pygame.draw.rect(transparente, (0, 0, 0), song_btt)
            pygame.draw.rect(transparente, (0, 0, 0), eliminar_btt)
            pygame.draw.rect(transparente, (0, 0, 0), search_btt)
            pygame.draw.rect(tela, ("#7E57B1"), tampa_btt1)
            pygame.draw.rect(tela, ("#7E57B1"), tampa_btt2)

            alternativa_rects = []
            for i, alternativa in enumerate(perguntas3[pergunta_atual]["alternativas"]):
                # Crie um retângulo maior
                alternativa_rect = pygame.Rect(910, 163 + i * 105, 420, 80)  # Ajuste as dimensões conforme necessário
                alternativa_rects.append(alternativa_rect)

            for i, alternativa in enumerate(perguntas3[pergunta_atual]["alternativas"]):
                alternativa_texto = font.render(alternativa, True, (ROXO))
                alternativa_rect = alternativa_texto.get_rect(center=alternativa_rects[i].center)
                game_tela.blit(alternativa_texto, alternativa_rect)

            # Restante do seu código...

            tempo_passado = pygame.time.get_ticks() - tempo_inicial
            if tempo_passado >= tempo_limite:
                res.append("Errou")
                pergunta_atual += 1
                tempo_inicial = pygame.time.get_ticks()

            tempo_restante = max(0, (tempo_limite - tempo_passado) // 1000)  # Calculate remaining time in seconds
            tempo_texto = font2.render(f"{tempo_restante} ", True, (ROXO))
            max_width = 500

            def render_text_with_line_breaks(text, font, max_width):
                words = text.split(" ")
                lines = []
                current_line = ""

                for word in words:
                    test_line = current_line + word + " "
                    test_size = font.size(test_line)

                    if test_size[0] <= max_width:
                        current_line = test_line
                    else:
                        lines.append(current_line)
                        current_line = word + " "

                lines.append(current_line)

                return lines

            # Use a função render_text_with_line_breaks para renderizar o texto com quebras de linha
            pergunta_text = perguntas3[pergunta_atual]["pergunta"]
            pergunta_lines = render_text_with_line_breaks(pergunta_text, font, max_width)
            y_offset = 300

            for line in pergunta_lines:
                pergunta_surface = font.render(line, True, (ROXO))
                pergunta_rect = pergunta_surface.get_rect(center=(480, y_offset))
                game_tela.blit(pergunta_surface, pergunta_rect)
                y_offset += 50  # Espaçamento entre linhas

                game_tela.blit(tempo_texto, (470, 210))

            pygame.display.update()

        else:
            aprv1()
            tela2 = False

tela22 = False
def sobre():
    global tela22
    tela22 = True
    sobre_tela = pygame.display.set_mode((altura, largura))
    sobre_img = pygame.image.load("31.png")
    sobre_img = pygame.transform.scale(sobre_img, (altura, largura))
    back_btt6 = pygame.Rect(130, 110, 65, 65)
    

    while tela22:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                
                if back_btt6.collidepoint(event.pos):
                    tela22 = False
                    


        sobre_tela.blit(sobre_img,(0, 0))
        
        pygame.draw.rect(transparente, (0, 0, 0), back_btt6)
        
        pygame.display.flip()
        

credits_tela = pygame.display.set_mode((altura, largura))
credits = pygame.image.load("2.png")
credits = pygame.transform.scale(credits, (altura, largura))
back_btt = pygame.Rect(185, 510, 95, 95)
sobre_btt = pygame.Rect(690, 510, 345, 95)
doe_btt = pygame.Rect(1075, 510, 175, 95)

def abrir_creditos():
    global texto, posicao_texto
    tela1 = False
    tela3 = True

    while tela3:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if back_btt.collidepoint(event.pos):
                    tela3 = False

                    
                if doe_btt.collidepoint(event.pos):
                    # main()
                    exibir_texto_temporario((550, 630))
                if sobre_btt.collidepoint(event.pos):
                    sobre()
        credits_tela.blit(credits, (0, 0))
        pygame.draw.rect(transparente, (0, 0, 0), back_btt)
        pygame.draw.rect(transparente, (0, 0, 0), doe_btt)
        pygame.draw.rect(transparente, (0, 0, 0), sobre_btt)
        pygame.display.update()

def exibir_texto_temporario(posicao_texto):
    texto = font.render("Disponível em breve", True, AMARELO)
    tela.blit(texto, posicao_texto)
    pygame.display.update()
    pygame.time.delay(500)

dica_tela = pygame.display.set_mode((largura, altura))
dica_width = dica_tela.get_width()
dica_height = dica_tela.get_height()
dica = pygame.image.load("3.png")
dica = pygame.transform.scale(dica, (altura, largura))
next = pygame.Rect(680, 570, 85, 85)

def abrir_dica():
    tela2 = False
    tela4 = True

    while tela4:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if next.collidepoint(event.pos):
                    tela4 = False
                    tela2 = True

        dica_tela.blit(dica, (0, 0))
        pygame.draw.rect(transparente, (0, 0, 0), next)
        pygame.display.update()

aprv_tela = pygame.display.set_mode((largura, altura))
aprv_width = aprv_tela.get_width()
aprv_height = aprv_tela.get_height()
aprv_image = pygame.image.load("5.png")
aprv_image = pygame.transform.scale(aprv_image, (altura, largura))
btt_next_aprv = pygame.Rect(1060, 320, 85, 85)
font4 = pygame.font.Font(None, 42)

def aprv1():
    tela2 = False
    tela5 = True
    y_offset = 50
    

    while tela5:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if btt_next_aprv.collidepoint(event.pos):
                    if score <= 30:
                        tela5 = False
                        nodoc()
                    elif score > 30 and score <= 50:
                        tela5 = False
                        noob()
                    elif score > 50 and score <= 80:
                        tela5 = False
                        pro()
                    else:
                        tela5 = False
                        mestre()

        score_text = font.render(f"Aproveitamento {score}%", True, (AMARELO))

        text_lines = render_text_with_spacing(res, font4, 30)
        salvar_dados2({"qtdacertadas": qtdacertadas, "qtdacertadas2": qtdacertadas2, "qtdacertadas3": qtdacertadas3})
        aprv_tela.blit(aprv_image, (0, 0))
        aprv_tela.blit(score_text, (550, 30))
        pygame.draw.rect(transparente, (0, 0, 0), btt_next_aprv)
        for text_surface, text_rect in text_lines:
            aprv_tela.blit(text_surface, text_rect)
        pygame.display.update()

def render_text_with_spacing(text_list, font, spacing):
    rendered_lines = []
    y_offset = 93

    for text in text_list:
        text_surface = font.render(text, True, (ROXO))
        text_rect = text_surface.get_rect(center=(830, y_offset))
        rendered_lines.append((text_surface, text_rect))
        y_offset += 64

    return rendered_lines

nodoc_tela = pygame.display.set_mode((largura, altura))
nodoc_width = aprv_tela.get_width()
nodoc_height = aprv_tela.get_height()
nodoc_image = pygame.image.load("10.png")
nodoc_image = pygame.transform.scale(nodoc_image, (altura, largura))
tente_btt = pygame.Rect(420, 530, 600, 75)


def nodoc():
    tela5 = False
    tela6 = True
    score = 0

    while tela6:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if tente_btt.collidepoint(event.pos):
                    tela1 = True
                    tela6 = False
                    tela_inicial()
                if video1_btt.collidepoint(event.pos):
                    exibir_texto_temporario((550, 30))
                if video2_btt.collidepoint(event.pos):
                    exibir_texto_temporario((550, 30))
        nodoc_tela.blit(nodoc_image, (0, 0))
        pygame.draw.rect(transparente, (0, 0, 0), tente_btt)
        

        pygame.display.update()

noob_tela = pygame.display.set_mode((altura, largura))
noob_width = noob_tela.get_width()
noob_height = noob_tela.get_height()
noob_image = pygame.image.load("6.png")
noob_image = pygame.transform.scale(noob_image, (altura, largura))
home_btt = pygame.Rect(885, 120, 65, 65)

def noob():
    global titulo_noob, titulo_pro, titulo_mestre, coins
    titulo_noob += 1
    coins += 40
    salvar_dados5()
    salvar_dados3({"titulo_noob": titulo_noob, "titulo_pro": titulo_pro, "titulo_mestre": titulo_mestre})
    tela5 = False
    tela7 = True
    score = 0
    while tela7:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if home_btt.collidepoint(event.pos):
                    tela1 = True
                    tela7 = False

                    tela_inicial()

        noob_tela.blit(noob_image, (0, 0))
        pygame.draw.rect(transparente, (0, 0, 0), home_btt)
        pygame.display.update()

pro_tela = pygame.display.set_mode((altura, largura))
pro_width = pro_tela.get_width()
pro_height = pro_tela.get_height()
pro_image = pygame.image.load("7.png")
pro_image = pygame.transform.scale(pro_image, (altura, largura))

def pro():
    global titulo_noob, titulo_mestre, titulo_pro, coins
    titulo_pro += 1
    coins += 60
    salvar_dados5()
    salvar_dados3({"titulo_noob": titulo_noob, "titulo_pro": titulo_pro, "titulo_mestre": titulo_mestre})
    tela5 = False
    tela8 = True
    score = 0
    while tela8:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if home_btt.collidepoint(event.pos):
                    tela1 = True
                    tela8 = False
                    tela_inicial()

        pro_tela.blit(pro_image, (0, 0))
        pygame.draw.rect(transparente, (0, 0, 0), home_btt)

        pygame.display.update()

mestre_tela = pygame.display.set_mode((altura, largura))
mestre_width = mestre_tela.get_width()
mestre_height = mestre_tela.get_height()
mestre_image = pygame.image.load("16.png")
mestre_image = pygame.transform.scale(mestre_image, (altura, largura))
home_btt2 = pygame.Rect(1095, 240, 75, 75)

def mestre():
    global titulo_mestre, titulo_noob, titulo_pro,coins
    coins += 100
    titulo_mestre += 1
    salvar_dados5()
    salvar_dados3({"titulo_noob": titulo_noob, "titulo_pro": titulo_pro, "titulo_mestre": titulo_mestre})
    tela5 = False
    tela9 = True
    score = 0
    while tela9:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if home_btt2.collidepoint(event.pos):
                    tela1 = True
                    tela9 = False
                    tela_inicial()

        mestre_tela.blit(mestre_image, (0, 0))
        pygame.draw.rect(transparente, (0, 0, 0), home_btt2)

        pygame.display.update()

def tocar_musica(musica):
    #pygame.mixer.music.load(musica)
    som = pygame.mixer.Sound(musica)
    #som.set_volume(0.2)
    som.play()
     # -1 para reprodução contínua

def tocar_musica2(musica):
    pygame.mixer.music.load(musica)
    #pygame.mixer.music.set_volume(0.2)
    pygame.mixer.music.play(-1)  # -1 para reprodução contínua
tocar_musica2(musica3)

def alternar_musica():
    if pygame.mixer.music.get_busy():  # Verifique se a música está tocando
        pygame.mixer.music.pause()  # Pausar a música
    else:
        pygame.mixer.music.unpause()

tela1 = True

def tela_inicial():
    global tela1, font

    while tela1:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if start.collidepoint(event.pos):
                    tela20 = True
                    # tela_de_carregamento()
                    # abrir_game()
                    abrir_niveis()

                if credits_btt.collidepoint(event.pos):
                    abrir_creditos()
                if dica_btt1.collidepoint(event.pos):
                    abrir_dica()

        

        tela.blit(home, (0, 0))
        

        pygame.draw.rect(transparente, (0, 0, 0), credits_btt)
        pygame.draw.rect(transparente, (0, 0, 0), dica_btt1)
        pygame.draw.rect(transparente, (0, 0, 0), start)

        pygame.display.update()

tela_inicial()
