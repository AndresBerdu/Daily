extends State

var file: SortFile:
	get: return actor as SortFile

func enter() -> void:
	file.z_index = 10                                   # por encima de los contenedores
	file.scale = Vector2.ONE * file.grab_scale

func exit() -> void:
	file.z_index = 0
	# la escala la restaura el siguiente estado; en Sorted solo se desvanece
	if file.is_idle() or true:
		pass

func update(delta: float) -> void:
	var goal := file.get_global_mouse_position() + file.grab_offset
	file.global_position = file.global_position.lerp(goal, 1.0 - exp(-file.follow_speed * delta))

	# Al soltar el boton, el juego decide: clasificar o regresar
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		file.dropped.emit(file)
		if file.is_dragging():          # si nadie lo movio de estado, regresa
			transitioned.emit("return")
