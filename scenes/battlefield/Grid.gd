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
    return not cells.has(grid_pos)

func place_unit(unit: Unit, grid_pos: Vector2i) -> bool:
    if not is_within_bounds(grid_pos) or not is_cell_empty(grid_pos):
        return false
    
    cells[grid_pos] = unit
    unit.position = grid_to_world(grid_pos)
    return true

func remove_unit(grid_pos: Vector2i) -> Unit:
    if cells.has(grid_pos):
        var unit = cells[grid_pos]
        cells.erase(grid_pos)
        return unit
    return null

func get_cell_center(grid_pos: Vector2i) -> Vector2:
    return Vector2(
        grid_pos.x * CELL_SIZE + CELL_SIZE/2,
        grid_pos.y * CELL_SIZE + CELL_SIZE/2
    )

func get_cells_in_range(from_pos: Vector2i, range: int) -> Array:
    var cells_in_range = []
    for x in range(-range, range + 1):
        for y in range(-range, range + 1):
            var check_pos = Vector2i(from_pos.x + x, from_pos.y + y)
            if is_within_bounds(check_pos) and Vector2i(x, y).length() <= range:
                cells_in_range.append(check_pos)
    return cells_in_range 