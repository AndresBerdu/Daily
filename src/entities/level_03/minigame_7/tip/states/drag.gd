extends State

var tip: CableTip:
	get: return actor as CableTip

func enter() -> void:
	tip.set_layer(10)            # el plug arrastrado queda por encima de todo

func exit() -> void:
	tip.set_layer(tip.base_z)    # vuelve a su capa normal, aun sobre los puertos
	tip.released.emit(tip)

func update(delta: float) -> void:
	var goal := tip.apply_magnet(tip.get_global_mouse_position() + tip.grab_offset)

	# Al soltar el boton, decide: conectar o regresar
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		transitioned.emit("connected" if tip.can_connect(goal) else "return")
		return

	tip.global_position = tip.global_position.lerp(goal, 1.0 - exp(-tip.follow_speed * delta))
