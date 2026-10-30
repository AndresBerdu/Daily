extends Control
## Menu principal. Para agregar un boton: ponlo en la escena y anade su linea en `actions`.

const BUTTONS := "MainContainer/ButtonContainer"

@onready var buttons: Control = get_node(BUTTONS)


func _ready() -> void:
	var actions := {
		"BtnNewGame": GameFlow.start_new_game,
		"BtnLoadGame": func(): GameFlow.open_load_menu(self),
		"BtnSettigns": func(): GameFlow.open_settings(self),   # (asi se llama el nodo en la escena)
		"BtnExit": GameFlow.quit_game,
	}
	for button_name in actions:
		(buttons.get_node(button_name) as BaseButton).pressed.connect(actions[button_name])

	# Sin partidas guardadas no hay nada que cargar
	var load_button := buttons.get_node("BtnLoadGame") as BaseButton
	load_button.disabled = not SaveManager.has_any_save()
	load_button.modulate.a = 0.5 if load_button.disabled else 1.0
