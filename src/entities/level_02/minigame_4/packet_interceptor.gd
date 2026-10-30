class_name PacketInterceptor
extends Control

signal completed       # el jugador sobrevivió
signal failed          # te quedaste sin corazones
signal car_hit         # el camión chocó (la carrera se reinicia)

@export var ground_obstacles: Array[PackedScene]   # virus, bomb, wall
@export var air_obstacles: Array[PackedScene]      # hook
@export_range(0.0, 1.0) var air_chance := 0.3      # probabilidad de que salga un hook

@export_group("Velocidad")
@export var start_speed := 150.0
@export var max_speed := 300.0
@export var speed_gain := 4.0        # cuánto sube por segundo

@export_group("Reglas")
@export var min_gap := 1.5           # segundos entre obstáculos
@export var max_gap := 3.0
@export var survive_seconds := 30.0
@export var restart_delay := 1.0

@onready var spawner_ground: Marker2D = $SpawnerEnemy1
@onready var spawner_air: Marker2D = $SpawnerEnemy2
@export var despawn_margin := 48.0 
@onready var car: PacketCar = $CarPacket
@onready var shutdown: Control = $WindowShutDown
@onready var btn_on: BaseButton = $BtnOn
@onready var playfield: Control = $Playfield
@onready var button_sfx: AudioStreamPlayer = $ButtonSfx
@onready var hit_sfx: AudioStreamPlayer = $HitSfx

@export var hit_costs_heart := true    # cada choque quita un corazón

var spawn_timer := Timer.new()
var running := false
var finished := false
var speed := 0.0
var elapsed := 0.0


func _ready() -> void:
	shutdown.show()          # PC apagado hasta presionar el botón
	btn_on.show()
	btn_on.pressed.connect(_on_power_on)

	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_obstacle)
	add_child(spawn_timer)
	GameManager.game_over.connect(_on_game_over)

func _on_power_on() -> void:
	button_sfx.play()
	btn_on.hide()
	shutdown.hide()
	_start_run()

func _start_run() -> void:
	get_tree().call_group("packet_obstacle", "queue_free")
	elapsed = 0.0
	speed = start_speed
	running = true
	car.start()
	_schedule_next()

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	speed = minf(max_speed, speed + speed_gain * delta)
	get_tree().call_group("packet_obstacle", "set_speed", speed)

	if elapsed >= survive_seconds:
		_win()

func _schedule_next() -> void:
	# El intervalo se acorta al ir más rápido, para mantener la misma distancia
	var gap := randf_range(min_gap, max_gap) * (start_speed / speed)
	spawn_timer.start(gap)

func _spawn_obstacle() -> void:
	if not running:
		return

	var use_air := not air_obstacles.is_empty() and \
			(ground_obstacles.is_empty() or randf() < air_chance)
	var pool: Array[PackedScene] = air_obstacles if use_air else ground_obstacles
	if pool.is_empty():
		return
	var marker := spawner_air if use_air else spawner_ground

	var obstacle := pool.pick_random().instantiate() as PacketObstacle
	playfield.add_child(obstacle)                 # el recorte de Playfield lo oculta fuera de pantalla
	obstacle.global_position = marker.global_position
	obstacle.speed = speed
	obstacle.despawn_x = playfield.global_position.x - despawn_margin
	obstacle.hit.connect(_on_car_hit)

	_schedule_next()

func _on_car_hit() -> void:
	if not running:
		return
	running = false
	spawn_timer.stop()
	car.stop()
	hit_sfx.play()
	get_tree().call_group("packet_obstacle", "set_speed", 0.0)
	car_hit.emit()

	if hit_costs_heart:
		GameManager.lose_heart()      # si era el ultimo, dispara game_over

	if finished:
		return                         # game_over ya cerro el minijuego

	await get_tree().create_timer(restart_delay).timeout
	if not finished:
		_start_run()                   # reinicia solo la carrera, no el nivel

# Sin corazones: detiene todo y avisa al PC
func _on_game_over() -> void:
	if finished:
		return
	finished = true
	running = false
	spawn_timer.stop()
	car.stop()
	get_tree().call_group("packet_obstacle", "queue_free")
	shutdown.show()
	failed.emit()

func _win() -> void:
	finished = true
	running = false
	spawn_timer.stop()
	car.stop()
	get_tree().call_group("packet_obstacle", "queue_free")
	shutdown.show()          # el PC se apaga al terminar
	completed.emit()

func get_board_rect() -> Rect2:
	var frame := $Window as Sprite2D
	var r := frame.get_rect()
	return Rect2(frame.position + r.position * frame.scale, r.size * frame.scale)
