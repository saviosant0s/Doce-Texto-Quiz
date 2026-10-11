#!/bin/bash
# Gera o carro de Fórmula 1 da Corrida de Doces no Blender (modelo original,
# feito por ferramentas/blender/carro_f1.py) em godot/assets/carros/carro_f1.glb.
# Uso: [BLENDER=/caminho/do/blender] ferramentas/gerar_carro_f1.sh [--previa build/prints/f1_previa]
# Precisa do Blender 4.2 ou mais novo (testado no 4.5 LTS) e do Pillow no Python do sistema.
set -e
cd "$(dirname "$0")/.."
"${BLENDER:-blender}" -b -P ferramentas/blender/carro_f1.py -- --saida "$(pwd)/godot/assets/carros/carro_f1.glb" "$@" 2>&1 \
	| grep -E "CARRO_F1|Error|Traceback|Saved" || true
