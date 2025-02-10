extends Node2D

const RangeIndicator = preload("res://scenes/battlefield/RangeIndicator.gd")

const GRID_WIDTH = 24  # 24 cells wide
const GRID_HEIGHT = 24  # 24 cells high

var grid: Grid
var selected_unit: Unit = null
var selected_squad: Array = []  # Currently selected squad
var squad_original_positions: Dictionary = {}  # Stores original positions for each unit in squad
var squad_valid_moves: Dictionary = {}  # Stores valid moves for each unit in squad
var coherency_warning_highlights: Array[Node2D] = []  # Highlights for units out of coherency
var movement_highlights: Array[Node2D] = []
var shooting_highlights: Array[Node2D] = []
var charge_highlights: Array[Node2D] = []
var charge_target: Unit = null
var range_indicator: Node2D = null
var deployment_highlights: Array[Node2D] = []
var deployment_preview: Unit = null  # Ghost unit showing what will be deployed
var deployment_panel: Panel
var deployment_zones = {
	GameEnums.PlayerTurn.PLAYER_1: Rect2i(0, 0, GRID_WIDTH, 6),  # Player 1's deployment zone (bottom)
	GameEnums.PlayerTurn.PLAYER_2: Rect2i(0, GRID_HEIGHT - 6, GRID_WIDTH, 6)  # Player 2's deployment zone (top)
}
var unit_stats: Panel
var squad_panel: Panel
var squad_list: ItemList

@onready var game = get_parent()
@onready var combat_log = $CombatLog
@onready var finish_squad_button = $FinishSquadButton

func _ready():
	grid = Grid.new(GRID_WIDTH, GRID_HEIGHT)
	add_child(grid)
	create_deployment_zones()
	unit_stats = $CanvasLayer/UnitStats
	deployment_panel = $CanvasLayer/DeploymentPanel
	deployment_panel.squad_deployment_finished.connect(_on_squad_deployment_finished)
	squad_panel = $CanvasLayer/SquadPanel
	squad_list = $CanvasLayer/SquadPanel/VBoxContainer/SquadList
	squad_list.item_selected.connect(_on_squad_selected)
	deployment_panel.unit_selected.connect(_on_deployment_unit_selected)
	finish_squad_button.pressed.connect(_on_finish_squad_pressed)
	finish_squad_button.hide()
	squad_panel.hide()
	# Wait one frame to ensure game is fully initialized
	await get_tree().process_frame
	update_deployment_preview()

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

func create_highlight(color: Color) -> Node2D:
	var highlight = Polygon2D.new()
	highlight.polygon = PackedVector2Array([
		Vector2(-16, -16),
		Vector2(16, -16),
		Vector2(16, 16),
		Vector2(-16, 16)
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
		GameEnums.GamePhase.CHARGE:
			handle_charge_click(grid_pos)
		GameEnums.GamePhase.FIGHT:
			handle_fight_click(grid_pos)
		GameEnums.GamePhase.MORALE:
			handle_morale_click(grid_pos)
		# Other phases will be implemented later

func handle_deployment_click(grid_pos: Vector2i):
	if not is_in_deployment_zone(grid_pos, game.current_player):
		return
		
	if deployment_preview:
		# Use the actual unit from the deployment panel instead of a duplicate
		var unit_to_deploy = deployment_panel.get_selected_unit()
		if not unit_to_deploy:
			return
			
		game.deploy_unit(unit_to_deploy, grid_pos)
		deployment_panel.remove_unit(unit_to_deploy)  # Remove the deployed unit from the panel
		update_deployment_preview()  # Update preview for next unit

func is_in_deployment_zone(grid_pos: Vector2i, player: int) -> bool:
	var zone = deployment_zones[player]
	return zone.has_point(grid_pos)

func highlight_valid_moves(unit: Unit):
	clear_highlights()
	if not squad_valid_moves.has(unit):
		return
	
	var valid_moves = squad_valid_moves[unit]
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
	for highlight in coherency_warning_highlights:
		highlight.queue_free()
	coherency_warning_highlights.clear()
	for highlight in charge_highlights:
		highlight.queue_free()
	charge_highlights.clear()
	if range_indicator:
		range_indicator.queue_free()
		range_indicator = null

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
		if game.current_phase == GameEnums.GamePhase.MOVEMENT and squad_valid_moves.has(unit):
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
			# Only allow selecting units from the current squad
			if not selected_squad.is_empty() and selected_squad.has(clicked_unit) and squad_valid_moves.has(clicked_unit):
				select_unit(clicked_unit)
	elif selected_unit and squad_valid_moves.has(selected_unit):
		var valid_moves = squad_valid_moves[selected_unit]
		if grid_pos in valid_moves:
			var from_pos = grid.get_unit_cell_pos(selected_unit)
			if grid.move_unit(selected_unit, from_pos, grid_pos):
				clear_selection()
				# Highlight other moveable units in the squad
				for unit in selected_squad:
					if squad_valid_moves.has(unit):
						highlight_valid_moves(unit)
				# Update coherency highlights after movement
				update_coherency_highlights()

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
			if unit is Unit and not unit.is_destroyed:  # Only include non-destroyed units
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
	
	# Add range indicator
	range_indicator = create_range_indicator(
		grid.grid_to_world(unit_pos),
		unit.shooting_range
	)
	add_child(range_indicator)
	
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
	
	if not grid.has_line_of_sight(shooter_pos, target_pos):
		combat_log.add_message("No line of sight to target!", Color.RED)
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
	else:
		combat_log.add_message("No damage dealt", Color.GREEN)
	
	shooter.has_shot = true
	clear_selection()

func create_movement_highlight() -> Node2D:
	return create_highlight(Color(0, 1, 0, 0.3))  # Semi-transparent green

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
	print("- Current phase: ", game.current_phase)
	if not grid.is_within_bounds(grid_pos):
		print("- Click out of bounds")
		return
		
	var clicked_unit = grid.cells.get(grid_pos)
	print("- Unit at position: ", "None" if not clicked_unit else clicked_unit.get_unit_type())
	if clicked_unit is Unit:
		# Don't allow selecting or targeting destroyed units
		if clicked_unit.is_destroyed:
			return

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

func create_range_indicator(center_pos: Vector2, range: int) -> Node2D:
	var indicator = Node2D.new()
	
	# Convert range to pixels
	var range_in_pixels = range * Grid.CELL_SIZE
	var circle = RangeIndicator.new(range_in_pixels)
	indicator.add_child(circle)
	
	indicator.position = center_pos
	return indicator

func _process(_delta):
	if not unit_stats:  # Skip if unit_stats isn't ready yet
		print("UnitStats not ready")  # Debug print
		return
		
	var mouse_pos = get_local_mouse_position()
	var grid_pos = grid.world_to_grid(mouse_pos)
	var hovered_unit = grid.cells.get(grid_pos)
	
	if hovered_unit is Unit:
		print("Hovering over unit: ", hovered_unit.get_unit_type())  # Debug print
		unit_stats.update_stats(hovered_unit)
		unit_stats.visible = true
		unit_stats.position = mouse_pos + Vector2(20, 20)  # Offset from cursor
	else:
		unit_stats.visible = false

func update_deployment_preview():
	if game.current_phase != GameEnums.GamePhase.DEPLOYMENT:
		deployment_panel.hide()
		if deployment_preview:
			deployment_preview.queue_free()
			deployment_preview = null
		return
		
	var deployable_units = game.get_deployable_units()
	if deployable_units.is_empty():
		if deployment_preview:
			deployment_preview.queue_free()
			deployment_preview = null
		deployment_panel.hide()
		squad_panel.show()
		update_squad_list()
	else:
		deployment_panel.show()  # Make sure panel is visible
		deployment_panel.update_units(deployable_units)

func _on_deployment_unit_selected(unit: Unit):
	if deployment_preview:
		deployment_preview.queue_free()
	if unit:
		deployment_preview = unit.duplicate()
		deployment_preview.modulate.a = 0.5  # Make it semi-transparent
		add_child(deployment_preview)

func select_squad(squad: Array):
	selected_squad = squad
	finish_squad_button.show()
	squad_original_positions.clear()
	squad_valid_moves.clear()
	
	match game.current_phase:
		GameEnums.GamePhase.MOVEMENT:
			for unit in squad:
				var pos = grid.get_unit_cell_pos(unit)
				squad_original_positions[unit] = pos
				if unit.can_move():
					squad_valid_moves[unit] = grid.get_cells_in_range(pos, unit.movement, true)  # true for empty_only
			# Highlight all moveable units in the squad
			for unit in squad:
				if unit.can_move():
					highlight_valid_moves(unit)
			# Show initial coherency state
			update_coherency_highlights()
		GameEnums.GamePhase.CHARGE:
			clear_highlights()
			# Highlight charge range for entire squad
			var has_chargeable_units = false
			for unit in squad:
				if unit.can_charge():
					has_chargeable_units = true
					var unit_pos = grid.get_unit_cell_pos(unit)
					print("Adding charge range indicator for unit at: ", unit_pos)
					
					# Add range indicator
					var range_circle = RangeIndicator.new(unit.CHARGE_RANGE * Grid.CELL_SIZE)
					range_circle.position = grid.grid_to_world(unit_pos)
					add_child(range_circle)
					movement_highlights.append(range_circle)
					
					# Find enemy units in range
					var targets = grid.get_units_in_range(unit_pos, unit.CHARGE_RANGE, true, game.current_player)
					print("Found ", targets.size(), " potential targets in range")
					for target in targets:
						var target_pos = grid.get_unit_cell_pos(target)
						if grid.has_line_of_sight(unit_pos, target_pos):
							print("Highlighting target at: ", target_pos)
							var highlight = create_highlight(Color(1, 0, 0, 0.3))
							highlight.position = grid.grid_to_world(target_pos)
							movement_highlights.append(highlight)
							add_child(highlight)
			
			if not has_chargeable_units:
				print("No units can charge in this squad")
				combat_log.add_message("No units in this squad can charge!")
				return

			# Show which units can charge
			for unit in squad:
				if unit.can_charge():
					print("Highlighting chargeable unit")
					var unit_highlight = create_highlight(Color(0, 1, 0, 0.3))
					unit_highlight.position = grid.grid_to_world(grid.get_unit_cell_pos(unit))
					movement_highlights.append(unit_highlight)
					add_child(unit_highlight)
			combat_log.add_message("Click an enemy unit within range to attempt a charge")

func _on_finish_squad_pressed():
	# Check coherency for all units in the squad
	var all_coherent = true
	for unit in selected_squad:
		if not unit.is_in_coherency(grid, selected_squad):
			all_coherent = false
			break
	
	if not all_coherent:
		# Revert all moved units in the squad to their original positions
		for unit in selected_squad:
			if squad_original_positions.has(unit):
				var original_pos = squad_original_positions[unit]
				var current_pos = grid.get_unit_cell_pos(unit)
				grid.move_unit(unit, current_pos, original_pos)
				unit.has_moved = false
		combat_log.add_message("Squad movement reverted - models out of coherency!", Color.RED)
	else:
		# Mark all units in squad as moved only after confirming movement
		for unit in selected_squad:
			unit.has_moved = true
	
	selected_squad = []
	squad_original_positions.clear()
	squad_valid_moves.clear()
	clear_selection()
	finish_squad_button.hide()

func update_squad_list():
	squad_list.clear()
	var player_squads = game.active_squads[game.current_player]
	for squad in player_squads:
		if squad.is_empty():
			continue
		var squad_name = squad[0].get_unit_type()
		if squad.size() > 1:
			squad_name += " Squad (" + str(squad.size()) + " models)"
		squad_list.add_item(squad_name)

func _on_squad_selected(index: int):
	var player_squads = game.active_squads[game.current_player]
	if index >= 0 and index < player_squads.size():
		select_squad(player_squads[index])

func next_phase():
	match game.current_phase:
		GameEnums.GamePhase.DEPLOYMENT:
			deployment_panel.hide()
			squad_panel.hide()
		GameEnums.GamePhase.MOVEMENT:
			deployment_panel.hide()
			squad_panel.show()
			update_squad_list()
		GameEnums.GamePhase.SHOOTING:
			deployment_panel.hide()
			squad_panel.hide()
		GameEnums.GamePhase.CHARGE:
			deployment_panel.hide()
			squad_panel.show()
			update_squad_list()
			combat_log.add_message("Charge Phase: Select a squad to make charges")
			clear_selection()
		GameEnums.GamePhase.FIGHT:
			clear_selection()
			squad_panel.hide()
		GameEnums.GamePhase.MORALE:
			clear_selection()
			squad_panel.hide()

func add_squad_to_active(squad: Array, player: int):
	game.active_squads[player].append(squad)
	print("Added squad to active squads. Total squads:", game.active_squads[player].size())

func create_coherency_warning_highlight() -> Node2D:
	var highlight = Polygon2D.new()
	highlight.polygon = PackedVector2Array([
		Vector2(-16, -16),
		Vector2(16, -16),
		Vector2(16, 16),
		Vector2(-16, 16)
	])
	highlight.color = Color(1, 0.5, 0, 0.3)  # Semi-transparent orange
	return highlight

func update_coherency_highlights():
	# Clear existing coherency highlights
	for highlight in coherency_warning_highlights:
		highlight.queue_free()
	coherency_warning_highlights.clear()
	
	# Check each unit in the squad
	if not selected_squad.is_empty():
		for unit in selected_squad:
			if not unit.is_in_coherency(grid, selected_squad):
				var highlight = create_coherency_warning_highlight()
				var unit_pos = grid.get_unit_cell_pos(unit)
				highlight.position = grid.grid_to_world(unit_pos)
				coherency_warning_highlights.append(highlight)
				add_child(highlight)

func _on_squad_deployment_finished(squad_id: int):
	print("Battlefield received squad_deployment_finished signal")
	# Forward the signal to the game
	game._on_squad_deployment_finished(squad_id)

func handle_charge_click(grid_pos: Vector2i):
	if not grid.is_within_bounds(grid_pos):
		return
		
	var clicked_unit = grid.cells.get(grid_pos)
	if clicked_unit is Unit:
		# If clicking an enemy unit and we have a squad selected
		if clicked_unit.owner_player != game.current_player and not selected_squad.is_empty():
			# Find closest charging unit to target
			var min_distance = 999
			var closest_charger = null
			var target_pos = grid.get_unit_cell_pos(clicked_unit)
			
			for unit in selected_squad:
				if unit.can_charge():
					var charger_pos = grid.get_unit_cell_pos(unit)
					# Calculate actual distance for charge range
					var dx = target_pos.x - charger_pos.x
					var dy = target_pos.y - charger_pos.y
					var distance = sqrt(dx * dx + dy * dy)
					print("Unit at %s, distance to target: %f" % [charger_pos, distance])
					if distance <= unit.CHARGE_RANGE and distance < min_distance:
						min_distance = distance
						closest_charger = unit
			
			if closest_charger:
				combat_log.add_message("%s attempting to charge %s..." % [closest_charger.get_unit_type(), clicked_unit.get_unit_type()], Color.YELLOW)
				combat_log.add_message("Distance to target: %.1f cells" % min_distance)
				var charge_roll = closest_charger.roll_charge()
				combat_log.add_message("Charge roll (2D6): %d cells (needed %d+)" % [charge_roll, ceil(min_distance)], 
					Color.GREEN if charge_roll >= ceil(min_distance) else Color.RED)
				
				if charge_roll >= ceil(min_distance):
					combat_log.add_message("Charge successful! %s made it into combat!" % closest_charger.get_unit_type(), Color.GREEN)
					combat_log.add_message("Move charging unit up to %d cells to get into base contact" % charge_roll)
					# Mark valid charge move cells
					var valid_charge_cells = []
					var charge_cells = grid.get_cells_in_range(grid.get_unit_cell_pos(closest_charger), charge_roll, true)
					for cell in charge_cells:
						if grid.get_distance(cell, target_pos) <= 1:  # Engagement range
							valid_charge_cells.append(cell)
					
					# Highlight valid charge moves
					clear_highlights()
					for cell in valid_charge_cells:
						var highlight = create_highlight(Color(0, 1, 0, 0.3))
						highlight.position = grid.grid_to_world(cell)
						movement_highlights.append(highlight)
						add_child(highlight)
					
					# Store charge information for move phase
					charge_target = clicked_unit
					squad_valid_moves[closest_charger] = valid_charge_cells
				else:
					combat_log.add_message("Charge failed! Roll of %d cells was not enough to reach the target." % charge_roll, Color.RED)
					combat_log.add_message("The squad cannot charge again this turn.")
					# Mark all units in squad as having attempted charge
					for unit in selected_squad:
						unit.has_charged = true
					clear_selection()
			else:
				combat_log.add_message("No units in the squad are within %d cells to attempt a charge!" % Unit.CHARGE_RANGE, Color.RED)
		
		# If clicking a valid charge move location
		elif charge_target and selected_unit and squad_valid_moves.has(selected_unit):
			var valid_moves = squad_valid_moves[selected_unit]
			if grid_pos in valid_moves:
				var from_pos = grid.get_unit_cell_pos(selected_unit)
				if grid.move_unit(selected_unit, from_pos, grid_pos):
					selected_unit.has_charged = true
					selected_unit.is_in_melee = true
					charge_target.is_in_melee = true
					clear_selection()
					# Allow moving other units in the charging squad
					highlight_remaining_charge_moves()
		
		# ... remove old charge code ...

func highlight_remaining_charge_moves():
	clear_highlights()
	var any_moves = false
	for unit in selected_squad:
		if not unit.has_charged and unit.can_charge():
			any_moves = true
			var highlight = create_highlight(Color(0, 1, 0, 0.3))
			highlight.position = grid.grid_to_world(grid.get_unit_cell_pos(unit))
			movement_highlights.append(highlight)
			add_child(highlight)
	
	if not any_moves:
		clear_selection()
		charge_target = null

func handle_fight_click(grid_pos: Vector2i):
	if not grid.is_within_bounds(grid_pos):
		return
		
	var clicked_unit = grid.cells.get(grid_pos)
	if clicked_unit is Unit:
		if clicked_unit.owner_player == game.current_player and clicked_unit.is_in_melee and not clicked_unit.has_fought:
			select_unit(clicked_unit)
			# Highlight valid fight targets (units in engagement range)
			highlight_fight_targets(clicked_unit)
		elif selected_unit and clicked_unit.can_be_targeted_by(game.current_player):
			# Resolve melee combat
			resolve_melee_combat(selected_unit, clicked_unit)
			clear_selection()

func handle_morale_click(grid_pos: Vector2i):
	# For now, morale phase is automatic
	pass

func highlight_fight_targets(unit: Unit):
	clear_highlights()
	var unit_pos = grid.get_unit_cell_pos(unit)
	var cells_in_range = grid.get_cells_in_range(unit_pos, unit.ENGAGEMENT_RANGE, false)  # false for empty_only
	var potential_targets = []
	for cell in cells_in_range:
		var target = grid.cells.get(cell)
		if target is Unit and target.owner_player != unit.owner_player:
			potential_targets.append(target)
	
	for target in potential_targets:
		if target.can_be_targeted_by(unit.owner_player) and target.is_in_melee:
			var target_pos = grid.get_unit_cell_pos(target)
			var highlight = create_highlight(Color(1, 0, 0, 0.3))
			highlight.position = grid.grid_to_world(target_pos)
			charge_highlights.append(highlight)
			add_child(highlight)

func resolve_melee_combat(attacker: Unit, defender: Unit):
	combat_log.add_message("%s fights %s in melee!" % [attacker.get_unit_type(), defender.get_unit_type()])
	
	# Roll attacks
	var num_hits = 0
	for i in range(attacker.attacks):
		if attacker.roll_to_hit(true):  # true for melee
			num_hits += 1
	combat_log.add_message("Hits: %d/%d" % [num_hits, attacker.attacks])
	
	# Roll wounds
	var num_wounds = 0
	for i in range(num_hits):
		if attacker.roll_to_wound(defender.toughness):
			num_wounds += 1
	combat_log.add_message("Wounds: %d/%d" % [num_wounds, num_hits])
	
	# Roll saves
	var damage = 0
	for i in range(num_wounds):
		if not defender.roll_armor_save():
			damage += 1
	
	if damage > 0:
		defender.take_damage(damage)
		combat_log.add_message("%s takes %d damage!" % [defender.get_unit_type(), damage])
	else:
		combat_log.add_message("No damage dealt!")
	
	attacker.has_fought = true
