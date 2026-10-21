#!/bin/bash
# Vídeo vertical de divulgação (formato stories/reels do Instagram, 1080x1920,
# ~31 s): grava as melhores partes do jogo jogando sozinho (o próprio Godot,
# --write-movie a 30 quadros por segundo) e edita quadro a quadro com cortes no
# ritmo da música, transições, câmera lenta, legendas, adesivos e a tela final
# (ferramentas/editar_video_stories.py).
# Saída: build/stories/doce_texto_stories.mp4 (+ capa.jpg).
# Precisa de xvfb-run, ffmpeg e python3 com Pillow, numpy e scipy. Grava em
# uns 45 minutos (sem placa de vídeo) e edita em uns 4.
# Uso (na pasta do repositório): ferramentas/gerar_video_stories.sh
#     (as cenas já gravadas em build/stories/cenas ficam; apague para regravar)
#     SO_MONTAR=1 ferramentas/gerar_video_stories.sh   (só remonta, sem gravar de novo)
#     SO_GRAVAR=1 ferramentas/gerar_video_stories.sh   (só grava as cenas que faltam)
cd "$(dirname "$0")/.." || exit 1
SAIDA=build/stories
mkdir -p "$SAIDA/cenas"
if ls /usr/share/vulkan/icd.d/lvp_icd*.json >/dev/null 2>&1; then
	RENDER="--rendering-method mobile --rendering-driver vulkan"
else
	RENDER="--rendering-method gl_compatibility --rendering-driver opengl3"
fi
# a área do jogo no vídeo (o resto são as faixas de cima e de baixo, onde o
# Instagram põe o nome e a caixa de mensagem)
LARGURA=1080
ALTURA=1560

# o modo filme grava no tamanho da tela do projeto: um override.cfg (só
# durante a gravação) põe a tela em pé, com a interface no tamanho certo
tela_do_filme() {  # largura, altura
	cat > godot/override.cfg <<CFG
[display]
window/size/viewport_width=$1
window/size/viewport_height=$2
CFG
}
trap 'rm -f godot/override.cfg' EXIT

# nome, tela, opções da captura... (cena já gravada fica: apague para regravar).
# QUADRADO=1: grava em 1280x1280 (jogos 2D feitos para a tela deitada, como o
# Doce Match e a Fábrica: a interface fica do tamanho de sempre e o editor
# recorta a parte da ação)
gravar() {
	if [ -f "$SAIDA/cenas/$1.avi" ]; then
		echo "cena já gravada: $1"
		return
	fi
	local tam=${LARGURA}x${ALTURA}
	if [ -n "$QUADRADO" ]; then
		tam=1280x1280
		tela_do_filme 1280 1280
	else
		tela_do_filme $LARGURA $ALTURA
	fi
	# shellcheck disable=SC2086
	timeout 1800 xvfb-run -a -s "-screen 0 ${tam}x24" godot --path godot $RENDER \
		--resolution $tam --write-movie "$(pwd)/$SAIDA/cenas/$1.avi" --fixed-fps 30 \
		-- --capturar="$2" --saida="$(pwd)/$SAIDA/cenas/nada.png" --retrato --sem_musica --qualidade=2 --animacoes "${@:3}" \
		> "$SAIDA/cenas/$1.log" 2>&1
	echo "cena gravada: $1 ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$SAIDA/cenas/$1.avi") s)"
}

REGIOES=--regioes=ilha,bosque,montanha
if [ -z "$SO_MONTAR" ]; then
	gravar 1_vila vila --video_vila --hora=17.4 --duracao=4.6
	gravar 2_corrida corrida --trailer_corrida=6.6 --corrida_inicio=100
	gravar 3_chefao vila --video_chefao --duracao=6.2
	# golpes de luta: voadora, o SUPER (tornado com uppercut) que nocauteia, pirueta, cambalhota
	gravar 4_batalha batalha --video_batalha --batalha_super --desafiante=1 --arena_vencidos=1 \
		--nivel_doce=brigadeiro:5 --leitura=0.8 --golpe_inicial=1 --duracao=16
	gravar 6_final vila --abertura_final --abertura_sem_texto --duracao=5.4
	# paisagens (ver VOOS em godot/scripts/ferramentas/captura.gd)
	gravar por_do_sol vila --video_voo=por_do_sol --hora=18.2 --duracao=4.4 $REGIOES
	gravar ilha vila --video_voo=ilha --hora=17.6 --duracao=4.4 $REGIOES
	gravar chuva vila --video_voo=chuva --hora=13 --chuva --duracao=4.4 $REGIOES
	gravar timelapse vila --video_voo=timelapse --hora=17.2 --hora_ate=20.6 --duracao=5.0 $REGIOES
	# a cozinha da Confeitaria (o doce pega, vende e melhora a máquina)
	gravar cozinha cozinha --confeitaria --video_cozinha --duracao=13
	QUADRADO=1 gravar match doce_match --video_match=8 --duracao=8
	# a maçã evoluindo do nível 1 ao 5 (vira maçã do amor)
	QUADRADO=1 gravar evolucao colecao --video_evolucao=maca --duracao=11
fi
[ -n "$SO_GRAVAR" ] || python3 ferramentas/editar_video_stories.py "$SAIDA"
