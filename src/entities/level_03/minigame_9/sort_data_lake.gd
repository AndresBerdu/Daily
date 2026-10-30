class_name SortDataLake
extends Node2D

signal completed                                 # 20 datos buenos clasificados
signal failed                                    # te quedaste sin corazones
signal progress_changed(current: int, total: int)

@export var file_scene: PackedScene              # file.tscn
@export_group("Texturas")
@export var images_texture: Texture2D          # archivos de tipo Images
@export var videos_texture: Texture2D          # archivos de tipo Videos
@export var iso_texture: Texture2D             # archivos de tipo ISO
@export var virus_textures: Array[Texture2D]   # hasta 3 variantes de virus
@export_group("Reglas")
@export var good_needed := 20
@export_range(0.0, 1.0) var bad_chance := 0.3    # probabilidad de que salga un dato dañino
@export var wrong_costs_heart := true
@export var next_delay := 0.25                   # pausa entre un archivo y el siguiente
@export var auto_start := false

@onready var spawn_marker: Marker2D = $SpawnFiles
@onready var correct_bit_sfx: AudioStreamPlayer = $CorrectBitSfx
@onready var bad_bit_sfx: AudioStreamPlayer = $BadBitSfx
@onready var bins_node: Node = $bins     # contenedor de los cuatro SortBin

var bins: Array[SortBin] = []
var current_file: SortFile = null
var sorted_good := 0
var running := false
var finishing := false


func _ready() -> void:
	for child in bins_node.get_children():
		var bin := child as SortBin
		if bin:
			bins.append(bin)
		else:
			push_warning("%s no tiene sort_bin.gd, se ignora" % child.name)

	GameManager.game_over.connect(_on_game_over)

	if auto_start:
		start()


func start() -> void:
	if file_scene == null or bins.is_empty():
		push_error("SortDataLake: asigna File Scene y revisa los contenedores")
		return
	sorted_good = 0
	finishing = false
	running = true
	progress_changed.emit(sorted_good, good_needed)
	_spawn_file()


# --- Aparicion de archivos ---
func _spawn_file() -> void:
	if not running:
		return

	var kind: SortFile.Kind
	var texture: Texture2D = null

	if randf() < bad_chance and not virus_textures.is_empty():
		kind = SortFile.Kind.VIRUS
		texture = virus_textures.pick_random()
	else:
		# Uno de los tres tipos buenos, al azar
		kind = [SortFile.Kind.IMAGES, SortFile.Kind.VIDEOS, SortFile.Kind.ISO].pick_random()
		match kind:
			SortFile.Kind.IMAGES: texture = images_texture
			SortFile.Kind.VIDEOS: texture = videos_texture
			SortFile.Kind.ISO: texture = iso_texture

	var instance := file_scene.instantiate()
	var file := instance as SortFile
	if file == null:
		push_error("file.tscn: la raiz debe tener sort_file.gd")
		instance.queue_free()
		return

	add_child(file)
	file.global_position = spawn_marker.global_position
	file.setup(kind, texture)
	file.dropped.connect(_on_dropped)
	file.removed.connect(_on_file_removed)
	current_file = file

	var effect := get_node_or_null("OldWindoeEffect")
	if effect:
		move_child(file, effect.get_index())


# --- Clasificar ---
func _on_dropped(file: SortFile) -> void:
	_clear_hover()
	var bin := _bin_at(file.global_position)

	if bin == null:
		file.go("return")                   # solto fuera de los contenedores: sin castigo
		return

	if bin.accepts == file.kind:
		correct_bit_sfx.play()
		if file.kind != SortFile.Kind.VIRUS:
			sorted_good += 1
			progress_changed.emit(sorted_good, good_needed)
			if sorted_good >= good_needed:
				finishing = true
		file.go("sorted")
	else:
		file.go("return")
		bad_bit_sfx.play()
		if wrong_costs_heart:
			GameManager.lose_heart()


func _bin_at(point: Vector2) -> SortBin:
	for bin in bins:
		if bin.contains(point):
			return bin
	return null


func _on_file_removed(_file: SortFile) -> void:
	current_file = null
	if finishing:
		running = false
		completed.emit()
		return

	await get_tree().create_timer(next_delay).timeout
	if running:
		_spawn_file()


# Resalta el contenedor bajo el archivo que se esta arrastrando
func _process(_delta: float) -> void:
	if current_file == null or not is_instance_valid(current_file) or not current_file.is_dragging():
		return
	for bin in bins:
		bin.set_hover(bin.contains(current_file.global_position))


func _clear_hover() -> void:
	for bin in bins:
		bin.set_hover(false)


# --- Derrota ---
func _on_game_over() -> void:
	if not running:
		return
	running = false
	finishing = false
	if is_instance_valid(current_file):
		current_file.queue_free()
	current_file = null
	_clear_hover()
	failed.emit()


# Rectangulo del monitor, para que el PC lo centre en pantalla
func get_board_rect() -> Rect2:
	var frame := $Window as Sprite2D
	var r := frame.get_rect()
	return Rect2(frame.position + r.position * frame.scale, r.size * frame.scale)
