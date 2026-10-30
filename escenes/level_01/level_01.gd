class_name Level01
extends Node2D

# ============================================================
# SEÑALES
# ============================================================
signal time_changed(seconds_left: int)               # Segundos restantes del minijuego 1 (para el HUD)
signal level_finished(won: bool, coins_earned: int)  # Resultado del minijuego 1
signal minigame2_finished                            # Se emite al instalar los 24 PCs

# ============================================================
# CONSTANTES
# ============================================================
const COIN_REWARD := 20               # Monedas que se dan al completar cada minijuego
const MINIGAME1_DURATION := 60.0      # Duración del minijuego 1 en segundos (1 minuto)
const ISO_ID := "image_iso"           # Id del ItemData de la imagen ISO
const RELEASE_AGENT_ID := "release_agent"   # Despegante: se gasta al quitar la moneda pegada
const USB_ID := "usb"                 # Id de la USB que se le entrega a Sara

# Variables que se guardan con la partida (ver save_state / _apply_loaded_state)
const SAVED_VARS := [
	"suit_obtained", "box_open", "sara_taking", "martin_taking",
	"card2_given", "card3_given", "elevator_opened",
	"minigame1_done", "installed_count", "repaired_new_pcs",
]

# ============================================================
# CONFIGURACIÓN DESDE EL INSPECTOR
# ============================================================
@export_group("Minijuego 1")
@export var min_spawn := 3.0                    # Tiempo mínimo entre problemas de oficinistas
@export var max_spawn := 6.0                    # Tiempo máximo entre problemas
@export var max_simultaneous := 2               # Problemas activos a la vez
@export var worker_textures: Array[Texture2D]   # Apariencias posibles de los oficinistas
@export var suit_box: Item                      # Caja que contiene el traje de técnico

@export_group("Tarjetas de acceso")
@export var card_access_tier_1: ItemData = preload("res://src/components/items/props/card_access/card_access_tier_1.tres")
@export var card_access_tier_2: ItemData = preload("res://src/components/items/props/card_access/card_access_tier_2.tres")
@export var card_access_tier_3: ItemData = preload("res://src/components/items/props/card_access/card_access_tier_3.tres")

# ============================================================
# NODOS
# ============================================================
@onready var start_minigame_sfx: AudioStreamPlayer = $StartMinigameSfx            # suena al empezar un minijuego
@onready var minigame_finished_sfx: AudioStreamPlayer = $MinigameFinishedSfx    # suena al completarlo

# --- Minijuego 1 ---
@onready var spawner: Marker2D = $Teleports/SpawnerMinigame1   # Destino del teletransporte
@onready var workers_node: Node2D = $Workers                   # Contenedor de los oficinistas

# --- Minijuego 2 ---
@onready var spawner2: Marker2D = $Teleports/SpawnerMinigame2  # Destino del teletransporte
@onready var desktops_node: Node2D = $Desktops                 # Contenedor de los PCs

# --- Minijuego 3 ---
@onready var new_pcs_node: Node2D = $NewPcs                    # Contenedor de los PCs a reparar

# --- Torniquetes, agrupados por nivel de tarjeta ---
@onready var ticket_gate_1: TicketGate = $TicketsGate/Tier1/TicketGate
@onready var ticket_gate_2: TicketGate = $TicketsGate/Tier1/TicketGate2
@onready var ticket_gate_3: TicketGate = $TicketsGate/Tier1/TicketGate3
@onready var ticket_gate_4: TicketGate = $TicketsGate/Tier2/TicketGate4
@onready var ticket_gate_5: TicketGate = $TicketsGate/Tier3/TicketGate5

# --- Ascensor al siguiente nivel ---
@onready var elevator: Elevator = $Elevator

# ============================================================
# ESTADO
# ============================================================
# --- Progreso de la historia ---
var suit_obtained := false            # El jugador ya recogió el traje
var box_open := false                 # Sara ya habló y la caja se puede abrir
var sara_taking := false              # Ya habló con Sara por primera vez
var martin_taking := false            # Ya habló con Martín por primera vez
var card2_given := false              # Martín entregó la tarjeta de nivel 2
var card3_given := false              # Sara entregó la tarjeta de nivel 3
var elevator_opened := false          # Martín activó el ascensor

# --- Minijuego 1 ---
var running := false                  # true mientras corre el minijuego 1
var minigame1_started := false
var minigame1_done := false
var minigame1_time_left := MINIGAME1_DURATION
var workers: Array[OfficeWorker] = []
var spawn_timer := Timer.new()        # Controla cuándo aparece el siguiente problema

# --- Minijuego 2 ---
var desktops: Array[Desktop] = []
var installed_count := 0              # PCs instalados hasta ahora
var minigame2_started := false

# --- Minijuego 3 ---
var repaired_new_pcs: Array = []      # nombres de los PCs ya reparados (se guarda con la partida)


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

	# Registra los PCs del minijuego 3 y escucha cuando se reparan
	for child in new_pcs_node.get_children():
		var pc := child as NewPc
		if pc:
			pc.repaired.connect(_on_new_pc_repaired.bind(pc))

	# Asigna la apariencia de cada oficinista según la semilla de la partida
	_assign_appearances()

	# Si las vidas llegan a 0, termina el minijuego
	GameManager.game_over.connect(_on_game_over)

	# Timer que dispara la aparición de problemas
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_problem)
	add_child(spawn_timer)

	# La caja avisa al recogerse
	suit_box.collected.connect(_on_suit_collected)

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
	if martin_taking:
		LevelUtils.open_gates([ticket_gate_1, ticket_gate_2, ticket_gate_3])   # tarjeta 1
	if card2_given:
		LevelUtils.open_gates([ticket_gate_4])
	if card3_given:
		LevelUtils.open_gates([ticket_gate_5])
	if elevator_opened:
		elevator.is_elevator_operational = true
	for child in new_pcs_node.get_children():
		if child is NewPc and repaired_new_pcs.has(str(child.name)):
			child.mark_done()


# ============================================================
# MINIJUEGO 1: problemas de los oficinistas
# ============================================================

# La llama el diálogo de Sara: el minijuego 1 arranca cuando el diálogo se cierra
func request_minigame() -> void:
	if minigame1_started:
		return
	minigame1_started = true
	LevelUtils.after_dialogue(_begin_minigame)


# Teletransporta al jugador y arranca el contador y la aparición de problemas
func _begin_minigame() -> void:
	await SceneTransition.play(PlayerControl.teleport_to.bind(spawner))
	start_minigame_sfx.play()

	minigame1_time_left = MINIGAME1_DURATION
	running = true
	time_changed.emit(int(minigame1_time_left))
	_schedule_next_spawn()


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


# Descuenta el tiempo del minijuego 1 y lo termina al llegar a 0
func _process(delta: float) -> void:
	if not running:
		return

	minigame1_time_left -= delta
	time_changed.emit(max(0, ceili(minigame1_time_left)))

	if minigame1_time_left <= 0.0:
		_finish(true)


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
		minigame_finished_sfx.play()
		InventoryManager.remove_item(USB_ID)       # Sara se queda con la USB
		earned = COIN_REWARD
		GameManager.add_coins(earned)
	else:
		minigame1_started = false   # Permite hablar con Sara y reintentar

	level_finished.emit(won, earned)


# Se quedó sin vidas
func _on_game_over() -> void:
	_finish(false)


# ============================================================
# MINIJUEGO 2: instalación en los PCs
# ============================================================

# La llama el diálogo de Martín. Exige haber terminado el minijuego 1 y tener la ISO
func request_minigame2() -> void:
	if minigame1_done and has_image_iso() and not minigame2_started:
		minigame2_started = true
		LevelUtils.after_dialogue(_begin_minigame2)


# Teletransporta al jugador y desbloquea todos los PCs
func _begin_minigame2() -> void:
	await SceneTransition.play(PlayerControl.teleport_to.bind(spawner2))
	start_minigame_sfx.play()

	for d in desktops:
		d.activate()


# Un PC quedó en pantalla azul por no hacer el reboot a tiempo
func _on_desktop_repair_failed(_d: Desktop) -> void:
	GameManager.lose_heart()


# Un PC terminó de instalarse; al completar todos se da la recompensa
func _on_desktop_installed(_d: Desktop) -> void:
	installed_count += 1

	if installed_count >= desktops.size():
		InventoryManager.remove_item(ISO_ID)       # la imagen ISO ya se instalo en los PCs
		minigame_finished_sfx.play()
		minigame2_finished.emit()
		GameManager.add_coins(COIN_REWARD)
		print("Minijuego 2 completado")


# ============================================================
# MINIJUEGO 3: reparacion de PCs
# ============================================================

# Anota el PC reparado para que no haya que repetirlo despues de cargar la partida
func _on_new_pc_repaired(pc: NewPc) -> void:
	var pc_name := str(pc.name)
	if not repaired_new_pcs.has(pc_name):
		repaired_new_pcs.append(pc_name)


# ============================================================
# TARJETAS DE ACCESO Y ASCENSOR (las llaman los diálogos)
# ============================================================

# Martín entrega la tarjeta de nivel 1 y abre los torniquetes del tier 1
func get_card_access() -> void:
	LevelUtils.give_card(card_access_tier_1, [ticket_gate_1, ticket_gate_2, ticket_gate_3])


# Martín entrega la tarjeta de nivel 2 y abre los torniquetes del tier 2
func get_card_access_tier_2() -> void:
	if card2_given:
		return
	card2_given = LevelUtils.give_card(card_access_tier_2, [ticket_gate_4])


# Sara entrega la tarjeta de nivel 3 y abre los torniquetes del tier 3
func get_card_access_tier_3() -> void:
	if card3_given:
		return
	card3_given = LevelUtils.give_card(card_access_tier_3, [ticket_gate_5])


# Martín deja operativo el ascensor hacia el siguiente nivel
func open_elevator() -> void:
	if elevator_opened:
		return
	elevator_opened = true
	elevator.is_elevator_operational = true


# El despegante se gasta al quitar la unica moneda pegada (la llama el dialogo)
func use_release_agent() -> void:
	InventoryManager.remove_item(RELEASE_AGENT_ID)


# Sara habilita la caja del traje
func unlock_box() -> void:
	box_open = true


# ============================================================
# CONSULTAS PARA LOS DIÁLOGOS
# ============================================================

# --- Caja y objetos ---
func is_box_unlocked() -> bool:
	return box_open


func has_suit() -> bool:
	return suit_obtained


func has_usb() -> bool:
	return InventoryManager.has_item(USB_ID)


func has_release_agent() -> bool:
	return InventoryManager.has_item(RELEASE_AGENT_ID)


func has_image_iso() -> bool:
	return InventoryManager.has_item(ISO_ID)


# --- Tarjetas y ascensor ---
func has_card_tier_2() -> bool:
	return card2_given


func has_card_tier_3() -> bool:
	return card3_given


func is_elevator_open() -> bool:
	return elevator_opened


# --- Minijuegos ---
func is_minigame1_done() -> bool:
	return minigame1_done


# True cuando los 24 PCs están instalados
func is_minigame2_done() -> bool:
	return installed_count >= desktops.size() and desktops.size() > 0


# ============================================================
# EVENTOS
# ============================================================

# La caja avisa que el traje fue recogido
func _on_suit_collected(_item: Item) -> void:
	suit_obtained = true
