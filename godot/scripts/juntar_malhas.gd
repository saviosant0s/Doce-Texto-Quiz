class_name JuntarMalhas
## Deixa as cenas 3D montadas por código leves para o celular:
##
## - `simplificar()`: esferas, cilindros e roscas pequenas ficam com menos
##   faces (um granulado não precisa do detalhe de uma bola grande).
## - `juntar()`: as peças paradas do cenário (que não se mexem nem somem)
##   viram poucos blocos, um por material, e os contornos de desenho viram um
##   bloco por cor. Centenas de peças separadas pesavam no celular: cada uma
##   era desenhada à parte, às vezes duas vezes (contorno) ou três (sombra).
##
## Chame depois de montar a cena e de CenarioVila.estilo_desenho().

const CONTORNO := preload("res://tema/contorno_junto.gdshader")


## Menos faces nas formas pequenas (pelo tamanho no mundo).
static func simplificar(raiz: Node) -> void:
	for no in raiz.find_children("*", "MeshInstance3D", true, false):
		var peca := no as MeshInstance3D
		if not peca.mesh is PrimitiveMesh:
			continue
		var tamanho := (peca.get_aabb().size * peca.global_transform.basis.get_scale()).abs()
		var maior := maxf(tamanho.x, maxf(tamanho.y, tamanho.z))
		var lados := clampi(roundi(5 + maior * 9.0), 6, 24)
		if peca.mesh is SphereMesh:
			peca.mesh.radial_segments = mini(peca.mesh.radial_segments, lados)
			peca.mesh.rings = mini(peca.mesh.rings, maxi(3, lados / 2))
		elif peca.mesh is CylinderMesh:
			peca.mesh.radial_segments = mini(peca.mesh.radial_segments, lados)
		elif peca.mesh is TorusMesh:
			peca.mesh.rings = mini(peca.mesh.rings, lados)
			peca.mesh.ring_segments = mini(peca.mesh.ring_segments, maxi(4, lados / 2))
		elif peca.mesh is CapsuleMesh:
			peca.mesh.radial_segments = mini(peca.mesh.radial_segments, maxi(4, lados / 2))
			peca.mesh.rings = mini(peca.mesh.rings, 1 if maior < 0.3 else 3)


## Junta as peças paradas de `raiz`. Ficam de fora os bonecos (DoceAndante) e
## tudo dentro de nós cujo nome começa com um dos `excluir` (ex.: "Folha" das
## portas, "Nuvem"). Retorna quantas peças foram juntadas.
## Com `so_filhos`, junta só as peças filhas diretas de `raiz` (usado nos
## bonecos: cada parte que se mexe junta as suas peças).
static func juntar(raiz: Node3D, excluir: Array, so_filhos := false) -> int:
	var inversa := raiz.global_transform.affine_inverse()
	var solidos := {}  # chave do material -> {"mat", "st"}
	var contornos := {}  # cor -> {"cor", "espessura", "pos", "dir", "ind"}
	var juntadas := 0
	var pecas: Array = raiz.get_children().filter(func(n): return n is MeshInstance3D) if so_filhos \
		else raiz.find_children("*", "MeshInstance3D", true, false)
	if pecas.size() < 2:
		return 0
	for no in pecas:
		var peca := no as MeshInstance3D
		var mat := peca.material_override as StandardMaterial3D
		if mat == null or peca.mesh == null or not peca.visible or _fica_de_fora(peca, raiz, excluir):
			continue
		var xf := inversa * peca.global_transform
		var chave := _chave(mat)
		if not solidos.has(chave):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			solidos[chave] = {"mat": mat, "st": st}
		solidos[chave]["st"].append_from(peca.mesh, 0, xf)
		var contorno := peca.material_overlay as ShaderMaterial
		if contorno:
			_somar_contorno(contornos, peca.mesh, xf, contorno)
		peca.get_parent().remove_child(peca)
		peca.queue_free()
		juntadas += 1
	for chave in solidos:
		var bloco := MeshInstance3D.new()
		bloco.name = "Bloco"
		bloco.mesh = solidos[chave]["st"].commit()
		bloco.material_override = solidos[chave]["mat"]
		raiz.add_child(bloco)
	for chave in contornos:
		var c: Dictionary = contornos[chave]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = c["pos"]
		arrays[Mesh.ARRAY_COLOR] = c["dir"]
		arrays[Mesh.ARRAY_INDEX] = c["ind"]
		var malha := ArrayMesh.new()
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := ShaderMaterial.new()
		mat.shader = CONTORNO
		mat.set_shader_parameter("cor", c["cor"])
		mat.set_shader_parameter("espessura", c["espessura"])
		var bloco := MeshInstance3D.new()
		bloco.name = "BlocoContorno"
		bloco.mesh = malha
		bloco.material_override = mat
		bloco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(bloco)
	return juntadas


## Junta as peças de um boneco (ex.: um DoceAndante) parte por parte: as
## peças de cada nó que se mexe (corpo, olhos, braço, perna...) viram um bloco
## dentro desse mesmo nó, então as animações continuam funcionando.
static func juntar_boneco(boneco: Node3D) -> void:
	var partes: Array = [boneco]
	partes.append_array(boneco.find_children("*", "Node3D", true, false).filter(
		func(n): return not n is MeshInstance3D and not n is CollisionShape3D))
	for parte in partes:
		juntar(parte, [], true)


static func _fica_de_fora(peca: Node, raiz: Node, excluir: Array) -> bool:
	var no := peca.get_parent()
	while no != null and no != raiz:
		if no is DoceAndante:
			return true
		for prefixo in excluir:
			if String(no.name).begins_with(prefixo):
				return true
		no = no.get_parent()
	return false


## Materiais iguais (mesma cor, textura, brilho...) viram um só.
static func _chave(mat: StandardMaterial3D) -> String:
	return "%s|%.2f|%.2f|%d|%d|%s|%s|%.2f|%d|%d" % [mat.albedo_color.to_html(), mat.roughness, mat.metallic,
		mat.albedo_texture.get_instance_id() if mat.albedo_texture else 0, mat.transparency,
		mat.emission.to_html() if mat.emission_enabled else "-", str(mat.uv1_scale), mat.emission_energy_multiplier,
		mat.texture_filter, mat.shading_mode]


## Acrescenta a peça ao bloco de contorno da cor dela, gravando em cada vértice
## a direção de "inchar" (a mesma que tema/contorno.gdshader calculava).
static func _somar_contorno(contornos: Dictionary, malha: Mesh, xf: Transform3D, contorno: ShaderMaterial) -> void:
	var cor: Color = contorno.get_shader_parameter("cor")
	var chave := cor.to_html()
	if not contornos.has(chave):
		contornos[chave] = {"cor": cor, "espessura": contorno.get_shader_parameter("espessura"),
			"pos": PackedVector3Array(), "dir": PackedColorArray(), "ind": PackedInt32Array()}
	var c: Dictionary = contornos[chave]
	var forma: int = contorno.get_shader_parameter("forma")
	var arrays := malha.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normais: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices = arrays[Mesh.ARRAY_INDEX]
	var giro := xf.basis.orthonormalized()
	var inicio: int = c["pos"].size()
	var pos: PackedVector3Array = c["pos"]
	var dir: PackedColorArray = c["dir"]
	for i in vertices.size():
		var v := vertices[i]
		var d: Vector3
		match forma:
			1:
				d = v.sign()
			2:
				var lado := Vector2(v.x, v.z)
				lado = lado.normalized() if lado.length() > 0.001 else Vector2.ZERO
				d = Vector3(lado.x, signf(v.y), lado.y)
			3:
				d = v.normalized() if v.length() > 0.001 else Vector3.ZERO
			_:
				d = normais[i]
		d = (giro * d).clamp(-Vector3.ONE, Vector3.ONE)
		pos.append(xf * v)
		dir.append(Color(d.x * 0.5 + 0.5, d.y * 0.5 + 0.5, d.z * 0.5 + 0.5))
	var ind: PackedInt32Array = c["ind"]
	if indices == null or indices.is_empty():
		for i in vertices.size():
			ind.append(inicio + i)
	else:
		for i in indices:
			ind.append(inicio + i)
	c["pos"] = pos
	c["dir"] = dir
	c["ind"] = ind
