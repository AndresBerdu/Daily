class_name BoardCpu
extends Node2D

signal finished

enum Phase { OLD_GREASE, BUSY, ALCOHOL_APPLIED, CLEANED, DONE }

@export var rub_distance_needed := 500.0   # píxeles que hay que frotar
@export var alcohol_alpha := 0.7           # opacidad del alcohol
@export var fade_time := 0.5

@onready var old_grease: Sprite2D = $OldTermalGrease
@onready var alcohol: Sprite2D = $Alchol
@onready var new_grease: Sprite2D = $NewTermalGrease
@onready var area: Area2D = $InteractionArea

var swab: Swab                  # lo asigna MotherboardGame
var phase := Phase.OLD_GREASE
var progress := 0.0

func _ready() -> void:
	old_grease.show()
	old_grease.modulate.a = 1.0
	alcohol.show()
	alcohol.modulate.a = 0.0
	new_grease.show()
	new_grease.modulate.a = 0.0
	area.input_event.connect(_on_input_event)

func _on_input_event(_vp: Node, event: InputEvent, _idx: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if swab and swab.dragging:
		return
	match phase:
		Phase.OLD_GREASE:
			_apply_alcohol()
		Phase.CLEANED:
			_apply_new_grease()

func _apply_alcohol() -> void:
	phase = Phase.BUSY
	var tween := create_tween()
	tween.tween_property(alcohol, "modulate:a", alcohol_alpha, fade_time)
	await tween.finished
	phase = Phase.ALCOHOL_APPLIED

func _process(_delta: float) -> void:
	if phase != Phase.ALCOHOL_APPLIED or swab == null or not swab.dragging:
		return
	if not swab.cleaner_area.overlaps_area(area):
		return

	# Cada píxel frotado sobre la CPU avanza la limpieza
	progress = minf(1.0, progress + swab.move_delta / rub_distance_needed)
	old_grease.modulate.a = 1.0 - progress
	alcohol.modulate.a = alcohol_alpha * (1.0 - progress)

	if progress >= 1.0:
		phase = Phase.CLEANED

func _apply_new_grease() -> void:
	phase = Phase.BUSY
	var tween := create_tween()
	tween.tween_property(new_grease, "modulate:a", 1.0, fade_time)
	await tween.finished
	phase = Phase.DONE
	area.input_pickable = false
	finished.emit()
