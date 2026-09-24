#!/bin/bash
# Gera o executável para Windows em build/windows/DoceTextoQuiz.exe (um arquivo
# só, com o jogo dentro). Precisa dos modelos de exportação do Godot para
# Windows (Editor > Gerenciar modelos de exportação).
set -e
cd "$(dirname "$0")/.."
mkdir -p build/windows
godot --headless --path godot --export-release "Windows" ../build/windows/DoceTextoQuiz.exe
echo "Executável: build/windows/DoceTextoQuiz.exe"
