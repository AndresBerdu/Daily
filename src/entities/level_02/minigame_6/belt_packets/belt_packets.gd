class_name BeltPackets
extends Node2D

signal completed
signal failed
signal queue_changed
signal packet_resolved(correct: bool)

@export var packet_scene: PackedScene
@export var main_path: Path2D         # si se deja vacio usa el hijo "Path2D"
@export var good_path: Path2D         # hijo "GoodPath"
@export var bad_path: Path2D          # hijo "BadPath"
@export var left_goes_to_good := true # la flecha izquierda envia al camino bueno
@export var auto_start := false

@export_group("Reglas")
@export var total_packets := 10
@export var spawn_interval := 6.0     # segundos entre intentos de generar un paquete
@export var max_on_belt := 3          # paquetes sin decidir a la vez
@export var belt_speed := 60.0        # pixeles por segundo hasta el centro
@export var packet_spacing := 28.0    # separacion entre paquetes en la fila
@export var decide_time := 40.0       # segundos para decidir, desde que llega al centro
@export var exit_time := 3.0          # segundos que tarda en recorrer el camino elegido
@export_range(0.0, 1.0) var good_chance := 0.4

@export_group("Texturas de la caja")
@export var valid_packet_texture: Texture2D                # 1 paquete sano
@export var corrupted_packet_textures: Array[Texture2D]    # 3 paquetes corruptos

@export_group("Texturas del contenido")
@export var valid_content_texture: Texture2D               # 1 contenido bueno (la nota)
@export var bad_content_textures: Array[Texture2D]         # 3 contenidos maliciosos

var queue: Array[BeltPacket] = []     # paquetes sin decidir; el primero es el mas cercano al centro
var spawn_timer := Timer.new()
var spawned := 0
var finished_count := 0
var path_length := 0.0
var running := false

func _ready() -> void:
	if main_path == null:
		main_path = get_node_or_null("Path2D") as Path2D
	if good_path == null:
		good_path = get_node_or_null("GoodPath") as Path2D
	if bad_path == null:
		bad_path = get_node_or_null("BadPath") as Path2D

	GameManager.game_over.connect(_on_game_over)

	spawn_timer.timeout.connect(_spawn_packet)
	add_child(spawn_timer)

	if auto_start:
		start()

func start() -> void:
	if packet_scene == null or main_path == null or good_path == null or bad_path == null:
		push_error("BeltPackets: faltan Packet Scene o alguno de los tres caminos")
		return
	if main_path.curve == null or main_path.curve.get_baked_length() <= 0.0:
		push_error("BeltPackets: el Path2D principal no tiene una curva valida")
		return

	_clear_packets()
	path_length = main_path.curve.get_baked_length()
	spawned = 0
	finished_count = 0
	running = true
	spawn_timer.start(spawn_interval)
	_spawn_packet()

# --- Generacion de paquetes ---
func _spawn_packet() -> void:
	if not running or spawned >= total_packets:
		return
	# Si la cinta esta llena, espera al siguiente intento
	if queue.size() >= max_on_belt:
		return

	spawned += 1
	if spawned >= total_packets:
		spawn_timer.stop()

	# Un paquete bueno cumple todo; uno malo falla en una sola cosa
	var good := randf() < good_chance
	var flaw := -1 if good else randi() % 3   # 0 = IP, 1 = contenido, 2 = caja corrupta

	var ip := _make_ip(flaw != 0)

	# Contenido: la nota buena o uno de los 3 maliciosos
	var bad_content := flaw == 1 and not bad_content_textures.is_empty()
	var content_tex: Texture2D = valid_content_texture
	if bad_content:
		content_tex = bad_content_textures.pick_random()

	# Caja: la sana o una de las 3 corruptas
	var corrupted := flaw == 2 and not corrupted_packet_textures.is_empty()
	var box_texture: Texture2D = valid_packet_texture
	if corrupted:
		box_texture = corrupted_packet_textures.pick_random()

	var should_be_good := ip_is_valid(ip) and not bad_content and not corrupted

	var instance := packet_scene.instantiate()
	var packet := instance as BeltPacket
	if packet == null:
		push_error("packet.tscn: la raiz debe tener packet.gd")
		instance.queue_free()
		return

	var follower := _make_follower(main_path)
	follower.add_child(packet)

	packet.setup(ip, box_texture, content_tex, should_be_good,
			belt_speed, path_length, decide_time, exit_time)
	packet.reached_center.connect(_on_packet_reached_center)
	packet.timed_out.connect(_on_packet_timed_out)
	packet.finished.connect(_on_packet_finished)

	queue.append(packet)
	_update_slots()
	queue_changed.emit()

func _make_ip(valid: bool) -> String:
	var parts := PackedStringArray()
	for i in 4:
		parts.append(str(randi_range(1, 254)))
	if not valid:
		var i := randi() % 4
		match randi() % 4:
			0: parts[i] = str(randi_range(256, 999))       # octeto fuera de rango
			1: parts.remove_at(i)                          # faltan octetos
			2: parts[i] = "x" + str(randi_range(1, 99))    # letras
			3: parts.append(str(randi_range(1, 254)))      # sobra un octeto
	return ".".join(parts)

static func ip_is_valid(ip: String) -> bool:
	var parts := ip.split(".")
	if parts.size() != 4:
		return false
	for p in parts:
		if not p.is_valid_int():
			return false
		var n := int(p)
		if n < 0 or n > 255:
			return false
	return true

func _make_follower(path: Path2D) -> PathFollow2D:
	var follower := PathFollow2D.new()
	follower.loop = false
	follower.rotates = false            # el texto del paquete no debe girar
	path.add_child(follower)
	return follower

# Cada paquete se detiene detras del anterior, el primero en el final del camino
func _update_slots() -> void:
	for i in queue.size():
		var packet := queue[i]
		packet.target_progress = maxf(0.0, path_length - i * packet_spacing)

# --- Acciones del PC ---
# Solo se puede actuar sobre el paquete que ya llego al centro
func has_front() -> bool:
	return not queue.is_empty() and queue[0].is_waiting()

func front_is_open() -> bool:
	return has_front() and queue[0].opened

func open_front() -> void:
	if has_front():
		queue[0].open()
		queue_changed.emit()

func send_front(left: bool) -> void:
	if not has_front():
		return
	_route(queue[0], left == left_goes_to_good)

# --- Recorrido ---
func _on_packet_reached_center(_packet: BeltPacket) -> void:
	_update_slots()
	queue_changed.emit()

# Se acabo el tiempo sin decidir: va siempre al lado equivocado
func _on_packet_timed_out(packet: BeltPacket) -> void:
	_route(packet, not packet.should_be_good)

func _route(packet: BeltPacket, to_good: bool) -> void:
	packet.decide(BeltPacket.Decision.GOOD if to_good else BeltPacket.Decision.BAD)
	queue.erase(packet)
	_update_slots()
	queue_changed.emit()

	var target := good_path if to_good else bad_path
	_move_to_path.call_deferred(packet, target)

func _move_to_path(packet: BeltPacket, path: Path2D) -> void:
	if not is_instance_valid(packet):
		return
	var old := packet.get_parent()
	old.remove_child(packet)
	old.queue_free()
	var follower := _make_follower(path)
	follower.add_child(packet)
	packet.start_exit()

func _on_packet_finished(packet: BeltPacket) -> void:
	var correct := packet.is_correct()
	packet.get_parent().queue_free()    # elimina el follower y el paquete

	if not correct:
		GameManager.lose_heart()
	finished_count += 1
	packet_resolved.emit(correct)

	if running and finished_count >= total_packets:
		running = false
		completed.emit()

# --- Fin del minijuego ---
func _on_game_over() -> void:
	if not running:
		return
	running = false
	spawn_timer.stop()
	_clear_packets()
	failed.emit()

func _clear_packets() -> void:
	for path in [main_path, good_path, bad_path]:
		if path == null:
			continue
		for child in path.get_children():
			if child is PathFollow2D and child.get_child_count() > 0:
				child.queue_free()
	queue.clear()
	queue_changed.emit()
