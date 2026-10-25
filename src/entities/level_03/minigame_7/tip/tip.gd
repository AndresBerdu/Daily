class_name CableTip
extends Node2D

signal grab_requested(tip: CableTip)
signal released(tip: CableTip)
signal plugged(tip: CableTip)

@export_group("Cable")
@export var cable_width := 3.0
@export var cable_offset := Vector2.ZERO       # donde sale el cable, relativo al plug
@export_range(0.0, 0.3) var cable_sag := 0.08  # cuanto se curva (fraccion de la distancia)
@export_range(0.0, 0.6) var cable_handle := 0.35
@export var base_z := 2  

@export_group("Movimiento")
@export var follow_speed := 25.0               # que tan pegado sigue al mouse
@export var return_speed := 700.0              # pixeles por segundo al regresar

@export_group("Magnetismo")
@export var magnet_radius := 56.0              # distancia a la que empieza a atraer
@export_range(0.0, 1.0) var magnet_strength := 0.9
@export var connect_radius := 24.0             # al soltar dentro de este radio, se conecta

@onready var sprite: Sprite2D = $Sprite2D
@onready var drag_shape: CollisionShape2D = $DraggableArea/CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine

var color_id := -1
var home_global := Vector2.ZERO
var target_input: CableInput = null
var grab_offset := Vector2.ZERO
var cable: Line2D

func _ready() -> void:
	z_index = base_z
	# El cable es hijo del plug pero se dibuja en coordenadas globales y por detras
	cable = Line2D.new()
	cable.top_level = true
	cable.show_behind_parent = true
	cable.width = cable_width
	cable.begin_cap_mode = Line2D.LINE_CAP_ROUND
	cable.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(cable)
	cable.global_position = Vector2.ZERO
	cable.hide()

# La llama el minijuego despues de agregar el plug a su marker
func setup(id: int, color: Color, texture: Texture2D, input: CableInput) -> void:
	color_id = id
	target_input = input
	home_global = global_position
	cable.default_color = color
	if texture:
		sprite.texture = texture
	else:
		sprite.self_modulate = color

func _process(_delta: float) -> void:
	_update_cable()

func set_layer(z: int) -> void:
	z_index = z
	cable.z_index = z - 1

# --- Entrada ---
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not is_idle() or not _mouse_over():
		return
	grab_offset = global_position - get_global_mouse_position()
	grab_requested.emit(self)

func _mouse_over() -> bool:
	var local := drag_shape.to_local(get_global_mouse_position())
	var shape := drag_shape.shape
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size / 2.0
		return absf(local.x) <= half.x and absf(local.y) <= half.y
	if shape is CircleShape2D:
		return local.length() <= (shape as CircleShape2D).radius
	return local.length() <= 16.0

# --- Estados ---
func is_idle() -> bool:
	var current := state_machine.current_state
	return current != null and current.name == &"Idle"

func start_drag() -> void:
	_go("drag")

func _go(state_name: String) -> void:
	var current := state_machine.current_state
	if current:
		current.transitioned.emit(state_name)

# --- Magnetismo ---
# Atrae la posicion deseada hacia el input de su color
func apply_magnet(goal: Vector2) -> Vector2:
	if target_input == null or target_input.occupied:
		return goal
	var plug := target_input.plug_position()
	var dist := goal.distance_to(plug)
	if dist >= magnet_radius:
		return goal
	var pull := 1.0 - dist / magnet_radius
	pull = pull * pull * (3.0 - 2.0 * pull)            # suaviza la atraccion
	return goal.lerp(plug, pull * magnet_strength)

func can_connect(pos: Vector2) -> bool:
	return target_input != null and not target_input.occupied \
			and pos.distance_to(target_input.plug_position()) <= connect_radius

# --- Cable curvo ---
func _update_cable() -> void:
	var a := home_global
	var b := global_position + cable_offset
	var dist := a.distance_to(b)
	if dist < 2.0:
		cable.hide()
		return
	cable.show()

	var dir := 1.0 if b.x >= a.x else -1.0
	var handle := dist * cable_handle
	var sag := dist * cable_sag
	var c1 := a + Vector2(handle * dir, sag)
	var c2 := b + Vector2(-handle * dir, sag)

	var points := PackedVector2Array()
	var steps := 20
	for i in steps + 1:
		points.append(a.bezier_interpolate(c1, c2, b, float(i) / steps))
	cable.points = points
