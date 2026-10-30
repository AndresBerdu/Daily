class_name Npc
extends CharacterBody2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start := "start"
@export var sprite_texture: Texture2D
@export_enum("d", "u", "h") var start_facing := "d"
@export var face_left := false
@export_group("Apariencias (opcional)")
@export var texture_down: Texture2D     # si se asigna, face("d") cambia a esta hoja
@export var texture_side: Texture2D     # si se asigna, face("h") cambia a esta hoja

var player_in_range := false

func _ready() -> void:
	if sprite_texture:
		$Sprite2D.texture = sprite_texture

	set_meta("facing", start_facing)
	$Sprite2D.flip_h = face_left
	play_anim("idle")

	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)

func play_anim(action: String) -> void:
	var facing: String = get_meta("facing", "d")
	var anim_name := action + "_" + facing
	if $AnimationPlayer.has_animation(anim_name):
		$AnimationPlayer.play(anim_name)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and PlayerControl.is_interact(event) and dialogue_resource:
		speak()
		get_viewport().set_input_as_handled()


## Empieza a hablar. Sin titulo usa dialogue_start; con titulo salta a ese punto del dialogo.
func speak(title := "") -> void:
	if dialogue_resource == null:
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, title if title != "" else dialogue_start, [self])


## Orienta al NPC. facing: "d" (frente), "u" (espalda) o "h" (de lado, flip = mira a la izquierda)
func face(facing: String, flip := false) -> void:
	var sprite := $Sprite2D as Sprite2D
	set_meta("facing", facing)
	face_left = flip
	sprite.flip_h = flip
	if facing == "h" and texture_side:
		sprite.texture = texture_side
	elif facing == "d" and texture_down:
		sprite.texture = texture_down
	play_anim("idle")


## Lo coloca en un marcador y lo orienta
func teleport_to(target: Node2D, facing := "d", flip := false) -> void:
	if target == null:
		return
	global_position = target.global_position
	face(facing, flip)
