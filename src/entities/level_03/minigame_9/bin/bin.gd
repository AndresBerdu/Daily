class_name SortBin
extends Node2D

@export var accepts := SortFile.Kind.IMAGES   # que tipo de dato recibe este contenedor
@export var bin_texture: Texture2D              # su imagen (opcional)
@export var drop_margin := 6.0                  # tolerancia extra alrededor del contenedor

var sprite: Sprite2D


func _ready() -> void:
	var sprites := find_children("*", "Sprite2D", true, false)
	if sprites.is_empty():
		push_error("%s: necesita un Sprite2D" % name)
		return
	sprite = sprites[0]
	if bin_texture:
		sprite.texture = bin_texture


# true si el punto (global) cae sobre el contenedor
func contains(point: Vector2) -> bool:
	if sprite == null:
		return false
	var rect := sprite.get_rect().grow(drop_margin)
	return rect.has_point(sprite.to_local(point))


# Resalta el contenedor mientras se arrastra un archivo sobre el
func set_hover(value: bool) -> void:
	if sprite:
		sprite.modulate = Color(1.3, 1.3, 1.3) if value else Color.WHITE
