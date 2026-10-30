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
const COIN_REWARD := 40               # Monedas por minijuego completado
const GAME_DURATION := 120.0      # 2 minutos
const SERVERS_NEEDED := 4         # servidores dañados que hay que reparar
const CREDENTIALS_ID := "credentials"

# Variables que se guardan con la partida (ver save_state / _apply_loaded_state)
const SAVED_VARS := [
	"met_boss", "boss_at_spawn_1",
	"minigame_7_done", "minigame_8_done", "boxes_removed",
	"card7_given", "boss_at_spawn_2", "lake_explained",
	"minigame_9_done", "elevator_opened",
]

# ============================================================
# CONFIGURACIÓN DESDE EL INSPECTOR
# ============================================================
@export var server_scene: PackedScene     # server.tscn (raíz con cable_server.gd)
@export var npc_boss: Npc                 # el jefe Jeff Besos
@export var minigame_8_pc: Pc             # PC de las zonas de disponibilidad

@export_group("Tarjetas de acceso")
@export var card_access_tier_7: ItemData = preload("res://src/components/items/props/card_access/card_access_tier_7.tres")

# ============================================================
# NODOS
# ============================================================
@onready var start_minigame_sfx: AudioStreamPlayer = $StartMinigameSfx            # suena al empezar un minijuego
@onready var minigame_finished_sfx: AudioStreamPlayer = $MinigameFinishedSfx    # suena al completarlo
@onready var server_markers_node: Node2D = $ServersSpawner
@onready var spawn_player_room: Marker2D = $TeleportPlayers/SpawnPlayer1   # sala de servidores
@onready var spawn_player_boss: Marker2D = $TeleportPlayers/SpawnPlayer2   # junto al jefe
@onready var boss_spawn_1: Marker2D = $SpawnerNpcs/SpawnerJeffBesos         # 1er lugar del jefe
@onready var boss_area: Area2D = $DetedAreaNpcTp/JeffBesosTp                # zona que lleva al jefe a su 1er lugar
@onready var boss_area_2: Area2D = $DetedAreaNpcTp/JeffBesosTp2            # zona que lo lleva a la sala del data lake
@onready var boxes_node: Node2D = $Boxes
@onready var boss_spawn_2: Marker2D = $SpawnerNpcs/SpawnerJeffBesos2       # 2do lugar del jefe (sala del data lake)
@onready var ticket_gate: TicketGate = $TicketGates/TicketGate             # ultimo torniquete
@onready var elevator: Elevator = $Elevator
@onready var minigame_9_pc: Pc = $Pcs/Pc2                                  # PC del data lake
# ============================================================
# ESTADO
# ============================================================
# --- Progreso de la historia ---
var met_boss := false                # ya hablaste con el jefe por primera vez
var boss_at_spawn_1 := false         # el jefe ya está en su primer lugar
var minigame_7_done := false         # servidores reparados
var minigame_7_failed := false       # se acabó el tiempo o te quedaste sin corazones
var minigame_8_done := false         # zonas de disponibilidad completadas
var boxes_removed := false           # las cajas del camino ya desaparecieron
var card7_given := false             # el jefe ya entrego la tarjeta del ultimo torniquete
var boss_at_spawn_2 := false         # el jefe ya esta en la sala del data lake
var lake_explained := false          # el jefe ya explico el data lake
var minigame_9_done := false         # data lake organizado
var elevator_opened := false         # el jefe dejo operativo el ascensor

# --- Minijuego 7 ---
var running := false
var started := false                 # el minijuego 7 ya se pidió o arrancó
var time_left := GAME_DURATION
var repaired := 0

var markers: Array[Marker2D] = []
var servers: Array[CableServer] = []


func _ready() -> void:
	for child in server_markers_node.get_children():
		if child is Marker2D:
			markers.append(child)

	boss_area.body_entered.connect(_on_boss_area_entered)
	boss_area_2.body_entered.connect(_on_boss_area_2_entered)
	GameManager.game_over.connect(_on_game_over)

	# El PC del minijuego 8 exige las credenciales
	if minigame_8_pc:
		minigame_8_pc.required_item_id = CREDENTIALS_ID
		minigame_8_pc.locked_text = "Necesitas tus credenciales para usar este PC."
		minigame_8_pc.completed.connect(_on_minigame_8_completed)

	minigame_9_pc.completed.connect(_on_minigame_9_completed)

	# Si se cargo una partida, vuelve a dejar el nivel como estaba
	LevelUtils.load_state(self, SAVED_VARS)
	_apply_loaded_state()


# ============================================================
# GUARDADO
# ============================================================

# La llaman SaveManager al guardar y SceneTransition al salir del nivel
func save_state() -> void:
	LevelUtils.store_state(self, SAVED_VARS)


# Reaplica en el mundo lo que el progreso guardado ya habia cambiado
func _apply_loaded_state() -> void:
	if npc_boss:
		if boss_at_spawn_2:
			npc_boss.teleport_to(boss_spawn_2)
		elif boss_at_spawn_1:
			npc_boss.teleport_to(boss_spawn_1)
	if boxes_removed:
		LevelUtils.remove_node(boxes_node)
	if minigame_8_done and minigame_8_pc:
		minigame_8_pc.mark_done()
	if card7_given:
		LevelUtils.open_gates([ticket_gate])
	if minigame_9_done:
		minigame_9_pc.mark_done()
	if elevator_opened:
		elevator.is_elevator_operational = true


# ============================================================
# EL JEFE
# ============================================================

# JeffBesosTp: el jefe pasa a su 1er lugar.
# Solo cuenta si ya hablaste con el o ya terminaste el minijuego 7
func _on_boss_area_entered(body: Node) -> void:
	if not body.is_in_group("player") or boss_at_spawn_1:
		return
	if not (met_boss or minigame_7_done):
		return
	_move_boss_to_spawn_1()


# JeffBesosTp2: con la tarjeta 7 ya entregada, el jefe pasa a la sala del data lake
func _on_boss_area_2_entered(body: Node) -> void:
	if not body.is_in_group("player") or boss_at_spawn_2 or not card7_given:
		return
	boss_at_spawn_2 = true
	if npc_boss:
		npc_boss.teleport_to(boss_spawn_2)


func _move_boss_to_spawn_1() -> void:
	if npc_boss == null:
		return
	boss_at_spawn_1 = true
	npc_boss.teleport_to(boss_spawn_1)

# ============================================================
# FLUJO DEL MINIJUEGO 7
# ============================================================

# La llama el diálogo del jefe: el minijuego arranca cuando el diálogo se cierra
func request_minigame() -> void:
	if started:
		return
	started = true
	minigame_7_failed = false
	LevelUtils.after_dialogue(_begin_minigame)


func _begin_minigame() -> void:
	await SceneTransition.play(_enter_room)
	start_minigame_sfx.play()

	repaired = 0
	time_left = GAME_DURATION
	running = true
	time_changed.emit(int(time_left))


# Teletransporta al jugador a la sala y coloca los servidores (con la pantalla en negro)
func _enter_room() -> void:
	PlayerControl.teleport_to(spawn_player_room)
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
		move_child(server, $Player.get_index())     # antes del Player: el jugador se dibuja encima
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
		minigame_finished_sfx.play()
		GameManager.add_coins(COIN_REWARD)
	else:
		minigame_7_failed = true
		started = false             # permite hablar con el jefe y reintentar
		GameManager.lose_heart()

	minigame_finished.emit(won)
	await SceneTransition.play(_return_to_boss)

	# Ganaste: las cajas desaparecen y el camino queda libre
	if won:
		boxes_removed = true
		LevelUtils.remove_node(boxes_node, 0.6)     # el camino queda libre
		if npc_boss:
			npc_boss.speak("servers_done")


# Devuelve al jugador junto al jefe y retira los servidores
func _return_to_boss() -> void:
	PlayerControl.teleport_to(spawn_player_boss)
	_clear_servers()    # el jefe siempre está ahí al volver

# ============================================================
# MINIJUEGO 8: zonas de disponibilidad
# ============================================================

func _on_minigame_8_completed() -> void:
	if minigame_8_done:
		return
	minigame_8_done = true
	InventoryManager.remove_item(CREDENTIALS_ID)     # las credenciales se gastan
	GameManager.add_coins(COIN_REWARD)


# ============================================================
# TARJETA, MINIJUEGO 9 Y ASCENSOR
# ============================================================

# El jefe entrega la tarjeta y se abre el ultimo torniquete (la llama el dialogo)
func give_card_tier_7() -> void:
	if card7_given:
		return
	card7_given = true
	LevelUtils.give_card(card_access_tier_7, [ticket_gate])


func _on_minigame_9_completed() -> void:
	if minigame_9_done:
		return
	minigame_9_done = true
	GameManager.add_coins(COIN_REWARD)
	# El jefe no habla solo: el jugador debe volver con el para que lo deje ir (abre el ascensor)


# Deja operativo el ascensor (la llama el dialogo)
func open_elevator() -> void:
	elevator_opened = true
	elevator.is_elevator_operational = true


# ============================================================
# CONSULTAS PARA LOS DIÁLOGOS
# ============================================================

func has_credentials() -> bool:
	return InventoryManager.has_item(CREDENTIALS_ID)
