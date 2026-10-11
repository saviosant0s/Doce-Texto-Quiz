#!/bin/bash
# Gera o carro de Fórmula 1 da Corrida de Doces no Blender (modelo original,
# feito por ferramentas/blender/carro_f1.py): godot/assets/carros/carro_f1.glb
# (qualidades até ALTA) e carro_f1_ultra.glb (ULTRA, mais detalhado), mais a
# folha de adesivos do ULTRA (f1_adesivos.png).
# Uso: [BLENDER=/caminho/do/blender] ferramentas/gerar_carro_f1.sh [--previa build/prints/f1_previa]
#      (a prévia é do carro do ULTRA: três fotos no Cycles)
# Precisa do Blender 4.2 ou mais novo (testado no 4.5 LTS) e do Pillow no Python do sistema.
set -e
cd "$(dirname "$0")/.."
for detalhe in normal ultra; do
	nome=$([ "$detalhe" = ultra ] && echo carro_f1_ultra || echo carro_f1)
	extra=$([ "$detalhe" = ultra ] && echo "$@" || true)
	"${BLENDER:-blender}" -b -P ferramentas/blender/carro_f1.py -- --detalhe "$detalhe" \
		--saida "$(pwd)/godot/assets/carros/$nome.glb" $extra 2>&1 | grep -E "CARRO_F1|Error|Traceback|Saved" || true
done
