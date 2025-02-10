extends Node2D

class_name Grid

const CELL_SIZE = 32  # Size of each grid cell in pixels
const GRID_COLOR = Color(0.2, 0.2, 0.2, 0.5)

var width: int  # Grid width in cells
var height: int  # Grid height in cells
var cells: Dictionary = {}  # Dictionary to store cell occupancy

func _init(w: int, h: int):
	width = w
	height = h

func _draw():
	# Draw vertical lines
	for x in range(width + 1):
		var from = Vector2(x * CELL_SIZE, 0)
		var to = Vector2(x * CELL_SIZE, height * CELL_SIZE)
		draw_line(from, to, GRID_COLOR)

	# Draw horizontal lines
	for y in range(height + 1):
		var from = Vector2(0, y * CELL_SIZE)
		var to = Vector2(width * CELL_SIZE, y * CELL_SIZE)
		draw_line(from, to, GRID_COLOR)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / CELL_SIZE), floor(world_pos.y / CELL_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE + CELL_SIZE/2, grid_pos.y * CELL_SIZE + CELL_SIZE/2)

func is_within_bounds(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < width and grid_pos.y >= 0 and grid_pos.y < height

func is_cell_empty(grid_pos: Vector2i) -> bool:
	# Check if any of the cells are occupied
	return not cells.has(grid_pos)

func can_place_unit(unit: Unit, base_pos: Vector2i) -> bool:
	# Check if all required cells are within bounds and empty
	for offset in unit.occupied_cells:
		var check_pos = base_pos + offset
		if not is_within_bounds(check_pos) or not is_cell_empty(check_pos):
			return false
	return true

func place_unit(unit: Unit, grid_pos: Vector2i) -> bool:
	if not can_place_unit(unit, grid_pos):
		return false
	
	# Place unit in all its cells
	for offset in unit.occupied_cells:
		var pos = grid_pos + offset
		cells[pos] = unit
	
	unit.position = grid_to_world(grid_pos)
	return true

func remove_unit(grid_pos: Vector2i) -> Unit:
	var unit = cells.get(grid_pos)
	if unit:
		# Remove unit from all its occupied cells
		for offset in unit.occupied_cells:
			var pos = grid_pos + offset
			if cells.get(pos) == unit:
				cells.erase(pos)
		return unit
	return null

func get_cell_center(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE/2,
		grid_pos.y * CELL_SIZE + CELL_SIZE/2
	)

func get_cells_in_range(from_pos: Vector2i, range_value: int, empty_only: bool) -> Array:
	var cells = []
	# Check all cells within a square area
	for x in range(-range_value, range_value + 1):
		for y in range(-range_value, range_value + 1):
			var check_pos = Vector2i(from_pos.x + x, from_pos.y + y)
			# For charge range, use actual distance instead of Manhattan distance
			var distance = sqrt(x*x + y*y)  # Use actual distance for charge range
			if is_within_bounds(check_pos) and distance <= range_value:
				if empty_only:
					if is_cell_empty(check_pos):
						cells.append(check_pos)
				else:
					cells.append(check_pos)
	return cells

func get_distance(from_pos: Vector2i, to_pos: Vector2i) -> int:
	return abs(to_pos.x - from_pos.x) + abs(to_pos.y - from_pos.y)

func get_units_in_range(from_pos: Vector2i, range: int, enemy_only: bool = false, owner: int = -1) -> Array:
	var units = []
	var cells_in_range = get_cells_in_range(from_pos, range, false)  # false for empty_only
	
	for cell_pos in cells_in_range:
		if cells.has(cell_pos):
			var unit = cells[cell_pos]
			# Calculate actual distance for range check
			var dx = cell_pos.x - from_pos.x
			var dy = cell_pos.y - from_pos.y
			var distance = sqrt(dx * dx + dy * dy)
			if distance > range:
				continue
				
			if enemy_only and unit.owner_player != owner:
				units.append(unit)
			elif not enemy_only:
				units.append(unit)
	
	return units

func move_unit(unit: Unit, from_pos: Vector2i, to_pos: Vector2i) -> bool:
	if not is_within_bounds(to_pos) or not is_cell_empty(to_pos):
		return false
	
	cells.erase(from_pos)
	cells[to_pos] = unit
	unit.position = grid_to_world(to_pos)
	return true

func get_unit_cell_pos(unit: Unit) -> Vector2i:
	for pos in cells:
		if cells[pos] == unit:
			# Return the base position (leftmost cell for horizontal units)
			for offset in unit.occupied_cells:
				var check_pos = pos - offset
				var is_base = true
				for other_offset in unit.occupied_cells:
					var other_pos = check_pos + other_offset
					if cells.get(other_pos) != unit:
						is_base = false
						break
				if is_base:
					return check_pos
	return Vector2i(-1, -1)  # Invalid position if unit not found

func has_line_of_sight(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	# Simple line of sight check - just checking if there are units in between
	var dx = to_pos.x - from_pos.x
	var dy = to_pos.y - from_pos.y
	var steps = max(abs(dx), abs(dy))
	
	if steps == 0:
		return true
		
	var x_step = float(dx) / steps
	var y_step = float(dy) / steps
	
	# Check each cell along the line
	for i in range(1, steps):
		var check_x = from_pos.x + floor(x_step * i)
		var check_y = from_pos.y + floor(y_step * i)
		var check_pos = Vector2i(check_x, check_y)
		
		# If there's a unit in the way, block line of sight
		if cells.has(check_pos) and check_pos != to_pos:
			return false
	
	return true 

func get_path_to_engagement(from_pos: Vector2i, to_pos: Vector2i) -> Array:
	var path = []
	var best_distance = 999
	
	# Check all cells around the target
	for x in range(-1, 2):
		for y in range(-1, 2):
			var check_pos = Vector2i(to_pos.x + x, to_pos.y + y)
			if is_within_bounds(check_pos) and is_cell_empty(check_pos):
				var dist_to_target = get_distance(check_pos, to_pos)
				if dist_to_target <= 1:  # Within engagement range
					var dist_from_start = get_distance(from_pos, check_pos)
					if dist_from_start < best_distance:
						best_distance = dist_from_start
						path = [check_pos]
	
	return path 
