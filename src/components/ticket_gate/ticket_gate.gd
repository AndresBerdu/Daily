extends Node2D
class_name TicketGate

@export var sprite_open: Texture2D = preload("res://assets/sprites/props/ticket_gate/ticket_gate_open.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var permission_collision: CollisionShape2D = $PermissionShape

var is_open:= false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func open_ticket_gate() -> void:
	sprite.texture = sprite_open
	permission_collision.set_deferred("disabled", true)
