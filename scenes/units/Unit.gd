extends Node2D

class_name Unit

# Unit Size and Shape
var size: Vector2i = Vector2i(1, 1)  # Default size is 1x1
var occupied_cells: Array[Vector2i] = []  # Cells this unit occupies relative to its base position

# Unit Stats
var movement: int
var weapon_skill: int
var ballistic_skill: int
var shooting_range: int = 12  # Default 12 cells range (adjust as needed)
var strength: int
var toughness: int
var wounds: int
var armor_save: int
var attacks: int

# Current state
var current_wounds: int
var has_moved: bool = false
var has_shot: bool = false
var has_charged: bool = false
var has_fought: bool = false
var is_in_melee: bool = false
var last_charge_roll: int = 0  # Store the last successful charge roll
var owner_player: int
var is_destroyed: bool = false
var squad_id: int = -1  # To identify which squad this unit belongs to
const COHERENCY_DISTANCE: int = 2  # Maximum distance between squad members
const CHARGE_RANGE: int = 12  # Maximum cells a unit can charge
const ENGAGEMENT_RANGE: int = 1

@onready var color_rect = $ColorRect
@onready var selection_highlight = $SelectionHighlight
@onready var unit_label = $UnitLabel
@onready var health_bar = $HealthBar

func _init():
	set_base_stats()
	current_wounds = wounds

func _ready():
	# Add player color tint
	if owner_player == GameEnums.PlayerTurn.PLAYER_1:
		color_rect.modulate = Color(0.9, 0.2, 0.2)  # Bright red for player 1
	else:
		color_rect.modulate = Color(0.2, 0.2, 0.9)  # Bright blue for player 2

	# Set up health bar
	health_bar.max_value = wounds
	health_bar.value = current_wounds

	# Set unit label
	var player_indicator = "P1-" if owner_player == GameEnums.PlayerTurn.PLAYER_1 else "P2-"
	unit_label.text = player_indicator + get_unit_type()

func set_base_stats():
	# Override in child classes
	pass

func can_move() -> bool:
	return not has_moved and not is_destroyed

func can_shoot() -> bool:
	return not has_shot and not is_destroyed

func can_fight() -> bool:
	return not has_fought and not is_destroyed

func reset_actions():
	has_moved = false
	has_shot = false
	has_charged = false
	has_fought = false
	is_in_melee = false

func roll_dice() -> int:
	return randi() % 6 + 1

func roll_to_hit(is_melee: bool) -> bool:
	var roll = roll_dice()
	return roll >= (weapon_skill if is_melee else ballistic_skill)

func roll_to_wound(target_toughness: int) -> bool:
	var roll = roll_dice()
	var required = get_wound_roll_required(strength, target_toughness)
	return roll >= required

func roll_armor_save() -> bool:
	var roll = roll_dice()
	return roll >= armor_save

static func get_wound_roll_required(attacker_strength: int, defender_toughness: int) -> int:
	if attacker_strength >= defender_toughness * 2:
		return 2
	elif attacker_strength > defender_toughness:
		return 3
	elif attacker_strength == defender_toughness:
		return 4
	elif attacker_strength <= defender_toughness / 2:
		return 6
	else:
		return 5

func get_unit_type() -> String:
	# Override in child classes
	return "Unit"

func set_selected(selected: bool):
	selection_highlight.visible = selected

func take_damage(amount: int):
	current_wounds -= amount
	if current_wounds <= 0:
		is_destroyed = true
		# Visual feedback for destroyed unit
		modulate = Color(0.5, 0.5, 0.5, 0.5)  # Gray out the unit
		# Add a destroyed indicator
		unit_label.text = unit_label.text + " (Destroyed)"
	health_bar.value = current_wounds

func can_be_targeted() -> bool:
	return not is_destroyed

func can_be_targeted_by(attacker_player: int) -> bool:
	return not is_destroyed and owner_player != attacker_player

func is_in_coherency(grid: Grid, squad: Array) -> bool:
	if squad.size() <= 1:  # Single model units are always in coherency
		return true
	
	var my_pos = grid.get_unit_cell_pos(self)
	if my_pos == Vector2i(-1, -1):
		return false
	
	# Check if this unit is within coherency distance of any other squad member
	for other_unit in squad:
		if other_unit == self:
			continue
		var other_pos = grid.get_unit_cell_pos(other_unit)
		if other_pos != Vector2i(-1, -1) and grid.get_distance(my_pos, other_pos) <= COHERENCY_DISTANCE:
			return true
	
	return false

func can_charge() -> bool:
	return not has_charged and not is_destroyed # and not has_shot

func roll_charge() -> int:
	return roll_dice() + (3* roll_dice())  # 2D6
