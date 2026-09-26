class_name Moveis3D
## Os móveis da MINHA CASA em 3D, feitos de peças simples (Pecas3D) com cara
## de doce. Cada um é montado centrado no chão (0, 0, 0), com a frente para
## +z, ocupando o tamanho dele em casas de 1 m (ver Casa.MOVEIS). Também faz
## as texturas do papel de parede e do piso.


static func _m(cor: String, aspereza := 0.5, metal := 0.0) -> StandardMaterial3D:
	return Pecas3D.material(Color(cor), aspereza, metal)


static func _luz(cor: String, forca := 1.2) -> StandardMaterial3D:
	var mat := _m(cor, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(cor)
	mat.emission_energy_multiplier = forca
	return mat


static func montar(id: String, pai: Node3D) -> void:
	match id:
		"tapete_glace":
			Pecas3D.cilindro(pai, 0.95, 0.95, 0.03, Vector3(0, 0.015, 0), _m("#FFE3EE", 0.9))
			Pecas3D.rosquinha(pai, 0.78, 0.92, Vector3(0, 0.03, 0), _m("#FF8FB8", 0.8), Vector3(1, 0.15, 1))
			for i in 10:
				var a := i * TAU / 10.0
				Pecas3D.esfera(pai, 0.06, Vector3(cos(a) * 0.5, 0.03, sin(a) * 0.5),
					_m(["#6FD3FF", "#FFD23F", "#7BE07B"][i % 3], 0.4), Vector3(1, 0.4, 1))
		"sofa_marshmallow":
			var marsh := _m("#FFF6FA", 0.85)
			var rosa := _m("#FFC2DA", 0.85)
			Pecas3D.caixa(pai, Vector3(1.8, 0.35, 0.8), Vector3(0, 0.3, 0.05), marsh)
			for x in [-0.45, 0.45]:
				Pecas3D.cilindro(pai, 0.3, 0.3, 0.8, Vector3(x, 0.55, 0.1), rosa, Vector3(1, 1, 0.55), Vector3(90, 0, 0))
			Pecas3D.caixa(pai, Vector3(1.8, 0.7, 0.25), Vector3(0, 0.75, -0.3), marsh)
			for x in [-0.95, 0.95]:
				Pecas3D.cilindro(pai, 0.2, 0.2, 0.8, Vector3(x, 0.55, 0.05), marsh, Vector3.ONE, Vector3(90, 0, 0))
			for x in [-0.8, 0.8]:
				Pecas3D.cilindro(pai, 0.05, 0.04, 0.14, Vector3(x, 0.07, 0.3), _m("#7A4322", 0.5))
		"poltrona_pudim":
			var pudim := _m("#F2B544", 0.35)
			Pecas3D.cilindro(pai, 0.38, 0.42, 0.45, Vector3(0, 0.25, 0.05), pudim)
			Pecas3D.cilindro(pai, 0.38, 0.38, 0.06, Vector3(0, 0.49, 0.05), _m("#7A3E12", 0.2))
			Pecas3D.caixa(pai, Vector3(0.8, 0.6, 0.18), Vector3(0, 0.75, -0.3), pudim)
			Pecas3D.caixa(pai, Vector3(0.8, 0.08, 0.2), Vector3(0, 1.08, -0.3), _m("#7A3E12", 0.2))
		"mesa_biscoito":
			var biscoito := _m("#D9A05B", 0.9)
			Pecas3D.cilindro(pai, 0.45, 0.45, 0.07, Vector3(0, 0.7, 0), biscoito)
			for i in 6:
				var a := i * TAU / 6.0
				Pecas3D.esfera(pai, 0.05, Vector3(cos(a) * 0.25, 0.74, sin(a) * 0.25), _m("#4A2412", 0.4), Vector3(1, 0.5, 1))
			Pecas3D.cilindro(pai, 0.06, 0.08, 0.66, Vector3(0, 0.34, 0), _m("#8A5A2B", 0.6))
			Pecas3D.cilindro(pai, 0.25, 0.28, 0.04, Vector3(0, 0.02, 0), _m("#8A5A2B", 0.6))
			Pecas3D.cilindro(pai, 0.12, 0.1, 0.12, Vector3(0.1, 0.8, 0.05), _m("#FFFFFF", 0.3))
		"cadeira_pirulito":
			var cor := _m("#8B7CF6", 0.2)
			Pecas3D.cilindro(pai, 0.28, 0.28, 0.08, Vector3(0, 0.45, 0), cor)
			for p in [Vector3(-0.18, 0, -0.18), Vector3(0.18, 0, -0.18), Vector3(-0.18, 0, 0.18), Vector3(0.18, 0, 0.18)]:
				Pecas3D.cilindro(pai, 0.03, 0.03, 0.45, p + Vector3(0, 0.22, 0), _m("#FFFFFF", 0.4))
			Pecas3D.cano(pai, Vector3(0, 0.45, -0.22), Vector3(0, 1.05, -0.22), 0.03, _m("#FFFFFF", 0.4))
			Pecas3D.cilindro(pai, 0.26, 0.26, 0.06, Vector3(0, 1.1, -0.22), cor, Vector3.ONE, Vector3(90, 0, 0))
			Pecas3D.rosquinha(pai, 0.1, 0.2, Vector3(0, 1.1, -0.18), _m("#FFFFFF", 0.3), Vector3(1, 1, 0.3), Vector3(90, 0, 0))
		"cama_bolo":
			var massa := _m("#FFE2B0", 0.8)
			Pecas3D.caixa(pai, Vector3(0.95, 0.4, 1.9), Vector3(0, 0.25, 0), massa)
			Pecas3D.caixa(pai, Vector3(0.97, 0.08, 1.92), Vector3(0, 0.3, 0), _m("#FF8FB8", 0.5))
			Pecas3D.caixa(pai, Vector3(0.9, 0.12, 1.3), Vector3(0, 0.5, 0.25), _m("#C9E4FF", 0.85))
			Pecas3D.esfera(pai, 0.28, Vector3(0, 0.55, -0.62), _m("#FFFFFF", 0.9), Vector3(1.4, 0.5, 0.8))
			Pecas3D.caixa(pai, Vector3(0.95, 0.9, 0.12), Vector3(0, 0.45, -0.92), _m("#7A4322", 0.4))
			Pecas3D.esfera(pai, 0.12, Vector3(0, 0.95, -0.92), _m("#E8263F", 0.15))
		"estante_chocolate":
			var choco := _m("#6B3A1F", 0.4)
			Pecas3D.caixa(pai, Vector3(1.8, 1.8, 0.4), Vector3(0, 0.9, -0.25), choco)
			for y in [0.45, 0.95, 1.45]:
				Pecas3D.caixa(pai, Vector3(1.7, 0.4, 0.05), Vector3(0, y, -0.03), _m("#3E1F0E", 0.5))
				for k in 6:
					var cor: String = ["#E8364F", "#6FD3FF", "#FFD23F", "#7BE07B", "#B07CFF", "#FF8A5B"][(k + int(y * 4)) % 6]
					Pecas3D.caixa(pai, Vector3(0.12, 0.3 - (k % 2) * 0.05, 0.25), Vector3(-0.7 + k * 0.16, y - 0.05, -0.1), _m(cor, 0.5))
		"luminaria_bala":
			Pecas3D.cilindro(pai, 0.2, 0.25, 0.08, Vector3(0, 0.04, 0), _m("#FFFFFF", 0.4))
			Pecas3D.cano(pai, Vector3(0, 0.05, 0), Vector3(0, 1.3, 0), 0.03, _m("#FFFFFF", 0.4))
			Pecas3D.esfera(pai, 0.3, Vector3(0, 1.5, 0), _luz("#FFB3D1", 1.4), Vector3(1.3, 1, 1))
			for x in [-0.42, 0.42]:
				Pecas3D.cilindro(pai, 0.0, 0.14, 0.2, Vector3(x, 1.5, 0), _m("#FF6FAE", 0.3), Vector3.ONE, Vector3(0, 0, 90 * signf(x)))
			var luz := OmniLight3D.new()
			luz.light_color = Color("#FFD1E3")
			luz.omni_range = 3.0
			luz.light_energy = 1.2
			luz.position = Vector3(0, 1.5, 0)
			pai.add_child(luz)
		"planta_cupcake":
			Pecas3D.cilindro(pai, 0.28, 0.2, 0.35, Vector3(0, 0.17, 0), _m("#FF8FB8", 0.6))
			Pecas3D.esfera(pai, 0.27, Vector3(0, 0.38, 0), _m("#FFF3E0", 0.8), Vector3(1, 0.4, 1))
			for i in 5:
				var a := i * TAU / 5.0
				Pecas3D.esfera(pai, 0.18, Vector3(cos(a) * 0.12, 0.7 + (i % 2) * 0.15, sin(a) * 0.12), _m("#4F9142", 0.8), Vector3(0.7, 1.3, 0.7))
			Pecas3D.esfera(pai, 0.08, Vector3(0, 1.0, 0), _m("#E8263F", 0.2))
		"tv_wafer":
			Pecas3D.caixa(pai, Vector3(1.8, 0.45, 0.45), Vector3(0, 0.23, -0.2), _m("#E8C07A", 0.8))
			for x in [-0.6, 0.0, 0.6]:
				Pecas3D.caixa(pai, Vector3(0.5, 0.3, 0.02), Vector3(x, 0.23, 0.03), _m("#C99A52", 0.8))
			Pecas3D.caixa(pai, Vector3(1.4, 0.85, 0.08), Vector3(0, 0.95, -0.3), _m("#2A1D45", 0.3))
			Pecas3D.caixa(pai, Vector3(1.25, 0.7, 0.02), Vector3(0, 0.95, -0.25), _luz("#6FB8FF", 0.9))
			Pecas3D.esfera(pai, 0.1, Vector3(-0.25, 1.0, -0.23), _luz("#FFD23F", 1.2), Vector3(1, 1, 0.2))
			Pecas3D.esfera(pai, 0.08, Vector3(0.2, 0.9, -0.23), _luz("#FF6FAE", 1.2), Vector3(1, 1, 0.2))
		"geladeira_sorvete":
			Pecas3D.caixa(pai, Vector3(0.8, 1.7, 0.7), Vector3(0, 0.85, -0.1), _m("#C9F2E6", 0.3))
			Pecas3D.caixa(pai, Vector3(0.82, 0.03, 0.72), Vector3(0, 1.1, -0.1), _m("#8FD6BF", 0.3))
			for y in [0.7, 1.35]:
				Pecas3D.caixa(pai, Vector3(0.06, 0.3, 0.06), Vector3(0.3, y, 0.28), _m("#FFFFFF", 0.2, 0.6))
			Pecas3D.cilindro(pai, 0.0, 0.2, 0.35, Vector3(0, 1.88, -0.1), _m("#E0A45A", 0.8), Vector3.ONE, Vector3(180, 0, 0))
			Pecas3D.esfera(pai, 0.22, Vector3(0, 2.1, -0.1), _m("#FF8FB8", 0.6))
		"piano_chocolate":
			var choco := _m("#4A2412", 0.25)
			Pecas3D.caixa(pai, Vector3(1.7, 1.1, 0.55), Vector3(0, 0.75, -0.2), choco)
			Pecas3D.caixa(pai, Vector3(1.5, 0.08, 0.3), Vector3(0, 0.8, 0.2), _m("#FFFFFF", 0.3))
			for k in 10:
				Pecas3D.caixa(pai, Vector3(0.06, 0.05, 0.18), Vector3(-0.63 + k * 0.14, 0.86, 0.15), _m("#1A0D06", 0.3))
			for x in [-0.75, 0.75]:
				Pecas3D.caixa(pai, Vector3(0.1, 0.6, 0.3), Vector3(x, 0.3, 0.15), choco)
			Pecas3D.cilindro(pai, 0.14, 0.12, 0.2, Vector3(0.5, 1.4, -0.2), _m("#FFFFFF", 0.3))
		"aquario_gelatina":
			Pecas3D.caixa(pai, Vector3(1.7, 0.5, 0.6), Vector3(0, 0.25, -0.1), _m("#7A4322", 0.5))
			var vidro := _m("#7FE0FF", 0.05, 0.2)
			vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vidro.albedo_color.a = 0.45
			Pecas3D.caixa(pai, Vector3(1.6, 0.8, 0.55), Vector3(0, 0.9, -0.1), vidro)
			for i in 4:
				var p := Vector3(-0.5 + i * 0.33, 0.8 + (i % 2) * 0.2, -0.1)
				Pecas3D.esfera(pai, 0.1, p, _m(["#FF8A5B", "#FFD23F", "#FF6FAE", "#7BE07B"][i], 0.2), Vector3(1.5, 0.8, 0.6))
			Pecas3D.caixa(pai, Vector3(1.55, 0.08, 0.5), Vector3(0, 0.55, -0.1), _m("#FFE3A0", 0.9))
		"relogio_cuco":
			var madeira := _m("#8A5A2B", 0.6)
			Pecas3D.caixa(pai, Vector3(0.5, 1.9, 0.35), Vector3(0, 0.95, -0.2), madeira)
			Pecas3D.cilindro(pai, 0.2, 0.2, 0.04, Vector3(0, 1.5, -0.01), _m("#FFF3E0", 0.4), Vector3.ONE, Vector3(90, 0, 0))
			Pecas3D.caixa(pai, Vector3(0.02, 0.15, 0.02), Vector3(0, 1.55, 0.02), _m("#2A1D45", 0.3))
			Pecas3D.caixa(pai, Vector3(0.1, 0.02, 0.02), Vector3(0.04, 1.5, 0.02), _m("#2A1D45", 0.3))
			Pecas3D.cilindro(pai, 0.0, 0.4, 0.3, Vector3(0, 2.05, -0.2), _m("#E8364F", 0.4), Vector3(1, 1, 0.6))
			Pecas3D.esfera(pai, 0.1, Vector3(0, 0.8, -0.01), _m("#FFC83D", 0.2, 0.7))
		"bau_brinquedos":
			Pecas3D.caixa(pai, Vector3(0.8, 0.5, 0.6), Vector3(0, 0.25, 0), _m("#6FD3FF", 0.5))
			Pecas3D.caixa(pai, Vector3(0.84, 0.1, 0.64), Vector3(0, 0.52, -0.05), _m("#FFD23F", 0.5), Vector3(-15, 0, 0))
			Pecas3D.esfera(pai, 0.14, Vector3(-0.15, 0.6, 0.05), _m("#E8364F", 0.3))
			Pecas3D.caixa(pai, Vector3(0.15, 0.15, 0.15), Vector3(0.18, 0.62, 0.0), _m("#7BE07B", 0.5), Vector3(0, 30, 20))
		"trofeu_gigante":
			var ouro := _m("#FFC83D", 0.15, 0.85)
			Pecas3D.caixa(pai, Vector3(0.6, 0.3, 0.6), Vector3(0, 0.15, 0), _m("#4A2412", 0.3))
			Pecas3D.cilindro(pai, 0.08, 0.15, 0.5, Vector3(0, 0.55, 0), ouro)
			Pecas3D.cilindro(pai, 0.4, 0.15, 0.6, Vector3(0, 1.1, 0), ouro)
			for x in [-0.42, 0.42]:
				Pecas3D.rosquinha(pai, 0.1, 0.16, Vector3(x, 1.15, 0), ouro, Vector3.ONE, Vector3(90, 0, 0))
			Pecas3D.esfera(pai, 0.12, Vector3(0, 1.5, 0), _luz("#FFE27A", 1.0))
		"bolo_torre":
			var y := 0.0
			for i in 5:
				var r := 0.42 - i * 0.07
				Pecas3D.cilindro(pai, r, r, 0.3, Vector3(0, y + 0.15, 0),
					_m(["#FF8FB8", "#7A4322", "#FFD23F", "#8FE3C0", "#8B7CF6"][i], 0.5))
				y += 0.3
			Pecas3D.cilindro(pai, 0.03, 0.03, 0.25, Vector3(0, y + 0.12, 0), _m("#FFFFFF", 0.4))
			Pecas3D.esfera(pai, 0.05, Vector3(0, y + 0.3, 0), _luz("#FFB347", 2.0), Vector3(1, 1.6, 1))
		"fliperama_mini":
			Pecas3D.caixa(pai, Vector3(0.7, 1.6, 0.6), Vector3(0, 0.8, -0.1), _m("#5E3D8E", 0.4))
			Pecas3D.caixa(pai, Vector3(0.55, 0.45, 0.03), Vector3(0, 1.25, 0.21), _luz("#8FD3F4", 1.0))
			Pecas3D.caixa(pai, Vector3(0.7, 0.1, 0.35), Vector3(0, 0.9, 0.3), _m("#8B7CF6", 0.4), Vector3(-20, 0, 0))
			for x in [-0.15, 0.1, 0.25]:
				Pecas3D.esfera(pai, 0.05, Vector3(x, 0.97, 0.32), _m(["#E8364F", "#FFD23F", "#7BE07B"][[-0.15, 0.1, 0.25].find(x)], 0.2))
			Pecas3D.caixa(pai, Vector3(0.72, 0.18, 0.62), Vector3(0, 1.65, -0.1), _luz("#FF6FAE", 0.8))
		"banco_praca":
			var madeira := _m("#B5773F", 0.7)
			var ferro := _m("#2B2B30", 0.4, 0.6)
			for k in 3:
				Pecas3D.caixa(pai, Vector3(1.7, 0.06, 0.14), Vector3(0, 0.45, -0.15 + k * 0.16), madeira)
			for k in 2:
				Pecas3D.caixa(pai, Vector3(1.7, 0.12, 0.05), Vector3(0, 0.7 + k * 0.2, -0.3), madeira, Vector3(-10, 0, 0))
			for x in [-0.75, 0.75]:
				Pecas3D.caixa(pai, Vector3(0.06, 0.45, 0.5), Vector3(x, 0.22, -0.05), ferro)
				Pecas3D.caixa(pai, Vector3(0.06, 0.6, 0.06), Vector3(x, 0.72, -0.32), ferro)
			Pecas3D.esfera(pai, 0.12, Vector3(0.5, 0.55, 0.0), _m("#FF6FAE", 0.4), Vector3(1, 0.6, 1))
		"retrato_vila":
			Pecas3D.caixa(pai, Vector3(0.12, 1.3, 0.12), Vector3(0, 0.65, -0.1), _m("#6B3A1F", 0.5), Vector3(-8, 0, 0))
			for x in [-0.3, 0.3]:
				Pecas3D.caixa(pai, Vector3(0.06, 1.1, 0.06), Vector3(x, 0.52, 0.12), _m("#6B3A1F", 0.5), Vector3(8, 0, 0))
			var quadro := Node3D.new()
			quadro.position = Vector3(0, 1.25, 0.02)
			quadro.rotation_degrees = Vector3(-8, 0, 0)
			pai.add_child(quadro)
			Pecas3D.caixa(quadro, Vector3(0.9, 0.7, 0.06), Vector3.ZERO, _m("#FFC83D", 0.2, 0.7))
			Pecas3D.caixa(quadro, Vector3(0.76, 0.56, 0.04), Vector3(0, 0, 0.02), _m("#9FD4F7", 0.6))
			Pecas3D.caixa(quadro, Vector3(0.76, 0.18, 0.04), Vector3(0, -0.19, 0.03), _m("#7BBF5A", 0.8))
			Pecas3D.cilindro(quadro, 0.0, 0.12, 0.2, Vector3(-0.15, -0.02, 0.05), _m("#E8364F", 0.5))
			Pecas3D.caixa(quadro, Vector3(0.14, 0.14, 0.02), Vector3(-0.15, -0.15, 0.05), _m("#FFF1DC", 0.6))
			Pecas3D.cilindro(quadro, 0.1, 0.1, 0.3, Vector3(0.18, -0.05, 0.05), _m("#FF8FB8", 0.5))
		"robo_office":
			var metal := _m("#C9CED6", 0.3, 0.6)
			Pecas3D.cilindro(pai, 0.25, 0.3, 0.7, Vector3(0, 0.45, 0), metal)
			Pecas3D.caixa(pai, Vector3(0.5, 0.4, 0.4), Vector3(0, 1.05, 0), metal)
			for x in [-0.12, 0.12]:
				Pecas3D.esfera(pai, 0.06, Vector3(x, 1.08, 0.2), _luz("#6FD3FF", 1.5))
			Pecas3D.cano(pai, Vector3(0, 1.25, 0), Vector3(0, 1.45, 0), 0.02, metal)
			Pecas3D.esfera(pai, 0.05, Vector3(0, 1.48, 0), _luz("#E8364F", 1.5))
			Pecas3D.caixa(pai, Vector3(0.3, 0.2, 0.02), Vector3(0, 0.55, 0.3), _luz("#2E7D32", 0.8))
			for x in [-0.35, 0.35]:
				Pecas3D.cano(pai, Vector3(x * 0.8, 0.7, 0), Vector3(x, 0.4, 0.1), 0.04, metal)
			Pecas3D.cilindro(pai, 0.3, 0.3, 0.08, Vector3(0, 0.04, 0), _m("#2A2A30", 0.5))


# --- Papel de parede e piso ---------------------------------------------------------

static var _texturas := {}


## Textura de um papel de parede (repete a cada metro).
static func textura_parede(id: String) -> Texture2D:
	var chave := "parede_" + id
	if _texturas.has(chave):
		return _texturas[chave]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	match id:
		"listras_rosa":
			for x in 64:
				img.fill_rect(Rect2i(x, 0, 1, 64), Color("#FFD1E3") if (x / 8) % 2 == 0 else Color("#FFF1F6"))
		"bolinhas_menta":
			img.fill(Color("#DDF7EE"))
			_bolinhas(img, Color("#8FE3C0"), 5)
		"xadrez_lilas":
			for x in 64:
				for y in 64:
					img.set_pixel(x, y, Color("#E4DEFF") if ((x / 16) + (y / 16)) % 2 == 0 else Color("#CFC4FA"))
		"chocolate":
			img.fill(Color("#8A5A3A"))
			for y in [0, 32]:
				img.fill_rect(Rect2i(0, y, 64, 2), Color("#6B3A1F"))
			for x in [0, 32]:
				img.fill_rect(Rect2i(x, 0, 2, 64), Color("#6B3A1F"))
		"ceu_estrelado":
			img.fill(Color("#2B2A5E"))
			var r := RandomNumberGenerator.new()
			r.seed = 5
			for i in 14:
				var p := Vector2i(r.randi_range(2, 61), r.randi_range(2, 61))
				img.fill_rect(Rect2i(p.x - 1, p.y, 3, 1), Color("#FFE27A"))
				img.fill_rect(Rect2i(p.x, p.y - 1, 1, 3), Color("#FFE27A"))
		_:
			img.fill(Color("#FFF3E0"))
			for y in 64:
				if y % 16 == 0:
					img.fill_rect(Rect2i(0, y, 64, 1), Color("#F4E4CC"))
	var tex := ImageTexture.create_from_image(img)
	_texturas[chave] = tex
	return tex


static func textura_piso(id: String) -> Texture2D:
	var chave := "piso_" + id
	if _texturas.has(chave):
		return _texturas[chave]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	match id:
		"biscoito":
			img.fill(Color("#E0A864"))
			img.fill_rect(Rect2i(0, 0, 64, 2), Color("#B97F3E"))
			img.fill_rect(Rect2i(0, 0, 2, 64), Color("#B97F3E"))
			for p in [Vector2i(14, 16), Vector2i(40, 22), Vector2i(26, 44), Vector2i(50, 50)]:
				img.fill_rect(Rect2i(p.x, p.y, 4, 4), Color("#5A2E17"))
		"carpete_rosa":
			img.fill(Color("#FFC7DD"))
			var r := RandomNumberGenerator.new()
			r.seed = 3
			for i in 200:
				img.set_pixel(r.randi_range(0, 63), r.randi_range(0, 63), Color("#FFB0CE"))
		"xadrez_choco":
			for x in 64:
				for y in 64:
					img.set_pixel(x, y, Color("#6B3A1F") if ((x / 32) + (y / 32)) % 2 == 0 else Color("#F3E3B5"))
		"marmore":
			img.fill(Color("#F6F2F7"))
			var r := RandomNumberGenerator.new()
			r.seed = 9
			for i in 5:
				var p := Vector2(r.randf() * 64, r.randf() * 64)
				for k in 30:
					p += Vector2(r.randf_range(0.2, 1.6), r.randf_range(-1, 1))
					img.set_pixel(int(p.x) % 64, posmod(int(p.y), 64), Color("#D9CCE3"))
			img.fill_rect(Rect2i(0, 0, 64, 1), Color("#E0D6E6"))
			img.fill_rect(Rect2i(0, 0, 1, 64), Color("#E0D6E6"))
		_:
			img.fill(Color("#C98A5A"))
			for y in [0, 16, 32, 48]:
				img.fill_rect(Rect2i(0, y, 64, 1), Color("#A56B3F"))
				var junta := 20 if (y / 16) % 2 == 0 else 44
				img.fill_rect(Rect2i(junta, y, 1, 16), Color("#A56B3F"))
	var tex := ImageTexture.create_from_image(img)
	_texturas[chave] = tex
	return tex


static func _bolinhas(img: Image, cor: Color, raio: int) -> void:
	for centro in [Vector2i(16, 16), Vector2i(48, 48)]:
		for x in range(-raio, raio + 1):
			for y in range(-raio, raio + 1):
				if x * x + y * y <= raio * raio:
					img.set_pixel(centro.x + x, centro.y + y, cor)
