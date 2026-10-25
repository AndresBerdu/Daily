extends State

var packet: BeltPacket:
	get: return actor as BeltPacket

var done := false

func enter() -> void:
	done = false
	packet.exit_left = packet.exit_time

func update(delta: float) -> void:
	if done:
		return
	var follower := packet.get_parent() as PathFollow2D
	if follower == null:
		return

	packet.exit_left -= delta
	follower.progress_ratio = clampf(1.0 - packet.exit_left / packet.exit_time, 0.0, 1.0)
	if packet.exit_left <= 0.0:
		done = true
		packet.finished.emit(packet)
