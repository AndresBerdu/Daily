class_name NewPc
extends Node2D

signal repaired

const MOTHERBOARD_SCENE := preload("res://src/entities/level_01/minigame_3/mother_board/mother_board.tscn")  # cambia a tu ruta

@onready var area: Area2D = $InteractionArea

var is_repaired := false
var is_open := false

func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if is_repaired or is_open or not event.is_action_pressed("interact"):
		return
	if not _player_inside():
		return
	get_viewport().set_input_as_handled()
	_open_game()

func _open_game() -> void:
	is_open = true
	_freeze_player(true)

	var game := MOTHERBOARD_SCENE.instantiate() as MotherboardGame
	game.completed.connect(_on_completed)
	game.closed.connect(_on_closed)
	get_tree().current_scene.add_child(game)

func _on_completed() -> void:
	is_repaired = true
	repaired.emit()

func _on_closed() -> void:
	is_open = false
	_freeze_player(false)

# Detiene al jugador sin pausar el árbol (la pausa rompería los Area2D del minijuego)
func _freeze_player(frozen: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
