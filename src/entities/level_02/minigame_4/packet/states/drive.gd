extends State

var car: PacketCar:
	get: return actor as PacketCar

func enter() -> void:
	car.play_anim("drive")

func physics_update(_delta: float) -> void:
	if not car.active:
		return
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up"):
		transitioned.emit("jump")
	elif Input.is_action_pressed("ui_down"):
		transitioned.emit("shrink")
