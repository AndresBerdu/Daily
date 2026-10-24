class_name UserEntry
extends RefCounted

signal delete_pressed(entry: UserEntry)

var cells: Array[Control] = []
var button: BaseButton
var is_intruder := false
var removing := false

var _grid: GridContainer

# Saca las celdas del molde y las pone directamente en la cuadricula,
# empezando en la posicion "index"
func _init(template: Control, grid: GridContainer, index: int, id: int, data: Dictionary) -> void:
	_grid = grid
	is_intruder = data["intruder"]

	var label_id := template.get_node("LabelId") as Label
	var label_name := template.get_node("LabelName") as Label
	var label_email := template.get_node("LabelEmail") as Label
	var label_created := template.get_node("LabelCreatedAt") as Label
	button = template.get_node("BtnDelete") as BaseButton

	label_id.text = str(id)
	label_name.text = data["name"]
	label_email.text = data["email"]
	label_created.text = data["created"]

	var ordered: Array[Control] = [label_id, label_name, label_email, label_created, button]
	for i in ordered.size():
		var cell := ordered[i]
		template.remove_child(cell)
		grid.add_child(cell)
		grid.move_child(cell, index + i)
		cell.modulate.a = 0.0
		if cell is Label:
			(cell as Label).clip_text = true   # respeta el ancho de la columna
		cells.append(cell)
	template.free()                            # el molde ya esta vacio

	button.pressed.connect(func():
		if not removing:
			delete_pressed.emit(self)
	)

	var tween := grid.create_tween().set_parallel(true)
	for cell in cells:
		tween.tween_property(cell, "modulate:a", 1.0, 0.2)

# Desvanece las celdas y las elimina
func remove() -> void:
	removing = true
	button.disabled = true
	var tween := _grid.create_tween().set_parallel(true)
	for cell in cells:
		tween.tween_property(cell, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(_free_cells)

func _free_cells() -> void:
	for cell in cells:
		if is_instance_valid(cell):
			cell.queue_free()
