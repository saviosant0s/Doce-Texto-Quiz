// Silhueta de cor única (personagens ainda bloqueados): usa só o contorno
// (transparência) da imagem, sem deixar aparecer as cores dela.
shader_type canvas_item;

uniform vec4 cor : source_color = vec4(0.29, 0.19, 0.47, 0.9);

void fragment() {
	COLOR = vec4(cor.rgb, texture(TEXTURE, UV).a * cor.a);
}
