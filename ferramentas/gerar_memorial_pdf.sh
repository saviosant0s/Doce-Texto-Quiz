#!/bin/bash
# Gera docs/inpi/memorial_descritivo.pdf a partir do HTML, atualizando antes o
# hash SHA-512 do código-fonte (ferramentas/hash_inpi.sh).
# Precisa do Node com Playwright (Chromium).
set -e
cd "$(dirname "$0")/.."
HASH=$(ferramentas/hash_inpi.sh | sed -n 's/^SHA-512: //p')
VERSAO=$(sed -n 's/^config\/version="\(.*\)"/\1/p' godot/project.godot)
HTML=docs/inpi/memorial_descritivo.html
sed -i -E "s#(<div class=\"hash\">)[0-9a-f]+(</div>)#\1$HASH\2#" "$HTML"
sed -i -E "s#doce_texto_quiz_codigo_fonte_v[0-9.]+\.zip#doce_texto_quiz_codigo_fonte_v$VERSAO.zip#" "$HTML"
NODE=${NODE:-node}
PLAYWRIGHT=${PLAYWRIGHT:-playwright}
"$NODE" -e "
const { chromium } = require('$PLAYWRIGHT');
(async () => {
  const navegador = await chromium.launch();
  const pagina = await navegador.newPage();
  await pagina.goto('file://' + require('path').resolve('$HTML'), { waitUntil: 'networkidle' });
  await pagina.pdf({ path: 'docs/inpi/memorial_descritivo.pdf', format: 'A4', printBackground: true, preferCSSPageSize: true });
  await navegador.close();
})();
"
echo "PDF: docs/inpi/memorial_descritivo.pdf (hash $HASH)"
