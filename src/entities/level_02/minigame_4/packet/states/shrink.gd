extends State

var car: PacketCar:
	get: return actor as PacketCar

func enter() -> void:
	car.set_shrunk(true)       # la colisión baja y el hook ya no lo toca
	car.play_anim("shrink")

func physics_update(_delta: float) -> void:
	if not car.active:
		return
	if not Input.is_action_pressed("ui_down"):
		transitioned.emit("enlarge")
