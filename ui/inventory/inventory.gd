extends CanvasLayer

@onready var list: VBoxContainer = $InventoryContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var slot_template: Control = list.get_node("ItemSlot")

var ids: Array[String] = []   # id de cada fila, en orden
var selected := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue recibiendo input en pausa
	slot_template.hide()
	hide()
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo():
		_toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return

	if event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_accept"):
		if selected < ids.size():
			InventoryManager.toggle_equip(ids[selected])
	elif event.is_action_pressed("ui_cancel"):
		_toggle()
	else:
		return
	get_viewport().set_input_as_handled()

func _toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		selected = 0
		_refresh()

func _move(step: int) -> void:
	if ids.is_empty():
		return
	selected = wrapi(selected + step, 0, ids.size())
	_highlight()

func _refresh() -> void:
	for child in list.get_children():
		if child != slot_template:
			child.queue_free()

	ids.clear()
	for id in InventoryManager.items:
		var data: Dictionary = InventoryManager.items[id]
		var slot := slot_template.duplicate() as Control
		slot.show()
		slot.get_node("Icon").texture = data["icon"]
		slot.get_node("LabelName").text = data["name"]
		slot.get_node("LabelQuantity").text = "x%d" % data["quantity"]
		slot.get_node("LabelEquipped").text = "Equipado" if InventoryManager.is_equipped(id) else ""
		list.add_child(slot)
		ids.append(id)

	selected = clampi(selected, 0, max(ids.size() - 1, 0))
	_highlight()

func _highlight() -> void:
	var index := 0
	for child in list.get_children():
		if child == slot_template or child.is_queued_for_deletion():
			continue
		child.modulate = Color.WHITE if index == selected else Color(0.6, 0.6, 0.6)
		index += 1
