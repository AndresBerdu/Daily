extends Node2D

signal minigame_completed(number: int)  

# ============================================================
# CONSTANTES
# ============================================================
const COIN_REWARD := 30               # Monedas por minijuego completado
const YUDERNIS_SIDE := preload("res://assets/sprites/characters/npc/yudernis_neleixys/character_boss_yudernis_nileixys_idle_side.png")
const YUDERNIS_DOWN := preload("res://assets/sprites/characters/npc/yudernis_neleixys/character_boss_yudernis_neleixys_idle_down.png")
const GOLDEN_TICKET := preload("res://src/components/items/props/golden_ticket.tres")
const GOOGLE_CERT_ID := "google_certificate"
const AWS_CERT_ID := "aws_certificate"

# Objeto que se gasta al completar cada minijuego (numero -> id del item)
const MINIGAME_ITEMS := {
	5: GOOGLE_CERT_ID,
	6: AWS_CERT_ID,
}

# Variables que se guardan con la partida (ver save_state / _apply_loaded_state)
const SAVED_VARS := [
	"talk_first_boss", "card5_given", "card6_given",
	"boss_at_gate_1", "boss_at_zone_2", "boss_at_zone_3",
	"minigame_4_done", "minigame_5_done", "minigame_6_done",
	"elevator_opened", "boxes_deleted",
]

# ============================================================
# NODOS
# ============================================================
@onready var start_minigame_sfx: AudioStreamPlayer = $StartMinigameSfx            # suena al empezar un minijuego
@onready var minigame_finished_sfx: AudioStreamPlayer = $MinigameFinishedSfx    # suena al completarlo

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

# --- Marcadores ---
@onready var spawner_yudernis: Marker2D = $SpawnersNpcs/SpawnerYudernis      # junto a los torniquetes
@onready var spawner_yudernis_2: Marker2D = $SpawnersNpcs/SpawnerYudernis2   # al cruzar teleport_1
@onready var spawner_yudernis_3: Marker2D = $SpawnersNpcs/SpawnerYudernis3   # junto al minijuego 6
@onready var spawner_player: Marker2D = $SpawnersNpcs/SpawnerPlayer          # jugador en el minijuego 6

# --- Zona que mueve al jefe despues de darte la tarjeta 5 ---
@onready var teleport_1: Area2D = $Teleports/TeleportYudernis
@onready var teleport_2: Area2D = $Teleports/TeleportYudernis2   # con la tarjeta 6, el jefe pasa junto al minijuego 6

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
var boss_at_zone_3 := false      # ya se movio al cruzar teleport_2 (junto al minijuego 6)

# --- Minijuegos ---
var minigame_4_done := false
var minigame_5_done := false
var minigame_6_done := false
var belt_started := false

# --- Ascensor ---
var elevator_opened := false
var boxes_deleted := false    # ya se quitaron las cajas del inicio
var belt_ready := false       # true cuando el jugador ya fue llevado a la sala 6
var rewarded := {}  

func _ready() -> void:
	# Apariencias del jefe para npc_yudernis.face()/teleport_to() (mejor: asignalas en el Inspector del NPC)
	npc_yudernis.texture_side = YUDERNIS_SIDE
	npc_yudernis.texture_down = YUDERNIS_DOWN

	minigame_5.required_item_id = GOOGLE_CERT_ID
	minigame_5.locked_text = "Necesitas el certificado de Google."
	
	minigame_4.completed.connect(_on_minigame_4_completed)
	minigame_5.completed.connect(_on_minigame_5_completed)
	minigame_6.completed.connect(_on_belt_completed)
	minigame_6.failed.connect(_on_belt_failed)

	teleport_1.body_entered.connect(_on_teleport_1_entered)
	teleport_2.body_entered.connect(_on_teleport_2_entered)
	InventoryManager.item_added.connect(_on_item_added)

	# Red de seguridad: el minijuego 6 no puede estar corriendo antes de tiempo
	if minigame_6.running:
		minigame_6.stop()

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
	if boxes_deleted:
		LevelUtils.remove_node(boxes)

	# El jefe vuelve al ultimo lugar donde estaba
	if boss_at_zone_3:
		npc_yudernis.teleport_to(spawner_yudernis_3)
	elif boss_at_zone_2:
		npc_yudernis.teleport_to(spawner_yudernis_2, "h", true)
	elif boss_at_gate_1:
		npc_yudernis.teleport_to(spawner_yudernis)

	if boss_at_gate_1:
		LevelUtils.open_gates([ticket_gate_1])
	if card5_given:
		LevelUtils.open_gates([ticket_gate_2])
	if card6_given:
		LevelUtils.open_gates([ticket_gate_3])
	if elevator_opened:
		elevator.is_elevator_operational = true

	# Minijuegos ya completados: no se repiten ni vuelven a dar premio
	var done := {4: minigame_4_done, 5: minigame_5_done, 6: minigame_6_done}
	for number in done:
		if done[number]:
			rewarded[number] = true
	if minigame_4_done:
		minigame_4.mark_done()
	if minigame_5_done:
		minigame_5.mark_done()

# ============================================================
# EVENTOS DE LA HISTORIA
# ============================================================

# Al recoger el traje y la tarjeta 4: el jefe baja a los torniquetes y se abre el primero
func _on_item_added(_id: String, _amount: int) -> void:
	if boss_at_gate_1 or not has_card_tier_4_and_suit():
		return

	boss_at_gate_1 = true
	npc_yudernis.teleport_to(spawner_yudernis)
	LevelUtils.open_gates([ticket_gate_1])


# Al cruzar la zona (con la tarjeta 5 ya entregada) el jefe pasa al spawner 2
func _on_teleport_1_entered(body: Node) -> void:
	if not body.is_in_group("player") or not card5_given or boss_at_zone_2:
		return

	boss_at_zone_2 = true
	npc_yudernis.teleport_to(spawner_yudernis_2, "h", true)


# Al cruzar la segunda zona (con la tarjeta 6 ya entregada) el jefe pasa junto al minijuego 6
func _on_teleport_2_entered(body: Node) -> void:
	if not body.is_in_group("player") or not card6_given or boss_at_zone_3:
		return

	boss_at_zone_3 = true
	npc_yudernis.teleport_to(spawner_yudernis_3)


# ============================================================
# MINIJUEGOS
# ============================================================

func _on_minigame_4_completed() -> void:
	_complete_minigame(4)


func _on_minigame_5_completed() -> void:
	_complete_minigame(5)


func _on_belt_completed() -> void:
	minigame_finished_sfx.play()
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

	if MINIGAME_ITEMS.has(number):
		InventoryManager.remove_item(MINIGAME_ITEMS[number])

	GameManager.set_flag("minigame_%d_done" % number)
	GameManager.add_coins(COIN_REWARD)
	minigame_completed.emit(number)


func _on_belt_failed() -> void:
	belt_started = false          # permite volver a hablar con el jefe y reintentar


# La llama el dialogo: el minijuego 6 arranca cuando el dialogo se cierra
func request_belt_minigame() -> void:
	if belt_ready and not belt_started and has_aws_cert():
		belt_started = true
		LevelUtils.after_dialogue(_start_belt)


# Arranca el minijuego 6 con su sonido de inicio
func _start_belt() -> void:
	start_minigame_sfx.play()
	minigame_6.start()


# ============================================================
# FUNCIONES QUE LLAMAN LOS DIALOGOS
# ============================================================

# Quita las cajas que bloquean el camino
func delete_boxes() -> void:
	boxes_deleted = true
	LevelUtils.remove_node(boxes)


# Tarjeta 5: se entrega y se abre el torniquete 2
func give_card_tier_5() -> void:
	if card5_given:
		return
	card5_given = true
	GameManager.set_flag("card5_given")
	LevelUtils.give_card(card_access_tier_5, [ticket_gate_2])


# Tarjeta 6: se entrega y se abre el torniquete 3
func give_card_tier_6() -> void:
	if card6_given:
		return
	card6_given = true
	LevelUtils.give_card(card_access_tier_6, [ticket_gate_3])


# Lleva al jugador y al jefe a la sala del minijuego 6, con transicion
func teleport_to_belt() -> void:
	await SceneTransition.play(_do_teleport_to_belt)


func _do_teleport_to_belt() -> void:
	PlayerControl.teleport_to(spawner_player)
	npc_yudernis.teleport_to(spawner_yudernis_3)
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

func has_token() -> bool:
	return InventoryManager.has_item("token")


func give_golden_ticket_to_charlie() -> void:
	GameManager.set_flag(GameFlow.FLAG_TOKEN_TO_CHARLIE)      # decide el final del juego
	InventoryManager.remove_item("token", 1)
	InventoryManager.add_data(GOLDEN_TICKET, 1)


func give_token_to_suspect() -> void:
	if not InventoryManager.remove_item("token"):
		return
	GameManager.set_flag(GameFlow.FLAG_TOKEN_TO_STRANGER)
	GameManager.add_coins(999)


func has_google_cert() -> bool:
	return InventoryManager.has_item(GOOGLE_CERT_ID)


func has_aws_cert() -> bool:
	return InventoryManager.has_item(AWS_CERT_ID)


# true cuando el jugador ya fue llevado a la sala del minijuego 6
func is_belt_ready() -> bool:
	return belt_ready
