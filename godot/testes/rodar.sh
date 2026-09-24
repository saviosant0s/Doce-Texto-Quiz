#!/bin/bash
# Roda os testes automáticos do jogo. Uso (na pasta do repositório):
#     godot/testes/rodar.sh            (usa o comando "godot" do sistema)
#     GODOT=/caminho/godot godot/testes/rodar.sh
# Falha se algum teste falhar OU se aparecer qualquer erro de script no log.
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:-godot}"
LOG="$(mktemp)"
"$GODOT" --headless --path . --import >/dev/null 2>&1
timeout 300 "$GODOT" --headless --path . --scene res://testes/testes.tscn 2>&1 | tee "$LOG" \
	| grep -E "^- |FALHOU|PASSARAM|FALHARAM|SCRIPT ERROR|ERROR: " | grep -v "resources still in use"
STATUS=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
	echo "ERRO DE SCRIPT durante os testes (veja acima)."
	STATUS=1
fi
rm -f "$LOG"
exit $STATUS
