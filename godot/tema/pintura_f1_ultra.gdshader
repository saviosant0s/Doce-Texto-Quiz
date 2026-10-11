// Pintura do F1 na qualidade ULTRA (assets/carros/carro_f1_ultra.glb): as cores e
// faixas da equipe (pintura_f1.gdshaderinc) com verniz por cima (o reflexo do céu
// de um carro de verdade), os adesivos dos patrocinadores inventados (a folha
// assets/carros/f1_adesivos.png, feita por ferramentas/blender/carro_f1.py) e a
// parte de baixo um pouco mais escura (a sombra de contato que o renderizador do
// celular não calcula).
shader_type spatial;

#include "res://tema/pintura_f1.gdshaderinc"

uniform sampler2D adesivos : source_color, filter_linear_mipmap, repeat_disable;
uniform float metalico = 0.4;
uniform float aspereza = 0.38;
uniform float verniz = 1.0;
uniform float verniz_aspereza = 0.07;

varying vec3 p;
varying vec3 n;

// Partes da folha de adesivos: (x, y, largura, altura), de 0 a 1.
const vec4 DOCE_TEXTO = vec4(0.0, 0.0, 1.0, 0.5);
const vec4 QUIZ = vec4(0.0, 0.5, 0.5, 0.5);
const vec4 NUMERO = vec4(0.5, 0.5, 0.25, 0.5);

void vertex() {
	p = VERTEX;
	n = NORMAL;
}

// Adesivo na lateral (visto de fora, as letras se leem normal dos dois lados):
// ocupa de z0 a z1 (de frente para trás) e de y0 a y1 (de baixo para cima).
vec4 adesivo_lado(vec3 q, float z0, float z1, float y0, float y1, vec4 parte) {
	float u = q.x > 0.0 ? (z1 - q.z) / (z1 - z0) : (q.z - z0) / (z1 - z0);
	vec2 uv = vec2(u, (y1 - q.y) / (y1 - y0));
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	return texture(adesivos, parte.xy + uv * parte.zw);
}

// Adesivo em cima (lido de frente): de x -meia a meia e de z0 a z1 (o alto das
// letras fica para trás).
vec4 adesivo_cima(vec3 q, float meia, float z0, float z1, vec4 parte) {
	vec2 uv = vec2((meia - q.x) / (2.0 * meia), (z1 - q.z) / (z1 - z0));
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	return texture(adesivos, parte.xy + uv * parte.zw);
}

void fragment() {
	vec3 cor = cor_da_pintura(p, n);
	float ax = abs(p.x);
	float de_lado = smoothstep(0.4, 0.6, abs(n.x));
	vec4 a = vec4(0.0);
	if (ax > 0.14 && ax < 0.26) {  // lateral do corpo, acima do sidepod
		a = adesivo_lado(p, 0.10, 0.62, 0.33, 0.455, DOCE_TEXTO) * de_lado;
	} else if (ax > 0.45 && p.z < 0.2) {  // lateral do sidepod, acima da faixa
		a = adesivo_lado(p, -0.25, 0.05, 0.205, 0.325, QUIZ) * de_lado;
	} else if (ax > 0.355 && p.z > 1.6) {  // placas da asa traseira, por fora
		a = adesivo_lado(p, 1.70, 1.90, 0.36, 0.46, QUIZ) * de_lado;
	} else if (ax < 0.06 && p.z < -1.1) {  // número em cima do bico
		a = adesivo_cima(p, 0.05, -1.36, -1.20, NUMERO) * smoothstep(0.5, 0.7, n.y);
	}
	cor = mix(cor, a.rgb, a.a);
	ALBEDO = cor;
	METALLIC = metalico;
	ROUGHNESS = aspereza;
	CLEARCOAT = verniz;
	CLEARCOAT_ROUGHNESS = verniz_aspereza;
	// parte de baixo mais escura (sombra de contato do chão e do assoalho)
	AO = mix(0.55, 1.0, smoothstep(0.04, 0.22, p.y));
	AO_LIGHT_AFFECT = 0.4;
}
