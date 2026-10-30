extends Node2D
## Nivel final: los jefes presentan a Momero (el CEO) y se cierra el juego.
## El final depende de a quien se le entrego el token en el nivel 2.

const ENDING_DIALOGUE: DialogueResource = preload("res://escenes/top_floor/dialogues/ending.dialogue")

# Puntos de entrada del dialogo final (ver ending.dialogue)
const TITLE_HIRED := "hired"        # a Charlie o a nadie: te contratan
const TITLE_FIRED := "fired"        # se lo diste al hombre de la gabardina: te despiden

@onready var trigger: Area2D = $EndingTrigger

var _ending_started := false


func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_entered)


func _on_trigger_entered(body: Node) -> void:
	if _ending_started or not body.is_in_group("player"):
		return
	_ending_started = true

	var hired := _is_hired()
	DialogueManager.show_dialogue_balloon(ENDING_DIALOGUE, TITLE_HIRED if hired else TITLE_FIRED)
	# Al terminar de hablar: pantalla de gracias y menu. Si te despidieron, tambien se borra la partida
	LevelUtils.after_dialogue(GameFlow.finish_game.bind(not hired))


# Final bueno salvo que el token termine en manos del hombre de la gabardina
func _is_hired() -> bool:
	return not GameManager.has_flag(GameFlow.FLAG_TOKEN_TO_STRANGER)
