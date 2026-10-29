class_name Level03
extends Node2D

# ============================================================
# SEÑALES
# ============================================================
signal time_changed(seconds_left: int)    # para un contador en el HUD
signal minigame_finished(won: bool)

# ============================================================
# CONSTANTES
# ============================================================
const COIN_REWARD := 10
const GAME_DURATION := 120.0      # 2 minutos
const SERVERS_NEEDED := 4         # servidores dañados que hay que reparar
const CREDENTIALS_ID := "credentials"

# ============================================================
# CONFIGURACIÓN DESDE EL INSPECTOR
# ============================================================
@export var server_scene: PackedScene     # server.tscn (raíz con cable_server.gd)
@export var npc_boss: Npc                 # el jefe Jeff Besos
@export var minigame_8_pc: Pc             # PC de las zonas de disponibilidad

# ============================================================
# NODOS
# ============================================================
@onready var server_markers_node: Node2D = $ServersSpawner
@onready var spawn_player_room: Marker2D = $TeleportPlayers/SpawnPlayer1   # sala de servidores
@onready var spawn_player_boss: Marker2D = $TeleportPlayers/SpawnPlayer2   # junto al jefe
@onready var boss_spawn_1: Marker2D = $SpawnerNpcs/SpawnerJeffBesos         # 1er lugar del jefe
@onready var boss_area: Area2D = $DetedAreaNpcTp/Area2D                     # zona que mueve al jefe
@onready var boxes_node: Node2D = $Boxes
# ============================================================
# ESTADO
# ============================================================
# --- Progreso de la historia ---
var met_boss := false                # ya hablaste con el jefe por primera vez
var boss_at_spawn_1 := false         # el jefe ya está en su primer lugar
var minigame_7_done := false         # servidores reparados
var minigame_7_failed := false       # se acabó el tiempo o te quedaste sin corazones
var minigame_8_done := false         # zonas de disponibilidad completadas

# --- Minijuego 7 ---
var running := false
var started := false                 # el minijuego 7 ya se pidió o arrancó
var requested := false               # el diálogo lo pidió; arranca al cerrarse
var time_left := GAME_DURATION
var repaired := 0

var markers: Array[Marker2D] = []
var servers: Array[CableServer] = []


func _ready() -> void:
	for child in server_markers_node.get_children():
		if child is Marker2D:
			markers.append(child)

	boss_area.body_entered.connect(_on_boss_area_entered)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	GameManager.game_over.connect(_on_game_over)

	# El PC del minijuego 8 exige las credenciales
	if minigame_8_pc:
		minigame_8_pc.required_item_id = CREDENTIALS_ID
		minigame_8_pc.locked_text = "Necesitas tus credenciales para usar este PC."
		minigame_8_pc.completed.connect(_on_minigame_8_completed)


# ============================================================
# EL JEFE
# ============================================================

# Al pisar la zona, el jefe pasa a su primer lugar.
# Solo cuenta si ya hablaste con él o ya terminaste el minijuego 7
func _on_boss_area_entered(body: Node) -> void:
	if not body.is_in_group("player") or boss_at_spawn_1:
		return
	if not (met_boss or minigame_7_done):
		return
	_move_boss_to_spawn_1()


func _move_boss_to_spawn_1() -> void:
	if npc_boss == null:
		return
	boss_at_spawn_1 = true
	npc_boss.global_position = boss_spawn_1.global_position
	npc_boss.set_meta("facing", "d")
	npc_boss.play_anim("idle")

# El jefe empieza a hablar solo, con un título concreto del diálogo
func _boss_speaks(title: String) -> void:
	if npc_boss == null or npc_boss.dialogue_resource == null:
		return
	DialogueManager.show_dialogue_balloon(npc_boss.dialogue_resource, title, [npc_boss, self])
# ============================================================
# FLUJO DEL MINIJUEGO 7
# ============================================================

# La llama el diálogo del jefe: solo marca la petición.
# El minijuego arranca cuando el diálogo se cierra
func request_minigame() -> void:
	if started:
		return
	minigame_7_failed = false
	requested = true


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if requested and not started:
		requested = false
		started = true
		_begin_minigame()


func _begin_minigame() -> void:
	await SceneTransition.play(_enter_room)

	repaired = 0
	time_left = GAME_DURATION
	running = true
	time_changed.emit(int(time_left))


# Teletransporta al jugador a la sala y coloca los servidores (con la pantalla en negro)
func _enter_room() -> void:
	_teleport_player(spawn_player_room)
	_spawn_servers()


# Elige 4 de los marcadores al azar y pone un servidor en cada uno
func _spawn_servers() -> void:
	_clear_servers()

	if server_scene == null:
		push_error("Level03: asigna Server Scene en el Inspector")
		return

	var spots := markers.duplicate()
	spots.shuffle()

	for i in mini(SERVERS_NEEDED, spots.size()):
		var server := server_scene.instantiate() as CableServer
		if server == null:
			push_error("server.tscn: la raíz debe tener cable_server.gd")
			return
		add_child(server)
		server.global_position = (spots[i] as Marker2D).global_position
		server.repaired.connect(_on_server_repaired)
		servers.append(server)


func _clear_servers() -> void:
	for server in servers:
		if is_instance_valid(server):
			server.queue_free()
	servers.clear()


func _on_server_repaired() -> void:
	if not running:
		return
	repaired += 1
	if repaired >= SERVERS_NEEDED:
		_finish(true)


# Cuenta atrás de 2 minutos
func _process(delta: float) -> void:
	if not running:
		return

	time_left -= delta
	time_changed.emit(max(0, ceili(time_left)))

	if time_left <= 0.0:
		_finish(false)


# Sin corazones durante el minijuego
func _on_game_over() -> void:
	_finish(false)


func _finish(won: bool) -> void:
	if not running:
		return
	running = false     # primero: así lose_heart() no vuelve a entrar aquí

	# Cierra cualquier ventana de cables que siga abierta
	for server in servers:
		if is_instance_valid(server):
			server.force_close()

	if won:
		minigame_7_done = true
		GameManager.add_coins(COIN_REWARD)
	else:
		minigame_7_failed = true
		started = false             # permite hablar con el jefe y reintentar
		GameManager.lose_heart()

	minigame_finished.emit(won)
	await SceneTransition.play(_return_to_boss)

	# Ganaste: las cajas desaparecen y el camino queda libre
	if won:
		_remove_boxes()
		_boss_speaks("servers_done")


# Devuelve al jugador junto al jefe y retira los servidores
func _return_to_boss() -> void:
	_teleport_player(spawn_player_boss)
	_clear_servers()    # el jefe siempre está ahí al volver

# Las cajas se desvanecen y se eliminan; su colisión desaparece con ellas
func _remove_boxes() -> void:
	if not is_instance_valid(boxes_node):
		return
	var tween := create_tween()
	tween.tween_property(boxes_node, "modulate:a", 0.0, 0.6)
	tween.tween_callback(boxes_node.queue_free)

# Mueve al jugador a un marcador y reinicia su velocidad y la cámara
func _teleport_player(target: Marker2D) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	player.global_position = target.global_position
	if player is CharacterBody2D:
		player.velocity = Vector2.ZERO

	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.reset_smoothing()


# ============================================================
# MINIJUEGO 8: zonas de disponibilidad
# ============================================================

func _on_minigame_8_completed() -> void:
	if minigame_8_done:
		return
	minigame_8_done = true
	GameManager.add_coins(COIN_REWARD)


# ============================================================
# CONSULTAS PARA LOS DIÁLOGOS
# ============================================================

func has_credentials() -> bool:
	return InventoryManager.has_item(CREDENTIALS_ID)
