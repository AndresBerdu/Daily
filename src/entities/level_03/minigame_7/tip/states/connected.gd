extends State

var tip: CableTip:
	get: return actor as CableTip

func enter() -> void:
	tip.global_position = tip.target_input.plug_position()   # queda enchufado
	tip.target_input.occupied = true
	tip.plugged.emit(tip)
