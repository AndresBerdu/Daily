class_name Item
extends Node2D

signal collected(item: Item)

@export var dialogue_resource: DialogueResource
@export var dialogue_start := "start"
@export var item_texture: Texture2D
@export var start_enabled := true

@export_group("Inventario")
@export var pickable := false
@export var item_id := ""
@export var item_name := ""
@export var item_icon: Texture2D
@export var quantity := 1
@export var disappear_after := true
@export_enum("none", "suit", "shoes", "tools") var equip_slot := "none"

@onready var interaction_area: Area2D = $InteractionArea
@onready var sfx_sound: AudioStreamPlayer = $sfx

var enabled := true
var busy := false

func _ready() -> void:
	if item_texture:
		$Sprite2D.texture = item_texture
	DialogueManager.dialogue_ended.connect(func(_r): busy = false)
	set_enabled(start_enabled)

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	interaction_area.set_deferred("monitoring", value)

func _player_inside() -> bool:
	for body in interaction_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or busy or not event.is_action_pressed("interact"):
		return
	if not _player_inside():
		return
	get_viewport().set_input_as_handled()
	interact()

func interact() -> void:
	if dialogue_resource:
		busy = true
		DialogueManager.show_dialogue_balloon(
			dialogue_resource, dialogue_start, [self, get_tree().current_scene]
		)
	elif pickable:
		collect()

func collect() -> void:
	if not pickable or not enabled:
		return
	var slot := "" if equip_slot == "none" else equip_slot
	InventoryManager.add_item(item_id, item_name, item_icon, quantity, slot)
	sfx_sound.play()
	collected.emit(self)
	if disappear_after:
		set_enabled(false)
