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
	PlayerControl.freeze(self)
	await cover()
	if middle.is_valid():
		await middle.call()
	await reveal()
	PlayerControl.unfreeze(self)
	busy = false

# Para cambiar de escena con la transición.
# on_loaded: se ejecuta con la escena nueva ya lista, antes de descubrir la pantalla.
# save_leaving: false al cargar partida / ir al menú, para que el nivel que sale
# no sobrescriba el progreso que se acaba de cargar.
func change_scene(packed: PackedScene, on_loaded := Callable(), save_leaving := true) -> void:
	if busy:
		return
	busy = true
	var leaving := get_tree().current_scene
	if save_leaving and leaving and leaving.has_method("save_state"):
		leaving.save_state()          # el progreso del nivel se conserva al cambiar de escena
	PlayerControl.freeze(self)
	await cover()
	PlayerControl.reset()            # lo que dejo congelado la escena anterior no pasa a la nueva
	PlayerControl.freeze(self)       # y seguimos congelados mientras dura la transicion
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	await get_tree().process_frame   # espera a que la nueva escena esté lista
	if on_loaded.is_valid():
		on_loaded.call()
	await reveal()
	PlayerControl.unfreeze(self)     # un dialogo que empiece al cargar la escena (lobby) sigue congelando
	busy = false
