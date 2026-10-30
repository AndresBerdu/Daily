class_name NewPc
extends Node2D

signal repaired

const MOTHERBOARD_SCENE := preload("res://src/entities/level_01/minigame_3/mother_board/mother_board.tscn")  # cambia a tu ruta

@onready var area: Area2D = $InteractionArea
@onready var start_minigame_sfx: AudioStreamPlayer = $StartMinigameSfx
@onready var minigame_finished_sfx: AudioStreamPlayer = $MinigameFinishedSfx

var is_repaired := false
var is_open := false

func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if is_repaired or is_open or not PlayerControl.is_interact(event):
		return
	if not _player_inside():
		return
	get_viewport().set_input_as_handled()
	_open_game()

func _open_game() -> void:
	is_open = true
	start_minigame_sfx.play()
	PlayerControl.freeze(self)

	var game := MOTHERBOARD_SCENE.instantiate() as MotherboardGame
	game.completed.connect(_on_completed)
	game.closed.connect(_on_closed)
	get_tree().current_scene.add_child(game)

# Deja el PC como ya reparado (al cargar una partida), sin repetir el minijuego
func mark_done() -> void:
	is_repaired = true

func _on_completed() -> void:
	is_repaired = true
	minigame_finished_sfx.play()
	repaired.emit()

func _on_closed() -> void:
	is_open = false
	PlayerControl.unfreeze(self)
