class_name Player
extends CharacterBody2D

@export var frame_width := 0               # ancho de UN frame en pixeles; 0 = igual a la altura de la hoja
@export var invulnerable_time := 1.0     # tiempo sin poder recibir otro golpe

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine

var invulnerable := false

func _ready() -> void:
	process_priority = 100                  # corre despues de la animacion
	_strip_sheet_tracks()
	anim.mixer_updated.connect(_apply_outfit)
	InventoryManager.equipment_changed.connect(func(_slot, _id): _apply_outfit())
	_apply_outfit()

func _process(_delta: float) -> void:
	# Dialogo, minijuego o transicion abiertos: el jugador pasa al estado "frozen"
	if PlayerControl.is_frozen() and _current_action() != "frozen":
		var current := state_machine.current_state
		if current:
			current.transitioned.emit("frozen")
	_apply_outfit()

# Elimina las pistas que cambian la hoja, para que ninguna animacion pise el traje
func _strip_sheet_tracks() -> void:
	for lib_name in anim.get_animation_library_list():
		var lib := anim.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var a := lib.get_animation(anim_name)
			for i in range(a.get_track_count() - 1, -1, -1):
				var path := String(a.track_get_path(i))
				if path.ends_with(":texture") or path.ends_with(":hframes") or path.ends_with(":vframes"):
					push_warning("Player: quitando la pista '%s' de la animacion '%s'" % [path, anim_name])
					a.remove_track(i)
	anim.clear_caches()

func _current_action() -> String:
	var current := state_machine.current_state
	return String(current.name).to_lower() if current else "idle"

func _apply_outfit() -> void:
	var suit := InventoryManager.get_equipped_data("suit")
	if suit == null or suit.suit_sheets == null:
		return                              # sin traje: conserva la hoja actual

	var facing: String = get_meta("facing", "d")
	var tex := suit.suit_sheets.get_sheet(_current_action(), facing)
	if tex == null or sprite.texture == tex:
		return

	sprite.texture = tex
	sprite.vframes = 1
	var w := frame_width if frame_width > 0 else tex.get_height()
	sprite.hframes = maxi(1, tex.get_width() / w)

# La llaman los pinchos (y cualquier otro peligro)
func take_damage(amount := 1) -> void:
	if invulnerable:
		return
	invulnerable = true

	for i in amount:
		GameManager.lose_heart()
	state_machine.current_state.transitioned.emit("hurt")

	await get_tree().create_timer(invulnerable_time).timeout
	invulnerable = false
