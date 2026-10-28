class_name ShopCounter
extends Node2D

const SHOP_UI: PackedScene = preload("res://ui/shop/shop_ui.tscn")   # ajusta la ruta

@export var shop_name := "Tienda"
@export var entries: Array[ShopEntry]    # lo que vende ESTA tienda

@onready var area: Area2D = $InteractionArea

var remaining: Array[int] = []           # unidades que quedan de cada entrada
var is_open := false

func _ready() -> void:
	for entry in entries:
		remaining.append(entry.stock if entry != null else 0)

func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if is_open or not event.is_action_pressed("interact") or event.is_echo():
		return
	if entries.is_empty() or not _player_inside():
		return
	get_viewport().set_input_as_handled()
	_open()

func _open() -> void:
	is_open = true

	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(layer)

	var ui := SHOP_UI.instantiate() as ShopUI
	layer.add_child(ui)
	ui.setup(entries, remaining)
	ui.closed.connect(func():
		is_open = false
		layer.queue_free()
	)
