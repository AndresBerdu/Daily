extends Node

const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 3

var current_slot := 0      # slot de la partida en curso (0 = aun no se guardo ni cargo ninguno)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))

func save_game(slot: int) -> bool:
	var scene := get_tree().current_scene
	if scene.has_method("save_state"):
		scene.save_state()          # el nivel anota su progreso antes de guardar
	var player := PlayerControl.get_player()
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
		"story": GameManager.story,
		"player_pos": [player.global_position.x, player.global_position.y] if player else [],
	}
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar el slot %d" % slot)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	current_slot = slot
	return true

## Borra un slot (por ejemplo, al ser despedido)
func delete_slot(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(slot)))
	if current_slot == slot:
		current_slot = 0

func read_slot(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_path(slot), FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

# Slot (1..SLOT_COUNT) guardado mas recientemente; 0 si no hay ninguno
func get_last_slot() -> int:
	var best := 0
	var best_time := 0
	for slot in range(1, SLOT_COUNT + 1):
		if not has_save(slot):
			continue
		var modified := FileAccess.get_modified_time(_path(slot))
		if modified >= best_time:
			best_time = modified
			best = slot
	return best

func has_any_save() -> bool:
	return get_last_slot() > 0

# El cambio de escena lo hace GameFlow
func load_game(slot: int) -> void:
	GameFlow.load_slot(slot)

func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
