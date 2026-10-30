extends Control
## Menu de opciones: volumenes y musica. Los cambios se oyen al instante.
## "Guardar" los guarda en disco; ESC los descarta y cierra.

signal closed

const BOX := "SettingsContainer/MarginContainer/VBoxContainer"

@onready var box: Control = get_node(BOX)

var _snapshot: Dictionary


func _ready() -> void:
	_snapshot = SettingsManager.snapshot()

	# slider -> bus de audio. Para otro volumen: agrega el slider y una linea aqui
	var sliders := {
		"HSliderMaster": SettingsManager.BUS_MASTER,
		"HSliderMusic": SettingsManager.BUS_MUSIC,
		"HSliderSFX": SettingsManager.BUS_SFX,
	}
	for slider_name in sliders:
		var bus: StringName = sliders[slider_name]
		var slider := box.get_node(slider_name) as HSlider
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = SettingsManager.get_volume(bus)
		slider.value_changed.connect(func(value: float): SettingsManager.set_volume(bus, value))

	var music_check := box.get_node("HBoxContainerMusicOn/CheckBoxMusic") as CheckBox
	music_check.button_pressed = SettingsManager.music_enabled
	music_check.toggled.connect(SettingsManager.set_music_enabled)

	(box.get_node("BtnSave") as BaseButton).pressed.connect(_on_save_pressed)


func _on_save_pressed() -> void:
	SettingsManager.save()
	_close()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		SettingsManager.restore(_snapshot)     # descarta lo que se movio
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
