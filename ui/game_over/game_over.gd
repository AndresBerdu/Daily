extends Control
## Pantalla de game over. GameFlow la muestra cuando se acaban las vidas.
## Cuando termina la musica avisa con `finished` y GameFlow decide a donde ir.

signal finished

const MIN_SECONDS := 2.0     # por si la musica no tiene duracion

@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	var seconds := MIN_SECONDS
	if music.stream:
		seconds = maxf(music.stream.get_length(), MIN_SECONDS)
	# El temporizador ignora la pausa: el juego esta detenido mientras se ve esta pantalla
	await get_tree().create_timer(seconds, true).timeout
	finished.emit()
