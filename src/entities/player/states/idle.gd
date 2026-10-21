extends State

func enter() -> void:
	actor.velocity = Vector2.ZERO
	var anim: AnimationPlayer = actor.get_node("AnimationPlayer")
	var facing: String = actor.get_meta("facing", "d")  # "d" por defecto
	anim.play("idle_" + facing)

func physics_update(_delta: float) -> void:
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		transitioned.emit("walk")
