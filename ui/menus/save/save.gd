extends CanvasLayer

signal saved(slot: int)
signal closed

@onready var slots: Array[Control] = [
	$BackgroundContainer/Slot1,
	$BackgroundContainer/Slot2,
	$BackgroundContainer/Slot3,
]

var selected := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	for i in slots.size():
		slots[i].mouse_entered.connect(_select.bind(i))
		slots[i].gui_input.connect(_on_slot_gui_input.bind(i))
		_refresh_slot(i)
	_select(0)

func _refresh_slot(i: int) -> void:
	var slot := slots[i]
	var has_save := SaveManager.has_save(i + 1)

	slot.get_node("Sprite2D").visible = has_save
	slot.get_node("InfoContainer").visible = has_save
	slot.get_node("HBoxContainer").visible = not has_save

	if has_save:
		var d := SaveManager.read_slot(i + 1)
		slot.get_node("InfoContainer/LabelName").text = str(d.get("player_name", ""))
		slot.get_node("InfoContainer/LabelCoins").text = str(d.get("coins", 0))
		slot.get_node("InfoContainer/LabelLevelName").text = str(d.get("level_name", ""))
		slot.get_node("InfoContainer/LabelDate").text = SaveManager.format_time(d.get("play_time", 0.0))

func _select(i: int) -> void:
	selected = i
	for j in slots.size():
		slots[j].modulate = Color.WHITE if j == selected else Color(0.6, 0.6, 0.6)

func _save_slot(i: int) -> void:
	if SaveManager.save_game(i + 1):
		_refresh_slot(i)
		saved.emit(i + 1)

func _on_slot_gui_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_save_slot(i)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_select((selected + 1) % slots.size())
	elif event.is_action_pressed("ui_up"):
		_select((selected - 1 + slots.size()) % slots.size())
	elif event.is_action_pressed("ui_accept"):
		_save_slot(selected)
	elif event.is_action_pressed("ui_cancel"):
		_close()
	else:
		return
	get_viewport().set_input_as_handled()

func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
