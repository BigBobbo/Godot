extends Panel

signal unit_selected(unit: Unit)

@onready var unit_list = $VBoxContainer/UnitList
@onready var type_label = $VBoxContainer/SelectedUnitInfo/Type
@onready var movement_label = $VBoxContainer/SelectedUnitInfo/Movement
@onready var bs_label = $VBoxContainer/SelectedUnitInfo/BS
@onready var strength_label = $VBoxContainer/SelectedUnitInfo/Strength
@onready var toughness_label = $VBoxContainer/SelectedUnitInfo/Toughness
@onready var wounds_label = $VBoxContainer/SelectedUnitInfo/Wounds

var units_to_deploy: Array[Unit] = []
var selected_unit: Unit = null

func _ready():
	unit_list.item_selected.connect(_on_unit_selected)

func update_units(units: Array[Unit]):
	print("Updating deployment panel with units:", units.size())
	units_to_deploy = units
	refresh_list()

func refresh_list():
	print("Refreshing unit list with", units_to_deploy.size(), "units")
	unit_list.clear()
	for unit in units_to_deploy:
		print("Adding unit:", unit.get_unit_type())
		unit_list.add_item(unit.get_unit_type())

func _on_unit_selected(index: int):
	if index >= 0 and index < units_to_deploy.size():
		selected_unit = units_to_deploy[index]
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
	refresh_list()
	if unit == selected_unit:
		selected_unit = null
		update_unit_info(null)

func get_selected_unit() -> Unit:
	return selected_unit 