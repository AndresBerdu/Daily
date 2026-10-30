extends State
## El jugador se queda quieto mientras PlayerControl lo mantenga congelado
## (dialogos, minijuegos abiertos, transiciones...).

func enter() -> void:
	actor.velocity = Vector2.ZERO
	var facing: String = actor.get_meta("facing", "d")
	actor.get_node("AnimationPlayer").play("idle_" + facing)

func update(_delta: float) -> void:
	if not PlayerControl.is_frozen():
		transitioned.emit("idle")
