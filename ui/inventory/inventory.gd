extends CanvasLayer

@onready var list: VBoxContainer = $InventoryContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var slot_template: Control = list.get_node("ItemSlot")

func _ready() -> void:
	slot_template.hide()
	hide()
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo():
		visible = not visible
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	for child in list.get_children():
		if child != slot_template:
			child.queue_free()

	for id in InventoryManager.items:
		var data: Dictionary = InventoryManager.items[id]
		var slot := slot_template.duplicate() as Control
		slot.show()
		slot.get_node("Icon").texture = data["icon"]
		slot.get_node("LabelName").text = data["name"]
		slot.get_node("LabelQuantity").text = "x%d" % data["quantity"]
		list.add_child(slot)
