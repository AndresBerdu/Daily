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
@export var screw_lift := 10.0
@export var screw_turns := 2.0

@export_group("Pista visual")
@export var hint_color := Color(1.0, 0.1, 0.1)
@export_range(0.0, 1.0) var weld_hint_alpha := 0.6   # opacidad de la marca de soldadura mientras parpadea (0 = sin pista)
@export_range(0.0, 1.0) var ghost_alpha := 0.4   # opacidad del tornillo fantasma al rearmar

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $InteractionArea
@onready var sfx: AudioStreamPlayer = $sfx              # tornillos
@onready var weld_sfx: AudioStreamPlayer = $weld_sfx    # soldaduras

var is_fixed := false
var busy := false
var reassembling := false
var origin_position := Vector2.ZERO
var hint_tween: Tween

func _ready() -> void:
	origin_position = sprite.position
	var tex := tex_screw if kind == Kind.SCREW else tex_weld
	if tex:
		sprite.texture = tex
	if kind == Kind.WELD:
		sprite.modulate.a = 0.0
	area.input_pickable = false
	area.input_event.connect(_on_input_event)

# Fase de desarmado: tornillos y soldaduras
func activate() -> void:
	if is_fixed:
		return
	area.input_pickable = true
	if kind == Kind.SCREW:
		hint_tween = Blink.pulse(sprite, "self_modulate", Color.WHITE, hint_color)
	elif weld_hint_alpha > 0.0:
		# La marca se ve y parpadea en rojo, igual que los tornillos
		sprite.modulate.a = weld_hint_alpha
		hint_tween = Blink.pulse(sprite, "self_modulate", Color.WHITE, hint_color)

# Fase final: el tornillo vuelve a su agujero como fantasma y hay que apretarlo
func activate_reassembly() -> void:
	if kind != Kind.SCREW:
		return
	is_fixed = false
	busy = false
	reassembling = true
	sprite.position = origin_position
	sprite.rotation = 0.0
	sprite.modulate.a = ghost_alpha
	area.input_pickable = true
	hint_tween = Blink.pulse(sprite, "self_modulate", Color.WHITE, hint_color)

func _on_input_event(_vp: Node, event: InputEvent, _idx: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if is_fixed or busy:
		return
	_start_fix()

func _start_fix() -> void:
	busy = true
	area.input_pickable = false
	(sfx if kind == Kind.SCREW else weld_sfx).play()

	Blink.stop(hint_tween, sprite, "self_modulate", Color.WHITE)

	fix_started.emit(self, fix_duration)

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	if kind == Kind.SCREW and reassembling:
		# Apretar: parte de arriba y gira al revés mientras baja
		sprite.position = origin_position + Vector2(0, -screw_lift)
		sprite.rotation = TAU * screw_turns
		tween.tween_property(sprite, "rotation", 0.0, fix_duration)
		tween.tween_property(sprite, "position", origin_position, fix_duration)
		tween.tween_property(sprite, "modulate:a", 1.0, fix_duration)
	elif kind == Kind.SCREW:
		# Aflojar: gira, sube y se desvanece
		tween.tween_property(sprite, "rotation", TAU * screw_turns, fix_duration)
		tween.tween_property(sprite, "position:y", sprite.position.y - screw_lift, fix_duration)
		tween.tween_property(sprite, "modulate:a", 0.0, fix_duration)
	else:
		# Soldadura: aparece con un fundido
		tween.tween_property(sprite, "modulate:a", 1.0, fix_duration)
	await tween.finished

	is_fixed = true
	busy = false
	fixed.emit(self)
