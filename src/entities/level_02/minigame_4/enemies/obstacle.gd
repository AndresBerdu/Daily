class_name PacketObstacle
extends Area2D

signal hit

var speed := 0.0
var despawn_x := -INF

func _ready() -> void:
	add_to_group("packet_obstacle")
	body_entered.connect(_on_body_entered)
	_play_animation()

func _play_animation() -> void:
	for child in get_children():
		var sprite := child as AnimatedSprite2D
		if sprite == null or sprite.sprite_frames == null:
			continue
		if sprite.sprite_frames.has_animation("run"):
			sprite.play("run")
		else:
			sprite.play()   # el hook usa su animación por defecto

func set_speed(value: float) -> void:
	speed = value

func _process(delta: float) -> void:
	global_position.x -= speed * delta
	if global_position.x < despawn_x:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("packet_car"):
		hit.emit()
