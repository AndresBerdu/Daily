extends State

func enter() -> void:
	actor.velocity = Vector2.ZERO # Empieza quieto
	var anim: AnimationPlayer = actor.get_node("AnimationPlayer") # Nodo de animación
	var facing: String = actor.get_meta("facing", "d")  # "d" por defecto (down)
	anim.play("idle_" + facing) # Reproduce la animacion por defecto

# Actualización de las fisicas del jugador a otro estado 
func physics_update(_delta: float) -> void:
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO:
		transitioned.emit("walk")
