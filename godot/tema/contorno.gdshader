// Contorno de desenho animado (Vila dos Doces): desenha a peça de novo, um
// pouco maior e só por dentro (cull_front), numa cor escura. Vai no
// material_overlay de cada peça grande. A espessura é em metros no mundo
// (desfaz a escala do nó). `forma` escolhe para onde "inchar":
// 0 = normais (esferas, cápsulas, roscas), 1 = caixa, 2 = cilindro/cone,
// 3 = a partir do centro (prismas).
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, depth_draw_opaque;

uniform vec4 cor : source_color = vec4(0.23, 0.13, 0.37, 1.0);
uniform float espessura = 0.035;
uniform int forma = 0;

void vertex() {
	vec3 escala = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 direcao = NORMAL;
	if (forma == 1) {
		direcao = sign(VERTEX);
	} else if (forma == 2) {
		vec2 lado = length(VERTEX.xz) > 0.001 ? normalize(VERTEX.xz) : vec2(0.0);
		direcao = vec3(lado.x, sign(VERTEX.y), lado.y);
	} else if (forma == 3) {
		direcao = length(VERTEX) > 0.001 ? normalize(VERTEX) : vec3(0.0);
	}
	VERTEX += direcao * espessura / max(escala, vec3(0.001));
}

void fragment() {
	ALBEDO = cor.rgb;
}
