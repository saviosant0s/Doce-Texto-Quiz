#!/bin/bash
# Monta o pacote de entrega (para a professora / INPI) em build/entrega/:
#   Doce_Texto_Quiz_v<versão>.zip   executáveis + código-fonte (com o hash)
#   Doce_Texto_Quiz_Memorial_Descritivo_v<versão>.pdf   (fora do zip)
#
# Uso: KEYSTORE=... KEYSTORE_SENHA=... ferramentas/gerar_entrega.sh
# (NODE e PLAYWRIGHT como em gerar_memorial_pdf.sh, para o PDF)
set -e
cd "$(dirname "$0")/.."
VERSAO=$(sed -n 's/^config\/version="\(.*\)"/\1/p' godot/project.godot)
NOME="Doce Texto Quiz v$VERSAO"
SAIDA=build/entrega
PASTA="$SAIDA/$NOME"
rm -rf "$SAIDA" && mkdir -p "$PASTA/1 - Executaveis/Windows" "$PASTA/1 - Executaveis/Android" "$PASTA/2 - Codigo-fonte"

echo "Executável do Windows..."
ferramentas/gerar_exe.sh > build/export_exe.log 2>&1
cp build/windows/DoceTextoQuiz.exe "$PASTA/1 - Executaveis/Windows/"

echo "APK do Android (64 bits)..."
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${KEYSTORE_ALIAS:-docetexto}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$KEYSTORE_SENHA"
ferramentas/godot_exportar.sh --export-release "Android 64 bits" "../$SAIDA/DoceTextoQuiz.apk" > build/export_apk64.log 2>&1
mv "$SAIDA/DoceTextoQuiz.apk" "$PASTA/1 - Executaveis/Android/"
rm -f "$SAIDA"/*.idsig

echo "Código-fonte e hash..."
HASH=$(ferramentas/hash_inpi.sh | sed -n 's/^SHA-512: //p')
cp "build/inpi/doce_texto_quiz_codigo_fonte_v$VERSAO.zip" "$PASTA/2 - Codigo-fonte/"
printf 'Arquivo: doce_texto_quiz_codigo_fonte_v%s.zip\r\nAlgoritmo: SHA-512\r\nHash: %s\r\n' "$VERSAO" "$HASH" \
	> "$PASTA/2 - Codigo-fonte/HASH_SHA-512.txt"

echo "Memorial descritivo (PDF)..."
ferramentas/gerar_memorial_pdf.sh > /dev/null
cp docs/inpi/memorial_descritivo.pdf "$SAIDA/Doce_Texto_Quiz_Memorial_Descritivo_v$VERSAO.pdf"

# LEIA-ME com quebras de linha do Windows (abre certinho no Bloco de Notas)
sed "s/{VERSAO}/$VERSAO/g; s/{HASH}/$HASH/g" docs/inpi/LEIA-ME_entrega.txt | sed 's/$/\r/' > "$PASTA/LEIA-ME.txt"

( cd "$SAIDA" && zip -9 -q -r "Doce_Texto_Quiz_v$VERSAO.zip" "$NOME" )
rm -rf "$PASTA"
ls -la "$SAIDA"
