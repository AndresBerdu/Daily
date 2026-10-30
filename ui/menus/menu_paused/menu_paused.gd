extends Control
## Menu de pausa. PauseManager lo abre; ESC o "Reanudar" lo cierran.
## Para agregar un boton: ponlo en la escena y anade su linea en `actions`.

signal resume_requested

const BUTTONS := "Alpha/MenuPaused/MarginContainer/BtnContainer"

@onready var buttons: Control = get_node(BUTTONS)

var _submenu: Node       # cargar partida u opciones, si hay uno abierto


func _ready() -> void:
	var actions := {
		"BtnResum": func(): resume_requested.emit(),
		"BtnLoadGame": func(): _submenu = GameFlow.open_load_menu(self),
		"BtnOptions": func(): _submenu = GameFlow.open_settings(self),
		"BtnExit": GameFlow.go_to_main_menu,
	}
	for button_name in actions:
		(buttons.get_node(button_name) as BaseButton).pressed.connect(actions[button_name])

	var load_button := buttons.get_node("BtnLoadGame") as BaseButton
	load_button.disabled = not SaveManager.has_any_save()
	load_button.modulate.a = 0.5 if load_button.disabled else 1.0


func _input(event: InputEvent) -> void:
	# Con un submenu abierto, ESC lo cierra el propio submenu, no este
	if is_instance_valid(_submenu):
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		resume_requested.emit()
