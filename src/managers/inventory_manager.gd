extends Node

signal item_added(id: String, amount: int)
signal inventory_changed
signal equipment_changed(slot: String, id: String)

const SLOTS := ["suit", "shoes"]

# id -> { "name", "icon", "quantity", "slot" }
var items: Dictionary = {}

# slot -> id equipado ("" = nada)
var equipped: Dictionary = {"suit": "", "shoes": ""}

func add_item(id: String, item_name: String, icon: Texture2D, amount := 1, slot := "") -> void:
	if items.has(id):
		items[id]["quantity"] += amount
	else:
		items[id] = {"name": item_name, "icon": icon, "quantity": amount, "slot": slot}
	item_added.emit(id, amount)
	inventory_changed.emit()

func remove_item(id: String, amount := 1) -> bool:
	if get_quantity(id) < amount:
		return false
	items[id]["quantity"] -= amount
	if items[id]["quantity"] <= 0:
		_unequip_if_needed(id)
		items.erase(id)
	inventory_changed.emit()
	return true

func has_item(id: String) -> bool:
	return items.has(id)

func get_quantity(id: String) -> int:
	return items[id]["quantity"] if items.has(id) else 0

# --- Equipamiento ---
func can_equip(id: String) -> bool:
	return items.has(id) and items[id].get("slot", "") in SLOTS

func is_equipped(id: String) -> bool:
	var slot: String = items.get(id, {}).get("slot", "")
	return slot != "" and equipped.get(slot, "") == id

func get_equipped(slot: String) -> String:
	return equipped.get(slot, "")

func equip(id: String) -> void:
	if not can_equip(id):
		return
	var slot: String = items[id]["slot"]
	equipped[slot] = id
	equipment_changed.emit(slot, id)
	inventory_changed.emit()

func unequip(slot: String) -> void:
	if equipped.get(slot, "") == "":
		return
	equipped[slot] = ""
	equipment_changed.emit(slot, "")
	inventory_changed.emit()

func toggle_equip(id: String) -> void:
	if not can_equip(id):
		return
	if is_equipped(id):
		unequip(items[id]["slot"])
	else:
		equip(id)

func _unequip_if_needed(id: String) -> void:
	for slot in equipped:
		if equipped[slot] == id:
			equipped[slot] = ""
			equipment_changed.emit(slot, "")

# --- Guardado ---
func to_save_data() -> Dictionary:
	var saved_items := {}
	for id in items:
		var it: Dictionary = items[id]
		saved_items[id] = {
			"name": it["name"],
			"icon_path": it["icon"].resource_path if it["icon"] else "",
			"quantity": it["quantity"],
			"slot": it.get("slot", ""),
		}
	return {"items": saved_items, "equipped": equipped.duplicate()}

func load_save_data(data: Dictionary) -> void:
	items.clear()
	var saved_items: Dictionary = data.get("items", {})
	for id in saved_items:
		var d: Dictionary = saved_items[id]
		var icon: Texture2D = load(d["icon_path"]) if d.get("icon_path", "") != "" else null
		items[id] = {
			"name": d["name"],
			"icon": icon,
			"quantity": int(d["quantity"]),
			"slot": d.get("slot", ""),
		}
	equipped = {"suit": "", "shoes": ""}
	var saved_eq: Dictionary = data.get("equipped", {})
	for slot in saved_eq:
		if saved_eq[slot] != "" and items.has(saved_eq[slot]):
			equipped[slot] = saved_eq[slot]
	inventory_changed.emit()
