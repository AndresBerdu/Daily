class_name BoardPlaceholder
extends Node2D

signal fix_started(placeholder: BoardPlaceholder, duration: float)
signal fixed(placeholder: BoardPlaceholder)

enum Kind { SCREW, WELD }

@export var kind := Kind.SCREW
@export var tex_screw: Texture2D
@export var tex_weld: Texture2D

@export_group("Animación")
@export var fix_duration := 0.9
@export var screw_lift := 10.0     # píxeles que sube el tornillo
@export var screw_turns := 2.0     # vueltas que da

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $InteractionArea

var is_fixed := false
var busy := false

func _ready() -> void:
	var tex := tex_screw if kind == Kind.SCREW else tex_weld
	if tex:
		sprite.texture = tex
	area.input_event.connect(_on_input_event)

func _on_input_event(_vp: Node, event: InputEvent, _idx: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if is_fixed or busy:
		return
	_start_fix()

func _start_fix() -> void:
	busy = true
	fix_started.emit(self, fix_duration)

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	if kind == Kind.SCREW:
		tween.tween_property(sprite, "rotation", TAU * screw_turns, fix_duration)
		tween.tween_property(sprite, "position:y", sprite.position.y - screw_lift, fix_duration)
	tween.tween_property(sprite, "modulate:a", 0.0, fix_duration)  # ambos se desvanecen
	await tween.finished

	is_fixed = true
	busy = false
	area.input_pickable = false
	fixed.emit(self)
