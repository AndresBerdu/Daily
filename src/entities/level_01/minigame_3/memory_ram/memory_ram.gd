class_name BoardRam
extends Node2D

signal seated(ram: BoardRam)

enum State { OLD, MOVING, WAITING_SEAT, DONE }

var put_new_ram = load("res://assets/audio/sfx/put_ram_sfx.ogg")

@export var new_texture: Texture2D = preload("res://assets/sprites/items/tools/new_memory_ram.png")    # new_memory_ram
@export var lift_distance := 40.0
@export var move_time := 0.35

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $InteractionArea
@onready var ram_sfx: AudioStreamPlayer = $ram_sfx

var state := State.OLD
var home_position := Vector2.ZERO

func _ready() -> void:
	home_position = position
	area.input_event.connect(_on_input_event)

func _on_input_event(_vp: Node, event: InputEvent, _idx: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	match state:
		State.OLD:
			_lift()
		State.WAITING_SEAT:
			_seat()

func _lift() -> void:
	state = State.MOVING
	ram_sfx.play()
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", home_position.y - lift_distance, move_time)
	await tween.finished
	if new_texture:
		sprite.texture = new_texture
	state = State.WAITING_SEAT

func _seat() -> void:
	state = State.MOVING
	ram_sfx.stream = put_new_ram
	ram_sfx.play()
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", home_position, move_time)
	await tween.finished
	state = State.DONE
	area.input_pickable = false
	seated.emit(self)
