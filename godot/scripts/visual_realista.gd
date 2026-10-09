class_name VisualRealista
## Gráficos "super realistas" (pedido do Sávio) com custo baixo, para não
## pesar em placa integrada: céu com sol, halo e nuvens (tema/ceu_doce.gdshader),
## líquidos com ondinhas, reflexo do céu e brilho do sol
## (tema/liquido_doce.gdshader), sombras suaves e o fundo bem longe desfocado.
## No ULTRA (computador forte, renderizador Forward+): SSAO, SSIL, SSR e névoa
## volumétrica. Na qualidade BAIXA (e no navegador) fica tudo como antes.

const CEU := preload("res://tema/ceu_doce.gdshader")
const LIQUIDO := preload("res://tema/liquido_doce.gdshader")

## Líquidos criados (para o céu mudar a cor refletida com a hora).
static var _liquidos: Array[ShaderMaterial] = []
static var _ruido_nuvens: NoiseTexture2D
static var _ondas: NoiseTexture2D

## Tipos de líquido: [cor da beira, cor do meio, reflexo, aspereza, velocidade, força das ondas]
const LIQUIDOS := {
	"morango": ["#FFB3CF", "#FF6FA3", 0.65, 0.05, 0.02, 0.24],
	"chocolate": ["#6E3518", "#3A1A0A", 0.1, 0.12, 0.008, 0.14],
	"calda": ["#E6A957", "#A8661F", 0.5, 0.08, 0.05, 0.2],
}


static func ligado() -> bool:
	return not CenarioVila.modo_leve() and Qualidade.nivel() != Qualidade.BAIXA


## O céu: shader realista (ou o céu simples de antes, na BAIXA).
static func ceu(topo: Color, horizonte: Color, chao: Color) -> Material:
	if not ligado():
		var simples := ProceduralSkyMaterial.new()
		simples.sky_top_color = topo
		simples.sky_horizon_color = horizonte
		simples.ground_horizon_color = horizonte
		simples.ground_bottom_color = chao
		return simples
	var mat := ShaderMaterial.new()
	mat.shader = CEU
	mat.set_shader_parameter("ruido", _nuvens())
	cores_do_ceu(mat, topo, horizonte, chao)
	return mat


## Muda as cores do céu (o simples ou o realista).
static func cores_do_ceu(mat: Material, topo: Color, horizonte: Color, chao := Color(-1, 0, 0)) -> void:
	if mat is ProceduralSkyMaterial:
		var simples := mat as ProceduralSkyMaterial
		simples.sky_top_color = topo
		simples.sky_horizon_color = horizonte
		simples.ground_horizon_color = horizonte
		if chao.r >= 0.0:
			simples.ground_bottom_color = chao
	elif mat is ShaderMaterial:
		var shader := mat as ShaderMaterial
		shader.set_shader_parameter("cor_topo", topo)
		shader.set_shader_parameter("cor_horizonte", horizonte)
		if chao.r >= 0.0:
			shader.set_shader_parameter("cor_chao", chao)
	for liquido in _liquidos:
		if is_instance_valid(liquido):
			liquido.set_shader_parameter("cor_ceu", horizonte)
			liquido.set_shader_parameter("cor_ceu_topo", topo)


## Hora do dia no céu realista: a cor do sol, a noite (0 a 1) e a chuva.
static func clima_do_ceu(mat: Material, cor_sol: Color, noite: float, chuva: bool) -> void:
	if not mat is ShaderMaterial:
		return
	var shader := mat as ShaderMaterial
	shader.set_shader_parameter("cor_sol", cor_sol)
	shader.set_shader_parameter("noite", noite)
	shader.set_shader_parameter("cobertura", 0.82 if chuva else 0.48)
	shader.set_shader_parameter("cinza", 0.7 if chuva else 0.0)


## Material de líquido (`tipo` em LIQUIDOS). `centro` e `raios` (x, z do
## mundo): o meio fica mais escuro (lago); raios zero = cor só da beira (rio).
## Na BAIXA, devolve o material liso de antes (`simples`).
static func liquido(tipo: String, simples: Material, centro := Vector2.ZERO, raios := Vector2.ZERO,
		direcao := Vector2(1.0, 0.6)) -> Material:
	if not ligado():
		return simples
	var dados: Array = LIQUIDOS[tipo]
	var mat := ShaderMaterial.new()
	mat.shader = LIQUIDO
	mat.set_shader_parameter("cor_rasa", Color(dados[0]))
	mat.set_shader_parameter("cor_funda", Color(dados[1]))
	mat.set_shader_parameter("reflexo", dados[2])
	mat.set_shader_parameter("aspereza", dados[3])
	mat.set_shader_parameter("velocidade", dados[4])
	mat.set_shader_parameter("forca_onda", dados[5])
	mat.set_shader_parameter("centro", centro)
	mat.set_shader_parameter("raios", raios)
	mat.set_shader_parameter("direcao", direcao)
	mat.set_shader_parameter("ondas", _ondinhas())
	_liquidos = _liquidos.filter(func(m): return is_instance_valid(m))
	_liquidos.append(mat)
	return mat


## Na ALTA, o fundo bem longe fica levemente desfocado (como numa câmera de
## verdade; custa um passe de desfoque). Põe na câmera `camera`.
static func camera(camera: Camera3D) -> void:
	if not ligado() or Qualidade.nivel() < Qualidade.ALTA:
		camera.attributes = null
		return
	var foco := CameraAttributesPractical.new()
	foco.dof_blur_far_enabled = true
	foco.dof_blur_far_distance = 75.0  # (só o horizonte: a vila continua nítida)
	foco.dof_blur_far_transition = 60.0
	foco.dof_blur_amount = 0.04
	camera.attributes = foco


## Sombras suaves na ALTA. (A névoa com a cor do céu e o brilho do sol
## — fog_aerial_perspective e fog_sun_scatter — ficaram de fora: no
## renderizador Mobile, com elas ligadas, os postes, as pedrinhas e a forminha
## do doce perdiam a luz do sol e ficavam arroxeados.)
static func ambiente(ambiente: Environment) -> void:
	if not ligado():
		return
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM if Qualidade.nivel() >= Qualidade.ALTA else RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	if Qualidade.nivel() == Qualidade.ULTRA and Qualidade.ultra_ativo():
		_ultra(ambiente)


## ULTRA (renderizador Forward+, computador forte): sombra de contato nos
## cantos e embaixo das coisas (SSAO), luz colorida rebatida das paredes e do
## chão (SSIL), reflexo dos prédios e doces nos lagos (SSR) e raios de sol na
## névoa (névoa volumétrica, com as sombras).
static func _ultra(ambiente: Environment) -> void:
	ambiente.ssao_enabled = true
	ambiente.ssao_radius = 1.2
	ambiente.ssao_intensity = 2.2
	ambiente.ssao_power = 1.6
	ambiente.ssao_detail = 0.6
	ambiente.ssao_light_affect = 0.15
	ambiente.ssil_enabled = true
	ambiente.ssil_radius = 4.0
	ambiente.ssil_intensity = 0.45
	ambiente.ssr_enabled = true
	ambiente.ssr_max_steps = 56
	ambiente.ssr_fade_in = 0.15
	ambiente.ssr_fade_out = 2.0
	ambiente.ssr_depth_tolerance = 0.3
	ambiente.volumetric_fog_enabled = true
	ambiente.volumetric_fog_density = 0.0025
	ambiente.volumetric_fog_albedo = Color("#FFF1F6")
	ambiente.volumetric_fog_anisotropy = 0.65  # o brilho fica para o lado do sol (raios de luz)
	ambiente.volumetric_fog_length = 70.0
	ambiente.volumetric_fog_sky_affect = 0.0
	ambiente.volumetric_fog_ambient_inject = 0.0
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)


## Desliga os efeitos do ULTRA na hora (o jogo ficou lento e a qualidade desceu).
static func desligar_ultra(ambiente: Environment) -> void:
	ambiente.ssao_enabled = false
	ambiente.ssil_enabled = false
	ambiente.ssr_enabled = false
	ambiente.volumetric_fog_enabled = false
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM if Qualidade.nivel() >= Qualidade.ALTA else RenderingServer.SHADOW_QUALITY_SOFT_LOW)


## O sol: no ULTRA, sombra que fica mais suave quanto mais longe do objeto
## (como a de verdade) e quatro faixas de sombra (nítida perto, até longe).
static func sol(luz: DirectionalLight3D) -> void:
	if Qualidade.nivel() != Qualidade.ULTRA or not Qualidade.ultra_ativo():
		return
	luz.light_angular_distance = 0.6
	luz.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	luz.directional_shadow_max_distance = 70.0
	luz.shadow_blur = 1.0


static func _nuvens() -> NoiseTexture2D:
	if _ruido_nuvens == null:
		var ruido := FastNoiseLite.new()
		ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		ruido.frequency = 0.012
		ruido.fractal_type = FastNoiseLite.FRACTAL_FBM
		ruido.fractal_octaves = 5
		ruido.fractal_gain = 0.55
		ruido.seed = 21
		_ruido_nuvens = NoiseTexture2D.new()
		_ruido_nuvens.width = 512
		_ruido_nuvens.height = 512
		_ruido_nuvens.seamless = true
		_ruido_nuvens.generate_mipmaps = true
		_ruido_nuvens.noise = ruido
	return _ruido_nuvens


static func _ondinhas() -> NoiseTexture2D:
	if _ondas == null:
		var ruido := FastNoiseLite.new()
		ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		ruido.frequency = 0.022
		ruido.fractal_type = FastNoiseLite.FRACTAL_FBM
		ruido.fractal_octaves = 3
		ruido.seed = 5
		_ondas = NoiseTexture2D.new()
		_ondas.width = 256
		_ondas.height = 256
		_ondas.seamless = true
		_ondas.as_normal_map = true
		_ondas.bump_strength = 4.0
		_ondas.generate_mipmaps = true
		_ondas.noise = ruido
	return _ondas
