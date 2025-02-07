extends Node2D

var current_phase: GameEnums.GamePhase = GameEnums.GamePhase.DEPLOYMENT
var current_player: GameEnums.PlayerTurn = GameEnums.PlayerTurn.PLAYER_1
var deployment_units_remaining = {
	GameEnums.PlayerTurn.PLAYER_1: [],  # Array of squads (each squad is an array of units)
	GameEnums.PlayerTurn.PLAYER_2: []   # Array of squads
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
	
	# Keep armies as squads for deployment
	deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_1] = player1_army
	deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_2] = player2_army

func create_ork_army() -> Array:
	var army = []
	print("Creating army...")
	# Create Warboss
	var warboss_scene = load("res://scenes/units/Warboss.tscn")
	if warboss_scene == null:
		push_error("Failed to load Warboss scene")
		return army
	# Create Warboss squad (single model)
	var warboss_squad = []
	var warboss = warboss_scene.instantiate()
	warboss_squad.append(warboss)
	army.append(warboss_squad)
	print("Added warboss squad")
	
	# Create two squads of Ork Boyz
	for i in range(2):
		var boy_squad = []
		var boy_scene = load("res://scenes/units/OrkBoy.tscn")
		if boy_scene == null:
			push_error("Failed to load OrkBoy scene")
			continue
		for j in range(2):
			var boy = boy_scene.instantiate()
			boy_squad.append(boy)
		army.append(boy_squad)
		print("Added boy squad ", i, " with ", boy_squad.size(), " boys")
	print("Final army size: ", army.size(), " squads")
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
			if current_player == GameEnums.PlayerTurn.PLAYER_2:
				remove_destroyed_units()  # Clean up at end of turn
			switch_player()
	ui.update_labels()

func switch_player():
	current_player = GameEnums.PlayerTurn.PLAYER_2 if current_player == GameEnums.PlayerTurn.PLAYER_1 else GameEnums.PlayerTurn.PLAYER_1
	ui.update_labels()

func _input(event):
	if event.is_action_pressed("next_phase"):
		next_phase()

func get_deployable_units() -> Array:  # Returns Array of Array[Unit] (squads)
	if not setup_complete:
		return []
	print("Getting deployable units for player:", current_player)
	var player_squads = deployment_units_remaining[current_player]
	print("Available squads:", player_squads.size())
	if player_squads.is_empty():
		return []
	
	# Return all squads
	return player_squads

func deploy_unit(unit: Unit, grid_pos: Vector2i) -> bool:
	if not battlefield.is_in_deployment_zone(grid_pos, current_player):
		return false
		
	print("Attempting to deploy:", unit.get_unit_type(), "for player:", current_player)
	if battlefield.grid.place_unit(unit, grid_pos):
		var current_squad = battlefield.deployment_panel.get_selected_squad()
		print("Deploying unit from squad of size:", current_squad.size())
		current_squad.erase(unit)
		print("Squad size after removal:", current_squad.size())
		# Only switch player when the entire squad is deployed
		if current_squad.is_empty():
			print("Squad empty, removing from deployment units")
			# Remove the squad/unit from deployment_units_remaining
			deployment_units_remaining[current_player].erase(current_squad)
			print("Squads remaining for player", current_player, ":", deployment_units_remaining[current_player].size())
			switch_player()
			# Update the deployment panel with the next squad
			battlefield.update_deployment_preview()
		battlefield.add_child(unit)
		return true
	return false

func set_army_ownership(army: Array, player: int):
	print("Setting ownership for player:", player)
	for unit_or_squad in army:
		# All entries should be arrays (squads) now
		if unit_or_squad is Array:
			print("Setting ownership for squad of size:", unit_or_squad.size())
			for unit in unit_or_squad:
				unit.owner_player = player
				print("Set ownership for:", unit.get_unit_type())
		else:
			push_error("Found non-array in army:", unit_or_squad)

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

func remove_destroyed_units():
	var positions_to_clear = []
	for pos in battlefield.grid.cells:
		var unit = battlefield.grid.cells[pos]
		if unit is Unit and unit.is_destroyed:
			positions_to_clear.append(pos)
			unit.queue_free()
	
	for pos in positions_to_clear:
		battlefield.grid.remove_unit(pos)
