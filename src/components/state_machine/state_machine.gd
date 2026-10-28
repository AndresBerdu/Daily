class_name StateMachine
extends Node

@export var initial_state: State # Estado con el que empieza el jugador

var current_state: State # Estado actual
var states: Dictionary = {} # Todos los estados creados

func _ready() -> void:
	var actor := get_parent() # Tipo del nodo
	
	# Iteración para obtener todos los estados y agregarlso al diccionario
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.actor = actor
			child.transitioned.connect(_on_transition)
	
	# --- Configuración del estado ---
	if initial_state == null and get_child_count() > 0:
		initial_state = get_child(0) as State

	if initial_state:
		current_state = initial_state
		current_state.enter()

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## Fucnión para cambiar de estado a otro
func _on_transition(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())
	
	# Validamos que el nuevo estado no sea nulo
	if new_state == null or new_state == current_state:
		return
		
	current_state.exit()
	current_state = new_state
	current_state.enter()
