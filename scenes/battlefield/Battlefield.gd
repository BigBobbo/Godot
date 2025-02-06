extends Node2D

const GRID_WIDTH = 24  # 24 cells wide
const GRID_HEIGHT = 24  # 24 cells high

var grid: Grid
var selected_unit: Unit = null
var movement_highlights: Array[Node2D] = []
var deployment_zones = {
	GameEnums.PlayerTurn.PLAYER_1: Rect2i(0, 0, GRID_WIDTH, 6),  # Player 1's deployment zone (bottom)
	GameEnums.PlayerTurn.PLAYER_2: Rect2i(0, GRID_HEIGHT - 6, GRID_WIDTH, 6)  # Player 2's deployment zone (top)
}

@onready var game = get_parent()

func _ready():
	grid = Grid.new(GRID_WIDTH, GRID_HEIGHT)
	add_child(grid)

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
	
	var valid_moves = grid.get_cells_in_range(unit_pos, unit.movement)
	for pos in valid_moves:
		var highlight = create_movement_highlight()
		highlight.position = grid.grid_to_world(pos)
		movement_highlights.append(highlight)
		add_child(highlight)

func clear_highlights():
	for highlight in movement_highlights:
		highlight.queue_free()
	movement_highlights.clear()

func select_unit(unit: Unit):
	if selected_unit:
		selected_unit.set_selected(false)
		clear_highlights()
	selected_unit = unit
	if selected_unit:
		selected_unit.set_selected(true)
		if game.current_phase == GameEnums.GamePhase.MOVEMENT and unit.can_move():
			highlight_valid_moves(unit)

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
			var valid_moves = grid.get_cells_in_range(from_pos, selected_unit.movement)
			if grid_pos in valid_moves:
				if grid.move_unit(selected_unit, from_pos, grid_pos):
					selected_unit.has_moved = true
					clear_selection()

func clear_selection():
	select_unit(null)
	clear_highlights()

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
