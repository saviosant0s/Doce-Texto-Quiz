#!/bin/bash
# Gera o APK Android assinado em build/android/doce-texto-quiz.apk
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
echo "APK gerado: build/android/doce-texto-quiz.apk"
