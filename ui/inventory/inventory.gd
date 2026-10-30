extends CanvasLayer

@onready var scroll: ScrollContainer = $InventoryContainer/MarginContainer/ScrollContainer
@onready var grid: GridContainer = scroll.get_node("ItemGrid")
@onready var label_empty: Control = find_child("LabelEmpty", true, false)

# Las plantillas son las celdas hijas del grid (Icon, LabelName, LabelQuantity, LabelEquipped)
var templates: Array[Control] = []
var rows: Array[Array] = []      # celdas de cada fila (en el mismo orden que ids)

var ids: Array[String] = []
var selected := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for child in grid.get_children():
		templates.append(child as Control)
		child.hide()
	hide()
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo():
		# Si la tienda esta abierta (juego en pausa), el inventario no se abre
		if get_tree().paused and not visible:
			return
		_toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return

	if event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		if selected < ids.size():
			InventoryManager.activate(ids[selected])
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
	for row in rows:
		for cell in row:
			cell.queue_free()
	rows.clear()
	ids.clear()

	for id in InventoryManager.items:
		var entry: Dictionary = InventoryManager.items[id]
		var data: ItemData = entry["data"]
		var texts := [
			null,
			data.display_name,
			("x%d" % entry["quantity"]) if data.is_stackable() else "",
			_tag(id, data),
		]
		var row: Array[Control] = []
		for i in templates.size():
			var cell := templates[i].duplicate() as Control
			if i == 0:
				(cell as TextureRect).texture = data.icon
			else:
				(cell as Label).text = texts[i]
			cell.show()
			grid.add_child(cell)
			row.append(cell)
		rows.append(row)
		ids.append(id)

	selected = clampi(selected, 0, max(ids.size() - 1, 0))

	if label_empty:
		label_empty.visible = ids.is_empty()

	_highlight()

# Etiqueta segun el tipo de objeto
func _tag(id: String, data: ItemData) -> String:
	if data.is_equippable():
		return "Equipado" if InventoryManager.is_equipped(id) else "Equipar"
	if data.category == ItemData.Category.CONSUMABLE:
		return "Usar"
	return ""   # coleccionable: solo existe

func _highlight() -> void:
	for index in rows.size():
		var color := Color.WHITE if index == selected else Color(0.6, 0.6, 0.6)
		for cell in rows[index]:
			cell.modulate = color
	if selected < rows.size():
		scroll.ensure_control_visible(rows[selected][1])
