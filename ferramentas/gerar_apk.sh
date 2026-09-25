#!/bin/bash
# Gera os APKs Android assinados:
#   build/android/doce-texto-quiz.apk        celulares de hoje (64 bits)
#   build/android/doce-texto-quiz-32bits.apk celulares antigos/baratos (32 bits)
# Separados, cada um tem mais ou menos metade do tamanho (o GitHub recusa
# arquivos acima de 100 MB).
#
# Precisa de:
#   - Godot 4.7 com os modelos de exportação (Editor > Gerenciar modelos)
#   - Java (JDK 17 ou mais novo)
#   - Android SDK com build-tools (ou só o apksigner, ex.: apt install apksigner),
#     configurado no Godot em Editor > Configurações > Exportar > Android
#   - A keystore de assinatura. NUNCA coloque a keystore nem a senha no Git:
#     sem ela não dá para publicar atualizações do app na Play Store.
#
# Uso:
#   KEYSTORE=/caminho/doce_texto_quiz.keystore KEYSTORE_SENHA=... ferramentas/gerar_apk.sh
#   (sem KEYSTORE, gera um APK de teste assinado com a chave de depuração)
set -e
cd "$(dirname "$0")/.."
mkdir -p build/android
if [ -n "$KEYSTORE" ]; then
	export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
	export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${KEYSTORE_ALIAS:-docetexto}"
	export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$KEYSTORE_SENHA"
	MODO=--export-release
else
	echo "Sem KEYSTORE: gerando APK de teste (depuração)."
	MODO=--export-debug
fi
ferramentas/godot_exportar.sh $MODO "Android" ../build/android/doce-texto-quiz.apk
ferramentas/godot_exportar.sh $MODO "Android 32 bits" ../build/android/doce-texto-quiz-32bits.apk
echo "APKs gerados: build/android/doce-texto-quiz.apk e doce-texto-quiz-32bits.apk"
