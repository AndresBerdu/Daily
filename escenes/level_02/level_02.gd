extends Node2D

signal minigame_completed(number: int)  

# ============================================================
# CONSTANTES
# ============================================================
const COIN_REWARD := 10
const YUDERNIS_SIDE := preload("res://assets/sprites/characters/npc/yudernis_neleixys/character_boss_yudernis_nileixys_idle_side.png")
const YUDERNIS_DOWN := preload("res://assets/sprites/characters/npc/yudernis_neleixys/character_boss_yudernis_neleixys_idle_down.png")

# ============================================================
# NODOS
# ============================================================
# --- Minijuegos ---
@onready var minigame_4: Pc = $Pcs/PacketPc
@onready var minigame_5: Pc = $Pcs/SecurityPc
@onready var minigame_6: BeltPackets = $BeltPackets

# --- Tarjetas de acceso ---
@export_group("Tarjetas de acceso")
@export var card_access_tier_4: ItemData = preload("res://src/components/items/props/card_access/card_access_tier_4.tres")
@export var card_access_tier_5: ItemData = preload("res://src/components/items/props/card_access/card_access_tier_5.tres")
@export var card_access_tier_6: ItemData = preload("res://src/components/items/props/card_access/card_access_tier_6.tres")

# --- Torniquetes y ascensor ---
@onready var ticket_gate_1: TicketGate = $TicketsGate/TicketGate
@onready var ticket_gate_2: TicketGate = $TicketsGate/TicketGate2
@onready var ticket_gate_3: TicketGate = $TicketsGate/TicketGate3
@onready var elevator: Elevator = $Elevator

# --- Personajes ---
@onready var npc_yudernis: Npc = $Npcs/JefeYudernisNeleixys
@onready var player: Player = $Player

# --- Marcadores ---
@onready var spawner_yudernis: Marker2D = $SpawnersNpcs/SpawnerYudernis      # junto a los torniquetes
@onready var spawner_yudernis_2: Marker2D = $SpawnersNpcs/SpawnerYudernis2   # al cruzar teleport_1
@onready var spawner_yudernis_3: Marker2D = $SpawnersNpcs/SpawnerYudernis3   # junto al minijuego 6
@onready var spawner_player: Marker2D = $SpawnersNpcs/SpawnerPlayer          # jugador en el minijuego 6

# --- Zona que mueve al jefe despues de darte la tarjeta 5 ---
@onready var teleport_1: Area2D = $Teleports/TeleportYudernis

# --- Obstaculos que bloquean el camino al inicio ---
@onready var boxes: StaticBody2D = $Obstacle

# ============================================================
# ESTADO
# ============================================================
# --- Conversacion ---
var talk_first_boss := false     # ya hablo con el jefe por primera vez
var card5_given := false         # el jefe ya entrego la tarjeta 5
var card6_given := false         # el jefe ya entrego la tarjeta 6

# --- Posicion del jefe ---
var boss_at_gate_1 := false      # ya se movio al recoger el traje y la tarjeta 4
var boss_at_zone_2 := false      # ya se movio al cruzar teleport_1

# --- Minijuegos ---
var minigame_4_done := false
var minigame_5_done := false
var minigame_6_done := false
var belt_started := false
var minigame_6_requested := false   # el dialogo lo pidio; arranca al cerrarse

# --- Ascensor ---
var elevator_opened := false
var belt_ready := false       # true cuando el jugador ya fue llevado a la sala 6
var rewarded := {}  

func _ready() -> void:
	minigame_4.completed.connect(_on_minigame_4_completed)
	minigame_5.completed.connect(_on_minigame_5_completed)
	minigame_6.completed.connect(_on_belt_completed)
	minigame_6.failed.connect(_on_belt_failed)

	teleport_1.body_entered.connect(_on_teleport_1_entered)
	InventoryManager.item_added.connect(_on_item_added)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	# Red de seguridad: el minijuego 6 no puede estar corriendo antes de tiempo
	if minigame_6.running:
		minigame_6.stop()

# ============================================================
# EVENTOS DE LA HISTORIA
# ============================================================

# Al recoger el traje y la tarjeta 4: el jefe baja a los torniquetes y se abre el primero
func _on_item_added(_id: String, _amount: int) -> void:
	if boss_at_gate_1 or not has_card_tier_4_and_suit():
		return

	boss_at_gate_1 = true
	_move_boss(spawner_yudernis, false)
	ticket_gate_1.open_ticket_gate()


# Al cruzar la zona (con la tarjeta 5 ya entregada) el jefe pasa al spawner 2
func _on_teleport_1_entered(body: Node) -> void:
	if not body.is_in_group("player") or not card5_given or boss_at_zone_2:
		return

	boss_at_zone_2 = true
	_move_boss(spawner_yudernis_2, true)


# Coloca al jefe en un marcador y lo orienta
func _move_boss(marker: Marker2D, look_left: bool) -> void:
	npc_yudernis.global_position = marker.global_position

	var sprite := npc_yudernis.get_node("Sprite2D") as Sprite2D
	sprite.texture = YUDERNIS_SIDE if look_left else YUDERNIS_DOWN
	sprite.flip_h = look_left

	npc_yudernis.face_left = look_left
	npc_yudernis.set_meta("facing", "h" if look_left else "d")
	npc_yudernis.play_anim("idle")


# ============================================================
# MINIJUEGOS
# ============================================================

func _on_minigame_4_completed() -> void:
	_complete_minigame(4)


func _on_minigame_5_completed() -> void:
	_complete_minigame(5)


func _on_belt_completed() -> void:
	_complete_minigame(6)


# Marca el minijuego como hecho y da la recompensa una sola vez
func _complete_minigame(number: int) -> void:
	if rewarded.has(number):
		return
	rewarded[number] = true

	match number:
		4: minigame_4_done = true
		5: minigame_5_done = true
		6: minigame_6_done = true

	GameManager.add_coins(COIN_REWARD)
	minigame_completed.emit(number)


func _on_belt_failed() -> void:
	belt_started = false          # permite volver a hablar con el jefe y reintentar


# La llama el dialogo: solo marca la peticion. Arranca al cerrarse el dialogo
func request_belt_minigame() -> void:
	if belt_ready and not belt_started:
		minigame_6_requested = true


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if minigame_6_requested and not belt_started:
		minigame_6_requested = false
		belt_started = true
		minigame_6.start()


# ============================================================
# FUNCIONES QUE LLAMAN LOS DIALOGOS
# ============================================================

# Quita las cajas que bloquean el camino
func delete_boxes() -> void:
	if is_instance_valid(boxes):
		boxes.queue_free()


# Tarjeta 5: se entrega y se abre el torniquete 2
func give_card_tier_5() -> void:
	if card5_given:
		return
	card5_given = true
	InventoryManager.add_data(card_access_tier_5, 1)
	ticket_gate_2.open_ticket_gate()


# Tarjeta 6: se entrega y se abre el torniquete 3
func give_card_tier_6() -> void:
	if card6_given:
		return
	card6_given = true
	InventoryManager.add_data(card_access_tier_6, 1)
	ticket_gate_3.open_ticket_gate()


# Lleva al jugador y al jefe a la sala del minijuego 6, con transicion
func teleport_to_belt() -> void:
	await SceneTransition.play(_do_teleport_to_belt)


func _do_teleport_to_belt() -> void:
	player.velocity = Vector2.ZERO
	player.global_position = spawner_player.global_position
	_move_boss(spawner_yudernis_3, false)

	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.reset_smoothing()

	belt_ready = true


# Deja operativo el ascensor al siguiente nivel
func open_elevator() -> void:
	if elevator_opened:
		return
	elevator_opened = true
	elevator.is_elevator_operational = true


# ============================================================
# CONSULTAS PARA LOS DIALOGOS
# ============================================================

func has_card_tier_4_and_suit() -> bool:
	return InventoryManager.has_item("card_access_tier_4") \
			and InventoryManager.has_item("suit_security")
