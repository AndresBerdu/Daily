extends State

const FLASH_SHADER := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, amount);
}
"""

@export var duration := 0.4          # cuanto dura el estado
@export var flash_interval := 0.07   # cada cuanto cambia entre rojo y blanco
@export var flash_amount := 0.85
@export var red := Color(1.0, 0.15, 0.15)

var player: Player:
	get: return actor as Player

var material := ShaderMaterial.new()
var previous_material: Material
var time_left := 0.0
var flash_time := 0.0
var show_red := true

func _ready() -> void:
	var shader := Shader.new()
	shader.code = FLASH_SHADER
	material.shader = shader

func enter() -> void:
	player.velocity = Vector2.ZERO
	player.anim.pause()                       # sin animacion propia: se queda quieto
	previous_material = player.sprite.material
	player.sprite.material = material
	time_left = duration
	flash_time = flash_interval
	show_red = true
	_apply_flash()

func exit() -> void:
	player.sprite.material = previous_material

func update(delta: float) -> void:
	time_left -= delta
	flash_time -= delta
	if flash_time <= 0.0:
		flash_time = flash_interval
		show_red = not show_red
		_apply_flash()

	if time_left <= 0.0:
		transitioned.emit("idle")

func _apply_flash() -> void:
	material.set_shader_parameter("flash_color", red if show_red else Color.WHITE)
	material.set_shader_parameter("amount", flash_amount)
