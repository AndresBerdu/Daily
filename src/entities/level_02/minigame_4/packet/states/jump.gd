extends State

var car: PacketCar:
	get: return actor as PacketCar

func enter() -> void:
	car.vy = car.jump_velocity
	car.play_anim("jump")
	car.jump_sfx.play()

func physics_update(delta: float) -> void:
	if not car.active:
		return
	car.vy += car.gravity * delta
	car.global_position.y += car.vy * delta

	if car.global_position.y >= car.floor_y:
		car.global_position.y = car.floor_y
		car.vy = 0.0
		# Si sigues manteniendo abajo al aterrizar, entra directo a encoger
		transitioned.emit("shrink" if Input.is_action_pressed("ui_down") else "drive")
