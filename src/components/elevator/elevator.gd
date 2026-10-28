extends Node2D
class_name Elevator

@export var nex_level: PackedScene # Escena a la cual va pasar el siguiente nivel

@onready var elevator_area: Area2D = $ElevatorArea # Área del elevador
@onready var elevator_sprite: AnimatedSprite2D = $Elevator # Referencia al AnimatedSprite2D

var in_elevator_area := false
var player_has_curriculum = false
var is_animating := false # Evita que se presione varias veces seguidas
var is_elevator_operational := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	elevator_area.body_entered.connect(_on_elevator_entered)
	elevator_area.body_exited.connect(_on_elevator_exited)

func _on_elevator_entered(body: Node) -> void:
	if body.is_in_group("player"):
		in_elevator_area = true

func _on_elevator_exited(body: Node) -> void:
	if body.is_in_group("player"):
		in_elevator_area = false

func _unhandled_input(event: InputEvent) -> void:
	if is_elevator_operational:
		# Si no se presiona la tecla interact, o ya está animando, o no estamos en el área, no hacemos nada
		if not event.is_action_pressed("interact") or is_animating or not in_elevator_area:
				return
			
		is_animating = true
		elevator_sprite.play("open")
		await elevator_sprite.animation_finished
		SceneTransition.change_scene(nex_level)
