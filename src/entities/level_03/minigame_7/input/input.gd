class_name CableInput
extends Node2D

@export var plug_offset := Vector2.ZERO   # ajusta donde queda el plug al conectarse

@onready var sprite: Sprite2D = $Sprite2D

var color_id := -1
var occupied := false

func setup(id: int, color: Color, texture: Texture2D = null) -> void:
	color_id = id
	if texture:
		sprite.texture = texture
	else:
		sprite.self_modulate = color

func plug_position() -> Vector2:
	return global_position + plug_offset
