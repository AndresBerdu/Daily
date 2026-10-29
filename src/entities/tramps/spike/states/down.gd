extends State

var spike: Spike:
	get: return actor as Spike

var time_left := 0.0
var armed := false

func enter() -> void:
	spike.play_anim("down")
	armed = false

func update(delta: float) -> void:
	# El tiempo se calcula en el primer frame, para que SpikeRow ya haya configurado los valores
	if not armed:
		armed = true
		time_left = spike.down_time
		if spike.first_cycle:
			time_left += spike.start_delay
			spike.first_cycle = false

	time_left -= delta
	if time_left <= 0.0:
		transitioned.emit("rising")
