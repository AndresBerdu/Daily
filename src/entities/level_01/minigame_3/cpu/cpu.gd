class_name BoardCpu
extends Node2D

signal finished

enum Phase { INACTIVE, OLD_GREASE, BUSY, ALCOHOL_APPLIED, CLEANED, DONE }

@export var rub_distance_needed := 500.0
@export var alcohol_alpha := 0.7
@export var fade_time := 0.5
@export var hint_color := Color(1.0, 0.1, 0.1)

@onready var base: Sprite2D = $Sprite2D
@onready var old_grease: Sprite2D = $OldTermalGrease
@onready var alcohol: Sprite2D = $Alchol
@onready var new_grease: Sprite2D = $NewTermalGrease
@onready var area: Area2D = $InteractionArea
@onready var alcohol_sfx: AudioStreamPlayer = $AlcoholSfx            # al echar el alcohol
@onready var remove_grease_sfx: AudioStreamPlayer = $RemoveGreaseSfx  # mientras frotas con el bastoncillo
@onready var new_grease_sfx: AudioStreamPlayer = $NewGreaseSfx        # al poner la pasta nueva

var swab: Swab                   # lo asigna motherboard.gd
var phase := Phase.INACTIVE
var progress := 0.0
var hint_tween: Tween

func _ready() -> void:
	old_grease.show()
	old_grease.modulate.a = 1.0
	alcohol.show()
	alcohol.modulate.a = 0.0
	new_grease.show()
	new_grease.modulate.a = 0.0
	area.input_pickable = false
	area.input_event.connect(_on_input_event)

# La llama motherboard.gd cuando empieza la fase de la CPU
func activate() -> void:
	if phase != Phase.INACTIVE:
		return
	phase = Phase.OLD_GREASE
	area.input_pickable = true
	_start_hint()

func _start_hint() -> void:
	hint_tween = Blink.pulse(base, "self_modulate", Color.WHITE, hint_color)

func _stop_hint() -> void:
	Blink.stop(hint_tween, base, "self_modulate", Color.WHITE)

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
	_stop_hint()
	phase = Phase.BUSY
	alcohol_sfx.play()
	var tween := create_tween()
	tween.tween_property(alcohol, "modulate:a", alcohol_alpha, fade_time)
	await tween.finished
	phase = Phase.ALCOHOL_APPLIED
	swab.set_needed(true)            # ahora el bastoncillo se desbloquea y parpadea

func _process(_delta: float) -> void:
	var rubbing := phase == Phase.ALCOHOL_APPLIED and swab != null and swab.dragging \
			and swab.move_delta > 0.5 and swab.cleaner_area.overlaps_area(area)
	_update_rub_sound(rubbing)
	if not rubbing:
		return

	progress = minf(1.0, progress + swab.move_delta / rub_distance_needed)
	old_grease.modulate.a = 1.0 - progress
	alcohol.modulate.a = alcohol_alpha * (1.0 - progress)

	if progress >= 1.0:
		_stop_rub_sound()
		phase = Phase.CLEANED
		swab.set_needed(false)       # el bastoncillo vuelve a su sitio y se bloquea
		_start_hint()                # la CPU parpadea: falta la pasta nueva

# El sonido de frotar suena solo mientras el bastoncillo se mueve sobre la CPU
func _update_rub_sound(rubbing: bool) -> void:
	if rubbing:
		remove_grease_sfx.stream_paused = false
		if not remove_grease_sfx.playing:
			remove_grease_sfx.play()
	elif remove_grease_sfx.playing:
		remove_grease_sfx.stream_paused = true

func _stop_rub_sound() -> void:
	remove_grease_sfx.stream_paused = false
	remove_grease_sfx.stop()

func _apply_new_grease() -> void:
	_stop_hint()
	phase = Phase.BUSY
	new_grease_sfx.play()
	var tween := create_tween()
	tween.tween_property(new_grease, "modulate:a", 1.0, fade_time)
	await tween.finished
	phase = Phase.DONE
	area.input_pickable = false
	finished.emit()
