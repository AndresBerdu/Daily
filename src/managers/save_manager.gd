extends Node

const SAVE_DIR := "user://saves/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))

func save_game(slot: int) -> bool:
	var scene := get_tree().current_scene
	var data := {
		"player_name": GameManager.player_name,
		"coins": GameManager.coins,
		"hearts": GameManager.hearts,
		"play_time": GameManager.play_time,
		"level_path": scene.scene_file_path,
		"level_name": scene.name,
		"appearance_seed": GameManager.appearance_seed,
		"inventory": InventoryManager.to_save_data(),
		"flags": GameManager.flags,
	}
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar el slot %d" % slot)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

func read_slot(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_path(slot), FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func load_game(slot: int) -> void:
	var data := read_slot(slot)
	if data.is_empty():
		return
	GameManager.apply_save(data)
	get_tree().change_scene_to_file(data["level_path"])

func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
