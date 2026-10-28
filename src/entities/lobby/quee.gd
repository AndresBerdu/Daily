extends Node2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start := "start"

var player_in_range := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if dialogue_resource:
			DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
