class_name SecurityPc
extends StaticBody2D

@export var belt: BeltPackets    # si se deja vacio busca un hermano llamado "BeltPackets"

@onready var area: Area2D = $InteractionArea
@onready var btn_open: TextureButton = $BtnOpen
@onready var btn_left: TextureButton = $BtnLeft
@onready var btn_right: TextureButton = $BtnRight

var player_inside := false

func _ready() -> void:
	if belt == null:
		belt = get_parent().get_node_or_null("BeltPackets") as BeltPackets

	for btn in [btn_open, btn_left, btn_right]:
		btn.focus_mode = Control.FOCUS_NONE

	btn_open.pressed.connect(func(): if belt: belt.open_front())
	btn_left.pressed.connect(func(): if belt: belt.send_front(true))
	btn_right.pressed.connect(func(): if belt: belt.send_front(false))

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	if belt:
		belt.queue_changed.connect(_update_buttons)
	_update_buttons()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		_update_buttons()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		_update_buttons()

func _update_buttons() -> void:
	var can_use := player_inside and belt != null and belt.has_front()
	btn_open.visible = can_use and not belt.front_is_open()
	btn_left.visible = can_use
	btn_right.visible = can_use

# E tambien abre el paquete actual
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if player_inside and belt and belt.has_front() and not belt.front_is_open():
		get_viewport().set_input_as_handled()
		belt.open_front()
