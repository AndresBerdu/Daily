class_name ItemData
extends Resource

enum Category { EQUIPMENT, CONSUMABLE, COLLECTIBLE }
enum Slot { NONE, SUIT, SHOES, TOOLS }

@export var id := ""                       # unico, por ejemplo "zapatos_rapidos"
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var category := Category.COLLECTIBLE
@export var price := 0

@export_group("Equipo")
@export var slot := Slot.NONE              # solo si la categoria es EQUIPMENT
@export var speed_multiplier := 1.0        # zapatos: 1.25 = 25 % mas rapido
@export var suit_sheets: OutfitSheets  

@export_group("Consumible")
@export var heal_amount := 1               # corazones que cura

func is_equippable() -> bool:
	return category == Category.EQUIPMENT and slot != Slot.NONE


# Los equipos son unicos; consumibles y coleccionables se acumulan
func is_stackable() -> bool:
	return category != Category.EQUIPMENT


func slot_name() -> String:
	match slot:
		Slot.SUIT: return "suit"
		Slot.SHOES: return "shoes"
		Slot.TOOLS: return "tools"
	return ""
