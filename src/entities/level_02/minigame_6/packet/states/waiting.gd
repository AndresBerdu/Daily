extends State

var packet: BeltPacket:
	get: return actor as BeltPacket

func enter() -> void:
	packet.time_left = packet.decide_time
	packet.label_time.show()
	packet.watch.show()
	packet.update_time_label()
	packet.reached_center.emit(packet)

func update(delta: float) -> void:
	# Si ya se decidio, solo espera a que lo muevan al otro camino
	if packet.decision != BeltPacket.Decision.NONE:
		return

	packet.time_left -= delta
	packet.update_time_label()
	if packet.time_left <= 0.0:
		packet.time_left = 0.0
		packet.timed_out.emit(packet)
