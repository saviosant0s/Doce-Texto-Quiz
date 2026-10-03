#!/bin/bash
# Imagens e trailer da página de download (apk/index.html, ver
# ferramentas/publicar_web.sh), em build/divulgacao/:
#   imagens/*.jpg  telas do jogo (1280x720) e capa.jpg (capa do vídeo)
#   trailer.mp4    abertura da vila + um pedaço da corrida (~55 s)
# O vídeo é gravado pelo próprio Godot (--write-movie, 30 quadros por segundo
# fixos: fica liso mesmo sem placa de vídeo; demora uns 6 minutos).
# Precisa de xvfb-run e ffmpeg. Uso (na pasta do repositório):
#     ferramentas/gerar_divulgacao.sh            (imagens e trailer)
#     SO_IMAGENS=1 ferramentas/gerar_divulgacao.sh
cd "$(dirname "$0")/.." || exit 1
SAIDA=build/divulgacao
mkdir -p "$SAIDA/imagens"
if ls /usr/share/vulkan/icd.d/lvp_icd*.json >/dev/null 2>&1; then
	RENDER="--rendering-method mobile --rendering-driver vulkan"
else
	RENDER="--rendering-method gl_compatibility --rendering-driver opengl3"
fi

# 1) telas: "nome|tela|opções"
IMAGENS=(
	"vila|vila|--camera=0 --espera=1.5"
	"corrida|corrida|--corrida_pergunta --espera=0.3"
	"chefao|vila|--chefao=cc --espera=2.2"
	"batalha|batalha|--batalha=0,cc --espera=1.2"
	"cozinha|cozinha|--confeitaria --movimento --espera=1.0"
	"quiz|partida|--espera=1.0"
)
for item in "${IMAGENS[@]}"; do
	IFS='|' read -r nome tela opcoes <<< "$item"
	# shellcheck disable=SC2086
	RES=1280x720 ferramentas/capturar.sh "$tela" $opcoes > /dev/null
	ffmpeg -y -loglevel error -i "build/prints/$tela.png" -q:v 3 "$SAIDA/imagens/$nome.jpg"
	echo "imagem: $nome"
done
[ -n "$SO_IMAGENS" ] && exit 0

# 2) trailer
gravar() {  # nome, tela, opções da captura...
	# shellcheck disable=SC2086
	timeout 1800 xvfb-run -a -s "-screen 0 1280x720x24" godot --path godot $RENDER --resolution 1280x720 \
		--write-movie "$(pwd)/$SAIDA/$1.avi" --fixed-fps 30 \
		-- --capturar="$2" --saida="$(pwd)/$SAIDA/nada.png" "${@:3}" > "$SAIDA/$1.log" 2>&1
	echo "vídeo: $1"
}
gravar abertura vila --trailer
gravar corrida corrida --trailer_corrida=24
ffmpeg -y -loglevel error -i "$SAIDA/abertura.avi" -i "$SAIDA/corrida.avi" \
	-filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" \
	-c:v libx264 -crf 27 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k -movflags +faststart \
	"$SAIDA/trailer.mp4"
ffmpeg -y -loglevel error -ss 3 -i "$SAIDA/trailer.mp4" -frames:v 1 -q:v 3 "$SAIDA/imagens/capa.jpg"
rm -f "$SAIDA"/*.avi "$SAIDA"/*.log "$SAIDA/nada.png"
ls -la "$SAIDA" "$SAIDA/imagens"
