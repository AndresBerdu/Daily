class_name MotherboardGame
extends CanvasLayer

signal completed
signal closed

@export var tool_tilt_degrees := 25.0
@export var phase_delay := 0.6      # pausa entre una fase y la siguiente

@onready var screws_node: Node = $Screws
@onready var welders_node: Node = $Welders
@onready var rams_node: Node = $MemoriesRam
@onready var cpu: BoardCpu = $Cpu
@onready var swab: Swab = $Swab
@onready var welder: Sprite2D = $Welder
@onready var screwdriver: Sprite2D = $Screwdriver

var phases: Array = []     # lista de fases; cada fase es una lista de piezas
var phase_index := -1
var pending := 0           # piezas que faltan en la fase actual
var done := false

func _ready() -> void:
	layer = 20
	welder.hide()
	screwdriver.hide()
	cpu.swab = swab

	var screws: Array = []
	var welds: Array = []
	var rams: Array = []

	# Los placeholders se separan por su tipo (Kind), no por el nodo en que estén
	for holder in [screws_node, welders_node]:
		for child in holder.get_children():
			var ph := child as BoardPlaceholder
			if ph == null:
				continue
			ph.fix_started.connect(_on_fix_started)
			ph.fixed.connect(_on_part_done)
			if ph.kind == BoardPlaceholder.Kind.SCREW:
				screws.append(ph)
			else:
				welds.append(ph)

	for child in rams_node.get_children():
		var ram := child as BoardRam
		if ram:
			ram.seated.connect(_on_part_done)
			rams.append(ram)

	cpu.finished.connect(_on_part_done)

	# Orden del minijuego
	phases = [
		{"parts": screws, "method": "activate"},
		{"parts": welds, "method": "activate"},
		{"parts": rams, "method": "activate"},
		{"parts": [cpu], "method": "activate"},
		{"parts": screws, "method": "activate_reassembly"},
	]
	_next_phase()

# Activa las piezas de la siguiente fase (salta las fases vacías)
func _next_phase() -> void:
	if done:
		return
	phase_index += 1
	while phase_index < phases.size() and phases[phase_index]["parts"].is_empty():
		phase_index += 1

	if phase_index >= phases.size():
		_complete()
		return

	var phase: Dictionary = phases[phase_index]
	var parts: Array = phase["parts"]
	pending = parts.size()
	for part in parts:
		part.call(phase["method"])

func _on_part_done(_part = null) -> void:
	pending -= 1
	if pending <= 0:
		get_tree().create_timer(phase_delay).timeout.connect(_next_phase)

func _complete() -> void:
	done = true
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(_finish_game)

func _finish_game() -> void:
	completed.emit()
	closed.emit()
	queue_free()

# Muestra la herramienta inclinada sobre la pieza mientras se arregla
func _on_fix_started(ph: BoardPlaceholder, duration: float) -> void:
	
	var template := screwdriver if ph.kind == BoardPlaceholder.Kind.SCREW else welder
	var tool_sprite := template.duplicate() as Sprite2D
	add_child(tool_sprite)
	tool_sprite.show()
	tool_sprite.rotation_degrees = tool_tilt_degrees

	var r := tool_sprite.get_rect()
	var tip := Vector2(r.get_center().x, r.end.y) * tool_sprite.scale
	tool_sprite.global_position = ph.global_position - tip.rotated(tool_sprite.rotation)

	tool_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(tool_sprite, "modulate:a", 1.0, 0.12)
	tween.tween_interval(maxf(duration - 0.24, 0.0))
	tween.tween_property(tool_sprite, "modulate:a", 0.0, 0.12)
	tween.tween_callback(tool_sprite.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not done:
		closed.emit()
		queue_free()
