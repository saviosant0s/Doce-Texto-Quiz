// Pintura do carro de Fórmula 1 (assets/carros/carro_f1.glb, ver Kart3D): as
// cores da equipe com as faixas (pintura_f1.gdshaderinc), acabamento acetinado.
// No ULTRA é a pintura_f1_ultra.gdshader (verniz e adesivos).
shader_type spatial;

#include "res://tema/pintura_f1.gdshaderinc"

uniform float metalico = 0.35;
uniform float aspereza = 0.45;

varying vec3 p;
varying vec3 n;

void vertex() {
	p = VERTEX;
	n = NORMAL;
}

void fragment() {
	ALBEDO = cor_da_pintura(p, n);
	METALLIC = metalico;
	ROUGHNESS = aspereza;
}
