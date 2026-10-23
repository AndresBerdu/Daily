class_name MotherboardGame
extends CanvasLayer

signal completed       # todo reparado
signal closed          # se cerró (por completarse o por Esc)

@export var tool_tilt_degrees := 25.0   # inclinación de las herramientas

@onready var screws_node: Node = $Screws
@onready var welders_node: Node = $Welders
@onready var rams_node: Node = $MemoriesRam
@onready var cpu: BoardCpu = $Cpu
@onready var swab: Swab = $Swab
@onready var welder: Sprite2D = $Welder
@onready var screwdriver: Sprite2D = $Screwdriver

var pending := 0        # piezas que faltan por arreglar
var done := false

func _ready() -> void:
	layer = 20                          # por encima del mundo, debajo de la transición
	welder.hide()                       # solo sirven de molde
	screwdriver.hide()
	cpu.swab = swab

	var holders: Array[Node] = [screws_node, welders_node]
	for holder in holders:
		for child in holder.get_children():
			var ph := child as BoardPlaceholder
			if ph:
				pending += 1
				ph.fix_started.connect(_on_fix_started)
				ph.fixed.connect(_on_part_done)

	for child in rams_node.get_children():
		var ram := child as BoardRam
		if ram:
			pending += 1
			ram.seated.connect(_on_part_done)

	pending += 1                        # la CPU cuenta como una pieza
	cpu.finished.connect(_on_part_done)

# Muestra la herramienta inclinada sobre el placeholder mientras se arregla
func _on_fix_started(ph: BoardPlaceholder, duration: float) -> void:
	var template := screwdriver if ph.kind == BoardPlaceholder.Kind.SCREW else welder
	var tool_sprite := template.duplicate() as Sprite2D
	add_child(tool_sprite)
	tool_sprite.show()
	tool_sprite.rotation_degrees = tool_tilt_degrees

	# La punta (centro del borde inferior del sprite) queda sobre el placeholder
	var r := tool_sprite.get_rect()
	var tip := Vector2(r.get_center().x, r.end.y) * tool_sprite.scale
	tool_sprite.global_position = ph.global_position - tip.rotated(tool_sprite.rotation)

	tool_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(tool_sprite, "modulate:a", 1.0, 0.12)
	tween.tween_interval(maxf(duration - 0.24, 0.0))
	tween.tween_property(tool_sprite, "modulate:a", 0.0, 0.12)
	tween.tween_callback(tool_sprite.queue_free)

func _on_part_done(_part = null) -> void:
	pending -= 1
	if pending <= 0 and not done:
		done = true
		var tween := create_tween()
		tween.tween_interval(0.8)               # pausa para ver el resultado
		tween.tween_callback(_finish_game)

func _finish_game() -> void:
	completed.emit()
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not done:
		closed.emit()
		queue_free()
