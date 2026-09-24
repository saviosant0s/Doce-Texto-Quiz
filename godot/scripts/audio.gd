extends Node
## Música de fundo e efeitos sonoros, em canais (buses) separados para que cada
## um tenha seu volume. Disponível como `Audio` (autoload).

const EFEITOS := {
	"acerto": preload("res://assets/sons/acerto.ogg"),
	"erro": preload("res://assets/sons/erro.ogg"),
}
const BUS_MUSICA := "Musica"
const BUS_EFEITOS := "Efeitos"
const VOLUME_PADRAO_MUSICA := 0.8

var _musica := AudioStreamPlayer.new()
var _efeitos := AudioStreamPlayer.new()


func _ready() -> void:
	for bus in [BUS_MUSICA, BUS_EFEITOS]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	var musica: AudioStreamOggVorbis = load("res://assets/sons/musica_fundo.ogg")
	musica.loop = true
	_musica.stream = musica
	_musica.bus = BUS_MUSICA
	_efeitos.bus = BUS_EFEITOS
	add_child(_musica)
	add_child(_efeitos)
	aplicar_volumes()
	Progresso.alterado.connect(aplicar_volumes)
	_musica.play()


func tocar(efeito: String) -> void:
	_efeitos.stream = EFEITOS[efeito]
	_efeitos.play()


## Aplica os volumes salvos em Progresso.config (0 a 1) aos canais.
func aplicar_volumes() -> void:
	_volume_do_bus(BUS_MUSICA, Progresso.config.get("volume_musica", VOLUME_PADRAO_MUSICA))
	_volume_do_bus(BUS_EFEITOS, Progresso.config.get("volume_efeitos", 1.0))


func musica_ligada() -> bool:
	return Progresso.config.get("volume_musica", VOLUME_PADRAO_MUSICA) > 0.0


## Liga/desliga a música (lembra o volume de antes para religar igual).
func alternar_musica() -> bool:
	if musica_ligada():
		Progresso.config["volume_musica_antes"] = Progresso.config["volume_musica"]
		Progresso.config["volume_musica"] = 0.0
	else:
		Progresso.config["volume_musica"] = Progresso.config.get("volume_musica_antes", VOLUME_PADRAO_MUSICA)
	Progresso.salvar()
	return musica_ligada()


func _volume_do_bus(nome: String, volume: float) -> void:
	var indice := AudioServer.get_bus_index(nome)
	AudioServer.set_bus_mute(indice, volume <= 0.0)
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(volume, 0.0001)))
