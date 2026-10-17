// Cores e faixas da pintura do F1 (usado por pintura_f1.gdshader e, no ULTRA,
// pintura_f1_ultra.gdshader): a cor da equipe com as faixas desenhadas pela
// posição no carro (não precisa de textura): ponta do bico, faixa que sobe do
// sidepod até a cobertura do motor com um filete, e as pontas das placas das
// asas. Um carro só serve para todas as equipes, trocando as três cores.
// Posição no modelo: x para a direita, y para cima, z para trás (a frente é -z).

uniform vec3 cor_base : source_color = vec3(0.106, 0.149, 0.314);
uniform vec3 cor_destaque : source_color = vec3(0.835, 0.106, 0.18);
uniform vec3 cor_detalhe : source_color = vec3(1.0, 0.78, 0.15);

// 1 dentro da faixa de meia largura `meia` em volta de `centro` (borda suave)
float faixa(float valor, float centro, float meia) {
	float borda = fwidth(valor) * 1.5;
	return 1.0 - smoothstep(meia - borda, meia + borda, abs(valor - centro));
}

// p: posição no modelo; n: normal no modelo
vec3 cor_da_pintura(vec3 p, vec3 n) {
	vec3 cor = cor_base;
	float ax = abs(p.x);
	// bico: ponta na terceira cor e um anel na segunda logo atrás
	float bico = step(ax, 0.1) * step(0.095, p.y);
	cor = mix(cor, cor_detalhe, bico * step(p.z, -1.52));
	cor = mix(cor, cor_destaque, bico * faixa(p.z, -1.495, 0.022));
	// faixa que sobe do sidepod até o fim da cobertura do motor, com um filete em cima
	// (só nas laterais: em cima do sidepod, quase deitado, a faixa ficaria larga demais)
	float lado = smoothstep(0.1, 0.13, ax) * step(-0.36, p.z) * step(p.z, 1.55) * smoothstep(0.45, 0.65, abs(n.x));
	float centro = 0.15 + 0.17 * smoothstep(-0.35, 1.3, p.z);
	cor = mix(cor, cor_destaque, lado * faixa(p.y, centro, 0.03));
	cor = mix(cor, cor_detalhe, lado * faixa(p.y, centro + 0.05, 0.009));
	// pontas das placas das asas
	cor = mix(cor, cor_destaque, step(0.335, ax) * step(1.6, p.z) * step(0.575, p.y));
	cor = mix(cor, cor_destaque, step(0.59, ax) * step(p.z, -1.3));
	return cor;
}
