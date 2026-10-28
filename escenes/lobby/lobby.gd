extends Node2D  # deja el tipo que ya tenga tu script

const DIALOGUE_FIRST_JOB: DialogueResource = preload("res://escenes/lobby/dialogues/first_job.dialogue")

@onready var exit_area: Area2D = $ExitArea
@onready var elevator: Elevator = $Elevator

var in_exit_area := false

func _ready() -> void:
	DialogueManager.show_dialogue_balloon(DIALOGUE_FIRST_JOB, "start")
	exit_area.body_entered.connect(_on_exit_entered)
	exit_area.body_exited.connect(_on_exit_exited)

func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		in_exit_area = true

func _on_exit_exited(body: Node) -> void:
	if body.is_in_group("player"):
		in_exit_area = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if in_exit_area:
		get_tree().free()

func has_curriculum() -> bool:
	return InventoryManager.has_item("curriculum")

func open_elevator() -> void:
	elevator.is_elevator_operational = true
	
