extends State

var spike: Spike:
	get: return actor as Spike

var time_left := 0.0

func enter() -> void:
	time_left = spike.up_time
	spike.play_anim("up")

func physics_update(_delta: float) -> void:
	spike.hurt_overlapping()      # cubre al jugador que ya estaba encima y al que entra

func update(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		transitioned.emit("lowering")
