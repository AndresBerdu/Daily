extends State

var car: PacketCar:
	get: return actor as PacketCar

var time_left := 0.0

func enter() -> void:
	car.set_shrunk(false)      # la colisión vuelve a su tamaño normal
	car.play_anim("enlarge")
	time_left = car.anim_length("enlarge")

func physics_update(delta: float) -> void:
	if not car.active:
		return
	if Input.is_action_pressed("ui_down"):
		transitioned.emit("shrink")   # volvió a presionar abajo antes de terminar
		return
	time_left -= delta
	if time_left <= 0.0:
		transitioned.emit("drive")
