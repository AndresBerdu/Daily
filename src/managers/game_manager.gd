extends Node

signal hearts_changed(hearts: int)
signal coins_changed(coins: int)
signal heart_gained                # para el sonido del HUD
signal heart_lost
signal game_over

const MAX_HEARTS := 3

var hearts := MAX_HEARTS
var coins := 0
var play_time := 0.0              # segundos jugados en total
var player_name := "Técnico"
var appearance_seed := 0
var game_over_is_ending := false  # true si el game over actual es un final
var story := {}                   # progreso de cada nivel: ruta de la escena -> {variable: valor}

func _ready() -> void:
	if appearance_seed == 0:
		new_appearance_seed()

func new_appearance_seed() -> void:
	appearance_seed = randi()

func _process(delta: float) -> void:
	play_time += delta

func apply_save(data: Dictionary) -> void:
	appearance_seed = int(data.get("appearance_seed", appearance_seed))
	coins = int(data.get("coins", 0))
	hearts = int(data.get("hearts", MAX_HEARTS))
	play_time = float(data.get("play_time", 0.0))
	player_name = str(data.get("player_name", player_name))
	coins_changed.emit(coins)
	hearts_changed.emit(hearts)
	InventoryManager.load_save_data(data.get("inventory", {}))
	GameManager.flags = data.get("flags", {})
	story = data.get("story", {})

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func earn_coins_for_floor(amout: int) -> void:
	InventoryManager.remove_item("money", 1)
	add_coins(amout)

# Devuelve false si la vida ya estaba llena
func heal(amount := 1) -> bool:
	if hearts >= MAX_HEARTS:
		return false
	hearts = mini(MAX_HEARTS, hearts + amount)
	hearts_changed.emit(hearts)
	heart_gained.emit()
	return true

func lose_heart() -> void:
	if hearts <= 0:
		return
		
	hearts -= 1
	hearts_changed.emit(hearts)
	heart_lost.emit()
	
	if hearts <= 0:
		game_over_is_ending = false
		game_over.emit()

# Pierde todas las vidas de golpe (pantalla de game over)
## is_ending = true: el game over es un final (se borra la partida al terminar)
func force_game_over(is_ending := false) -> void:
	if hearts <= 0:
		return
	game_over_is_ending = is_ending
	hearts = 0
	hearts_changed.emit(hearts)
	game_over.emit()

# Empieza una partida desde cero
func new_game() -> void:
	reset_run()
	play_time = 0.0
	flags.clear()
	story.clear()
	new_appearance_seed()
	InventoryManager.load_save_data({})     # vacia el inventario y vuelve a poner el traje por defecto

func reset_run() -> void:
	hearts = MAX_HEARTS
	coins = 0
	game_over_is_ending = false
	hearts_changed.emit(hearts)
	coins_changed.emit(coins)

signal flag_changed(flag: String)

var flags := {}      # nombre -> true

func set_flag(flag_name: String, value := true) -> void:
	if value:
		flags[flag_name] = true
	else:
		flags.erase(flag_name)
	flag_changed.emit(flag_name)

func has_flag(flag_name: String) -> bool:
	return flags.has(flag_name)
