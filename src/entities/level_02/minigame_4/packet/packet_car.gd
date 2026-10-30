class_name PacketCar
extends CharacterBody2D

@export_group("Salto")
@export var jump_height := 60.0     # altura máxima en píxeles
@export var jump_time := 0.8        # segundos en el aire (antes eran 0.8)

@export_group("Encoger")
@export_range(0.2, 0.9) var shrink_height_ratio := 0.5

@onready var state_machine: StateMachine = $StateMachine
@onready var jump_sfx: AudioStreamPlayer = $JumpSfx
@onready var shrink_sfx: AudioStreamPlayer = $ShrinkSfx

var active := false
var vy := 0.0
var floor_y := 0.0
var gravity := 0.0
var jump_velocity := 0.0

var anim_player: AnimationPlayer
var anim_sprite: AnimatedSprite2D
var shape_node: CollisionShape2D
var rect: RectangleShape2D
var stand_size := Vector2.ZERO
var stand_pos := Vector2.ZERO

func _ready() -> void:
	add_to_group("packet_car")
	floor_y = global_position.y

	# Con altura h y tiempo T en el aire: v0 = 4h/T y g = 8h/T^2
	jump_velocity = -4.0 * jump_height / jump_time
	gravity = 8.0 * jump_height / (jump_time * jump_time)

	anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	anim_sprite = find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	_set_no_loop(["jump", "shrink", "enlarge"])

	shape_node = find_child("CollisionShape2D", true, false) as CollisionShape2D
	shape_node.shape = shape_node.shape.duplicate()
	rect = shape_node.shape as RectangleShape2D
	if rect == null:
		push_error("PacketCar: el CollisionShape2D debe usar un RectangleShape2D")
		return
	stand_size = rect.size
	stand_pos = shape_node.position

func start() -> void:
	reset()
	active = true
	var current := state_machine.current_state
	if current != null:
		current.transitioned.emit("drive")
	play_anim("drive")

func stop() -> void:
	active = false
	if anim_player:
		anim_player.pause()
	if anim_sprite:
		anim_sprite.pause()

func reset() -> void:
	global_position.y = floor_y
	vy = 0.0
	set_shrunk(false)

func set_shrunk(value: bool) -> void:
	if rect == null:
		return
	if value:
		rect.size = Vector2(stand_size.x, stand_size.y * shrink_height_ratio)
		shape_node.position = Vector2(
			stand_pos.x,
			stand_pos.y + (stand_size.y - rect.size.y) / 2.0
		)
	else:
		rect.size = stand_size
		shape_node.position = stand_pos

# fit_time > 0 estira o comprime la animación para que dure exactamente ese tiempo
func play_anim(anim_name: String, fit_time := 0.0) -> void:
	var speed := 1.0
	if fit_time > 0.0:
		var length := anim_length(anim_name)
		if length > 0.0:
			speed = length / fit_time

	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name, -1, speed)
	elif anim_sprite and anim_sprite.sprite_frames \
			and anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name, speed)

func anim_length(anim_name: String) -> float:
	if anim_player and anim_player.has_animation(anim_name):
		return anim_player.get_animation(anim_name).length
	if anim_sprite and anim_sprite.sprite_frames \
			and anim_sprite.sprite_frames.has_animation(anim_name):
		var frames := anim_sprite.sprite_frames
		var fps := frames.get_animation_speed(anim_name)
		return frames.get_frame_count(anim_name) / maxf(fps, 0.001)
	return 0.0

# Evita que estas animaciones se repitan: se quedan en su último frame
func _set_no_loop(names: Array) -> void:
	for n in names:
		if anim_player and anim_player.has_animation(n):
			anim_player.get_animation(n).loop_mode = Animation.LOOP_NONE
		if anim_sprite and anim_sprite.sprite_frames \
				and anim_sprite.sprite_frames.has_animation(n):
			anim_sprite.sprite_frames.set_animation_loop(n, false)
