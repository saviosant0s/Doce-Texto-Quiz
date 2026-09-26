#!/bin/bash
# Gera o executável para Windows em build/windows/DoceTextoQuiz.exe (um arquivo
# só, com o jogo dentro). Precisa dos modelos de exportação do Godot para
# Windows (Editor > Gerenciar modelos de exportação).
set -e
cd "$(dirname "$0")/.."
mkdir -p build/windows
ferramentas/godot_exportar.sh --export-release "Windows" ../build/windows/DoceTextoQuiz.exe
echo "Executável: build/windows/DoceTextoQuiz.exe"
