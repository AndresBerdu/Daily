class_name ShopEntry
extends Resource

@export var item: ItemData     # que objeto se vende
@export var stock := 1         # unidades disponibles; -1 = ilimitado

@export_group("Desbloqueo")
@export var required_flags: Array[String]   # banderas que deben estar activas
@export var hide_when_locked := false        # true: ni aparece en la lista
@export var locked_hint := "Bloqueado"       # texto que se ve mientras esta bloqueado

func is_unlocked() -> bool:
	for flag in required_flags:
		if not GameManager.has_flag(flag):
			return false
	return true
