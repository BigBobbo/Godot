extends Node2D

const GRID_WIDTH = 24  # 24 cells wide
const GRID_HEIGHT = 24  # 24 cells high

var grid: Grid
var selected_unit: Unit = null
var movement_highlights: Array[Node2D] = []
var shooting_highlights: Array[Node2D] = []
var deployment_highlights: Array[Node2D] = []
var deployment_zones = {
	GameEnums.PlayerTurn.PLAYER_1: Rect2i(0, 0, GRID_WIDTH, 6),  # Player 1's deployment zone (bottom)
	GameEnums.PlayerTurn.PLAYER_2: Rect2i(0, GRID_HEIGHT - 6, GRID_WIDTH, 6)  # Player 2's deployment zone (top)
}

@onready var game = get_parent()
@onready var combat_log = $CombatLog

func _ready():
	grid = Grid.new(GRID_WIDTH, GRID_HEIGHT)
	add_child(grid)
	create_deployment_zones()

func create_deployment_zones():
	# Player 1 deployment zone (red)
	var p1_zone = create_deployment_highlight(
		deployment_zones[GameEnums.PlayerTurn.PLAYER_1],
		Color(0.9, 0.2, 0.2, 0.1)  # Semi-transparent red
	)
	deployment_highlights.append(p1_zone)
	add_child(p1_zone)
	
	# Player 2 deployment zone (blue)
	var p2_zone = create_deployment_highlight(
		deployment_zones[GameEnums.PlayerTurn.PLAYER_2],
		Color(0.2, 0.2, 0.9, 0.1)  # Semi-transparent blue
	)
	deployment_highlights.append(p2_zone)
	add_child(p2_zone)

func create_deployment_highlight(zone: Rect2i, color: Color) -> Node2D:
	var highlight = Polygon2D.new()
	highlight.polygon = PackedVector2Array([
		Vector2(zone.position.x * Grid.CELL_SIZE, zone.position.y * Grid.CELL_SIZE),
		Vector2((zone.position.x + zone.size.x) * Grid.CELL_SIZE, zone.position.y * Grid.CELL_SIZE),
		Vector2((zone.position.x + zone.size.x) * Grid.CELL_SIZE, (zone.position.y + zone.size.y) * Grid.CELL_SIZE),
		Vector2(zone.position.x * Grid.CELL_SIZE, (zone.position.y + zone.size.y) * Grid.CELL_SIZE)
	])
	highlight.color = color
	return highlight

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var grid_pos = grid.world_to_grid(get_local_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_cell_click(grid_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			clear_selection()

func handle_cell_click(grid_pos: Vector2i):
	match game.current_phase:
		GameEnums.GamePhase.DEPLOYMENT:
			handle_deployment_click(grid_pos)
		GameEnums.GamePhase.MOVEMENT:
			handle_movement_click(grid_pos)
		GameEnums.GamePhase.SHOOTING:
			handle_shooting_click(grid_pos)
		# Other phases will be implemented later

func handle_deployment_click(grid_pos: Vector2i):
	if not is_in_deployment_zone(grid_pos, game.current_player):
		return
		
	var unit_to_deploy = game.get_next_unit_to_deploy()
	if unit_to_deploy:
		game.deploy_unit(unit_to_deploy, grid_pos)

func is_in_deployment_zone(grid_pos: Vector2i, player: int) -> bool:
	var zone = deployment_zones[player]
	return zone.has_point(grid_pos)

func highlight_valid_moves(unit: Unit):
	clear_highlights()
	var unit_pos = grid.get_unit_cell_pos(unit)
	if unit_pos == Vector2i(-1, -1):
		return
	
	var valid_moves = grid.get_cells_in_range(unit_pos, unit.movement, true)
	for pos in valid_moves:
		var highlight = create_movement_highlight()
		highlight.position = grid.grid_to_world(pos)
		movement_highlights.append(highlight)
		add_child(highlight)

func clear_highlights():
	for highlight in movement_highlights:
		highlight.queue_free()
	movement_highlights.clear()
	for highlight in shooting_highlights:
		highlight.queue_free()
	shooting_highlights.clear()

func select_unit(unit: Unit):
	print("\nSelect Unit called:")
	print("- Current phase: ", game.current_phase)
	if selected_unit:
		selected_unit.set_selected(false)
		clear_highlights()
	selected_unit = unit
	if selected_unit:
		print("- Selected unit: ", selected_unit.get_unit_type())
		print("- Can shoot: ", selected_unit.can_shoot())
		selected_unit.set_selected(true)
		if game.current_phase == GameEnums.GamePhase.MOVEMENT and unit.can_move():
			highlight_valid_moves(unit)
		elif game.current_phase == GameEnums.GamePhase.SHOOTING and unit.can_shoot():
			print("- Attempting to highlight targets")
			highlight_valid_targets(unit)

func handle_movement_click(grid_pos: Vector2i):
	if not grid.is_within_bounds(grid_pos):
		return
		
	var clicked_unit = grid.cells.get(grid_pos)
	if clicked_unit is Unit:
		if clicked_unit.owner_player == game.current_player:
			select_unit(clicked_unit)
	elif selected_unit and selected_unit.can_move():
		var from_pos = grid.get_unit_cell_pos(selected_unit)
		if from_pos != Vector2i(-1, -1):
			var valid_moves = grid.get_cells_in_range(from_pos, selected_unit.movement, true)
			if grid_pos in valid_moves:
				if grid.move_unit(selected_unit, from_pos, grid_pos):
					selected_unit.has_moved = true
					clear_selection()

func get_units_in_range(from_pos: Vector2i, range: int, enemy_only: bool = false, owner: int = -1) -> Array:
	print("\nGetting units in range:")
	print("- From position: ", from_pos)
	print("- Range: ", range)
	print("- Enemy only: ", enemy_only)
	print("- Owner: ", owner)
	var units = []
	var cells_in_range = grid.get_cells_in_range(from_pos, range, false)
	print("- Cells in range count: ", cells_in_range.size())
	
	for cell_pos in cells_in_range:
		if grid.cells.has(cell_pos):
			var unit = grid.cells[cell_pos]
			if unit is Unit:
				print("- Found unit: ", unit.get_unit_type(), " at pos: ", cell_pos)
				print("  Owner: ", unit.owner_player)
				if enemy_only and unit.owner_player != owner:
					print("  -> Added as enemy target")
					units.append([unit, cell_pos])
				elif not enemy_only:
					print("  -> Added as target")
					units.append([unit, cell_pos])
	
	print("- Total targets found: ", units.size())
	return units

func highlight_valid_targets(unit: Unit):
	print("\nHighlighting valid targets:")
	clear_highlights()
	var unit_pos = grid.get_unit_cell_pos(unit)
	print("- Shooter position: ", unit_pos)
	print("- Shooter range: ", unit.shooting_range)
	if unit_pos == Vector2i(-1, -1):
		print("- ERROR: Could not find shooter position")
		return
	
	var targets = get_units_in_range(unit_pos, unit.shooting_range, true, unit.owner_player)
	print("- Found targets: ", targets.size())
	for target_data in targets:
		var target = target_data[0]
		var target_pos = target_data[1]
		print("- Adding highlight for: ", target.get_unit_type(), " at ", target_pos)
		var highlight = create_target_highlight()
		highlight.position = grid.grid_to_world(target_pos)
		shooting_highlights.append(highlight)
		add_child(highlight)

func shoot_at_target(shooter: Unit, target: Unit):
	combat_log.add_message("-------------------")
	combat_log.add_message(shooter.get_unit_type() + " shooting at " + target.get_unit_type(), Color.YELLOW)
	var shooter_pos = grid.get_unit_cell_pos(shooter)
	var target_pos = grid.get_unit_cell_pos(target)
	if grid.get_distance(shooter_pos, target_pos) > shooter.shooting_range:
		combat_log.add_message("Target out of range!", Color.RED)
		return
	
	var hits = 0
	var hit_rolls = []
	# Roll to hit
	for i in range(shooter.attacks):
		var roll = shooter.roll_dice()
		hit_rolls.append(roll)
		if roll >= shooter.ballistic_skill:
			hits += 1
	combat_log.add_message("Hit rolls (" + str(shooter.ballistic_skill) + "+): " + str(hit_rolls))
	combat_log.add_message("Successful hits: " + str(hits), Color.YELLOW if hits > 0 else Color.RED)
	
	# Roll to wound
	var wounds = 0
	var wound_rolls = []
	for i in range(hits):
		var roll = shooter.roll_dice()
		wound_rolls.append(roll)
		var required = shooter.get_wound_roll_required(shooter.strength, target.toughness)
		if roll >= required:
			wounds += 1
	combat_log.add_message("Wound rolls (" + str(shooter.get_wound_roll_required(shooter.strength, target.toughness)) + "+): " + str(wound_rolls))
	combat_log.add_message("Successful wounds: " + str(wounds), Color.ORANGE if wounds > 0 else Color.RED)
	
	# Roll saves
	var saved = 0
	var save_rolls = []
	for i in range(wounds):
		var roll = target.roll_dice()
		save_rolls.append(roll)
		if roll >= target.armor_save:
			saved += 1
	combat_log.add_message("Save rolls (" + str(target.armor_save) + "+): " + str(save_rolls))
	combat_log.add_message("Successful saves: " + str(saved), Color.GREEN if saved > 0 else Color.RED)
	
	# Apply damage
	var damage = wounds - saved
	if damage > 0:
		target.take_damage(damage)
		combat_log.add_message("Final damage dealt: " + str(damage), Color.RED)
		if target.current_wounds <= 0:
			combat_log.add_message(target.get_unit_type() + " was destroyed!", Color.RED)
			# Remove the destroyed unit from the grid and scene
			var unit_pos = grid.get_unit_cell_pos(target)
			grid.remove_unit(unit_pos)
			target.queue_free()
	else:
		combat_log.add_message("No damage dealt", Color.GREEN)
	
	shooter.has_shot = true
	clear_selection()

func create_movement_highlight() -> Node2D:
	var highlight = Polygon2D.new()
	highlight.polygon = PackedVector2Array([
		Vector2(-14, -14),
		Vector2(14, -14),
		Vector2(14, 14),
		Vector2(-14, 14)
	])
	highlight.color = Color(0, 1, 0, 0.3)  # Semi-transparent green
	return highlight

func create_target_highlight() -> Node2D:
	var highlight = Polygon2D.new()
	highlight.polygon = PackedVector2Array([
		Vector2(-14, -14),
		Vector2(14, -14),
		Vector2(14, 14),
		Vector2(-14, 14)
	])
	highlight.color = Color(1, 0, 0, 0.3)  # Semi-transparent red
	return highlight

func clear_selection():
	select_unit(null)
	clear_highlights()

func handle_shooting_click(grid_pos: Vector2i):
	print("\nHandling shooting click:")
	print("- Click position: ", grid_pos)
	print("- Current phase: ", game.current_phase)  # Verify we're in shooting phase
	if not grid.is_within_bounds(grid_pos):
		print("- Click out of bounds")
		return
		
	var clicked_unit = grid.cells.get(grid_pos)
	print("- Unit at position: ", "None" if not clicked_unit else clicked_unit.get_unit_type())
	if clicked_unit is Unit:
		print("- Clicked unit: ", clicked_unit.get_unit_type(), " owner: ", clicked_unit.owner_player)
		print("- Current player: ", game.current_player)
		print("- Has shot: ", clicked_unit.has_shot)
		print("- Selected unit: ", "None" if not selected_unit else selected_unit.get_unit_type())
		if clicked_unit.owner_player == game.current_player and not clicked_unit.has_shot:
			print("- Selected unit for shooting")
			select_unit(clicked_unit)
			highlight_valid_targets(clicked_unit)
		elif selected_unit and clicked_unit.owner_player != game.current_player:
			print("- Attempting to shoot target")
			print("- Distance to target: ", grid.get_distance(grid.get_unit_cell_pos(selected_unit), grid_pos))
			print("- Shooter range: ", selected_unit.shooting_range)
			shoot_at_target(selected_unit, clicked_unit)
