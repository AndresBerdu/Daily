class_name BeltPacket
extends Node2D

signal reached_center(packet: BeltPacket)   # llego al final del camino principal
signal timed_out(packet: BeltPacket)        # se acabo el tiempo para decidir
signal finished(packet: BeltPacket)         # termino el camino elegido

enum Decision { NONE, GOOD, BAD }

@onready var box: Sprite2D = $Sprite2D
@onready var content_sprite: Sprite2D = $ContentPacket
@onready var label_ip: Label = $LabelIp
@onready var watch: Control = $Watch
@onready var label_time: Label = $Time
@onready var state_machine: StateMachine = $StateMachine

var decision := Decision.NONE
var should_be_good := false
var opened := false

var speed := 60.0              # pixeles por segundo en la cinta
var path_length := 0.0
var target_progress := 0.0     # hasta donde puede avanzar (lo fija la cola)
var decide_time := 40.0
var time_left := 40.0
var exit_time := 3.0
var exit_left := 0.0

func setup(ip: String, box_texture: Texture2D, content_tex: Texture2D, good: bool,
		belt_speed: float, length: float, decide: float, exit_t: float) -> void:
	label_ip.text = ip
	if box_texture:
		box.texture = box_texture          # sano o corrupto
	if content_tex:
		content_sprite.texture = content_tex
	content_sprite.hide()                  # el contenido se ve al abrirlo
	label_time.hide()                      # el contador aparece al llegar al centro
	watch.hide()
	should_be_good = good
	speed = belt_speed
	path_length = length
	decide_time = decide
	time_left = decide
	exit_time = maxf(exit_t, 0.1)

func open() -> void:
	opened = true
	content_sprite.show()

func decide(value: Decision) -> void:
	decision = value
	label_time.hide()
	watch.hide()

func is_correct() -> bool:
	return decision == (Decision.GOOD if should_be_good else Decision.BAD)

func is_waiting() -> bool:
	var current := state_machine.current_state
	return current != null and current.name == &"Waiting"

func start_exit() -> void:
	state_machine.current_state.transitioned.emit("exiting")

func update_time_label() -> void:
	label_time.text = "%d s" % maxi(0, ceili(time_left))
