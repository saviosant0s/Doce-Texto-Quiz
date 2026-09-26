// Contorno de desenho animado para as peças do cenário já juntadas num bloco
// só (ver JuntarMalhas): a direção de "inchar" de cada vértice vem gravada no
// lugar da normal (NORMAL), já no espaço do bloco.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, depth_draw_opaque;

uniform vec4 cor : source_color = vec4(0.23, 0.13, 0.37, 1.0);
uniform float espessura = 0.035;

void vertex() {
	VERTEX += NORMAL * espessura;
}

void fragment() {
	ALBEDO = cor.rgb;
}
