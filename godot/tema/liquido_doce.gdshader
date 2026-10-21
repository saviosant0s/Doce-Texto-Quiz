// Líquidos da vila (lago de morango, lago e fonte de chocolate, rio de calda):
// o céu refletido (o reflexo de cada ponto pega a cor do céu na direção em
// que a luz bate e volta, e as ondinhas entortam o reflexo), mais reflexo
// olhando rente (Fresnel), ondinhas que andam, o brilho do sol (luz
// especular) e o meio do lago mais escuro que a beira.
shader_type spatial;

uniform vec3 cor_rasa : source_color = vec3(1.0, 0.7, 0.81);
uniform vec3 cor_funda : source_color = vec3(1.0, 0.44, 0.64);
uniform vec3 cor_ceu : source_color = vec3(1.0, 0.84, 0.92);      // horizonte (CeuVila)
uniform vec3 cor_ceu_topo : source_color = vec3(0.62, 0.83, 0.97); // alto do céu (CeuVila)
uniform float reflexo = 0.6;
uniform float aspereza : hint_range(0.0, 1.0) = 0.06;
uniform float velocidade = 0.03;
uniform vec2 direcao = vec2(1.0, 0.6);
uniform float escala = 0.045;
uniform float forca_onda = 0.22;
uniform vec2 centro = vec2(0.0);
uniform vec2 raios = vec2(0.0);  // 0 = sem meio fundo (rio)
uniform sampler2D ondas : hint_normal, filter_linear_mipmap, repeat_enable;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = mundo.xz * escala;
	vec2 anda = direcao * TIME * velocidade;
	vec3 n1 = texture(ondas, uv + anda).rgb * 2.0 - 1.0;
	vec3 n2 = texture(ondas, uv * 2.1 - anda * 1.4 + vec2(0.37, 0.11)).rgb * 2.0 - 1.0;
	// de longe a superfície vira espelho (as ondinhas somem, como na água de verdade)
	float longe = distance(mundo, CAMERA_POSITION_WORLD);
	vec2 inclina = (n1.xy + n2.xy * 0.35) * forca_onda * (1.0 - smoothstep(6.0, 45.0, longe) * 0.85);
	NORMAL_MAP = normalize(vec3(inclina, 1.0)) * 0.5 + 0.5;
	// normal do mundo (a superfície é deitada) e o céu refletido
	vec3 normal_mundo = normalize(vec3(inclina.x, 1.0, inclina.y));
	vec3 olhar = normalize(mundo - CAMERA_POSITION_WORLD);
	vec3 r = reflect(olhar, normal_mundo);
	vec3 ceu = mix(cor_ceu, cor_ceu_topo, pow(clamp(r.y, 0.0, 1.0), 0.6));
	float fresnel = 0.08 + 0.92 * pow(1.0 - clamp(dot(-olhar, normal_mundo), 0.0, 1.0), 5.0);
	float beira = 1.0;
	if (raios.x > 0.0) {
		beira = smoothstep(0.3, 1.0, length((mundo.xz - centro) / raios));
	}
	vec3 base = mix(cor_funda, cor_rasa, beira);
	// (até 60% de reflexo e puxado para a cor do líquido: de longe, olhando
	// rente, o lago continua rosa em vez de virar um espelho branco do céu)
	float f = clamp(fresnel * reflexo * 1.6, 0.0, 0.6);
	ALBEDO = base * (1.0 - f);
	EMISSION = mix(ceu, ceu * base * 1.3, 0.35) * f * 0.85;
	ROUGHNESS = aspereza;
	SPECULAR = 0.9;
	METALLIC = 0.0;
}
