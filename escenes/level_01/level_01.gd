class_name Level01
extends Node2D

# --- Señales ---
signal time_changed(seconds_left: int)               # Segundos restantes del minijuego 1 (para el HUD)
signal level_finished(won: bool, coins_earned: int)  # Resultado del minijuego 1
signal minigame2_finished                            # Se emite al instalar los 24 PCs

# --- Constantes ---
const COIN_REWARD := 10               # Monedas que se dan al completar cada minijuego
const MINIGAME1_DURATION := 120.0     # Duración del minijuego 1 en segundos

# --- Configuración desde el Inspector ---
@export var min_spawn := 3.0                    # Tiempo mínimo entre problemas de oficinistas
@export var max_spawn := 6.0                    # Tiempo máximo entre problemas
@export var max_simultaneous := 2               # Problemas activos a la vez
@export var worker_textures: Array[Texture2D]   # Apariencias posibles de los oficinistas
@export var suit_box: Item                      # Caja que contiene el traje de técnico

# --- Nodos del minijuego 1 ---
@onready var spawner: Marker2D = $Teleports/SpawnerMinigame1   # Destino del teletransporte
@onready var workers_node: Node2D = $Workers                   # Contenedor de los oficinistas

# --- Nodos del minijuego 2 ---
@onready var spawner2: Marker2D = $Teleports/SpawnerMinigame2  # Destino del teletransporte
@onready var desktops_node: Node2D = $Desktops                 # Contenedor de los PCs

# --- Estado general ---
var running := false                  # true mientras corre el minijuego 1
var spawn_timer := Timer.new()        # Controla cuándo aparece el siguiente problema
var suit_obtained := false            # El jugador ya recogió el traje
var box_open := false                 # Sara ya habló y la caja se puede abrir

# --- Estado del minijuego 1 ---
var minigame1_started := false
var minigame1_done := false
var minigame1_requested := false      # El diálogo pidió empezar; arranca al cerrarse
var minigame1_time_left := MINIGAME1_DURATION
var workers: Array[OfficeWorker] = []

# --- Estado del minijuego 2 ---
var desktops: Array[Desktop] = []
var installed_count := 0              # PCs instalados hasta ahora
var minigame2_requested := false
var minigame2_started := false


func _ready() -> void:
	# Registra los oficinistas y escucha cuando alguno falla
	for child in workers_node.get_children():
		var w := child as OfficeWorker
		if w == null:
			push_warning("%s no usa office_worker.gd, se ignora" % child.name)
			continue
		workers.append(w)
		w.problem_failed.connect(_on_worker_failed)

	# Registra los PCs y escucha cuando se instalan o quedan en pantalla azul
	for child in desktops_node.get_children():
		var d := child as Desktop
		if d:
			desktops.append(d)
			d.installed.connect(_on_desktop_installed)
			d.repair_failed.connect(_on_desktop_repair_failed)

	# Asigna la apariencia de cada oficinista según la semilla de la partida
	_assign_appearances()

	# Si las vidas llegan a 0, termina el minijuego
	GameManager.game_over.connect(_on_game_over)

	# Timer que dispara la aparición de problemas
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_problem)
	add_child(spawn_timer)

	# Flujo con Sara: la caja avisa al recogerse y los diálogos avisan al cerrarse
	suit_box.collected.connect(_on_suit_collected)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


# ============================================================
# MINIJUEGO 1: problemas de los oficinistas
# ============================================================

# La llama el diálogo de Sara para pedir el inicio del minijuego 1
func request_minigame() -> void:
	if not minigame1_started:
		minigame1_requested = true


# Teletransporta al jugador y arranca el contador y la aparición de problemas
func _begin_minigame() -> void:
	await SceneTransition.play(_teleport_player.bind(spawner))

	minigame1_time_left = MINIGAME1_DURATION
	running = true
	time_changed.emit(int(minigame1_time_left))
	_schedule_next_spawn()


# La consulta Sara desde el diálogo
func is_minigame1_done() -> bool:
	return minigame1_done


# Reparte las apariencias con una semilla fija por partida,
# así no cambian al volver a cargar el juego
func _assign_appearances() -> void:
	if worker_textures.is_empty():
		return

	for w in workers:
		var index := hash("%d_%s" % [GameManager.appearance_seed, w.name]) % worker_textures.size()
		w.set_appearance(worker_textures[index])


# Activa un problema en un oficinista libre, respetando el máximo simultáneo
func _spawn_problem() -> void:
	if not running:
		return

	var active := workers.filter(func(w): return w.has_problem)

	if active.size() < max_simultaneous:
		var available := workers.filter(func(w): return not w.has_problem)
		if available.size() > 0:
			available.pick_random().start_problem()

	_schedule_next_spawn()


# Programa el siguiente problema en un tiempo aleatorio
func _schedule_next_spawn() -> void:
	spawn_timer.start(randf_range(min_spawn, max_spawn))


# Un oficinista no fue atendido a tiempo: se pierde un corazón
func _on_worker_failed() -> void:
	if running:
		GameManager.lose_heart()


# ============================================================
# MINIJUEGO 2: instalación en los PCs
# ============================================================

# La llama el diálogo de Sara. Solo vale si el minijuego 1 ya terminó
func request_minigame2() -> void:
	if minigame1_done and not minigame2_started:
		minigame2_requested = true


# Teletransporta al jugador y desbloquea todos los PCs
func _begin_minigame2() -> void:
	await SceneTransition.play(_teleport_player.bind(spawner2))

	for d in desktops:
		d.activate()


# La consulta Sara desde el diálogo: true cuando los 24 PCs están instalados
func is_minigame2_done() -> bool:
	return installed_count >= desktops.size() and desktops.size() > 0


# Un PC quedó en pantalla azul por no hacer el reboot a tiempo
func _on_desktop_repair_failed(_d: Desktop) -> void:
	GameManager.lose_heart()


# Un PC terminó de instalarse; al completar todos se da la recompensa
func _on_desktop_installed(_d: Desktop) -> void:
	installed_count += 1

	if installed_count >= desktops.size():
		minigame2_finished.emit()
		GameManager.add_coins(COIN_REWARD)
		print("Minijuego 2 completado")


# ============================================================
# FLUJO COMPARTIDO (Sara, caja y teletransporte)
# ============================================================

# Sara habilita la caja del traje
func unlock_box() -> void:
	box_open = true


# La caja consulta si ya puede entregar el traje
func is_box_unlocked() -> bool:
	return box_open


# Sara consulta si el jugador ya tiene el traje
func has_suit() -> bool:
	return suit_obtained


# La caja avisa que el traje fue recogido
func _on_suit_collected(_item: Item) -> void:
	suit_obtained = true


# Al cerrarse cualquier diálogo se revisa si había un minijuego pendiente
func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if minigame1_requested and not minigame1_started:
		minigame1_requested = false
		minigame1_started = true
		_begin_minigame()
	elif minigame2_requested and not minigame2_started:
		minigame2_requested = false
		minigame2_started = true
		_begin_minigame2()


# Mueve al jugador a un marcador y reinicia su velocidad y la cámara
func _teleport_player(target: Marker2D) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D

	if player:
		player.global_position = target.global_position

		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO   # Evita que conserve el movimiento anterior

		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.reset_smoothing()            # La cámara salta al nuevo punto sin deslizarse


# ============================================================
# CICLO DEL NIVEL
# ============================================================

# Descuenta el tiempo del minijuego 1 y lo termina al llegar a 0
func _process(delta: float) -> void:
	if not running:
		return

	minigame1_time_left -= delta
	time_changed.emit(max(0, ceili(minigame1_time_left)))

	if minigame1_time_left <= 0.0:
		_finish(true)


# Se quedó sin vidas
func _on_game_over() -> void:
	_finish(false)


# Cierra el minijuego 1. won = true si sobrevivió los 2 minutos
func _finish(won: bool) -> void:
	if not running:
		return

	running = false
	spawn_timer.stop()

	for w in workers:
		w.stop_problem()

	var earned := 0

	if won:
		minigame1_done = true
		earned = COIN_REWARD
		GameManager.add_coins(earned)
	else:
		minigame1_started = false   # Permite hablar con Sara y reintentar

	level_finished.emit(won, earned)
