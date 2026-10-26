class_name LatencyGame
extends Node2D

signal completed
signal failed
signal round_finished(correct: bool)

# Nombre del nodo -> datos de la ciudad
const ZONE_DATA := {
	"RioJaneiro": {"label": "Rio de Janeiro", "lat": -22.9, "lon": -43.2},
	"Maima": {"label": "Miami", "lat": 25.8, "lon": -80.2},
	"Berlin": {"label": "Berlin", "lat": 52.5, "lon": 13.4},
	"Shanghai": {"label": "Shanghai", "lat": 31.2, "lon": 121.5},
	"Sidney": {"label": "Sidney", "lat": -33.9, "lon": 151.2},
}

# Codigo del archivo de la bandera, nombre y ubicacion de la capital
const COUNTRIES := [
	{"code": "au", "name": "Australia", "lat": -35.3, "lon": 149.1},
	{"code": "br", "name": "Brasil", "lat": -15.8, "lon": -47.9},
	{"code": "ca", "name": "Canada", "lat": 45.4, "lon": -75.7},
	{"code": "cn", "name": "China", "lat": 39.9, "lon": 116.4},
	{"code": "co", "name": "Colombia", "lat": 4.7, "lon": -74.1},
	{"code": "eg", "name": "Egipto", "lat": 30.0, "lon": 31.2},
	{"code": "es", "name": "Espana", "lat": 40.4, "lon": -3.7},
	{"code": "fr", "name": "Francia", "lat": 48.9, "lon": 2.4},
	{"code": "it", "name": "Italia", "lat": 41.9, "lon": 12.5},
	{"code": "jp", "name": "Japon", "lat": 35.7, "lon": 139.7},
	{"code": "kr", "name": "Corea del Sur", "lat": 37.6, "lon": 127.0},
	{"code": "ma", "name": "Marruecos", "lat": 34.0, "lon": -6.8},
	{"code": "mx", "name": "Mexico", "lat": 19.4, "lon": -99.1},
	{"code": "nz", "name": "Nueva Zelanda", "lat": -41.3, "lon": 174.8},
	{"code": "pg", "name": "Papua Nueva Guinea", "lat": -9.4, "lon": 147.2},
	{"code": "us", "name": "Estados Unidos", "lat": 38.9, "lon": -77.0},
	{"code": "ve", "name": "Venezuela", "lat": 10.5, "lon": -66.9},
	{"code": "de", "name": "Alemania", "lat": 52.5, "lon": 13.4},
]

@export var flag_scene: PackedScene
@export var flags_folder := "res://assets/sprites/props/flags/"   # ajusta a tu carpeta
@export var rounds := 8
@export var time_per_round := 0.0     # 0 = sin limite de tiempo
@export var result_delay := 1.0       # pausa para ver el resultado
@export var show_latency := false     # mostrar los ms desde el inicio de la ronda
@export var auto_start := false

@export_group("Latencia")
@export var base_latency_ms := 8.0
@export var ms_per_km := 0.02
@export var jitter_ms := 4.0

@onready var flag_marker: Marker2D = $Marker2D
@onready var zones_node: Node = $Zones

var zones: Array[LatencyZone] = []
var deck: Array = []
var round_index := 0
var current_flag: CountryFlag = null
var correct_zone: LatencyZone = null
var round_timer := Timer.new()
var awaiting := false
var running := false

func _ready() -> void:
	for child in zones_node.get_children():
		var zone := child as LatencyZone
		if zone == null:
			push_warning("%s no tiene latency_zone.gd, se ignora" % child.name)
			continue
		var data: Dictionary = ZONE_DATA.get(zone.name, {})
		if data.is_empty():
			push_warning("La zona '%s' no esta en ZONE_DATA" % zone.name)
			continue
		zone.setup(data["label"], data["lat"], data["lon"])
		zone.selected.connect(_on_zone_selected)
		zones.append(zone)

	round_timer.one_shot = true
	round_timer.timeout.connect(func(): _resolve(null))   # tiempo agotado
	add_child(round_timer)

	GameManager.game_over.connect(_on_game_over)
	_set_zones_locked(true)

	if auto_start:
		start()

func start() -> void:
	if flag_scene == null or zones.is_empty():
		push_error("LatencyGame: asigna Flag Scene y revisa los nombres de las zonas")
		return
	_build_deck()
	round_index = 0
	running = true
	_next_round()

# Mezcla los paises; si hay mas rondas que paises, vuelve a mezclar
func _build_deck() -> void:
	deck.clear()
	while deck.size() < rounds:
		var pool := COUNTRIES.duplicate()
		pool.shuffle()
		deck.append_array(pool)
	deck.resize(rounds)

# --- Rondas ---
func _next_round() -> void:
	_clear_flag()
	for zone in zones:
		zone.set_mark(LatencyZone.Mark.NONE)

	if round_index >= rounds:
		running = false
		_set_zones_locked(true)
		completed.emit()
		return

	var country: Dictionary = deck[round_index]
	_spawn_flag(country)
	_compute_latencies(country)
	_refresh_labels(show_latency)
	_set_zones_locked(false)
	awaiting = true
	if time_per_round > 0.0:
		round_timer.start(time_per_round)

# La zona con menor latencia es la correcta
func _compute_latencies(country: Dictionary) -> void:
	correct_zone = null
	for zone in zones:
		var km := _distance_km(country["lat"], country["lon"], zone.lat, zone.lon)
		zone.latency = base_latency_ms + km * ms_per_km + randf_range(0.0, jitter_ms)
		if correct_zone == null or zone.latency < correct_zone.latency:
			correct_zone = zone

# Distancia en km entre dos puntos del planeta (formula de haversine)
func _distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var p1 := deg_to_rad(lat1)
	var p2 := deg_to_rad(lat2)
	var dp := deg_to_rad(lat2 - lat1)
	var dl := deg_to_rad(lon2 - lon1)
	var a := pow(sin(dp / 2.0), 2.0) + cos(p1) * cos(p2) * pow(sin(dl / 2.0), 2.0)
	return 6371.0 * 2.0 * atan2(sqrt(a), sqrt(1.0 - a))

func _on_zone_selected(zone: LatencyZone) -> void:
	_resolve(zone)

# chosen = null significa que se agoto el tiempo
func _resolve(chosen: LatencyZone) -> void:
	if not awaiting or not running:
		return
	awaiting = false
	round_timer.stop()
	_set_zones_locked(true)

	var correct := chosen == correct_zone
	correct_zone.set_mark(LatencyZone.Mark.CORRECT)
	if chosen != null and not correct:
		chosen.set_mark(LatencyZone.Mark.WRONG)
	_refresh_labels(true)
	round_finished.emit(correct)

	if not correct:
		GameManager.lose_heart()

	await get_tree().create_timer(result_delay).timeout
	if not running:
		return
	round_index += 1
	_next_round()

# --- Bandera ---
func _spawn_flag(country: Dictionary) -> void:
	var instance := flag_scene.instantiate()
	var flag := instance as CountryFlag
	if flag == null:
		push_error("flag.tscn: la raiz debe tener country_flag.gd")
		instance.queue_free()
		return
	add_child(flag)
	flag.global_position = flag_marker.global_position

	# Queda por debajo del efecto de pantalla vieja
	var effect := get_node_or_null("ColorRect")
	if effect:
		move_child(flag, effect.get_index())

	flag.setup(_load_flag(country["code"]), country["name"])
	current_flag = flag

func _load_flag(code: String) -> Texture2D:
	var path := flags_folder.path_join(code + ".png")
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("No se encontro la bandera: " + path)
	return null

func _clear_flag() -> void:
	if current_flag != null and is_instance_valid(current_flag):
		current_flag.queue_free()
	current_flag = null

# --- Utilidades ---
func _set_zones_locked(value: bool) -> void:
	for zone in zones:
		zone.set_locked(value)

func _refresh_labels(with_ms: bool) -> void:
	for zone in zones:
		if with_ms:
			zone.show_latency()
		else:
			zone.hide_latency()

# --- Fin del minijuego ---
func _on_game_over() -> void:
	if not running:
		return
	running = false
	awaiting = false
	round_timer.stop()
	_set_zones_locked(true)
	_clear_flag()
	failed.emit()
