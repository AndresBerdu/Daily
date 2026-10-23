class_name Swab
extends Node2D

@onready var cleaner_area: Area2D = $CleanerArea       # la punta
@onready var grab_area: Area2D = $InteractionArea      # el palito

var dragging := false
var move_delta := 0.0          # píxeles movidos en este frame
var home_position := Vector2.ZERO

var _grab_offset := Vector2.ZERO
var _last_pos := Vector2.ZERO

func _ready() -> void:
	home_position = global_position
	_last_pos = global_position
	grab_area.input_event.connect(_on_grab_input)
	cleaner_area.input_event.connect(_on_grab_input)   # también se puede agarrar por la punta

func _on_grab_input(_vp: Node, event: InputEvent, _idx: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if dragging:
		return
	dragging = true
	_grab_offset = global_position - get_global_mouse_position()
	_last_pos = global_position

func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if dragging and mb and not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		dragging = false
		var tween := create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "global_position", home_position, 0.25)

func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + _grab_offset
		move_delta = global_position.distance_to(_last_pos)
	else:
		move_delta = 0.0
	_last_pos = global_position
