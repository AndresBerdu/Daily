extends State

const SPEED := 120.0

@onready var walk_audio: AudioStreamPlayer = $"../../WalkAudio"

func physics_update(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if dir == Vector2.ZERO:
		transitioned.emit("idle")
		return

	var sprite: Sprite2D = actor.get_node("Sprite2D")
	var anim: AnimationPlayer = actor.get_node("AnimationPlayer")

	if dir.x != 0:
		sprite.flip_h = dir.x < 0
		anim.play("walk_h")
		actor.set_meta("facing", "h")
	elif dir.y < 0:
		anim.play("walk_u")
		actor.set_meta("facing", "u")
	else:
		anim.play("walk_d")
		actor.set_meta("facing", "d")

	actor.velocity = dir * SPEED
	actor.move_and_slide()
