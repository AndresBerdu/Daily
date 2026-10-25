extends Node2D

const COIN_REWARD := 10

@onready var belt: BeltPackets = $BeltPackets

var belt_started := false

func _ready() -> void:
	belt.completed.connect(_on_belt_completed)
	belt.failed.connect(_on_belt_failed)

	# Para probar el minijuego sin diálogos, descomenta esta línea:
	# _begin_belt_minigame()

func _begin_belt_minigame() -> void:
	if belt_started:
		return
	belt_started = true
	belt.start()

func request_belt_minigame() -> void:
	_begin_belt_minigame()

func _on_belt_completed() -> void:
	GameManager.add_coins(COIN_REWARD)
	print("Minijuego de paquetes completado")

func _on_belt_failed() -> void:
	belt_started = false
	print("Minijuego de paquetes fallido")
