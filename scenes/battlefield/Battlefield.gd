extends Node2D

const GRID_WIDTH = 24  # 24 cells wide
const GRID_HEIGHT = 24  # 24 cells high

var grid: Grid
var selected_unit: Unit = null
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

func handle_cell_click(grid_pos: Vector2i):
	match game.current_phase:
		GameEnums.GamePhase.DEPLOYMENT:
			handle_deployment_click(grid_pos)
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
	# TODO: Implement move range highlighting
	pass

func clear_highlights():
	# TODO: Implement clearing of highlights
	pass 
