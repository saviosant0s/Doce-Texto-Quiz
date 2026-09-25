// Contorno de desenho animado para as peças do cenário já juntadas num bloco
// só (ver JuntarMalhas): a direção de "inchar" de cada vértice vem gravada na
// cor do vértice (COLOR.rgb, de 0..1 para -1..1), já no espaço do bloco.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, depth_draw_opaque;

uniform vec4 cor : source_color = vec4(0.23, 0.13, 0.37, 1.0);
uniform float espessura = 0.035;

void vertex() {
	VERTEX += (COLOR.rgb * 2.0 - 1.0) * espessura;
}

void fragment() {
	ALBEDO = cor.rgb;
}
