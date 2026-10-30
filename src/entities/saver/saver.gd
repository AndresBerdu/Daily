class_name Saver
extends StaticBody2D

const SAVE_MENU := preload("res://ui/menus/save/save.tscn")  # cambia por tu ruta

@onready var area: Area2D = $InteractionArea
@onready var save_sfx: AudioStreamPlayer = $SaveSfx

var menu_open := false

func _ready() -> void:
	save_sfx.process_mode = Node.PROCESS_MODE_ALWAYS  # suena aunque el juego esté en pausa

func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if menu_open or not PlayerControl.is_interact(event):
		return
	if not _player_inside():
		return
	get_viewport().set_input_as_handled()
	_open_menu()

func _open_menu() -> void:
	menu_open = true
	var menu := SAVE_MENU.instantiate()
	menu.saved.connect(func(_slot): save_sfx.play())
	menu.closed.connect(func(): menu_open = false)
	get_tree().current_scene.add_child(menu)
