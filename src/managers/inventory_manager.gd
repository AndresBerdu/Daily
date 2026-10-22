extends Node

signal item_added(id: String, amount: int)
signal inventory_changed

# id -> { "name": String, "icon": Texture2D, "quantity": int }
var items: Dictionary = {}

func add_item(id: String, item_name: String, icon: Texture2D, amount := 1) -> void:
	if items.has(id):
		items[id]["quantity"] += amount
	else:
		items[id] = {"name": item_name, "icon": icon, "quantity": amount}
	item_added.emit(id, amount)
	inventory_changed.emit()

func remove_item(id: String, amount := 1) -> bool:
	if get_quantity(id) < amount:
		return false
	items[id]["quantity"] -= amount
	if items[id]["quantity"] <= 0:
		items.erase(id)
	inventory_changed.emit()
	return true

func has_item(id: String) -> bool:
	return items.has(id)

func get_quantity(id: String) -> int:
	return items[id]["quantity"] if items.has(id) else 0

# Para el sistema de guardado
func to_save_data() -> Dictionary:
	var out := {}
	for id in items:
		var it: Dictionary = items[id]
		out[id] = {
			"name": it["name"],
			"icon_path": it["icon"].resource_path if it["icon"] else "",
			"quantity": it["quantity"],
		}
	return out

func load_save_data(data: Dictionary) -> void:
	items.clear()
	for id in data:
		var d: Dictionary = data[id]
		var icon: Texture2D = load(d["icon_path"]) if d.get("icon_path", "") != "" else null
		items[id] = {"name": d["name"], "icon": icon, "quantity": int(d["quantity"])}
	inventory_changed.emit()
