class_name LevelUtils
extends RefCounted
## Funciones compartidas por todos los niveles. Se usan asi: LevelUtils.nombre(...)


## Ejecuta `action` cuando se cierre el dialogo actual.
## Sirve para "el dialogo pide un minijuego y este arranca al terminar de hablar".
static func after_dialogue(action: Callable) -> void:
	DialogueManager.dialogue_ended.connect(func(_r): action.call(), CONNECT_ONE_SHOT)


## Elimina un nodo; con `fade` > 0 se desvanece antes de borrarse.
static func remove_node(node: Node, fade := 0.0) -> void:
	if not is_instance_valid(node):
		return
	_record_world(node, "removed")      # queda anotado para no volver a aparecer al cargar
	if fade <= 0.0 or not node is CanvasItem:
		node.queue_free()
		return
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, fade)
	tween.tween_callback(node.queue_free)


## Abre una lista de torniquetes (TicketGate).
static func open_gates(gates: Array) -> void:
	for gate in gates:
		if is_instance_valid(gate):
			gate.open_ticket_gate()


## Entrega una tarjeta de acceso y abre los torniquetes que desbloquea.
## Devuelve false si la tarjeta no esta asignada.
static func give_card(card: ItemData, gates: Array = []) -> bool:
	if card == null:
		push_error("LevelUtils.give_card: la tarjeta es null, asignala en el Inspector")
		return false
	InventoryManager.add_data(card, 1)
	open_gates(gates)
	return true


# ---------- Progreso del nivel (se guarda en el slot junto con la partida) ----------
# Uso en un nivel:
#   const SAVED_VARS := ["met_boss", "minigame_done"]
#   func save_state() -> void: LevelUtils.store_state(self, SAVED_VARS)
#   y en _ready(): LevelUtils.load_state(self, SAVED_VARS)

## Anota en GameManager.story el valor actual de las variables indicadas
static func store_state(level: Node, names: Array) -> void:
	var state := {}
	for var_name in names:
		state[var_name] = level.get(var_name)
	GameManager.story[level.scene_file_path] = state


## Devuelve a las variables del nivel los valores guardados (si los hay).
## Tambien restaura el mundo: torniquetes abiertos y nodos eliminados (cajas, etc.)
static func load_state(level: Node, names: Array) -> void:
	restore_world(level)
	var state: Dictionary = GameManager.story.get(level.scene_file_path, {})
	for var_name in names:
		if not state.has(var_name):
			continue
		var value = state[var_name]
		if level.get(var_name) is int:
			value = int(value)       # JSON devuelve los numeros como decimales
		level.set(var_name, value)


# ---------- Estado del mundo (torniquetes abiertos y nodos eliminados) ----------
# Se anota solo, al abrir un TicketGate o usar remove_node(); asi ningun nivel tiene que
# acordarse de guardar cada torniquete o caja. Se guarda en GameManager.story.

const WORLD_PREFIX := "world:"


## Anota que un torniquete quedo abierto (lo llama TicketGate)
static func record_open_gate(gate: Node) -> void:
	_record_world(gate, "gates")


## Vuelve a abrir los torniquetes y a quitar los nodos que ya se habian eliminado
static func restore_world(level: Node) -> void:
	var world: Dictionary = GameManager.story.get(WORLD_PREFIX + level.scene_file_path, {})
	for path in world.get("gates", []):
		var gate := level.get_node_or_null(NodePath(str(path))) as TicketGate
		if gate:
			gate.open_ticket_gate()
	for path in world.get("removed", []):
		var node := level.get_node_or_null(NodePath(str(path)))
		if node:
			node.queue_free()


static func _record_world(node: Node, list_name: String) -> void:
	if not node.is_inside_tree():
		return
	var level := node.get_tree().current_scene
	if level == null or level.scene_file_path == "" or not level.is_ancestor_of(node):
		return
	var key := WORLD_PREFIX + level.scene_file_path
	if not GameManager.story.has(key):
		GameManager.story[key] = {"gates": [], "removed": []}
	var list: Array = GameManager.story[key].get(list_name, [])
	var path := str(level.get_path_to(node))
	if not list.has(path):
		list.append(path)
	GameManager.story[key][list_name] = list
