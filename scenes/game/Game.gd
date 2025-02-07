extends Node2D

var current_phase: GameEnums.GamePhase = GameEnums.GamePhase.DEPLOYMENT
var current_player: GameEnums.PlayerTurn = GameEnums.PlayerTurn.PLAYER_1
var deployment_units_remaining = {
	GameEnums.PlayerTurn.PLAYER_1: [],
	GameEnums.PlayerTurn.PLAYER_2: []
}
var battlefield: Node2D
@onready var ui = $GameUI
var setup_complete = false

func _ready():
	battlefield = $Battlefield
	setup_game()
	setup_complete = true

func setup_game():
	print("Setting up game...")
	# Initialize armies for both players
	var player1_army = create_ork_army()
	var player2_army = create_ork_army()
	print("Created armies - P1:", player1_army.size(), " P2:", player2_army.size())
	
	# Set owner for each unit
	set_army_ownership(player1_army, GameEnums.PlayerTurn.PLAYER_1)
	set_army_ownership(player2_army, GameEnums.PlayerTurn.PLAYER_2)
	
	# Flatten armies into a single array of units for deployment
	deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_1] = flatten_army(player1_army)
	deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_2] = flatten_army(player2_army)
	print("Units to deploy - P1:", deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_1].size(),
		  " P2:", deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_2].size())

func create_ork_army() -> Array:
	var army = []
	# Create Warboss
	var warboss_scene = load("res://scenes/units/Warboss.tscn")
	if warboss_scene == null:
		push_error("Failed to load Warboss scene")
		return army
	var warboss = warboss_scene.instantiate()
	army.append(warboss)
	
	# Create two squads of Ork Boyz
	for i in range(1):
		var boy_squad = []
		var boy_scene = load("res://scenes/units/OrkBoy.tscn")
		if boy_scene == null:
			push_error("Failed to load OrkBoy scene")
			continue
		for j in range(1):
			var boy = boy_scene.instantiate()
			boy_squad.append(boy)
		army.append(boy_squad)
	
	return army

func next_phase():
	match current_phase:
		GameEnums.GamePhase.DEPLOYMENT:
			if deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_1].is_empty() and \
			   deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_2].is_empty():
				current_phase = GameEnums.GamePhase.MOVEMENT
				battlefield.clear_selection()
		GameEnums.GamePhase.MOVEMENT:
			current_phase = GameEnums.GamePhase.SHOOTING
			battlefield.clear_selection()
			# Reset movement flags at end of next turn
			if current_player == GameEnums.PlayerTurn.PLAYER_2:
				reset_unit_actions()
		GameEnums.GamePhase.SHOOTING:
			current_phase = GameEnums.GamePhase.MELEE
		GameEnums.GamePhase.MELEE:
			current_phase = GameEnums.GamePhase.MOVEMENT
			switch_player()
	ui.update_labels()

func switch_player():
	current_player = GameEnums.PlayerTurn.PLAYER_2 if current_player == GameEnums.PlayerTurn.PLAYER_1 else GameEnums.PlayerTurn.PLAYER_1
	ui.update_labels()

func _input(event):
	if event.is_action_pressed("next_phase"):
		next_phase()

func get_deployable_units() -> Array[Unit]:
	if not setup_complete:
		return []
	print("Getting deployable units for player:", current_player)
	var player_units = deployment_units_remaining[current_player]
	print("Found units:", player_units.size())
	var typed_array: Array[Unit] = []
	typed_array.assign(player_units)
	return typed_array

func deploy_unit(unit: Unit, grid_pos: Vector2i) -> bool:
	if not battlefield.is_in_deployment_zone(grid_pos, current_player):
		return false
		
	if battlefield.grid.place_unit(unit, grid_pos):
		deployment_units_remaining[current_player].erase(unit)
		battlefield.add_child(unit)
		switch_player()
		return true
	return false

func set_army_ownership(army: Array, player: int):
	for unit_or_squad in army:
		if unit_or_squad is Unit:
			unit_or_squad.owner_player = player
		elif unit_or_squad is Array:  # It's a squad
			for unit in unit_or_squad:
				unit.owner_player = player

func flatten_army(army: Array) -> Array[Unit]:
	var flattened = []
	for unit_or_squad in army:
		if unit_or_squad is Unit:
			flattened.append(unit_or_squad)
		elif unit_or_squad is Array:  # It's a squad
			flattened.append_array(unit_or_squad)
	var typed_array: Array[Unit] = []
	typed_array.assign(flattened)
	return typed_array

func reset_unit_actions():
	for pos in battlefield.grid.cells:
		var unit = battlefield.grid.cells[pos]
		if unit is Unit:
			unit.reset_actions()
