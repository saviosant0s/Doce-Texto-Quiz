// Grama com volume da Vila dos Doces: folhinhas (MultiMesh) que balançam com
// o vento. A base é mais escura e a ponta mais clara; a cor de cada tufo vem
// da cor da instância (COLOR). As normais apontam para cima, para a grama
// toda receber a luz por igual, como num desenho.
shader_type spatial;
render_mode cull_disabled, specular_disabled, shadows_disabled;  // folhas finas: com sombra ficavam manchadas

uniform vec4 cor_base : source_color = vec4(0.30, 0.52, 0.27, 1.0);  // perto do chão (APK)
uniform vec4 cor_ponta : source_color = vec4(0.40, 0.60, 0.33, 1.0);
uniform float vento = 0.14;

varying float altura;

void vertex() {
	altura = UV.y;
	vec3 mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float onda = sin(TIME * 1.8 + mundo.x * 0.5 + mundo.z * 0.35) + 0.5 * sin(TIME * 3.1 + mundo.x * 1.2 - mundo.z * 0.8);
	float curva = altura * altura;
	VERTEX.x += onda * vento * curva;
	VERTEX.z += onda * vento * 0.6 * curva;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	// as duas faces da folha recebem a luz como se olhassem para cima (o verso
	// ficava escuro no modo de compatibilidade)
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = mix(cor_base.rgb, cor_ponta.rgb, altura) * COLOR.rgb;
}
