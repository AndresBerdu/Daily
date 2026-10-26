class_name CountryFlag
extends Node2D

func setup(texture: Texture2D, country_name: String) -> void:
	var sprite := find_child("Sprite2D", true, false) as Sprite2D
	if sprite and texture:
		sprite.texture = texture

	var labels := find_children("*", "Label", true, false)
	if not labels.is_empty():
		(labels[0] as Label).text = country_name

	# Aparece con un fundido
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
