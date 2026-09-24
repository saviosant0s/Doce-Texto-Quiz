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
