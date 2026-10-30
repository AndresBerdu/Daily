extends Node2D  # deja el tipo que ya tenga tu script

const DIALOGUE_FIRST_JOB: DialogueResource = preload("res://escenes/lobby/dialogues/first_job.dialogue")
const DIALOGUE_EXIT: DialogueResource = preload("res://escenes/lobby/dialogues/exit.dialogue")

@onready var exit_area: Area2D = $ExitArea
@onready var elevator: Elevator = $Elevator

var in_exit_area := false
var elevator_opened := false     # la recepcionista ya activo el ascensor
var intro_seen := false          # el tutorial inicial ya se mostro

const SAVED_VARS := ["elevator_opened", "intro_seen"]

func _ready() -> void:
	LevelUtils.load_state(self, SAVED_VARS)
	if elevator_opened:
		elevator.is_elevator_operational = true
	if not intro_seen:
		intro_seen = true
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
	if not PlayerControl.is_interact(event):
		return

	if in_exit_area:
		_leave_building()
		get_viewport().set_input_as_handled()

# El jugador se arrepiente y se va: al terminar el dialogo aparece el game over
func _leave_building() -> void:
	DialogueManager.show_dialogue_balloon(DIALOGUE_EXIT, "start")
	LevelUtils.after_dialogue(GameManager.force_game_over.bind(true))

func has_curriculum() -> bool:
	return InventoryManager.has_item("curriculum")

# La llaman SaveManager al guardar y SceneTransition al salir del nivel
func save_state() -> void:
	LevelUtils.store_state(self, SAVED_VARS)

func open_elevator() -> void:
	elevator_opened = true
	InventoryManager.remove_item("curriculum")     # se lo entregas a la recepcionista
	elevator.is_elevator_operational = true
	
