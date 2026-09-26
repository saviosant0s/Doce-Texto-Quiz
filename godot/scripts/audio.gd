extends Node
## Música de fundo e efeitos sonoros, em canais (buses) separados para que cada
## um tenha seu volume. Disponível como `Audio` (autoload).
##
## As músicas tocam uma depois da outra, em ordem aleatória, sem repetir a
## mesma em seguida. Para trocar as músicas, edite MUSICAS.

const EFEITOS := {
	"acerto": preload("res://assets/sons/acerto.ogg"),
	"erro": preload("res://assets/sons/erro.ogg"),
	# gerados por ferramentas/gerar_sons.py (originais)
	"moeda": preload("res://assets/sons/moeda.wav"),
	"estouro": preload("res://assets/sons/estouro.wav"),
	"porta": preload("res://assets/sons/porta.wav"),
	"passo": preload("res://assets/sons/passo.wav"),
	"pulo": preload("res://assets/sons/pulo.wav"),
	"construir": preload("res://assets/sons/construir.wav"),
	"caixa": preload("res://assets/sons/caixa.wav"),
	"explosao": preload("res://assets/sons/explosao.wav"),
	"especial": preload("res://assets/sons/especial.wav"),
	"vitoria": preload("res://assets/sons/vitoria.wav"),
}
## Quantos efeitos podem tocar ao mesmo tempo (passos + moedas + estouros...).
const CANAIS_EFEITOS := 8
const MUSICAS := [
	"res://assets/sons/musica_1.ogg",
	"res://assets/sons/musica_2.ogg",
	"res://assets/sons/musica_3.ogg",
]
const BUS_MUSICA := "Musica"
const BUS_EFEITOS := "Efeitos"
const VOLUME_PADRAO_MUSICA := 0.8

var _musica := AudioStreamPlayer.new()
var _efeitos: Array[AudioStreamPlayer] = []
var _proximo_canal := 0
## Ordem das músicas da rodada atual (índices de MUSICAS) e posição nela.
var _fila: Array[int] = []
var musica_atual := -1


func _ready() -> void:
	for bus in [BUS_MUSICA, BUS_EFEITOS]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_musica.bus = BUS_MUSICA
	_musica.finished.connect(proxima_musica)
	add_child(_musica)
	for i in CANAIS_EFEITOS:
		var canal := AudioStreamPlayer.new()
		canal.bus = BUS_EFEITOS
		add_child(canal)
		_efeitos.append(canal)
	aplicar_volumes()
	Progresso.alterado.connect(aplicar_volumes)
	proxima_musica()


## Toca a próxima música da fila (embaralha de novo quando a fila acaba).
func proxima_musica() -> void:
	if _fila.is_empty():
		for i in MUSICAS.size():
			_fila.append(i)
		_fila.shuffle()
		# não repete a música que acabou de tocar
		if _fila.size() > 1 and _fila[0] == musica_atual:
			_fila.push_back(_fila.pop_front())
	musica_atual = _fila.pop_front()
	_musica.stream = load(MUSICAS[musica_atual])
	_musica.play()


## Toca um efeito. `tom` muda a altura (1 = normal; >1 mais agudo), `volume_db`
## deixa mais baixo (negativo). Vários efeitos podem tocar juntos.
func tocar(efeito: String, tom := 1.0, volume_db := 0.0) -> void:
	var canal := _efeitos[_proximo_canal]
	_proximo_canal = (_proximo_canal + 1) % _efeitos.size()
	canal.stream = EFEITOS[efeito]
	canal.pitch_scale = tom
	canal.volume_db = volume_db
	canal.play()


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
