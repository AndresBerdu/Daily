class_name OfficeWorker
extends StaticBody2D

signal problem_solved
signal problem_failed

@export var time_limit := 15
@export var press_power := 18.0
@export var decay_per_second := 10.0

@onready var exclamation: Sprite2D = $Exclamation
@onready var bar: ProgressBar = $ProgressBar
@onready var area: Area2D = $InteractionArea
@onready var fail_timer: Timer = $FailTimer
@onready var problem_sfx: AudioStreamPlayer = $ProblmeSfx
@onready var sprite: Sprite2D = $Sprite2D

var has_problem := false
var helping := false   # true mientras el jugador está ayudando
var progress := 0.0

func _ready() -> void:
	exclamation.hide()
	bar.hide()
	fail_timer.one_shot = true
	fail_timer.timeout.connect(_on_fail_timer_timeout)

func set_appearance(texture: Texture2D) -> void:
	sprite.texture = texture

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

func stop_problem() -> void:
	has_problem = false
	helping = false
	fail_timer.paused = false
	fail_timer.stop()
	exclamation.hide()
	bar.hide()

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

func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

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

func _on_fail_timer_timeout() -> void:
	stop_problem()
	problem_failed.emit()
