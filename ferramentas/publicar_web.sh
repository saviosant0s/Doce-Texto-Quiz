#!/bin/bash
# Exporta a versão web e publica na branch gh-pages (GitHub Pages).
# Se KEYSTORE e KEYSTORE_SENHA estiverem definidos, gera também o APK e o
# publica em apk/doce-texto-quiz.apk (ver ferramentas/gerar_apk.sh). Gera e
# publica também o executável do Windows em windows/DoceTextoQuiz.zip.
#
# Uso: ferramentas/publicar_web.sh
# Precisa de: Godot 4.7 com os modelos de exportação, git com acesso de push.
set -e
cd "$(dirname "$0")/.."
RAIZ=$(pwd)
REV=$(git rev-parse --short HEAD)
DATA=$(TZ=America/Bahia date +"%d/%m %H:%M")
rm -rf build/web && mkdir -p build/web
godot --headless --path godot --export-release "Web" ../build/web/index.html > build/export_web.log 2>&1
test -f build/web/index.pck
if [ -n "$KEYSTORE" ]; then
	ferramentas/gerar_apk.sh > build/export_apk.log 2>&1
fi
# Executável para Windows (se os modelos de exportação do Windows estiverem instalados)
if ferramentas/gerar_exe.sh > build/export_exe.log 2>&1; then
	( cd build/windows && rm -f DoceTextoQuiz.zip && zip -9 -q DoceTextoQuiz.zip DoceTextoQuiz.exe )
fi
# O GitHub Pages guarda arquivos em cache por 10 min: o "?v=" força baixar o jogo novo
sed -i "s/\"fileSizes\":{\"index.pck\"/\"mainPack\":\"index.pck?v=$REV\",\"fileSizes\":{\"index.pck?v=$REV\"/" build/web/index.html
grep -q "index.pck?v=$REV" build/web/index.html
# Service worker de limpeza: remove o cache do modo PWA das versões antigas
cat > build/web/index.service.worker.js <<'JS'
// Remove o cache deixado pelas versões antigas (modo PWA) e se desinstala.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
	event.waitUntil((async () => {
		const chaves = await caches.keys();
		await Promise.all(chaves.map((chave) => caches.delete(chave)));
		await self.registration.unregister();
		const janelas = await self.clients.matchAll({ type: 'window' });
		janelas.forEach((janela) => janela.navigate(janela.url));
	})());
});
JS
# Cópia de trabalho da branch gh-pages em build/gh-pages
if [ ! -d build/gh-pages/.git ]; then
	git clone -q --branch gh-pages --single-branch "$(git remote get-url origin)" build/gh-pages
fi
cd build/gh-pages
git pull -q origin gh-pages
find . -mindepth 1 -maxdepth 1 ! -name .git ! -name apk ! -name windows -exec rm -rf {} +
cp -r "$RAIZ/build/web/." . && touch .nojekyll
if [ -n "$KEYSTORE" ]; then
	mkdir -p apk && cp "$RAIZ/build/android/doce-texto-quiz.apk" apk/
fi
if [ -f "$RAIZ/build/windows/DoceTextoQuiz.zip" ]; then
	mkdir -p windows && cp "$RAIZ/build/windows/DoceTextoQuiz.zip" windows/
fi
git add -A
git commit -q -m "Atualiza versão web ($REV)"
git push -q origin gh-pages
echo "publicado $REV ($DATA)"
