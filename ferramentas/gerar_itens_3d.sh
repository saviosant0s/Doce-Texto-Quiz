#!/bin/bash
# Gera as fotos PNG dos itens 3D (moeda, açúcar, XP e baús) em
# godot/assets/itens/ (ver godot/scripts/itens_3d.gd). Precisa de xvfb-run.
cd "$(dirname "$0")/.."
timeout 300 xvfb-run -a -s "-screen 0 1280x720x24" godot --path godot --rendering-method gl_compatibility --rendering-driver opengl3 \
	res://scripts/ferramentas/fotos_3d.tscn -- --itens 2>&1 | grep -E "foto:|ERROR" || true
godot --headless --path godot --import >/dev/null 2>&1
# recorta cada foto justa no objeto (quadrada, com uma margem pequena), para
# os itens ficarem grandes e nítidos mesmo como ícone pequeno
python3 - <<'PY'
from PIL import Image
import glob
for arq in glob.glob("godot/assets/itens/*.png"):
    img = Image.open(arq).convert("RGBA")
    caixa = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if not caixa:
        continue
    l, t, r, b = caixa
    lado = max(r - l, b - t) + 16
    cx, cy = (l + r) // 2, (t + b) // 2
    quadrado = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    quadrado.paste(img.crop((cx - lado // 2, cy - lado // 2, cx - lado // 2 + lado, cy - lado // 2 + lado)), (0, 0))
    quadrado.save(arq)
PY
godot --headless --path godot --import >/dev/null 2>&1
