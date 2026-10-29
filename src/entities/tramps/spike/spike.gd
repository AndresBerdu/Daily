class_name Spike
extends Node2D

@export_group("Tiempos (segundos)")
@export var down_time := 2.0       # escondidos: el jugador puede pasar
@export var warning_time := 0.4    # subiendo: aviso, todavia no hace dano
@export var up_time := 1.0         # afuera: hace dano
@export var lower_time := 0.2      # bajando
@export var start_delay := 0.0     # espera extra solo en el primer ciclo (desfasa la fila)

@export_group("Hoja de animacion")
@export var sheet: Texture2D                     # la tira completa de frames
@export var frame_count := 14                    # cuantos frames tiene la tira
@export var fps := 12.0
@export var down_range := Vector2i(0, 5)         # primer y ultimo frame (inclusive) de "down"
@export var rise_range := Vector2i(6, 8)         # frames de la transicion al subir
@export var up_range := Vector2i(9, 13)          # frames de "up"

@export_group("Dano")
@export var damage := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea


var first_cycle := true

func _ready() -> void:
	if sheet:
		sprite.sprite_frames = _build_frames()

	# Las animaciones de transicion se reproducen una sola vez
	var frames := sprite.sprite_frames
	if frames:
		for anim_name in ["rise", "lower"]:
			if frames.has_animation(anim_name):
				frames.set_animation_loop(anim_name, false)


# Crea el SpriteFrames cortando la tira en frames del mismo ancho
func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var width := sheet.get_width() / frame_count
	if width * frame_count != sheet.get_width():
		push_warning("Spike: el ancho de la hoja no es divisible entre frame_count (%d)" % frame_count)

	_add_anim(frames, "down", down_range, width, true)
	_add_anim(frames, "rise", rise_range, width, false)
	_add_anim(frames, "up", up_range, width, true)

	# "lower" es "rise" al reves
	_add_anim(frames, "lower", Vector2i(rise_range.y, rise_range.x), width, false)
	return frames


# first > last reproduce la animacion al reves
func _add_anim(frames: SpriteFrames, anim_name: String, range: Vector2i, width: int, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)

	var step := 1 if range.y >= range.x else -1
	var i := range.x
	while true:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * width, 0, width, sheet.get_height())
		frames.add_frame(anim_name, atlas)
		if i == range.y:
			break
		i += step

# fit_time > 0 estira o comprime la animacion para que dure justo ese tiempo
func play_anim(anim_name: String, fit_time := 0.0) -> void:
	var frames := sprite.sprite_frames
	
	if frames == null or not frames.has_animation(anim_name):
		return

	var speed := 1.0
	if fit_time > 0.0:
		var length := frames.get_frame_count(anim_name) / maxf(frames.get_animation_speed(anim_name), 0.001)
		speed = length / fit_time
	sprite.play(anim_name, speed)

# Si el jugador esta sobre el pincho, le hace dano
func hurt_overlapping() -> void:
	for body in damage_area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(damage)
