class_name ConnectAllCables
extends Node2D

signal completed       # todos los cables conectados
signal closed          # se cerro (completado o con Esc)

@export var tip_scene: PackedScene
@export var input_scene: PackedScene

# Orden de los 5 tipos: AC, DisplayPort, Ethernet, HDMI, USB
@export var tip_textures: Array[Texture2D]      # ac_tip, display_port_tip, ethernet_tip, hdmi_tip, usb_tip
@export var input_textures: Array[Texture2D]    # los puertos, en el mismo orden
@export var cable_colors: Array[Color] = [
	Color(0.15, 0.15, 0.15),   # AC: negro
	Color(0.2, 0.5, 1.0),      # DisplayPort: azul
	Color(1.0, 0.6, 0.1),      # Ethernet: naranja
	Color(0.9, 0.2, 0.2),      # HDMI: rojo
	Color(0.9, 0.9, 0.9),      # USB: gris claro
]
@export var center_on_screen := true
@export var finish_delay := 0.6

@onready var tips_node: Node = $Tips
@onready var cable_connected_sfx: AudioStreamPlayer = $CableConnectedSfx
@onready var inputs_node: Node = $Inputs
@onready var background: Control = $background

var tips: Array[CableTip] = []
var inputs: Array[CableInput] = []
var plugged_count := 0
var dragging_tip: CableTip = null
var done := false

func _ready() -> void:
	if tip_scene == null or input_scene == null:
		push_error("ConnectAllCables: asigna Tip Scene e Input Scene en el Inspector")
		return
	if center_on_screen:
		_center()
	_build()

# Centra el tablero en la pantalla (necesario si esta dentro de un CanvasLayer)
func _center() -> void:
	var board := background.size
	if board == Vector2.ZERO and background is TextureRect and (background as TextureRect).texture:
		board = (background as TextureRect).texture.get_size()
	position = (get_viewport_rect().size - board) / 2.0 - background.position

# Reparte los colores al azar entre los markers de plugs y los de inputs
func _build() -> void:
	var tip_markers := _markers(tips_node)
	var input_markers := _markers(inputs_node)
	var count := mini(tip_markers.size(), input_markers.size())

	var tip_ids: Array = range(count)
	var input_ids: Array = range(count)
	tip_ids.shuffle()
	input_ids.shuffle()

	# Primero los inputs, para que cada plug conozca el suyo
	var input_by_id := {}
	for i in count:
		var id: int = input_ids[i]
		var input := input_scene.instantiate() as CableInput
		if input == null:
			push_error("input.tscn: la raiz debe tener cable_input.gd")
			return
		input_markers[i].add_child(input)
		input.setup(id, _color(id), _texture(input_textures, id))
		inputs.append(input)
		input_by_id[id] = input

	for i in count:
		var id: int = tip_ids[i]
		var tip := tip_scene.instantiate() as CableTip
		if tip == null:
			push_error("tip.tscn: la raiz debe tener cable_tip.gd")
			return
		tip_markers[i].add_child(tip)
		tip.setup(id, _color(id), _texture(tip_textures, id), input_by_id[id])
		tip.grab_requested.connect(_on_grab_requested)
		tip.released.connect(_on_released)
		tip.plugged.connect(_on_plugged)
		tips.append(tip)

func _markers(holder: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for child in holder.get_children():
		if child is Node2D:
			out.append(child)
	return out

func _color(id: int) -> Color:
	return cable_colors[id % cable_colors.size()]

func _texture(list: Array[Texture2D], id: int) -> Texture2D:
	return list[id] if id < list.size() else null

# Solo un cable se arrastra a la vez
func _on_grab_requested(tip: CableTip) -> void:
	if done or dragging_tip != null:
		return
	dragging_tip = tip
	tip.start_drag()

func _on_released(tip: CableTip) -> void:
	if dragging_tip == tip:
		dragging_tip = null

func _on_plugged(_tip: CableTip) -> void:
	cable_connected_sfx.play()
	plugged_count += 1
	if plugged_count >= tips.size() and not done:
		done = true
		await get_tree().create_timer(finish_delay).timeout
		completed.emit()
		_close()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not done:
		get_viewport().set_input_as_handled()     # que ESC no abra tambien el menu de pausa
		_close()

func _close() -> void:
	closed.emit()
	var parent := get_parent()
	if parent is CanvasLayer:
		parent.queue_free()
	else:
		queue_free()
