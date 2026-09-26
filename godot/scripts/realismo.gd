class_name Realismo
## Acabamento realista dos materiais da vila e da cozinha (pedido do Sávio:
## "mais real, menos liso"). Cada material de cor lisa ganha:
##   - relevo (normal map) gerado por ruído, conforme o tipo de superfície:
##     LISO (calda, bala, glacê brilhante): micro-imperfeições bem de leve, e
##       uma camada de verniz (clearcoat) para o brilho "molhado";
##     ACETINADO (chocolate, massa, madeira pintada): relevo médio;
##     POROSO (açúcar, biscoito, algodão, papel): poros fortes e um brilho
##       suave de borda (aveludado);
##   - luz e reflexo físicos (Burley + GGX), sem os "degraus" do desenho.
## As texturas reais (fotos, ver Texturas) já têm relevo e ficam como estão.
## Os relevos são gerados uma vez só e reaproveitados (leve no celular).

enum Tipo { LISO, ACETINADO, POROSO }

## [frequência do ruído, força do relevo, repetições por metro]
const RUIDOS := {
	Tipo.LISO: [0.045, 3.0, 0.6],
	Tipo.ACETINADO: [0.09, 7.0, 0.9],
	Tipo.POROSO: [0.16, 10.0, 1.3],
}
const FORCA_RELEVO := {Tipo.LISO: 0.25, Tipo.ACETINADO: 0.5, Tipo.POROSO: 0.6}

static var _relevos := {}


static func tipo(mat: StandardMaterial3D) -> int:
	if mat.metallic > 0.3 or mat.roughness < 0.3:
		return Tipo.LISO
	return Tipo.ACETINADO if mat.roughness < 0.7 else Tipo.POROSO


## Normal map sem emendas, feito de ruído (um por tipo, guardado).
static func relevo(t: int) -> Texture2D:
	if _relevos.has(t):
		return _relevos[t]
	var ruido := FastNoiseLite.new()
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH if t != Tipo.POROSO else FastNoiseLite.TYPE_CELLULAR
	ruido.frequency = RUIDOS[t][0]
	ruido.fractal_type = FastNoiseLite.FRACTAL_FBM
	ruido.fractal_octaves = 4
	ruido.seed = 7 + t
	var textura := NoiseTexture2D.new()
	textura.width = 256
	textura.height = 256
	textura.seamless = true
	textura.as_normal_map = true
	textura.bump_strength = RUIDOS[t][1]
	textura.generate_mipmaps = true
	textura.noise = ruido
	_relevos[t] = textura
	return textura


## Deixa o material com luz e reflexo físicos e o relevo do tipo dele.
static func acabar(mat: StandardMaterial3D) -> void:
	if mat.has_meta("realista"):
		return
	mat.set_meta("realista", true)
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.metallic_specular = minf(mat.metallic_specular, 0.4)  # reflexo do céu na medida
	if mat.has_meta("real") or mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return  # foto escaneada: já tem relevo, aspereza e sombreado próprios
	var t := tipo(mat)
	if mat.normal_texture == null:
		mat.normal_enabled = true
		mat.normal_texture = relevo(t)
		mat.normal_scale = FORCA_RELEVO[t]
		if mat.albedo_texture == null:
			# sem desenho na cor: o relevo é projetado pelo mundo (sem emendas
			# e continua certo depois de as peças serem juntadas)
			mat.uv1_triplanar = true
			mat.uv1_world_triplanar = true
			mat.uv1_triplanar_sharpness = 3.0
			mat.uv1_scale = Vector3.ONE * RUIDOS[t][2]
	match t:
		Tipo.LISO:
			if mat.metallic < 0.3 and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				mat.clearcoat_enabled = true
				mat.clearcoat = 0.3
				mat.clearcoat_roughness = 0.25
			mat.roughness = maxf(mat.roughness, 0.12)
		Tipo.POROSO:
			mat.rim_enabled = true
			mat.rim = 0.1
			mat.rim_tint = 0.8
			mat.roughness = maxf(mat.roughness, 0.8)
