class_name Level01
extends Node2D

signal time_changed(seconds_left: int)
signal level_finished(won: bool, coins_earned: int)

const GAME_DURATION := 120.0
const COIN_REWARD := 10

@export var min_spawn := 3.0
@export var max_spawn := 6.0
@export var max_simultaneous := 2
@export var worker_textures: Array[Texture2D]
@export var suit_box: Item

@onready var spawner: Marker2D = $SpawnerMinigame1
@onready var workers_node: Node = $Workers

var time_left := GAME_DURATION
var running := false
var workers: Array[OfficeWorker] = []
var spawn_timer := Timer.new()
var started := false
var suit_obtained := false
var minigame_requested := false
var box_open := false

func _ready() -> void:
	# --- Trabajadores (están dentro del nodo Workers) ---
	for child in workers_node.get_children():
		var w := child as OfficeWorker
		if w == null:
			push_warning("%s no usa office_worker.gd, se ignora" % child.name)
			continue
		workers.append(w)
		w.problem_failed.connect(_on_worker_failed)

	# --- Apariencia aleatoria (misma por partida) ---
	_assign_appearances()

	# --- Vidas ---
	GameManager.game_over.connect(_on_game_over)

	# --- Timer de aparición de problemas ---
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_problem)
	add_child(spawn_timer)

	# --- Caja del traje y flujo con Sara ---
	suit_box.collected.connect(_on_suit_collected)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func unlock_box() -> void:
	box_open = true

func is_box_unlocked() -> bool:
	return box_open

func has_suit() -> bool:
	return suit_obtained

func _on_suit_collected(_item: Item) -> void:
	suit_obtained = true   # ya no arranca nada aquí

# La llama el diálogo de Sara
func request_minigame() -> void:
	if not started:
		minigame_requested = true

func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if minigame_requested and not started:
		minigame_requested = false
		started = true
		_begin_minigame()

func _begin_minigame() -> void:
	await SceneTransition.play(_teleport_player)
	start_level()

func _teleport_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		player.global_position = spawner.global_position
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.reset_smoothing()

func _assign_appearances() -> void:
	if worker_textures.is_empty():
		return
	for w in workers:
		var index := hash("%d_%s" % [GameManager.appearance_seed, w.name]) % worker_textures.size()
		w.set_appearance(worker_textures[index])

func start_level() -> void:
	time_left = GAME_DURATION
	running = true
	time_changed.emit(int(time_left))
	_schedule_next_spawn()

func _process(delta: float) -> void:
	if not running:
		return
		
	time_left -= delta
	time_changed.emit(max(0, ceili(time_left)))
	
	if time_left <= 0.0:
		_finish(true)

func _schedule_next_spawn() -> void:
	spawn_timer.start(randf_range(min_spawn, max_spawn))

func _spawn_problem() -> void:
	if not running:
		return
		
	var active := workers.filter(func(w): return w.has_problem)
	
	if active.size() < max_simultaneous:
		var available := workers.filter(func(w): return not w.has_problem)
		
		if available.size() > 0:
			available.pick_random().start_problem()
			
	_schedule_next_spawn()

func _on_worker_failed() -> void:
	if running:
		GameManager.lose_heart()

func _on_game_over() -> void:
	_finish(false)

func _finish(won: bool) -> void:
	if not running:
		return
		
	running = false
	spawn_timer.stop()
	
	for w in workers:
		w.stop_problem()
		
	var earned := 0
	
	if won:
		earned = COIN_REWARD
		GameManager.add_coins(earned)
		
	level_finished.emit(won, earned)
