extends State

var tip: CableTip:
	get: return actor as CableTip

func update(delta: float) -> void:
	tip.global_position = tip.global_position.move_toward(tip.home_global, tip.return_speed * delta)
	if tip.global_position.is_equal_approx(tip.home_global):
		transitioned.emit("idle")
