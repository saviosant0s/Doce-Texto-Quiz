// Céu realista da Vila dos Doces (e da corrida): degradê do horizonte ao
// topo com a faixa clara do ar ao longe, o SOL (disco com halo, mais largo e
// dourado no pôr do sol; o brilho/glow espalha), nuvens de ruído iluminadas
// pelo lado do sol (borda dourada no fim da tarde, base mais escura dando
// volume), a faixa laranja no horizonte com o sol baixo e o chão rosado
// abaixo do horizonte. As cores mudam com a hora
// (CeuVila.atualizar). Sem TIME de propósito: o reflexo do céu (luz ambiente)
// só é refeito quando a hora muda; com TIME seria refeito a cada quadro.
shader_type sky;
render_mode use_debanding;

uniform vec3 cor_topo : source_color = vec3(0.62, 0.83, 0.97);
uniform vec3 cor_horizonte : source_color = vec3(1.0, 0.84, 0.92);
uniform vec3 cor_chao : source_color = vec3(0.79, 0.70, 0.93);
uniform vec3 cor_sol : source_color = vec3(1.0, 0.94, 0.84);
uniform float noite = 0.0;
uniform float cobertura = 0.5;   // 0 = céu limpo, 1 = nublado
uniform float cinza = 0.0;       // nuvens de chuva
uniform vec2 deslocamento = vec2(0.0);
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	float acima = clamp(h, 0.0, 1.0);
	vec3 ceu = mix(cor_horizonte, cor_topo, pow(acima, 0.55));
	// faixa clara logo acima do horizonte (o ar ao longe)
	ceu = mix(ceu, cor_horizonte * 1.06, exp(-acima * 12.0) * 0.45);
	ceu = mix(ceu, cor_chao, smoothstep(0.0, -0.25, h));
	float cs = dot(d, LIGHT0_DIRECTION);
	float dia = 1.0 - noite * noite;  // (no começo do anoitecer o sol ainda brilha)
	// sol baixo (manhã e fim de tarde): halo largo e dourado e a faixa laranja
	// no horizonte, mais forte do lado do sol
	float baixo = 1.0 - clamp(LIGHT0_DIRECTION.y * 2.5, 0.0, 1.0);
	float lado_sol = max(dot(normalize(d.xz + vec2(1e-4)), normalize(LIGHT0_DIRECTION.xz + vec2(1e-4))), 0.0);
	float faixa = exp(-max(h, 0.0) * 6.0) * (0.3 + 0.7 * lado_sol * lado_sol) * pow(baixo, 1.5);
	ceu = mix(ceu, vec3(1.0, 0.6, 0.34), faixa * 0.75 * dia * (1.0 - cinza));
	float halo = pow(max(cs, 0.0), mix(30.0, 5.0, baixo)) * (0.25 + 0.75 * baixo);
	ceu += mix(cor_sol, vec3(1.0, 0.62, 0.3), baixo * 0.5) * halo * 0.7 * dia * (1.0 - cinza);
	float disco = smoothstep(0.99955, 0.99975, cs) * dia;
	vec3 resultado = ceu;
	if (h > -0.02) {
		vec2 uv = d.xz / (h + 0.12) * 0.2 + deslocamento;
		float n = texture(ruido, uv).r * 0.62 + texture(ruido, uv * 2.6 + vec2(0.31, 0.17)).r * 0.38;
		float c = smoothstep(1.0 - cobertura, 1.0 - cobertura + 0.3, n) * smoothstep(0.0, 0.2, h);
		float lado = max(cs, 0.0);
		vec3 nuvem = mix(cor_horizonte, vec3(1.0), 0.6) * (0.8 + 0.3 * lado);
		nuvem += cor_sol * pow(lado, 4.0) * 0.9 * baixo * dia;
		// base mais escura (volume) e nuvem de chuva cinza
		nuvem *= mix(0.78, 1.04, smoothstep(0.5, 0.95, n));
		nuvem = mix(nuvem, vec3(0.62, 0.64, 0.7) * (0.75 + 0.25 * n), cinza);
		nuvem = mix(nuvem, cor_topo * 0.55 + vec3(0.02, 0.02, 0.05), noite * 0.85);
		resultado = mix(ceu, nuvem, c * 0.92);
		disco *= 1.0 - c;
	}
	if (!AT_CUBEMAP_PASS) {
		resultado += cor_sol * disco * 6.0 * (1.0 - cinza);
	}
	COLOR = resultado;
}
