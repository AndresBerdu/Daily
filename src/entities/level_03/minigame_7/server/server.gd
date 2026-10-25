class_name CableServer
extends Node2D

signal repaired

const MINIGAME_SCENE: PackedScene = preload("res://src/entities/level_03/minigame_7/connect_all_cables.tscn")  # ajusta la ruta

@onready var area: Area2D = $InteractionArea

var is_open := false
var is_done := false

func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if is_done or is_open or not event.is_action_pressed("interact"):
		return
	if not _player_inside():
		return
	get_viewport().set_input_as_handled()
	_open_game()

func _open_game() -> void:
	is_open = true
	_freeze_player(true)

	# El minijuego va en un CanvasLayer para que se vea fijo en pantalla
	var layer := CanvasLayer.new()
	layer.layer = 20
	get_tree().current_scene.add_child(layer)

	var game := MINIGAME_SCENE.instantiate() as ConnectAllCables
	game.completed.connect(_on_completed)
	game.closed.connect(_on_closed)
	layer.add_child(game)

func _on_completed() -> void:
	is_done = true
	repaired.emit()

func _on_closed() -> void:
	is_open = false
	_freeze_player(false)

# Detiene al jugador sin pausar el arbol
func _freeze_player(frozen: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
