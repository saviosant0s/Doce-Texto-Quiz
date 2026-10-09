#!/bin/bash
# Roda o Godot para exportar (APK, executável). Com Vulkan disponível (placa de
# vídeo ou o pacote mesa-vulkan-drivers, Vulkan por software), exporta com o
# renderizador Mobile ligado: assim o "Shader Baker" compila os shaders antes
# (no export) e o jogo abre e anda sem engasgos na primeira vez. Sem Vulkan,
# exporta do jeito comum (--headless), sem os shaders prontos.
# Uso (da raiz do repositório): ferramentas/godot_exportar.sh --export-release "Windows" ../build/...
cd "$(dirname "$0")/.."
if ls /usr/share/vulkan/icd.d/*.json >/dev/null 2>&1 && command -v xvfb-run >/dev/null; then
	exec xvfb-run -a -s "-screen 0 1280x720x24" godot --path godot --rendering-method mobile --rendering-driver vulkan "$@"
else
	echo "Aviso: sem Vulkan; exportando sem os shaders pré-compilados." >&2
	exec godot --headless --path godot "$@"
fi
