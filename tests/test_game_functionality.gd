extends GutTest

# This is a test suite for the Warhammer 40K Tactical Game
# Run these tests using GUT plugin

# Preload required resources
const SaveGameClass = preload("res://scripts/SaveGame.gd")

# ---- Test Utilities ----

var game_scene = load("res://scenes/game/Game.tscn")
var game_instance = null
var battlefield = null
var grid = null

func before_each():
	# Create a fresh game instance for each test
	game_instance = game_scene.instantiate()
	add_child(game_instance)
	battlefield = game_instance.get_node("Battlefield")
	grid = battlefield.grid
	
	# Wait for game setup to complete
	await get_tree().process_frame
	
func after_each():
	# Clean up after each test
	if game_instance:
		game_instance.queue_free()
	game_instance = null
	battlefield = null
	grid = null
	
	# Force garbage collection to clean up orphaned nodes
	await get_tree().process_frame
	
	# In GUT, we can use the built-in garbage collection
	get_tree().call_deferred("garbage_collect")

# ---- Unit Tests ----

# === Grid System Tests ===

func test_grid_initialization():
	assert_not_null(grid, "Grid should be initialized")
	assert_eq(grid.width, 24, "Grid width should be 24")
	assert_eq(grid.height, 24, "Grid height should be 24")
	assert_eq(grid.cells.size(), 0, "Grid should start empty")

func test_grid_world_to_grid_conversion():
	var world_pos = Vector2(80, 64)
	var grid_pos = grid.world_to_grid(world_pos)
	
	assert_eq(grid_pos, Vector2i(2, 2), "World position (80, 64) should convert to grid (2, 2)")

func test_grid_grid_to_world_conversion():
	var grid_pos = Vector2i(3, 4)
	var world_pos = grid.grid_to_world(grid_pos)
	
	# Grid to world returns the center of the cell
	assert_eq(world_pos, Vector2(3 * 32 + 16, 4 * 32 + 16), "Grid position (3, 4) should convert to world center")

# === Unit Tests ===

func test_unit_creation():
	var ork_boy_scene = load("res://scenes/units/OrkBoy.tscn")
	var ork_boy = ork_boy_scene.instantiate()
	
	assert_not_null(ork_boy, "Should be able to instantiate an Ork Boy")
	assert_eq(ork_boy.movement, 5, "Ork Boy should have movement 5")
	assert_eq(ork_boy.weapon_skill, 3, "Ork Boy should have weapon skill 3")
	assert_eq(ork_boy.ballistic_skill, 5, "Ork Boy should have ballistic skill 5")
	assert_eq(ork_boy.strength, 4, "Ork Boy should have strength 4")
	assert_eq(ork_boy.toughness, 4, "Ork Boy should have toughness 4")
	assert_eq(ork_boy.wounds, 1, "Ork Boy should have 1 wound")
	assert_eq(ork_boy.armor_save, 6, "Ork Boy should have armor save 6+")
	assert_eq(ork_boy.attacks, 2, "Ork Boy should have 2 attacks")
	
	ork_boy.queue_free()

func test_unit_damage_and_destruction():
	var ork_boy_scene = load("res://scenes/units/OrkBoy.tscn")
	var ork_boy = ork_boy_scene.instantiate()
	add_child(ork_boy)  # Add to scene to initialize components
	
	# Wait for ready to be called
	await get_tree().process_frame
	
	assert_eq(ork_boy.current_wounds, ork_boy.wounds, "Unit should start with full wounds")
	assert_false(ork_boy.is_destroyed, "Unit should not start destroyed")
	
	ork_boy.take_damage(1)
	assert_eq(ork_boy.current_wounds, 0, "Ork Boy should have 0 wounds after taking 1 damage")
	assert_true(ork_boy.is_destroyed, "Ork Boy should be destroyed after losing all wounds")
	
	ork_boy.queue_free()

# === Unit Placement Tests ===

func test_unit_placement():
	var ork_boy_scene = load("res://scenes/units/OrkBoy.tscn")
	var ork_boy = ork_boy_scene.instantiate()
	ork_boy.owner_player = GameEnums.PlayerTurn.PLAYER_1
	
	var grid_pos = Vector2i(5, 5)
	var placement_success = grid.place_unit(ork_boy, grid_pos)
	
	assert_true(placement_success, "Should be able to place unit on empty grid")
	assert_true(grid.cells.has(grid_pos), "Grid should have the unit at the specified position")
	assert_eq(grid.cells[grid_pos], ork_boy, "The unit at the position should be the placed unit")
	assert_eq(ork_boy.position, grid.grid_to_world(grid_pos), "Unit world position should match grid position")
	
	ork_boy.queue_free()

func test_unit_placement_collision():
	var ork_boy1 = load("res://scenes/units/OrkBoy.tscn").instantiate()
	var ork_boy2 = load("res://scenes/units/OrkBoy.tscn").instantiate()
	
	var grid_pos = Vector2i(5, 5)
	
	# Place first unit
	var placement1 = grid.place_unit(ork_boy1, grid_pos)
	assert_true(placement1, "Should be able to place first unit")
	
	# Try to place second unit at same position
	var placement2 = grid.place_unit(ork_boy2, grid_pos)
	assert_false(placement2, "Should not be able to place second unit at same position")
	
	ork_boy1.queue_free()
	ork_boy2.queue_free()

# === Movement Tests ===

func test_unit_movement():
	var ork_boy = load("res://scenes/units/OrkBoy.tscn").instantiate()
	var start_pos = Vector2i(5, 5)
	var end_pos = Vector2i(7, 7)
	
	grid.place_unit(ork_boy, start_pos)
	assert_true(grid.cells.has(start_pos), "Unit should be at start position")
	
	var move_success = grid.move_unit(ork_boy, start_pos, end_pos)
	assert_true(move_success, "Movement should succeed to empty cell")
	assert_false(grid.cells.has(start_pos), "Start position should be empty after move")
	assert_true(grid.cells.has(end_pos), "End position should have unit after move")
	assert_eq(grid.cells[end_pos], ork_boy, "Unit should be at end position")
	
	ork_boy.queue_free()

# === Combat Tests ===

func test_wound_roll_calculation():
	# Test the static wound roll calculation function
	var results = {
		# S >= 2*T
		[8, 4]: 2,  # S twice T: 2+
		# S > T
		[5, 4]: 3,  # S > T: 3+
		# S = T
		[4, 4]: 4,  # S = T: 4+
		# S < T
		[3, 4]: 5,  # S < T: 5+
		# S <= T/2
		[2, 4]: 6   # S half or less than T: 6+
	}
	
	for comparison in results:
		var strength = comparison[0]
		var toughness = comparison[1]
		var expected = results[comparison]
		var actual = Unit.get_wound_roll_required(strength, toughness)
		assert_eq(actual, expected, "Wound roll for S:%d vs T:%d should be %d+, got %d+" % [strength, toughness, expected, actual])

func test_dice_roll_distribution():
	var ork_boy = load("res://scenes/units/OrkBoy.tscn").instantiate()
	var rolls = {}
	var num_rolls = 600  # Roll enough times for statistical significance
	
	# Count distribution of rolls
	for i in range(num_rolls):
		var roll = ork_boy.roll_dice()
		if not rolls.has(roll):
			rolls[roll] = 0
		rolls[roll] += 1
	
	# Check that all possible values (1-6) were rolled
	for i in range(1, 7):
		assert_true(rolls.has(i), "Roll %d should appear in %d rolls" % [i, num_rolls])
	
	# Check that no impossible values were rolled
	for roll in rolls.keys():
		assert_true(roll >= 1 and roll <= 6, "Roll should be between 1 and 6, got %d" % roll)
	
	# Check that distribution is roughly even (within 30% of expected)
	var expected_per_value = num_rolls / 6
	var margin = expected_per_value * 0.3
	for i in range(1, 7):
		assert_true(abs(rolls[i] - expected_per_value) < margin, 
			"Roll %d appeared %d times, expected roughly %d±%d" % [i, rolls[i], expected_per_value, margin])
	
	ork_boy.queue_free()

# === Game Phase Tests ===

func test_phase_transition():
	assert_eq(game_instance.current_phase, GameEnums.GamePhase.DEPLOYMENT, "Game should start in deployment phase")
	assert_eq(game_instance.current_player, GameEnums.PlayerTurn.PLAYER_1, "Player 1 should start")
	
	# Simulate completing deployment
	game_instance.deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_1] = []
	game_instance.deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_2] = []
	game_instance.next_phase()
	
	assert_eq(game_instance.current_phase, GameEnums.GamePhase.MOVEMENT, "Game should advance to movement phase")
	
	game_instance.next_phase()
	assert_eq(game_instance.current_phase, GameEnums.GamePhase.SHOOTING, "Game should advance to shooting phase")
	
	game_instance.next_phase()
	assert_eq(game_instance.current_phase, GameEnums.GamePhase.CHARGE, "Game should advance to charge phase")
	
	game_instance.next_phase()
	assert_eq(game_instance.current_phase, GameEnums.GamePhase.FIGHT, "Game should advance to fight phase")
	
	game_instance.next_phase()
	assert_eq(game_instance.current_phase, GameEnums.GamePhase.MORALE, "Game should advance to morale phase")
	
	game_instance.next_phase()
	assert_eq(game_instance.current_phase, GameEnums.GamePhase.MOVEMENT, "Game should loop back to movement phase")
	assert_eq(game_instance.current_player, GameEnums.PlayerTurn.PLAYER_2, "Player should switch to Player 2")

# === Squad Coherency Tests ===

func test_squad_coherency():
	# Create a squad of two Ork Boys
	var ork_boy1 = load("res://scenes/units/OrkBoy.tscn").instantiate()
	var ork_boy2 = load("res://scenes/units/OrkBoy.tscn").instantiate()
	
	# Give them the same squad ID
	var squad_id = 1
	ork_boy1.squad_id = squad_id
	ork_boy2.squad_id = squad_id
	
	# Place them within coherency distance
	grid.place_unit(ork_boy1, Vector2i(5, 5))
	grid.place_unit(ork_boy2, Vector2i(6, 6))
	
	var squad = [ork_boy1, ork_boy2]
	
	# Test coherency - both should be in coherency
	assert_true(ork_boy1.is_in_coherency(grid, squad), "First unit should be in coherency")
	assert_true(ork_boy2.is_in_coherency(grid, squad), "Second unit should be in coherency")
	
	# Move one unit out of coherency
	grid.move_unit(ork_boy2, Vector2i(6, 6), Vector2i(10, 10))
	
	# Test coherency again - both should be out of coherency
	assert_false(ork_boy1.is_in_coherency(grid, squad), "First unit should be out of coherency")
	assert_false(ork_boy2.is_in_coherency(grid, squad), "Second unit should be out of coherency")
	
	ork_boy1.queue_free()
	ork_boy2.queue_free()

# === Save/Load Tests ===

func test_save_game_serialization():
	var save_game = SaveGameClass.new()
	save_game.current_phase = GameEnums.GamePhase.MOVEMENT
	save_game.current_player = GameEnums.PlayerTurn.PLAYER_2
	save_game.units = [
		{
			"type": "OrkBoy",
			"position": Vector2i(5, 5),
			"owner": GameEnums.PlayerTurn.PLAYER_1,
			"squad_id": 1,
			"current_wounds": 1,
			"has_moved": false,
			"has_shot": false,
			"has_charged": false,
			"has_fought": false,
			"is_in_melee": false
		}
	]
	save_game.active_squads = {
		GameEnums.PlayerTurn.PLAYER_1: [[1]],
		GameEnums.PlayerTurn.PLAYER_2: []
	}
	
	var serialized = save_game.serialize()
	
	assert_true(serialized.has("current_phase"), "Serialized data should include current_phase")
	assert_true(serialized.has("current_player"), "Serialized data should include current_player")
	assert_true(serialized.has("units"), "Serialized data should include units")
	assert_true(serialized.has("active_squads"), "Serialized data should include active_squads")
	
	assert_eq(serialized.current_phase, GameEnums.GamePhase.MOVEMENT, "Phase should be preserved in serialization")
	assert_eq(serialized.current_player, GameEnums.PlayerTurn.PLAYER_2, "Player should be preserved in serialization")
	assert_eq(serialized.units.size(), 1, "Units array should be preserved in serialization")
	assert_true(serialized.active_squads.has(GameEnums.PlayerTurn.PLAYER_1), "Active squads should be preserved in serialization")
	
func test_save_game_deserialization():
	var serialized_data = {
		"current_phase": GameEnums.GamePhase.SHOOTING,
		"current_player": GameEnums.PlayerTurn.PLAYER_1,
		"units": [
			{
				"type": "OrkBoy",
				"position": Vector2i(3, 3),
				"owner": GameEnums.PlayerTurn.PLAYER_1,
				"squad_id": 2,
				"current_wounds": 1,
				"has_moved": true,
				"has_shot": false,
				"has_charged": false,
				"has_fought": false,
				"is_in_melee": false
			}
		],
		"active_squads": {
			str(GameEnums.PlayerTurn.PLAYER_1): [[2]],
			str(GameEnums.PlayerTurn.PLAYER_2): []
		}
	}
	
	var save_game = SaveGameClass.new()
	save_game.deserialize(serialized_data)
	
	assert_eq(save_game.current_phase, GameEnums.GamePhase.SHOOTING, "Phase should be correctly deserialized")
	assert_eq(save_game.current_player, GameEnums.PlayerTurn.PLAYER_1, "Player should be correctly deserialized")
	assert_eq(save_game.units.size(), 1, "Units should be correctly deserialized")
	assert_true(save_game.active_squads.has(GameEnums.PlayerTurn.PLAYER_1), "Active squads should be correctly deserialized")

# === Line of Sight Tests ===

func test_line_of_sight():
	var ork_boy1 = load("res://scenes/units/OrkBoy.tscn").instantiate()
	var ork_boy2 = load("res://scenes/units/OrkBoy.tscn").instantiate()
	var ork_boy3 = load("res://scenes/units/OrkBoy.tscn").instantiate()
	
	# Place units
	grid.place_unit(ork_boy1, Vector2i(5, 5))
	grid.place_unit(ork_boy2, Vector2i(10, 5))  # Same row, should have LOS
	grid.place_unit(ork_boy3, Vector2i(7, 5))   # Blocking unit in between
	
	# Test line of sight
	assert_true(grid.has_line_of_sight(Vector2i(5, 5), Vector2i(5, 10)), "Should have LOS to empty space")
	assert_false(grid.has_line_of_sight(Vector2i(5, 5), Vector2i(10, 5)), "Should not have LOS through blocking unit")
	
	ork_boy1.queue_free()
	ork_boy2.queue_free()
	ork_boy3.queue_free()

# === Deployment Zone Tests ===

func test_deployment_zones():
	# Test Player 1 deployment zone (bottom of map)
	var p1_zone = battlefield.deployment_zones[GameEnums.PlayerTurn.PLAYER_1]
	assert_eq(p1_zone.position.y, 0, "Player 1 zone should start at y=0")
	assert_eq(p1_zone.size.y, 6, "Player 1 zone should be 6 cells high")
	
	# Test Player 2 deployment zone (top of map)
	var p2_zone = battlefield.deployment_zones[GameEnums.PlayerTurn.PLAYER_2]
	assert_eq(p2_zone.position.y, battlefield.GRID_HEIGHT - 6, "Player 2 zone should start at y=18")
	assert_eq(p2_zone.size.y, 6, "Player 2 zone should be 6 cells high")
	
	# Test positions directly using the zone rectangles
	var pos1 = Vector2i(5, 2)
	var pos2 = Vector2i(5, 20)
	
	# Check if pos1 is in Player 1 zone
	assert_true(
		pos1.x >= p1_zone.position.x and pos1.x < p1_zone.position.x + p1_zone.size.x and
		pos1.y >= p1_zone.position.y and pos1.y < p1_zone.position.y + p1_zone.size.y,
		"Position (5,2) should be in Player 1 deployment zone"
	)
	
	# Check if pos1 is not in Player 2 zone
	assert_false(
		pos1.x >= p2_zone.position.x and pos1.x < p2_zone.position.x + p2_zone.size.x and
		pos1.y >= p2_zone.position.y and pos1.y < p2_zone.position.y + p2_zone.size.y,
		"Position (5,2) should not be in Player 2 deployment zone"
	)
	
	# Check if pos2 is in Player 2 zone
	assert_true(
		pos2.x >= p2_zone.position.x and pos2.x < p2_zone.position.x + p2_zone.size.x and
		pos2.y >= p2_zone.position.y and pos2.y < p2_zone.position.y + p2_zone.size.y,
		"Position (5,20) should be in Player 2 deployment zone"
	)
	
	# Check if pos2 is not in Player 1 zone
	assert_false(
		pos2.x >= p1_zone.position.x and pos2.x < p1_zone.position.x + p1_zone.size.x and
		pos2.y >= p1_zone.position.y and pos2.y < p1_zone.position.y + p1_zone.size.y,
		"Position (5,20) should not be in Player 1 deployment zone"
	)

# === Movement Range Tests ===

func test_movement_range_calculation():
	var ork_boy = load("res://scenes/units/OrkBoy.tscn").instantiate()
	grid.place_unit(ork_boy, Vector2i(10, 10))
	
	# Get movement range
	var movement_range = grid.get_cells_in_range(Vector2i(10, 10), ork_boy.movement, true)
	
	# Check that the range is correct
	assert_true(movement_range.size() > 0, "Movement range should not be empty")
	
	# The Grid class might be using Manhattan distance or a different calculation
	# Let's check that at least some cells within the expected range are included
	var expected_in_range = [
		Vector2i(10, 9), Vector2i(10, 11),  # Adjacent cells
		Vector2i(9, 10), Vector2i(11, 10),  # Adjacent cells
		Vector2i(7, 10), Vector2i(13, 10),  # Within 5 cells horizontally
		Vector2i(10, 7), Vector2i(10, 13)   # Within 5 cells vertically
	]
	
	for cell in expected_in_range:
		assert_true(movement_range.has(cell), "Cell %s should be in movement range" % cell)
	
	# Check that cells definitely outside range are not included
	var outside_cells = [
		Vector2i(10 + ork_boy.movement + 1, 10),  # Too far horizontally
		Vector2i(10, 10 + ork_boy.movement + 1),  # Too far vertically
		Vector2i(10 + ork_boy.movement, 10 + ork_boy.movement)  # Too far diagonally
	]
	
	for cell in outside_cells:
		assert_false(movement_range.has(cell), "Cell %s should not be in movement range" % cell)
	
	ork_boy.queue_free()

# === Helper Functions ===

func print_node_tree(node, indent = 0):
	var indent_str = ""
	for i in range(indent):
		indent_str += "  "
	
	print("%s%s (%s)" % [indent_str, node.name, node.get_class()])
	
	for child in node.get_children():
		print_node_tree(child, indent + 1)

func debug_battlefield():
	print("Debugging battlefield structure:")
	if battlefield:
		print_node_tree(battlefield)
	else:
		print("Battlefield is null!")

# === Run All Tests ===

func run_all_tests():
	print("Running all game tests...")
	
	# Grid tests
	test_grid_initialization()
	test_grid_world_to_grid_conversion()
	test_grid_grid_to_world_conversion()
	
	# Unit tests
	test_unit_creation()
	test_unit_damage_and_destruction()
	test_unit_placement()
	test_unit_placement_collision()
	
	# Movement tests
	test_unit_movement()
	test_movement_range_calculation()
	
	# Combat tests
	test_wound_roll_calculation()
	test_dice_roll_distribution()
	
	# Game phase tests
	test_phase_transition()
	
	# Squad coherency tests
	test_squad_coherency()
	
	# Save/Load tests
	test_save_game_serialization()
	test_save_game_deserialization()
	
	# Line of sight tests
	test_line_of_sight()
	
	# Deployment zone tests
	test_deployment_zones()
	
	print("All tests completed!") 
