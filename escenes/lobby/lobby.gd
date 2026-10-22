extends Node2D  # deja el tipo que ya tenga tu script

const ELEVATOR_SCENE := preload("res://escenes/level_01/level_01.tscn")

@onready var elevator_area: Area2D = $ElevatorArea
@onready var exit_area: Area2D = $ExitArea

var in_elevator_area := false
var in_exit_area := false

func _ready() -> void:
	elevator_area.body_entered.connect(_on_elevator_entered)
	elevator_area.body_exited.connect(_on_elevator_exited)

	exit_area.body_entered.connect(_on_exit_entered)
	exit_area.body_exited.connect(_on_exit_exited)

func _on_elevator_entered(body: Node) -> void:
	if body.is_in_group("player"):
		in_elevator_area = true

func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		in_exit_area = true

func _on_elevator_exited(body: Node) -> void:
	if body.is_in_group("player"):
		in_elevator_area = false

func _on_exit_exited(body: Node) -> void:
	if body.is_in_group("player"):
		in_exit_area = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if in_elevator_area:
		SceneTransition.change_scene(ELEVATOR_SCENE)
	elif in_exit_area:
		get_tree().free()
