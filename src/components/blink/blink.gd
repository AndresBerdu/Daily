class_name Blink
extends RefCounted

# Hace pulsar una propiedad entre "from" y "to".
# seconds = 0 significa que parpadea hasta que se detenga a mano.
static func pulse(node: Node, property: String, from: Variant, to: Variant,
		seconds := 0.0, half_period := 0.4) -> Tween:
	node.set_indexed(NodePath(property), from)
	var tween := node.create_tween()
	if seconds > 0.0:
		tween.set_loops(maxi(1, ceili(seconds / (half_period * 2.0))))
	else:
		tween.set_loops()   # infinito
	tween.tween_property(node, NodePath(property), to, half_period).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, NodePath(property), from, half_period).set_trans(Tween.TRANS_SINE)
	return tween

# Detiene el parpadeo. Si pasas "rest", la propiedad vuelve a ese valor.
static func stop(tween: Tween, node: Node, property: String, rest: Variant = null) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
	if rest != null and is_instance_valid(node):
		node.set_indexed(NodePath(property), rest)
