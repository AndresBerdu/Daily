class_name ShopCounter
extends Node2D

const SHOP_UI: PackedScene = preload("res://ui/shop/shop_ui.tscn")   # ajusta la ruta

# Se venden en TODAS las tiendas, al final de la lista. Para agregar otro, ponlo aqui.
const COMMON_ENTRIES: Array[ShopEntry] = [
	preload("res://src/components/items/props/healing_potion_entry.tres"),
]

@export var shop_name := "Tienda"
@export var entries: Array[ShopEntry]    # lo que vende ESTA tienda
@export var sell_common_items := true    # agrega lo que se vende en todas las tiendas (COMMON_ENTRIES)
@export var common_stock := -1           # unidades de los articulos comunes en ESTA tienda (-1 = las de su recurso)

@onready var area: Area2D = $InteractionArea

var remaining: Array[int] = []           # unidades que quedan de cada entrada
var initial_stock: Array[int] = []       # unidades con las que empieza cada entrada
var is_open := false

func _ready() -> void:
	entries = entries.duplicate()          # no modifica la lista guardada en la escena
	var first_common := entries.size()
	if sell_common_items:
		entries.append_array(COMMON_ENTRIES)
	for i in entries.size():
		var entry := entries[i]
		var units := entry.stock if entry != null else 0
		if i >= first_common and common_stock >= 0:
			units = common_stock
		remaining.append(units)
	initial_stock = remaining.duplicate()
	_restore_stock()

# Id unico de esta tienda dentro del juego
func _stock_key() -> String:
	var root: Node = owner if owner else get_tree().current_scene
	return "shop:%s:%s" % [root.scene_file_path, root.get_path_to(self)]

# El stock se guarda en GameManager.story para no poder comprar de nuevo tras cargar
func _restore_stock() -> void:
	var saved: Array = GameManager.story.get(_stock_key(), [])
	# Si la tienda tiene mas articulos que en el guardado, los nuevos conservan su stock inicial
	for i in mini(saved.size(), remaining.size()):
		# Un guardado viejo con stock ilimitado (-1) no pisa un stock que ahora es limitado
		if int(saved[i]) < 0 and remaining[i] >= 0:
			continue
		remaining[i] = int(saved[i])
		# Un guardado viejo con mas unidades de las permitidas ahora no las conserva
		if initial_stock[i] >= 0 and remaining[i] > initial_stock[i]:
			remaining[i] = initial_stock[i]

func _store_stock() -> void:
	GameManager.story[_stock_key()] = remaining.duplicate()

func _player_inside() -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if is_open or not PlayerControl.is_interact(event) or event.is_echo():
		return
	if entries.is_empty() or not _player_inside():
		return
	get_viewport().set_input_as_handled()
	_open()

func _open() -> void:
	is_open = true

	var layer := CanvasLayer.new()
	layer.layer = 30
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(layer)

	var ui := SHOP_UI.instantiate() as ShopUI
	layer.add_child(ui)
	ui.setup(entries, remaining)
	ui.closed.connect(func():
		is_open = false
		_store_stock()
		layer.queue_free()
	)
