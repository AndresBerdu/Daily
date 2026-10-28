extends Node

signal hearts_changed(hearts: int)
signal coins_changed(coins: int)
signal game_over

const MAX_HEARTS := 3

var hearts := MAX_HEARTS
var coins := 0
var play_time := 0.0              # segundos jugados en total
var player_name := "Técnico"
var appearance_seed := 0

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
	return true

func lose_heart() -> void:
	if hearts <= 0:
		return
		
	hearts -= 1
	hearts_changed.emit(hearts)
	
	if hearts <= 0:
		game_over.emit()

func reset_run() -> void:
	hearts = MAX_HEARTS
	coins = 0
	hearts_changed.emit(hearts)
	coins_changed.emit(coins)
