extends Panel

@onready var unit_name = $VBoxContainer/UnitName
@onready var movement = $VBoxContainer/Stats/Movement
@onready var bs = $VBoxContainer/Stats/BS
@onready var strength = $VBoxContainer/Stats/Strength
@onready var toughness = $VBoxContainer/Stats/Toughness
@onready var wounds = $VBoxContainer/Stats/Wounds
@onready var save = $VBoxContainer/Stats/Save

func update_stats(unit: Unit):
	print("Updating stats for: ", unit.get_unit_type())  # Debug print
	unit_name.text = unit.get_unit_type()
	movement.text = str(unit.movement) + "\""
	bs.text = str(unit.ballistic_skill) + "+"
	strength.text = str(unit.strength)
	toughness.text = str(unit.toughness)
	wounds.text = str(unit.current_wounds) + "/" + str(unit.wounds)
	save.text = str(unit.armor_save) + "+" 