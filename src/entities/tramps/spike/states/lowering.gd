extends State

var spike: Spike:
	get: return actor as Spike

var time_left := 0.0

func enter() -> void:
	time_left = spike.lower_time
	spike.play_anim("lower", spike.lower_time)

func update(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		transitioned.emit("down")
