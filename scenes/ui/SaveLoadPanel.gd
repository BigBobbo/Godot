extends Panel

signal save_game(slot_name: String)
signal load_game(slot_name: String)

@onready var save_list = $VBoxContainer/SaveList
@onready var save_name_edit = $VBoxContainer/SaveNameEdit
@onready var save_button = $VBoxContainer/HBoxContainer/SaveButton
@onready var load_button = $VBoxContainer/HBoxContainer/LoadButton
@onready var delete_button = $VBoxContainer/HBoxContainer/DeleteButton

const SAVE_DIR = "user://saves/"

func _ready():
	# Create saves directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	refresh_save_list()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		visible = !visible
		if visible:
			refresh_save_list()

func refresh_save_list():
	save_list.clear()
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".save"):
				save_list.add_item(file_name.trim_suffix(".save"))
			file_name = dir.get_next()

func _on_save_button_pressed():
	var save_name = save_name_edit.text.strip_edges()
	if save_name.is_empty():
		return
	save_game.emit(save_name)
	refresh_save_list()

func _on_load_button_pressed():
	var selected_items = save_list.get_selected_items()
	if selected_items.is_empty():
		return
	var save_name = save_list.get_item_text(selected_items[0])
	load_game.emit(save_name)
	visible = false

func _on_delete_button_pressed():
	var selected_items = save_list.get_selected_items()
	if selected_items.is_empty():
		return
	var save_name = save_list.get_item_text(selected_items[0])
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.remove(save_name + ".save")
	refresh_save_list()

func _on_save_list_item_selected(_index):
	save_name_edit.text = save_list.get_item_text(_index)
	load_button.disabled = false
	delete_button.disabled = false

func _on_save_list_empty_clicked(_at_position, _mouse_button_index):
	save_list.deselect_all()
	load_button.disabled = true
	delete_button.disabled = true 