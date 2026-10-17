// Chocolate grudado no doce que entrou na fonte da praça (DoceAndante.sujar):
// desenhado por cima das peças (material_overlay). Cobre até a altura em que
// o doce ficou mergulhado, com pingos escorrendo e respingos mais para cima.
// A conta é feita no espaço do "Modelo" (para_modelo): a mancha anda junto com
// o doce quando ele vira ou pula.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform mat4 para_modelo = mat4(1.0);
uniform float quanto : hint_range(0.0, 1.0) = 1.0; // 1 = acabou de sair da fonte
uniform float nivel = -0.3; // altura do chocolate no Modelo (os pés ficam em ~-1,2)
uniform vec4 cor : source_color = vec4(0.29, 0.14, 0.07, 1.0);

varying vec3 local;

void vertex() {
	local = (para_modelo * MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float sorteio(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

float ruido(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = i.x + i.y * 57.0 + i.z * 113.0;
	return mix(mix(mix(sorteio(n), sorteio(n + 1.0), f.x), mix(sorteio(n + 57.0), sorteio(n + 58.0), f.x), f.y),
		mix(mix(sorteio(n + 113.0), sorteio(n + 114.0), f.x), mix(sorteio(n + 170.0), sorteio(n + 171.0), f.x), f.y), f.z);
}

void fragment() {
	// a linha do chocolate desce um pouco enquanto seca
	float linha = nivel - (1.0 - quanto) * 0.45 + (ruido(local * 6.0) - 0.5) * 0.08;
	// o chocolate cobre de baixo até a linha; acima dela, respingos que
	// bateram mais alto escorreram até a linha (faixas de ponta redonda)
	float u = (atan(local.z, local.x) + PI) / TAU * 20.0;
	float faixa = 1.0 - abs(fract(u) - 0.5) * 2.0;
	float pingo = sorteio(floor(u) + 3.0) * 0.32 * sqrt(clamp((faixa - 0.45) / 0.55, 0.0, 1.0));
	float coberto = step(local.y, linha + pingo);
	// respingos soltos mais para cima
	float mancha = step(0.74, ruido(local * 4.2 + vec3(7.0))) * step(local.y, linha + 0.9);
	float a = clamp(coberto + mancha, 0.0, 1.0) * smoothstep(0.0, 0.2, quanto);
	if (a < 0.01) {
		discard;
	}
	ALBEDO = cor.rgb * (0.85 + ruido(local * 18.0) * 0.3);
	ROUGHNESS = 0.18;
	SPECULAR = 0.6;
	ALPHA = a * 0.97;
}
