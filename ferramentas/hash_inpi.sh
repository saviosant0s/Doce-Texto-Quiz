#!/bin/bash
# Gera o pacote do código-fonte do jogo e o seu resumo digital (hash SHA-512),
# exigido no pedido de registro de programa de computador no INPI.
#
# O pacote (build/inpi/*.zip) deve ser GUARDADO sem nenhuma alteração: é ele
# que comprova a autoria. Qualquer mudança no código gera outro hash; gere de
# novo na hora de enviar o pedido.
set -e
cd "$(dirname "$0")/.."
VERSAO=$(sed -n 's/^config\/version="\(.*\)"/\1/p' godot/project.godot)
SAIDA="build/inpi"
PACOTE="$SAIDA/doce_texto_quiz_codigo_fonte_v$VERSAO.zip"
mkdir -p "$SAIDA"
rm -f "$PACOTE"
# Só o código e os dados do jogo (sem arquivos gerados pelo editor), em ordem
# fixa e com datas fixas, para o mesmo código sempre dar o mesmo hash.
( cd godot && find . -type f \( -name '*.gd' -o -name '*.tscn' -o -name '*.tres' -o -name '*.json' \
	-o -name '*.gdshader' -o -name 'project.godot' -o -name '*.cfg' \) \
	-not -path './.godot/*' -not -name 'build.json' | LC_ALL=C sort > /tmp/lista_inpi.txt )
TEMP=$(mktemp -d)
( cd godot && xargs -a /tmp/lista_inpi.txt -d "\n" cp --parents -t "$TEMP" )
( cd "$TEMP" && xargs -a /tmp/lista_inpi.txt -d '\n' touch -d '2023-11-17 12:00:00 UTC' \
	&& TZ=UTC zip -X -q -D "$OLDPWD/$PACOTE" -@ < /tmp/lista_inpi.txt )
rm -rf "$TEMP"
echo "Versão: $VERSAO"
echo "Arquivos: $(wc -l < /tmp/lista_inpi.txt)"
echo "Pacote: $PACOTE"
echo "SHA-512: $(sha512sum "$PACOTE" | cut -d' ' -f1)"
