extends State

var file: SortFile:
	get: return actor as SortFile

func update(delta: float) -> void:
	file.global_position = file.global_position.move_toward(file.home_global, file.return_speed * delta)
	if file.global_position.is_equal_approx(file.home_global):
		transitioned.emit("idle")
