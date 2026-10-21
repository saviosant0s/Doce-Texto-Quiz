class_name Texturas
## Materiais com texturas reais (fotos escaneadas, licença CC0, do Poly Haven;
## ver assets/texturas/reais/LEIA-ME.md): cor, relevo (normal map) e o mapa
## "arm" (sombreado dos cantos, aspereza e metal). Projetadas pelo mundo
## (triplanar), servem em qualquer forma e continuam certas depois de as peças
## serem juntadas (JuntarMalhas). `tinta` multiplica a cor da foto (ex.: o
## reboco branco vira lilás); `escala` = repetições por metro.

const PASTA := "res://assets/texturas/reais/"


## `metalico` (0 a 1): 1 = metal de verdade (ouro, inox, cobre); 0 = pintado.
static func real(nome: String, tinta := "#FFFFFF", escala := 0.5, metalico := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tinta)
	mat.albedo_texture = load(PASTA + nome + "_cor.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load(PASTA + nome + "_relevo.jpg")
	var arm: Texture2D = load(PASTA + nome + "_arm.jpg")
	mat.roughness = 1.0
	mat.metallic = metalico
	mat.metallic_specular = 0.5
	mat.roughness_texture = arm
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.ao_enabled = true
	mat.ao_texture = arm
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_triplanar_sharpness = 4.0
	mat.uv1_scale = Vector3.ONE * escala
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.set_meta("real", true)  # estilo_desenho não põe luz "em degraus" nela
	return mat
