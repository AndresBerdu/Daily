class_name State
extends Node

signal transitioned(new_state_name: String)

var actor: CharacterBody2D # actor que va a usar la maquina de estado

## Función para iniciar la acción
func enter() -> void:
	pass

## Funcion para terminar la acción
func exit() -> void:
	pass

## Función para manejar las acciones que va a realizar el actor
func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void: # equivale a _process
	pass

func physics_update(_delta: float) -> void: # equivale a _physics_process
	pass
