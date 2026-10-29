class_name Item
extends Node2D

signal collected(item: Item)

@export var dialogue_resource: DialogueResource
@export var dialogue_start := "start"
@export var item_texture: Texture2D
@export var start_enabled := true
@export var coin_value := 0   

@export_group("Inventario")
@export var pickable := false
@export var item_data: ItemData        # que objeto entrega al recogerlo
@export var quantity := 1
@export var disappear_after := true

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
	print("interact: ", name, " | dialogo=", dialogue_resource != null, " | pickable=", pickable)
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
	if item_data == null and coin_value <= 0:
		push_error("%s: esta marcado como pickable pero no tiene Item Data ni Coin Value" % name)
		return

	# Objeto de inventario (opcional)
	if item_data != null:
		if not InventoryManager.add_data(item_data, quantity):
			push_warning("%s: no se pudo agregar '%s' al inventario" % [name, item_data.id])
			return

	# Monedas (opcional)
	if coin_value > 0:
		GameManager.add_coins(coin_value)

	sfx_sound.play()
	collected.emit(self)
	if disappear_after:
		set_enabled(false)
