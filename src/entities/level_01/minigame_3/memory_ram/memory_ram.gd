class_name BoardRam
extends Node2D

signal seated(ram: BoardRam)

enum State { INACTIVE, OLD, MOVING, WAITING_SEAT, DONE }

@export var new_texture: Texture2D = preload("res://assets/sprites/items/tools/new_memory_ram.png")
@export var lift_distance := 40.0
@export var move_time := 0.35

@export_group("Pista visual")
@export var hint_seconds := 4.0     # 0 = parpadea hasta que hagas clic
@export var hint_color := Color(1.0, 0.1, 0.1)

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $InteractionArea
@onready var remove_sfx: AudioStreamPlayer = $ram_sfx        # al sacar la memoria
@onready var put_sfx: AudioStreamPlayer = $put_ram_sfx      # al volver a ponerla

var state := State.INACTIVE
var home_position := Vector2.ZERO
var hint_tween: Tween

func _ready() -> void:
	home_position = position
	area.input_pickable = false
	area.input_event.connect(_on_input_event)

# La llama motherboard.gd cuando empieza la fase de las memorias
func activate() -> void:
	if state != State.INACTIVE:
		return
	state = State.OLD
	area.input_pickable = true
	_start_hint()

func _start_hint() -> void:
	hint_tween = Blink.pulse(sprite, "self_modulate", Color.WHITE, hint_color, hint_seconds)

func _stop_hint() -> void:
	Blink.stop(hint_tween, sprite, "self_modulate", Color.WHITE)

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
	_stop_hint()
	state = State.MOVING
	remove_sfx.play()
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", home_position.y - lift_distance, move_time)
	await tween.finished
	if new_texture:
		sprite.texture = new_texture
	state = State.WAITING_SEAT
	_start_hint()                    # parpadea otra vez: falta devolverla a su lugar

func _seat() -> void:
	_stop_hint()
	state = State.MOVING
	put_sfx.play()
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", home_position, move_time)
	await tween.finished
	state = State.DONE
	area.input_pickable = false
	seated.emit(self)
