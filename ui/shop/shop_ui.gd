class_name ShopUI
extends CanvasLayer

signal closed
signal purchased(data: ItemData)

const COLOR_SELECTED := Color(1.0, 0.9, 0.1)

@onready var list: VBoxContainer = $ShopContainer/MarginContainer/ScrollContainer/VBoxContainer
@onready var slot_template: Control = list.get_node("ItemSlot")

var entries: Array[ShopEntry] = []
var remaining: Array[int] = []      # es la misma lista del mostrador (se pasa por referencia)
var rows: Array[int] = []           # indice en entries de cada fila visible
var slots: Array[Control] = []
var selected := 0
var warned := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	slot_template.hide()
	GameManager.coins_changed.connect(func(_c): _refresh())
	InventoryManager.inventory_changed.connect(_refresh)

func setup(shop_entries: Array[ShopEntry], shop_remaining: Array[int]) -> void:
	entries = shop_entries
	remaining = shop_remaining
	for i in entries.size():
		if entries[i] != null and entries[i].item != null:
			rows.append(i)
	_build()
	selected = 0
	_refresh()
	get_tree().paused = true

func _build() -> void:
	for i in rows.size():
		var slot := slot_template.duplicate() as Control
		# Vacia el texto de ejemplo de la plantilla
		for label in slot.find_children("*", "Label", true, false):
			(label as Label).text = ""
		slot.show()
		list.add_child(slot)
		slots.append(slot)

func _get_label(slot: Control, node_name: String) -> Label:
	var label := slot.find_child(node_name, true, false) as Label
	if label == null and not warned.has(node_name):
		warned[node_name] = true
		push_warning("ShopUI: ItemSlot no tiene un Label llamado '%s'" % node_name)
	return label

func _set_text(slot: Control, node_name: String, text: String) -> void:
	var label := _get_label(slot, node_name)
	if label:
		label.text = text

func _refresh() -> void:
	for i in rows.size():
		var idx := rows[i]
		var data := entries[idx].item
		var slot := slots[i]

		var icon := slot.find_child("Icon", true, false) as TextureRect
		if icon:
			icon.texture = data.icon

		# Nombre: amarillo si es el seleccionado
		var name_label := _get_label(slot, "LabelName")
		if name_label:
			name_label.text = data.display_name
			if i == selected:
				name_label.add_theme_color_override("font_color", COLOR_SELECTED)
			else:
				name_label.remove_theme_color_override("font_color")

		# Cantidad: unidades que quedan en la tienda (vacio si es ilimitado)
		var left := remaining[idx]
		_set_text(slot, "LabelQuantity", ("x%d" % left) if left >= 0 else "")
		_set_text(slot, "LabelPrice", "%d$" % data.price)
		_set_text(slot, "LabelStatus", _status(idx))

# Vacio por defecto; solo aparece texto si hay algo que avisar
func _status(idx: int) -> String:
	var data := entries[idx].item
	if not data.is_stackable() and InventoryManager.has_item(data.id):
		return "Comprado"
	if remaining[idx] == 0:
		return "Agotado"
	if GameManager.coins < data.price:
		return "Sin monedas"
	return ""

func _can_buy(idx: int) -> bool:
	var data := entries[idx].item
	if remaining[idx] == 0:
		return false                                   # sin unidades en la tienda
	if not data.is_stackable() and InventoryManager.has_item(data.id):
		return false                                   # el equipo ya se compro
	return GameManager.coins >= data.price

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		_buy_selected()
	elif event.is_action_pressed("ui_cancel"):
		_close()
	else:
		return
	get_viewport().set_input_as_handled()

func _move(step: int) -> void:
	if rows.is_empty():
		return
	selected = wrapi(selected + step, 0, rows.size())
	_refresh()

func _buy_selected() -> void:
	if rows.is_empty():
		return
	var idx := rows[selected]
	if not _can_buy(idx):
		return

	var data := entries[idx].item
	GameManager.add_coins(-data.price)
	if not InventoryManager.add_data(data, 1):
		GameManager.add_coins(data.price)              # devuelve las monedas si no se pudo agregar
		return

	if remaining[idx] > 0:
		remaining[idx] -= 1                            # resta una unidad de la tienda
	purchased.emit(data)
	_refresh()

func _close() -> void:
	get_tree().paused = false
	closed.emit()
