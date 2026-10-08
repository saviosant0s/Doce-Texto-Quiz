#!/bin/bash
# Vídeo vertical de divulgação (formato stories/reels do Instagram, 1080x1920,
# ~31 s): grava as melhores partes do jogo jogando sozinho (o próprio Godot,
# --write-movie a 30 quadros por segundo) e edita quadro a quadro com cortes no
# ritmo da música, transições, câmera lenta, legendas, adesivos e a tela final
# (ferramentas/editar_video_stories.py).
# Saída: build/stories/doce_texto_stories.mp4 (+ capa.jpg).
# Precisa de xvfb-run, ffmpeg e python3 com Pillow, numpy e scipy. Grava em
# uns 15 minutos (sem placa de vídeo) e edita em uns 3.
# Uso (na pasta do repositório): ferramentas/gerar_video_stories.sh
#     (as cenas já gravadas em build/stories/cenas ficam; apague para regravar)
#     SO_MONTAR=1 ferramentas/gerar_video_stories.sh   (só remonta, sem gravar de novo)
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
cat > godot/override.cfg <<CFG
[display]
window/size/viewport_width=$LARGURA
window/size/viewport_height=$ALTURA
CFG
trap 'rm -f godot/override.cfg' EXIT

gravar() {  # nome, tela, opções da captura... (cena já gravada fica: apague para regravar)
	if [ -f "$SAIDA/cenas/$1.avi" ]; then
		echo "cena já gravada: $1"
		return
	fi
	# shellcheck disable=SC2086
	timeout 1800 xvfb-run -a -s "-screen 0 ${LARGURA}x${ALTURA}x24" godot --path godot $RENDER \
		--resolution ${LARGURA}x${ALTURA} --write-movie "$(pwd)/$SAIDA/cenas/$1.avi" --fixed-fps 30 \
		-- --capturar="$2" --saida="$(pwd)/$SAIDA/cenas/nada.png" --retrato --sem_musica --qualidade=2 "${@:3}" \
		> "$SAIDA/cenas/$1.log" 2>&1
	echo "cena gravada: $1 ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$SAIDA/cenas/$1.avi") s)"
}

if [ -z "$SO_MONTAR" ]; then
	gravar 1_vila vila --video_vila --duracao=4.6
	gravar 2_corrida corrida --trailer_corrida=6.6 --corrida_inicio=100
	gravar 3_chefao vila --video_chefao --duracao=6.2
	gravar 4_batalha batalha --video_batalha --duracao=5.6
	gravar 5_casa minha_casa --casa_cheia --duracao=3.8
	gravar 6_final vila --abertura_final --abertura_sem_texto --duracao=5.4
fi
python3 ferramentas/editar_video_stories.py "$SAIDA"
