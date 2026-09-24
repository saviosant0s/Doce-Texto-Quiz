extends Node
## Música de fundo e efeitos sonoros. Disponível como `Audio` (autoload).

const EFEITOS := {
	"acerto": preload("res://assets/sons/acerto.ogg"),
	"erro": preload("res://assets/sons/erro.ogg"),
}

var _musica := AudioStreamPlayer.new()
var _efeitos := AudioStreamPlayer.new()


func _ready() -> void:
	var musica: AudioStreamOggVorbis = load("res://assets/sons/musica_fundo.ogg")
	musica.loop = true
	_musica.stream = musica
	_musica.volume_db = -6.0
	add_child(_musica)
	add_child(_efeitos)
	# Espera o Jogo carregar a preferência salva
	await get_tree().process_frame
	if Jogo.musica_ligada:
		_musica.play()


func tocar(efeito: String) -> void:
	_efeitos.stream = EFEITOS[efeito]
	_efeitos.play()


func alternar_musica() -> bool:
	Jogo.musica_ligada = not Jogo.musica_ligada
	if Jogo.musica_ligada:
		_musica.play()
	else:
		_musica.stop()
	Jogo.salvar()
	return Jogo.musica_ligada
