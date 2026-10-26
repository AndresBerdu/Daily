class_name LatencyZone
extends Node2D

signal selected(zone: LatencyZone)

enum Mark { NONE, CORRECT, WRONG }

@onready var label: Label = $LabelZone
@onready var sprite: Sprite2D = $Sprite2D
@onready var button: BaseButton = $BtnSelected

var city_name := ""
var lat := 0.0
var lon := 0.0
var latency := 0.0
var locked := true

func _ready() -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_pressed)

# La llama el juego con los datos de la ciudad
func setup(city: String, latitude: float, longitude: float) -> void:
	city_name = city
	lat = latitude
	lon = longitude
	label.text = city

func _on_pressed() -> void:
	if not locked:
		selected.emit(self)

func set_locked(value: bool) -> void:
	locked = value

func show_latency() -> void:
	label.text = "%s %d ms" % [city_name, roundi(latency)]

func hide_latency() -> void:
	label.text = city_name

func set_mark(mark: Mark) -> void:
	match mark:
		Mark.CORRECT:
			sprite.self_modulate = Color(0.5, 1.0, 0.5)
		Mark.WRONG:
			sprite.self_modulate = Color(1.0, 0.4, 0.4)
		_:
			sprite.self_modulate = Color.WHITE
