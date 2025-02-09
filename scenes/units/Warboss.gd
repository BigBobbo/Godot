extends Unit

func set_base_stats():
	# Set size and shape
	size = Vector2i(2, 1)  # 2 cells wide, 1 cell tall
	occupied_cells = [
		Vector2i(0, 0),  # Base position
		Vector2i(1, 0),  # Cell to the right
	]
	
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
