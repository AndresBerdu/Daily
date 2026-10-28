class_name OutfitSheets
extends Resource

@export_group("Idle")
@export var idle_down: Texture2D
@export var idle_up: Texture2D
@export var idle_side: Texture2D

@export_group("Walk")
@export var walk_down: Texture2D
@export var walk_up: Texture2D
@export var walk_side: Texture2D

# action: "idle" o "walk"; facing: "d", "u" o "h"
func get_sheet(action: String, facing: String) -> Texture2D:
	var tex: Texture2D = null
	if action == "walk":
		match facing:
			"u": tex = walk_up
			"h": tex = walk_side
			_: tex = walk_down
		if tex != null:
			return tex          # si falta la de walk, cae a la de idle
	match facing:
		"u": return idle_up
		"h": return idle_side
		_: return idle_down
