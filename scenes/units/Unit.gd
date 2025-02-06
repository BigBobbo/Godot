extends Node2D

class_name Unit

# Unit Stats
var movement: int
var weapon_skill: int
var ballistic_skill: int
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
		color_rect.modulate = Color(1.0, 0.8, 0.8)  # Light red tint for player 1
	else:
		color_rect.modulate = Color(0.8, 0.8, 1.0)  # Light blue tint for player 2

	# Set up health bar
	health_bar.max_value = wounds
	health_bar.value = current_wounds

	# Set unit label
	unit_label.text = get_unit_type()

func set_base_stats():
	# Override in child classes
	pass

func can_move() -> bool:
	return not has_moved

func can_shoot() -> bool:
	return not has_shot

func can_fight() -> bool:
	return not has_fought

func reset_actions():
	has_moved = false
	has_shot = false
	has_fought = false

func roll_to_hit(is_melee: bool) -> bool:
	var roll = randi() % 6 + 1
	return roll >= (weapon_skill if is_melee else ballistic_skill)

func roll_to_wound(target_toughness: int) -> bool:
	var roll = randi() % 6 + 1
	var required = get_wound_roll_required(strength, target_toughness)
	return roll >= required

func roll_armor_save() -> bool:
	var roll = randi() % 6 + 1
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
	current_wounds = max(0, current_wounds - amount)
	health_bar.value = current_wounds 
