extends Panel

signal unit_selected(unit: Unit)

@onready var unit_list = $VBoxContainer/UnitList
@onready var type_label = $VBoxContainer/SelectedUnitInfo/Type
@onready var movement_label = $VBoxContainer/SelectedUnitInfo/Movement
@onready var bs_label = $VBoxContainer/SelectedUnitInfo/BS
@onready var strength_label = $VBoxContainer/SelectedUnitInfo/Strength
@onready var toughness_label = $VBoxContainer/SelectedUnitInfo/Toughness
@onready var wounds_label = $VBoxContainer/SelectedUnitInfo/Wounds

var units_to_deploy: Array = []  # Array of units in the current squad
var selected_unit: Unit = null
var current_squad: Array = []  # Current squad being deployed
var available_squads: Array = []  # All available squads
var selected_squad_index: int = -1

func _ready():
	unit_list.item_selected.connect(_on_unit_selected)

func update_units(squads: Array):  # Expects Array of Array[Unit] (squads)
	# Store the full squad list
	available_squads = squads
	refresh_squad_list()

func refresh_squad_list():
	print("Refreshing squad list")
	unit_list.clear()
	# Add each squad as an item
	for squad in available_squads:
		var squad_name = squad[0].get_unit_type()  # Use first unit's type as squad name
		if squad.size() > 1:
			squad_name += " Squad (" + str(squad.size()) + " models)"
		print("Adding squad:", squad_name)
		unit_list.add_item(squad_name)
	
	if not available_squads.is_empty() and selected_squad_index == -1:
		_on_unit_selected(0)

func _on_unit_selected(index: int):
	if index >= 0 and index < available_squads.size():
		selected_squad_index = index
		current_squad = available_squads[index]
		units_to_deploy = current_squad
		# Select first unit in squad
		if not current_squad.is_empty():
			selected_unit = current_squad[0]
			update_unit_info(selected_unit)
			unit_selected.emit(selected_unit)

func update_unit_info(unit: Unit):
	if not unit:
		type_label.text = "-"
		movement_label.text = "-"
		bs_label.text = "-"
		strength_label.text = "-"
		toughness_label.text = "-"
		wounds_label.text = "-"
		return
		
	type_label.text = unit.get_unit_type()
	movement_label.text = str(unit.movement) + "\""
	bs_label.text = str(unit.ballistic_skill) + "+"
	strength_label.text = str(unit.strength)
	toughness_label.text = str(unit.toughness)
	wounds_label.text = str(unit.wounds)

func remove_unit(unit: Unit):
	units_to_deploy.erase(unit)
	current_squad.erase(unit)
	# If squad is empty, remove it from available squads
	if current_squad.is_empty():
		available_squads.erase(current_squad)
		selected_squad_index = -1
		refresh_squad_list()
	else:
		# Select next unit in current squad
		if not current_squad.is_empty():
			selected_unit = current_squad[0]
			update_unit_info(selected_unit)
			unit_selected.emit(selected_unit)

func get_selected_unit() -> Unit:
	return selected_unit 

func get_selected_squad() -> Array:
	return current_squad 
