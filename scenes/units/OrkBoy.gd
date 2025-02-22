extends Unit

func set_base_stats():
    # Set size and shape
    size = Vector2i(1, 1)  # 1 cell wide, 1 cell tall
    occupied_cells = [
        Vector2i(0, 0),  # Base position only
    ]
    
    movement = 5
    weapon_skill = 3
    ballistic_skill = 5
    strength = 4
    toughness = 4
    wounds = 1
    armor_save = 6
    attacks = 2

func get_unit_type() -> String:
    return "Ork Boy" 