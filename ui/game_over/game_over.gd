extends Control
## Pantalla de game over. GameFlow la muestra cuando se acaban las vidas.

signal respawn_requested

var _used := false     # evita doble clic


func _ready() -> void:
	($Background/BtnRespawn as BaseButton).pressed.connect(_on_respawn)


func _on_respawn() -> void:
	if _used:
		return
	_used = true
	respawn_requested.emit()
