extends Node

signal item_added(id: String, amount: int)
signal inventory_changed
signal equipment_changed(slot: String, id: String)

const SLOTS := ["suit", "shoes", "tools"]
const DEFAULT_SUIT: ItemData = preload("res://src/components/items/suits/suit_default.tres")

func _ready() -> void:
	_ensure_default_suit()


func is_default_suit(id: String) -> bool:
	return DEFAULT_SUIT != null and id == DEFAULT_SUIT.id


# Garantiza que el traje por defecto exista y que siempre haya un traje puesto
func _ensure_default_suit() -> void:
	if DEFAULT_SUIT == null:
		return
	if not items.has(DEFAULT_SUIT.id):
		add_data(DEFAULT_SUIT, 1)
	if equipped.get("suit", "") == "":
		equip(DEFAULT_SUIT.id)
	print("Traje por defecto: id='", DEFAULT_SUIT.id, "' ruta=", DEFAULT_SUIT.resource_path)

# id -> { "data": ItemData, "name", "icon", "quantity", "slot" }
var items: Dictionary = {}

# slot -> id equipado ("" = nada)
var equipped: Dictionary = {"suit": "", "shoes": "", "tools": ""}

func add_data(data: ItemData, amount := 1) -> bool:
	if data == null or data.id == "":
		push_error("InventoryManager: el ItemData no existe o no tiene id")
		return false
	if items.has(data.id):
		if not data.is_stackable():
			push_warning("InventoryManager: '%s' ya esta en el inventario (los equipos no se duplican). Revisa que dos ItemData no compartan id" % data.id)
			return false
		items[data.id]["quantity"] += amount
	else:
		items[data.id] = {
			"data": data,
			"name": data.display_name,
			"icon": data.icon,
			"quantity": amount if data.is_stackable() else 1,
			"slot": data.slot_name() if data.is_equippable() else "",
		}
	item_added.emit(data.id, amount)
	inventory_changed.emit()
	return true

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
	return items.has(id) and (items[id]["data"] as ItemData).is_equippable()

func is_equipped(id: String) -> bool:
	var slot: String = items.get(id, {}).get("slot", "")
	return slot != "" and equipped.get(slot, "") == id

func get_equipped(slot: String) -> String:
	return equipped.get(slot, "")

func get_equipped_data(slot: String) -> ItemData:
	var id: String = equipped.get(slot, "")
	if id == "" or not items.has(id):
		return null
	return items[id]["data"]

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
	if not is_equipped(id):
		equip(id)
		return

	var slot: String = items[id]["slot"]
	if slot == "suit":
		# Siempre hay un traje puesto: el de por defecto no se quita
		# y cualquier otro traje se cambia por el de por defecto
		if not is_default_suit(id):
			equip(DEFAULT_SUIT.id)
	else:
		unequip(slot)

func _unequip_if_needed(id: String) -> void:
	for slot in equipped:
		if equipped[slot] == id:
			equipped[slot] = ""
			equipment_changed.emit(slot, "")
	_ensure_default_suit()

# Multiplicador de velocidad segun los zapatos puestos
func get_speed_multiplier() -> float:
	var shoes := get_equipped_data("shoes")
	return shoes.speed_multiplier if shoes else 1.0

# --- Uso ---
# Consumibles: curan y se gastan. Si la vida esta llena, no se gasta
func use_item(id: String) -> bool:
	if not items.has(id):
		return false
	var data: ItemData = items[id]["data"]
	if data.category != ItemData.Category.CONSUMABLE:
		return false
	if data.heal_amount > 0 and not GameManager.heal(data.heal_amount):
		return false
	remove_item(id, 1)
	return true

# Enter en el inventario: equipa si es equipo, usa si es consumible
func activate(id: String) -> void:
	if can_equip(id):
		toggle_equip(id)
	else:
		use_item(id)

# --- Guardado ---
func to_save_data() -> Dictionary:
	var saved_items := {}
	for id in items:
		var data: ItemData = items[id]["data"]
		saved_items[id] = {
			"data_path": data.resource_path,
			"quantity": items[id]["quantity"],
		}
	return {"items": saved_items, "equipped": equipped.duplicate()}

func load_save_data(data: Dictionary) -> void:
	items.clear()
	var saved_items: Dictionary = data.get("items", {})
	for id in saved_items:
		var path: String = saved_items[id].get("data_path", "")
		if path == "" or not ResourceLoader.exists(path):
			continue
		var res := load(path) as ItemData
		if res == null:
			continue
		add_data(res, int(saved_items[id].get("quantity", 1)))

	equipped = {"suit": "", "shoes": "", "tools": ""}
	var saved_eq: Dictionary = data.get("equipped", {})
	for slot in saved_eq:
		if saved_eq[slot] != "" and items.has(saved_eq[slot]):
			equipped[slot] = saved_eq[slot]
			equipment_changed.emit(slot, saved_eq[slot])

	_ensure_default_suit()        # <- la linea nueva, antes del emit final
	inventory_changed.emit()
