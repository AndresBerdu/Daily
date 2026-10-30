extends Node
## Autoload "GameFlow": el "mapa" del juego. Aqui viven las acciones de alto nivel:
## partida nueva, cargar, volver al menu, salir, game over y reaparecer.
## Los menus solo llaman a estas funciones; no cambian de escena por su cuenta.

const MAIN_MENU := "res://ui/menus/menu/menu.tscn"
const FIRST_LEVEL := "res://escenes/lobby/lobby.tscn"       # donde empieza una partida nueva

const SLOT_MENU_SCENE := preload("res://ui/menus/save/save.tscn")
const SETTINGS_SCENE := preload("res://ui/menus/settings/settings.tscn")
const GAME_OVER_SCENE := preload("res://ui/game_over/game_over.tscn")

# Banderas que decide el nivel 2 y que el final del juego consulta
const FLAG_TOKEN_TO_CHARLIE := "token_to_charlie"
const FLAG_TOKEN_TO_STRANGER := "token_to_stranger"

const THANK_YOU_SCENE := "res://ui/take_you/take_you.tscn"
const THANK_YOU_DURATION := 30.0   # segundos que se muestra la pantalla de gracias

const GAME_OVER_DELAY := 0.8     # pausa antes de mostrar la pantalla, para ver lo que paso

var _game_over_layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.game_over.connect(_on_game_over)


# ============================================================
# PARTIDAS
# ============================================================
func start_new_game() -> void:
	_leave_menus()
	GameManager.new_game()
	SaveManager.current_slot = 0
	_go_to(FIRST_LEVEL)


## Carga un slot. restore_hearts = true deja las vidas llenas (se usa al reaparecer).
func load_slot(slot: int, restore_hearts := false) -> bool:
	var data := SaveManager.read_slot(slot)
	var path: String = data.get("level_path", "")
	if data.is_empty() or not ResourceLoader.exists(path):
		push_warning("GameFlow: el slot %d no se puede cargar" % slot)
		return false

	_leave_menus()
	GameManager.apply_save(data)
	SaveManager.current_slot = slot
	if restore_hearts:
		GameManager.heal(GameManager.MAX_HEARTS)

	# El jugador reaparece donde se guardo la partida
	var pos: Array = data.get("player_pos", [])
	var on_loaded := Callable()
	if pos.size() == 2:
		on_loaded = PlayerControl.move_to.bind(Vector2(float(pos[0]), float(pos[1])))
	_go_to(path, on_loaded)
	return true


## Carga el ultimo guardado. Si no hay ninguno, empieza una partida nueva.
func respawn() -> void:
	var slot := SaveManager.get_last_slot()
	if slot == 0 or not load_slot(slot, true):
		start_new_game()


## Final del juego: pantalla de gracias unos segundos y de vuelta al menu.
## delete_save = true borra la partida en curso (despido irrevocable).
func finish_game(delete_save := false) -> void:
	if delete_save and SaveManager.current_slot > 0:
		SaveManager.delete_slot(SaveManager.current_slot)
	_leave_menus()
	await _go_to(THANK_YOU_SCENE)
	await get_tree().create_timer(THANK_YOU_DURATION).timeout
	go_to_main_menu()


func go_to_main_menu() -> void:
	_leave_menus()
	_go_to(MAIN_MENU)


func quit_game() -> void:
	get_tree().quit()


# ============================================================
# SUBMENUS (los usan el menu principal y el de pausa)
# ============================================================

## Menu de slots en modo "cargar". parent: el menu que lo abre.
func open_load_menu(parent: Node) -> SlotMenu:
	var menu := SLOT_MENU_SCENE.instantiate() as SlotMenu
	menu.mode = SlotMenu.Mode.LOAD
	menu.layer = UiLayer.SUBMENU
	parent.add_child(menu)
	return menu


func open_settings(parent: Node) -> Control:
	var settings := SETTINGS_SCENE.instantiate() as Control
	parent.add_child(settings)
	return settings


# ============================================================
# GAME OVER
# ============================================================
func _on_game_over() -> void:
	if is_instance_valid(_game_over_layer):
		return
	# El temporizador ignora la pausa, para que funcione aunque el juego este detenido
	await get_tree().create_timer(GAME_OVER_DELAY, true).timeout
	if is_instance_valid(_game_over_layer) or GameManager.hearts > 0:
		return

	_game_over_layer = CanvasLayer.new()
	_game_over_layer.layer = UiLayer.GAME_OVER
	_game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var screen := GAME_OVER_SCENE.instantiate()
	screen.finished.connect(_on_game_over_finished)
	_game_over_layer.add_child(screen)

	get_tree().root.add_child(_game_over_layer)
	get_tree().paused = true


# Termino la pantalla: un final borra la partida y va al menu; una derrota normal reaparece
func _on_game_over_finished() -> void:
	if GameManager.game_over_is_ending:
		finish_game(true)
	else:
		respawn()


# ============================================================
# INTERNO
# ============================================================

# Cierra pausa y game over y quita la pausa del arbol antes de cambiar de escena
func _leave_menus() -> void:
	PauseManager.close()
	if is_instance_valid(_game_over_layer):
		_game_over_layer.queue_free()
	_game_over_layer = null
	get_tree().paused = false


# No guarda el nivel que se abandona: asi no pisa el progreso que se acaba de cargar
func _go_to(path: String, on_loaded := Callable()) -> void:
	await SceneTransition.change_scene(load(path), on_loaded, false)
