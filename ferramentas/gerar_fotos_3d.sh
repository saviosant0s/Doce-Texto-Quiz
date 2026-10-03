#!/bin/bash
# Gera as fotos PNG dos doces 3D (ver godot/scripts/ferramentas/fotos_3d.gd).
# Precisa de uma tela (no Linux sem tela, usa xvfb-run).
cd "$(dirname "$0")/.."
timeout 300 xvfb-run -a -s "-screen 0 1280x720x24" godot --path godot --rendering-method gl_compatibility --rendering-driver opengl3 \
	res://scripts/ferramentas/fotos_3d.tscn 2>&1 | grep -E "foto:|ERROR" || true
godot --headless --path godot --import >/dev/null 2>&1
