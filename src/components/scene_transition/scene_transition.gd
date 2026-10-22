extends CanvasLayer

const DURATION := 0.4

var rect := ColorRect.new()
var busy := false

func _ready() -> void:
	layer = 100                                  # por encima del HUD y los menús
	process_mode = Node.PROCESS_MODE_ALWAYS      # funciona aunque el juego esté en pausa
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clics mientras dura
	rect.visible = false
	add_child(rect)

# Cubre la pantalla de izquierda a derecha
func cover() -> void:
	rect.size = get_viewport().get_visible_rect().size
	rect.position = Vector2(-rect.size.x, 0)
	rect.visible = true
	var tween := create_tween()
	tween.tween_property(rect, "position:x", 0.0, DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

# Descubre la pantalla, saliendo por la derecha
func reveal() -> void:
	var tween := create_tween()
	tween.tween_property(rect, "position:x", rect.size.x, DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	rect.visible = false

# Cubre, ejecuta la función que le pases, y descubre
func play(middle: Callable = Callable()) -> void:
	if busy:
		return
	busy = true
	await cover()
	if middle.is_valid():
		await middle.call()
	await reveal()
	busy = false

# Para cambiar de escena con la transición
func change_scene(packed: PackedScene) -> void:
	if busy:
		return
	busy = true
	await cover()
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	await get_tree().process_frame   # espera a que la nueva escena esté lista
	await reveal()
	busy = false
