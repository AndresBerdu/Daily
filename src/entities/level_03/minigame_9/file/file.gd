class_name SortFile
extends Node2D

signal dropped(file: SortFile)     # el jugador soltó el archivo
signal removed(file: SortFile)     # ya se clasificó y desapareció

enum Kind { IMAGES, VIDEOS, ISO, VIRUS }

@export var follow_speed := 30.0       # qué tan pegado sigue al mouse
@export var return_speed := 900.0      # pixeles por segundo al regresar
@export var grab_scale := 1.15         # crece un poco al agarrarlo

@onready var state_machine: StateMachine = $StateMachine

var sprite: Sprite2D
var kind := Kind.IMAGES
var home_global := Vector2.ZERO
var grab_offset := Vector2.ZERO


func _ready() -> void:
	var sprites := find_children("*", "Sprite2D", true, false)
	if sprites.is_empty():
		push_error("file.tscn: necesita un Sprite2D")
		return
	sprite = sprites[0]


# La llama el juego después de colocar el archivo en el marcador
func setup(file_kind: Kind, texture: Texture2D) -> void:
	kind = file_kind
	home_global = global_position
	if texture:
		sprite.texture = texture


# --- Agarrar ---
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not is_idle() or not _mouse_over():
		return
	grab_offset = global_position - get_global_mouse_position()
	go("drag")


func _mouse_over() -> bool:
	if sprite == null:
		return false
	return sprite.get_rect().has_point(sprite.to_local(get_global_mouse_position()))


# --- Estados ---
func _state_name() -> StringName:
	var current := state_machine.current_state
	return current.name if current else &""


func is_idle() -> bool:
	return _state_name() == &"Idle"


func is_dragging() -> bool:
	return _state_name() == &"Drag"


func go(state_name: String) -> void:
	var current := state_machine.current_state
	if current:
		current.transitioned.emit(state_name)
