class_name OfficeWorker
extends StaticBody2D

# --- Señales ---
signal problem_solved # Se emite cuando el jugador atiende a un trabajador
signal problem_failed # Se emite cuando el jugador no antiende a un trabajador

# --- Configuración desde el Inspector ---
@export var time_limit := 15 # Tiempo limite para antender a un trabajador
@export var press_power := 18.0 # Cada vez que se hace un clic
@export var decay_per_second := 10.0 # Decadencia de la barra por segundo

# --- Nodos del minijuego 1 ---
@onready var exclamation: Sprite2D = $Exclamation # Exclamación
@onready var bar: ProgressBar = $ProgressBar # Barra de progreso
@onready var area: Area2D = $InteractionArea # Area en al que interactua el jugador
@onready var fail_timer: Timer = $FailTimer # Tiempo para fallar
@onready var problem_sfx: AudioStreamPlayer = $ProblmeSfx # SFX de sonido
@onready var sprite: Sprite2D = $Sprite2D # Sprite del trabajador

#--- Variables ---
var has_problem := false # Se activa cuando tiene un problema
var helping := false   # true mientras el jugador está ayudando
var progress := 0.0 # Progreso del jugador 

func _ready() -> void:
	exclamation.hide() # Escondemos la exclamación
	bar.hide() # Escondemos la barra de progreso
	fail_timer.one_shot = true # so se activa cuando falla el jugador
	fail_timer.timeout.connect(_on_fail_timer_timeout) # Conectamos la señal cuando se acabá tiempo

# Enviamos la textura del tabajador
func set_appearance(texture: Texture2D) -> void:
	sprite.texture = texture

# Función para comenzar el problema
func start_problem() -> void:
	problem_sfx.play()
	has_problem = true
	helping = false
	progress = 0.0
	bar.value = 0
	exclamation.show()
	bar.hide()                  # la barra aparece al presionar E
	fail_timer.paused = false
	fail_timer.start(time_limit)

# Paramos el problema cunado el jugador falla
func stop_problem() -> void:
	has_problem = false
	helping = false
	fail_timer.paused = false
	fail_timer.stop()
	exclamation.hide()
	bar.hide()

# Funcón para actualizar cada frame
func _process(delta: float) -> void:
	if not has_problem or not helping:
		return
	progress = max(0.0, progress - decay_per_second * delta)
	bar.value = progress
	if progress <= 0.0:
		# dejó de ayudar: se oculta la barra y el tiempo sigue corriendo
		helping = false
		bar.hide()
		fail_timer.paused = false

# Verificamos que el jugador esta dentro del área
func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

# Validamos que el jugador puede interactuar 
func _unhandled_input(event: InputEvent) -> void:
	if not has_problem:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if not _player_inside():
		return

	if not helping:
		helping = true
		bar.show()
		fail_timer.paused = true   # mientras ayudas, el tiempo se detiene

	progress = min(100.0, progress + press_power)
	bar.value = progress
	get_viewport().set_input_as_handled()

	if progress >= 100.0:
		stop_problem()
		problem_solved.emit()

# Funcion para activar cuando se acaba el tiempo del problema
func _on_fail_timer_timeout() -> void:
	stop_problem()
	problem_failed.emit()
