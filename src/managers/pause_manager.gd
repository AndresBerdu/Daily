extends Node
## Autoload "PauseManager": abre y cierra el menu de pausa con ESC.
## Solo actua en escenas con jugador (niveles), no en el menu principal ni en game over.

const MENU_SCENE := preload("res://ui/menus/menu_paused/menu_paused.tscn")

var _layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if is_open() or not _can_open():
		return
	get_viewport().set_input_as_handled()
	open()


func is_open() -> bool:
	return is_instance_valid(_layer)


func open() -> void:
	if is_open():
		return
	_layer = CanvasLayer.new()
	_layer.layer = UiLayer.MENU
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var menu := MENU_SCENE.instantiate()
	menu.resume_requested.connect(close)
	_layer.add_child(menu)

	get_tree().root.add_child(_layer)
	get_tree().paused = true


## Seguro de llamar aunque no este abierto
func close() -> void:
	if not is_open():
		return
	_layer.queue_free()
	_layer = null
	get_tree().paused = false


# No se pausa si: no hay jugador, ya hay otra pausa (inventario, tienda, game over) o hay una transicion
func _can_open() -> bool:
	return PlayerControl.get_player() != null \
			and not get_tree().paused \
			and not SceneTransition.busy
