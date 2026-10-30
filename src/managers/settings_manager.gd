extends Node
## Autoload "SettingsManager": volumenes (Master, Music, SFX) y su guardado en disco.
## Los menus solo llaman a get_volume / set_volume / set_music_enabled / save.

signal changed

const SAVE_PATH := "user://settings.cfg"
const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"

var volumes := {BUS_MASTER: 1.0, BUS_MUSIC: 1.0, BUS_SFX: 1.0}   # 0.0 a 1.0
var music_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_apply_all()
	# Todo reproductor que siga en "Master" se manda solo a su bus (ver _route)
	get_tree().node_added.connect(_route)


# ---------- API para los menus ----------
func get_volume(bus: StringName) -> float:
	return volumes.get(bus, 1.0)


func set_volume(bus: StringName, value: float) -> void:
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply(bus)
	changed.emit()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_apply(BUS_MUSIC)
	changed.emit()


## Foto de los valores actuales, para poder cancelar los cambios (ESC en opciones)
func snapshot() -> Dictionary:
	return {"volumes": volumes.duplicate(), "music_enabled": music_enabled}


func restore(snap: Dictionary) -> void:
	volumes = snap["volumes"].duplicate()
	music_enabled = snap["music_enabled"]
	_apply_all()
	changed.emit()


func save() -> void:
	var cfg := ConfigFile.new()
	for bus in volumes:
		cfg.set_value("audio", String(bus), volumes[bus])
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.save(SAVE_PATH)


# ---------- Interno ----------
func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for bus in volumes:
		volumes[bus] = float(cfg.get_value("audio", String(bus), volumes[bus]))
	music_enabled = bool(cfg.get_value("audio", "music_enabled", true))


func _apply_all() -> void:
	for bus in volumes:
		_apply(bus)


func _apply(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index == -1:
		push_warning("SettingsManager: no existe el bus '%s'" % bus)
		return
	var value: float = volumes[bus]
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(index, value <= 0.0 or (bus == BUS_MUSIC and not music_enabled))


## Regla para que los sonidos obedezcan las opciones sin tocar cada escena:
## un reproductor que siga en "Master" va a "Music" si su nombre contiene "music"
## y a "SFX" en cualquier otro caso. Si le pones otro bus a mano, se respeta.
func _route(node: Node) -> void:
	if not (node is AudioStreamPlayer or node is AudioStreamPlayer2D):
		return
	if node.bus != BUS_MASTER:
		return
	var target := BUS_MUSIC if "music" in node.name.to_lower() else BUS_SFX
	if AudioServer.get_bus_index(target) != -1:
		node.bus = target
