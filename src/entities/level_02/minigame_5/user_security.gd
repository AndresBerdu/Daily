class_name UserSecurity
extends Control

signal completed      # eliminaste a todos los intrusos
signal failed         # te quedaste sin corazones

const USER_ROW: PackedScene = preload("res://src/entities/level_02/minigame_5/user/user.tscn")   # ajusta la ruta
const WARN_SCENE: PackedScene = preload("res://src/entities/level_02/minigame_5/warn/warn.tscn") # ajusta la ruta

@export var spawn_interval := 3.0
@export var alarm_threshold := 5          # la alarma salta con MAS de este numero de intrusos
@export var warn_marker: Marker2D         # donde aparece la alarma
@export var auto_start := true

@onready var list: GridContainer = $ScrollContainer/UserList

var spawn_timer := Timer.new()
var queue: Array[Dictionary] = []
var entries: Array[UserEntry] = []
var header_cells := 0       # celdas de encabezado al inicio del grid
var next_id := 1
var intruders := 0
var alarm_armed := true
var warn: Node2D = null
var running := false

func _ready() -> void:
	header_cells = list.get_child_count()    # los titulos que dejaste dentro del grid

	GameManager.game_over.connect(_on_game_over)

	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_user)
	add_child(spawn_timer)

	if auto_start:
		start()

func start() -> void:
	# Borra solo las filas anteriores, no los encabezados
	var children := list.get_children()
	for i in range(header_cells, children.size()):
		children[i].queue_free()
	entries.clear()
	_close_alarm()

	queue = UserBank.get_all()
	queue.shuffle()
	next_id = 1
	intruders = 0
	alarm_armed = true
	running = true
	spawn_timer.start()

func _spawn_user() -> void:
	if not running or queue.is_empty():
		return

	var data: Dictionary = queue.pop_back()
	var template := USER_ROW.instantiate() as Control
	if template == null:
		push_error("user.tscn: la raiz debe ser un Control (por ejemplo HBoxContainer)")
		spawn_timer.stop()
		return

	# El usuario mas reciente queda justo debajo de los encabezados
	var entry := UserEntry.new(template, list, header_cells, next_id, data)
	entry.delete_pressed.connect(_on_delete_pressed)
	entries.append(entry)
	next_id += 1

	if entry.is_intruder:
		intruders += 1

	if queue.is_empty():
		spawn_timer.stop()

	_update_alarm()
	_check_win()

func _on_delete_pressed(entry: UserEntry) -> void:
	if not running:
		return

	if entry.is_intruder:
		intruders -= 1
	else:
		GameManager.lose_heart()     # eliminaste a un usuario legitimo

	entries.erase(entry)
	entry.remove()
	_update_alarm()
	_check_win()

# --- Alarma ---
func _update_alarm() -> void:
	if intruders > alarm_threshold and alarm_armed:
		alarm_armed = false
		_show_alarm()
	elif intruders <= alarm_threshold:
		alarm_armed = true
		_close_alarm()

func _show_alarm() -> void:
	if warn != null:
		return
	warn = WARN_SCENE.instantiate() as Node2D
	add_child(warn)
	if warn_marker:
		warn.global_position = warn_marker.global_position
	else:
		push_warning("UserSecurity: asigna Warn Marker en el Inspector")

	# Queda por debajo del efecto de pantalla vieja
	var effect := get_node_or_null("OldWindowEffect")
	if effect:
		move_child(warn, effect.get_index())

	var sfx := warn.get_node_or_null("warn_sfx") as AudioStreamPlayer
	if sfx:
		sfx.play()

	var sprite := warn.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames:
		var names := sprite.sprite_frames.get_animation_names()
		if names.size() > 0:
			sprite.play(names[0])

	var close_btn := warn.get_node_or_null("CloseWarn") as BaseButton
	if close_btn:
		close_btn.pressed.connect(_close_alarm)

func _close_alarm() -> void:
	if warn != null:
		warn.queue_free()
		warn = null

# --- Resultado ---
func _check_win() -> void:
	if running and queue.is_empty() and intruders <= 0:
		running = false
		_close_alarm()
		completed.emit()

func _on_game_over() -> void:
	if not running:
		return
	running = false
	spawn_timer.stop()
	_close_alarm()
	failed.emit()
