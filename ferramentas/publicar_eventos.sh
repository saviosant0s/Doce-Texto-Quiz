#!/bin/bash
# Publica só o calendário de eventos (eventos/eventos.json) no site do jogo,
# sem gerar o app de novo. Os jogadores recebem os eventos novos na próxima
# vez que abrirem o jogo (com internet). Formato: docs/eventos.md.
# Uso: ferramentas/publicar_eventos.sh
set -e
cd "$(dirname "$0")/.."
RAIZ="$(pwd)"
python3 -c "import json,sys; d=json.load(open('eventos/eventos.json')); assert isinstance(d.get('eventos'), list); print(len(d['eventos']), 'evento(s)')"
if [ ! -d build/gh-pages/.git ]; then
	git clone -q --branch gh-pages --single-branch "$(git remote get-url origin)" build/gh-pages
fi
cd build/gh-pages
git pull -q origin gh-pages
cp "$RAIZ/eventos/eventos.json" eventos.json
git add eventos.json
if git diff --cached --quiet; then
	echo "eventos.json já estava publicado"
	exit 0
fi
git commit -q -m "Calendário de eventos"
git push -q origin gh-pages
echo "publicado: https://saviosant0s.github.io/Doce-Texto-Quiz/eventos.json"
