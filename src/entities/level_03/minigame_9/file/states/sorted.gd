extends State

var file: SortFile:
	get: return actor as SortFile

func enter() -> void:
	file.z_index = 5
	file.global_position = file.global_position       # se queda donde se solto

	var tween := file.create_tween()
	tween.tween_property(file, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		file.removed.emit(file)
		file.queue_free()
	)
