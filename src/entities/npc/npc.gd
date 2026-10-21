class_name Npc
extends CharacterBody2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start := "start"
@export var sprite_texture: Texture2D
@export_enum("d", "u", "h") var start_facing := "d"
@export var face_left := false

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
	if player_in_range and event.is_action_pressed("interact"):
		if dialogue_resource:
			DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
			get_viewport().set_input_as_handled()
