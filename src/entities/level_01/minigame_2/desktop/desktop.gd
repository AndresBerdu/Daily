class_name Desktop
extends Node2D

signal installed(desktop: Desktop)
signal repair_failed(desktop: Desktop)   # el jugador no llegó a tiempo al reboot

enum State { LOCKED, IDLE, INSTALLING, ERROR, FAILED, DONE }

@export var install_time := 8.0
@export_range(0.0, 1.0) var error_chance := 0.4
@export var reboot_time := 5.0           # segundos para hacer el reboot

@export_group("Texturas PC")
@export var tex_error: Texture2D         # pc_error
@export var tex_failed: Texture2D        # no llegó a tiempo
@export var tex_done: Texture2D          # opcional

@export_group("Botón Install")
@export var install_normal: Texture2D
@export var install_hover: Texture2D
@export var install_pressed: Texture2D

@export_group("Botón Reboot")
@export var reboot_normal: Texture2D
@export var reboot_hover: Texture2D
@export var reboot_pressed: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $InteractionArea
@onready var bar: ProgressBar = $ProgressBar
@onready var btn: TextureButton = $BtnAction
@onready var fail_timer: Timer = $FailTime
@onready var error_sfx: AudioStreamPlayer = $ErrorSfx

var windows_error = load("res://assets/audio/sfx/error_windows_sfx.ogg")

var state := State.LOCKED
var progress := 0.0
var error_at := -1.0
var player_inside := false
var tex_normal: Texture2D

func _ready() -> void:
	tex_normal = sprite.texture
	bar.min_value = 0
	bar.max_value = 100
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_on_button_pressed)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	fail_timer.one_shot = true
	fail_timer.timeout.connect(_on_fail_timeout)
	_update_ui()

func activate() -> void:
	if state == State.LOCKED:
		state = State.IDLE
		_update_ui()

## Deja el PC como ya instalado (al cargar una partida), sin avisar al nivel
func mark_done() -> void:
	state = State.DONE
	sprite.texture = tex_done if tex_done else tex_normal
	_update_ui()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		_update_ui()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		_update_ui()

func _set_button_textures(normal: Texture2D, hover: Texture2D, pressed: Texture2D) -> void:
	btn.texture_normal = normal
	btn.texture_hover = hover
	btn.texture_pressed = pressed

func _update_ui() -> void:
	var can_press := player_inside and state in [State.IDLE, State.ERROR, State.FAILED]
	btn.visible = can_press

	if state == State.ERROR:
		_set_button_textures(reboot_normal, reboot_hover, reboot_pressed)
	else:
		_set_button_textures(install_normal, install_hover, install_pressed)

	bar.visible = state == State.INSTALLING or state == State.ERROR

func _unhandled_input(event: InputEvent) -> void:
	if PlayerControl.is_interact(event) and not event.is_echo() and player_inside:
		if state in [State.IDLE, State.ERROR, State.FAILED]:
			get_viewport().set_input_as_handled()
			_on_button_pressed()

func _on_button_pressed() -> void:
	match state:
		State.IDLE, State.FAILED:
			_start_install()
		State.ERROR:
			_reboot()

func _start_install() -> void:
	state = State.INSTALLING
	progress = 0.0
	bar.value = 0
	sprite.texture = tex_normal
	error_at = randf_range(0.2, 0.8) if randf() < error_chance else -1.0
	_update_ui()

func _reboot() -> void:
	fail_timer.stop()
	state = State.INSTALLING
	error_at = -1.0
	sprite.texture = tex_normal
	_update_ui()

func _process(delta: float) -> void:
	if state != State.INSTALLING:
		return
	progress += delta / install_time
	bar.value = progress * 100.0

	if error_at >= 0.0 and progress >= error_at:
		_trigger_error()
	elif progress >= 1.0:
		_finish()

func _trigger_error() -> void:
	state = State.ERROR
	error_at = -1.0
	if tex_error:
		sprite.texture = tex_error
	error_sfx.play()
	fail_timer.start(reboot_time)
	_update_ui()

func _on_fail_timeout() -> void:
	if state != State.ERROR:
		return
	state = State.FAILED
	if tex_failed:
		sprite.texture = tex_failed
	repair_failed.emit(self)
	_update_ui()

func _finish() -> void:
	state = State.DONE
	sprite.texture = tex_done if tex_done else tex_normal
	_update_ui()
	installed.emit(self)
