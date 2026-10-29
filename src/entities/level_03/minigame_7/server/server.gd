class_name CableServer
extends Node2D

signal repaired
signal closed

const MINIGAME_SCENE: PackedScene = preload("res://src/entities/level_03/minigame_7/connect_all_cables.tscn")  # ajusta la ruta

@onready var area: Area2D = $InteractionArea

var is_open := false
var is_done := false
var layer: CanvasLayer


func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if is_done or is_open or not event.is_action_pressed("interact") or event.is_echo():
		return
	if not _player_inside():
		return
	get_viewport().set_input_as_handled()
	_open_game()


func _open_game() -> void:
	is_open = true
	_freeze_player(true)

	# El minijuego va en un CanvasLayer para verse fijo en pantalla
	layer = CanvasLayer.new()
	layer.layer = 20
	get_tree().current_scene.add_child(layer)

	var game := MINIGAME_SCENE.instantiate() as ConnectAllCables
	game.completed.connect(_on_completed)
	game.closed.connect(_on_closed)
	layer.add_child(game)


func _on_completed() -> void:
	is_done = true
	repaired.emit()


# ConnectAllCables libera su propia capa al cerrarse
func _on_closed() -> void:
	if not is_open:
		return
	is_open = false
	layer = null
	_freeze_player(false)
	closed.emit()


# La llama el nivel para cerrar la ventana a la fuerza (por ejemplo, al acabarse el tiempo)
func force_close() -> void:
	if not is_open:
		return
	is_open = false
	_freeze_player(false)
	if is_instance_valid(layer):
		layer.queue_free()
	layer = null
	closed.emit()


func _freeze_player(frozen: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
