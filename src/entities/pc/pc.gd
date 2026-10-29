class_name Pc
extends StaticBody2D

signal opened
signal completed      # el jugador completo el minijuego
signal failed         # el minijuego fallo (se puede reintentar)
signal closed         # se cerro la ventana, por el motivo que sea

@export_category("Pc Atributes")
@export var pc_texture: Texture2D
@export var minigame_escene: PackedScene     # se deja el nombre para no perder lo asignado

@export_category("Comportamiento")
@export var one_time := true                 # true: tras completarse ya no se vuelve a abrir
@export var close_delay := 1.0               # pausa tras completar o fallar, antes de cerrar
@export var dim_color := Color(0, 0, 0, 0.65)
@export var layer_index := 20

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

var is_open := false
var is_done := false
var layer: CanvasLayer
var game: Node
var session := 0        # identifica cada apertura, para ignorar temporizadores viejos


func _ready() -> void:
	if pc_texture:
		sprite.texture = pc_texture


func _player_inside() -> bool:
	for body in interaction_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	# Con el minijuego abierto, Esc lo cierra (sin marcarlo como completado)
	if is_open:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close()
		return

	if (one_time and is_done) or not event.is_action_pressed("interact") or event.is_echo():
		return
		
	if not _player_inside():
		return

	get_viewport().set_input_as_handled()
	_open_game()


# --- Apertura ---
func _open_game() -> void:
	if minigame_escene == null:
		push_error("%s: asigna Minigame Escene en el Inspector" % name)
		return

	is_open = true
	session += 1
	_freeze_player(true)

	# El minijuego va en un CanvasLayer para verse fijo en pantalla
	layer = CanvasLayer.new()
	layer.layer = layer_index
	get_tree().current_scene.add_child(layer)

	# Fondo oscuro que tapa el mundo y bloquea los clics hacia atras
	var dim := ColorRect.new()
	dim.color = dim_color
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)

	game = minigame_escene.instantiate()

	# Si el minijuego arranca solo, se apaga: el PC decide cuando empieza
	if "auto_start" in game:
		game.set("auto_start", false)

	layer.add_child(game)

	# Solo se conecta lo que el minijuego tenga
	_connect_signal("completed", _on_completed)
	_connect_signal("failed", _on_failed)
	_connect_signal("closed", _close)

	_center_game()

	if game.has_method("start"):
		game.call("start")

	opened.emit()


func _connect_signal(signal_name: String, callable: Callable) -> void:
	if game.has_signal(signal_name):
		game.connect(signal_name, callable)


# Centra el minijuego en pantalla si expone el rectangulo de su monitor
func _center_game() -> void:
	if not game.has_method("get_board_rect"):
		return
	var rect: Rect2 = game.call("get_board_rect")
	var screen := get_viewport().get_visible_rect().size
	var target := (screen - rect.size) / 2.0 - rect.position
	if game is Node2D:
		(game as Node2D).position = target
	elif game is Control:
		(game as Control).position = target


# --- Resultado ---
func _on_completed() -> void:
	if is_done and one_time:
		return
	is_done = true
	completed.emit()
	_close_later()


func _on_failed() -> void:
	failed.emit()
	_close_later()      # is_done sigue en false: el jugador puede reintentar


func _close_later() -> void:
	var id := session
	await get_tree().create_timer(close_delay).timeout
	if id == session:
		_close()


# Cierra y limpia. Es seguro llamarla varias veces
func _close() -> void:
	if not is_open:
		return
	is_open = false
	_freeze_player(false)

	if is_instance_valid(layer):
		layer.queue_free()      # el minijuego es hijo, se libera con la capa
	layer = null
	game = null
	closed.emit()


# Detiene al jugador sin pausar el arbol
func _freeze_player(frozen: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
