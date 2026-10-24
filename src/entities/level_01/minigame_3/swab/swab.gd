class_name Swab
extends Node2D

@export var hint_color := Color(1.0, 0.1, 0.1)

@onready var sprite: Sprite2D = $Sprite2D
@onready var cleaner_area: Area2D = $CleanerArea      # la punta
@onready var grab_area: Area2D = $InteractionArea     # el palito

var dragging := false
var needed := false            # true cuando el jugador debe usarlo
var move_delta := 0.0
var home_position := Vector2.ZERO
var hint_tween: Tween

var _grab_offset := Vector2.ZERO
var _last_pos := Vector2.ZERO

func _ready() -> void:
	home_position = global_position
	_last_pos = global_position
	grab_area.input_event.connect(_on_grab_input)
	cleaner_area.input_event.connect(_on_grab_input)
	_set_pickable(false)       # bloqueado hasta que la CPU lo necesite

# La CPU lo activa o desactiva según la fase
func set_needed(value: bool) -> void:
	needed = value
	_set_pickable(value)
	if not value and dragging:
		_drop()
	else:
		_refresh_hint()

func _set_pickable(value: bool) -> void:
	grab_area.input_pickable = value
	cleaner_area.input_pickable = value

# Parpadea solo cuando hace falta y nadie lo está sosteniendo
func _refresh_hint() -> void:
	Blink.stop(hint_tween, sprite, "self_modulate", Color.WHITE)
	hint_tween = null
	if needed and not dragging:
		hint_tween = Blink.pulse(sprite, "self_modulate", Color.WHITE, hint_color)

func _on_grab_input(_vp: Node, event: InputEvent, _idx: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if dragging or not needed:
		return
	dragging = true
	_grab_offset = global_position - get_global_mouse_position()
	_last_pos = global_position
	_refresh_hint()

func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if dragging and mb and not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_drop()

func _drop() -> void:
	dragging = false
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position", home_position, 0.25)
	_refresh_hint()            # si todavía hace falta, vuelve a parpadear

func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + _grab_offset
		move_delta = global_position.distance_to(_last_pos)
	else:
		move_delta = 0.0
	_last_pos = global_position
