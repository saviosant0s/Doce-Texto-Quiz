#!/bin/bash
# Tira um print de uma tela do jogo (precisa de xvfb-run no Linux sem tela).
# Uso: ferramentas/capturar.sh <tela> [opções]   -> build/prints/<tela>.png
# Telas: nomes em Telas.CENAS (godot/scripts/telas.gd).
# Opções (--acertos, --nivel, --liberar, --moedas, --historico, --revisao,
# --aba, --espera): veja godot/scripts/ferramentas/captura.gd
cd "$(dirname "$0")/.."
mkdir -p build/prints
timeout 60 xvfb-run -a -s "-screen 0 ${RES:-1280x720}x24" godot --path godot --rendering-driver opengl3 \
	--resolution ${RES:-1280x720} -- --capturar="$1" --saida="$(pwd)/build/prints/$(basename "$1" .tscn).png" "${@:2}" 2>&1 \
	| grep -E "SCRIPT ERROR|Parse Error" || true
echo "build/prints/$(basename "$1" .tscn).png"
