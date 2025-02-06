extends Unit

func set_base_stats():
	movement = 5
	weapon_skill = 2
	ballistic_skill = 5
	strength = 5
	toughness = 5
	wounds = 4
	armor_save = 4
	attacks = 4 

func get_unit_type() -> String:
	return "Warboss" 
