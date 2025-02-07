extends Node2D

class_name Unit

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
var has_fought: bool = false
var owner_player: int
var is_destroyed: bool = false

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
	has_fought = false

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
