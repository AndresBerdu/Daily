extends Node
## Autoload "PlayerControl": unico punto para congelar al jugador y moverlo.
## Congelar = el jugador pasa al estado "frozen" (queda quieto en idle).
## Varias fuentes pueden congelarlo a la vez (dialogo, minijuego, transicion...);
## el jugador solo se libera cuando TODAS lo han soltado.
## Debe ir DESPUES de DialogueManager en Proyecto > Autoload.

signal frozen_changed(frozen: bool)

var _sources: Array = []      # quienes lo tienen congelado (nodos o textos)
var _was_frozen := false


func _ready() -> void:
	# Mientras haya un dialogo en pantalla, el jugador no se mueve
	DialogueManager.dialogue_started.connect(func(_r): freeze("dialogue"))
	DialogueManager.dialogue_ended.connect(func(_r): unfreeze("dialogue"))


## source: normalmente `self` (un nodo) o un texto como "dialogue"
func freeze(source: Variant) -> void:
	if not _sources.has(source):
		_sources.append(source)
	_notify()


func unfreeze(source: Variant) -> void:
	_sources.erase(source)
	_notify()


## Suelta todas las fuentes (se usa al cambiar de escena para no quedar congelado)
func reset() -> void:
	_sources.clear()
	_notify()


func is_frozen() -> bool:
	_prune()
	return not _sources.is_empty()


## True si el evento es la tecla de accion (Espacio/Enter), no es eco
## y el jugador puede interactuar (no esta congelado por un dialogo o minijuego).
func is_interact(event: InputEvent) -> bool:
	return event.is_action_pressed("interact") and not event.is_echo() and not is_frozen()


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


## Mueve al jugador a un marcador, sin inercia y sin que la camara se deslice
func teleport_to(target: Node2D) -> void:
	if target == null:
		return
	move_to(target.global_position)


## Mueve al jugador a una posicion del mundo (tambien se usa al cargar una partida)
func move_to(world_position: Vector2) -> void:
	var player := get_player()
	if player == null:
		return
	player.global_position = world_position
	player.velocity = Vector2.ZERO
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.reset_smoothing()


# Quita las fuentes que ya no existen (por ejemplo un PC que se libero abierto)
func _prune() -> void:
	_sources = _sources.filter(func(s): return not (s is Object) or is_instance_valid(s))


func _notify() -> void:
	var now := is_frozen()
	if now != _was_frozen:
		_was_frozen = now
		frozen_changed.emit(now)
