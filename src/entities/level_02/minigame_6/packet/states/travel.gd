extends State

var packet: BeltPacket:
	get: return actor as BeltPacket

func update(delta: float) -> void:
	var follower := packet.get_parent() as PathFollow2D
	
	if follower == null:
		return

	follower.progress = move_toward(follower.progress, packet.target_progress, packet.speed * delta)

	# Llego al final real del camino principal
	var end := packet.path_length - 0.5
	if packet.target_progress >= end and follower.progress >= end:
		transitioned.emit("waiting")
