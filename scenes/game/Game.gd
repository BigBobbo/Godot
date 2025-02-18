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
var active_squads = {
	GameEnums.PlayerTurn.PLAYER_1: [],  # Array of arrays (squads)
	GameEnums.PlayerTurn.PLAYER_2: []
}
var current_squad: Array = []  # Currently selected squad
var next_squad_id: int = 0

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
	
	# Verify army ownership
	print("\nVerifying Player 1 army ownership:")
	for squad in player1_army:
		for unit in squad:
			if unit.owner_player != GameEnums.PlayerTurn.PLAYER_1:
				push_error("Player 1 unit has wrong owner!")
			print("P1 unit owner:", unit.owner_player)
	
	print("\nVerifying Player 2 army ownership:")
	for squad in player2_army:
		for unit in squad:
			if unit.owner_player != GameEnums.PlayerTurn.PLAYER_2:
				push_error("Player 2 unit has wrong owner!")
			print("P2 unit owner:", unit.owner_player)
	
	# Keep armies as squads for deployment
	deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_1] = player1_army
	deployment_units_remaining[GameEnums.PlayerTurn.PLAYER_2] = player2_army
	
	# Initialize active squads (will be populated after deployment)
	active_squads[GameEnums.PlayerTurn.PLAYER_1] = []
	active_squads[GameEnums.PlayerTurn.PLAYER_2] = []

func create_ork_army() -> Array:
	var army = []
	print("Creating army...")
	# Create Warboss
	#var warboss_scene = load("res://scenes/units/Warboss.tscn")
	#if warboss_scene == null:
		#push_error("Failed to load Warboss scene")
		#return army
	## Create Warboss squad (single model)
	#var warboss_squad = []
	#var warboss = warboss_scene.instantiate()
	#warboss.squad_id = get_next_squad_id()
	#warboss_squad.append(warboss)
	#army.append(warboss_squad)
	#print("Added warboss squad")
	
	# Create two squads of Ork Boyz
	for i in range(2):
		var boy_squad = []
		var new_squad_id = get_next_squad_id()
		var boy_scene = load("res://scenes/units/OrkBoy.tscn")
		if boy_scene == null:
			push_error("Failed to load OrkBoy scene")
			continue
		for j in range(2):
			var boy = boy_scene.instantiate()
			boy.squad_id = new_squad_id
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
				battlefield.next_phase()  # Tell battlefield about phase change
		GameEnums.GamePhase.MOVEMENT:
			current_phase = GameEnums.GamePhase.SHOOTING
			battlefield.clear_selection()
			battlefield.next_phase()  # Tell battlefield about phase change
			# Reset movement flags at end of next turn
			if current_player == GameEnums.PlayerTurn.PLAYER_2:
				reset_unit_actions()
		GameEnums.GamePhase.SHOOTING:
			current_phase = GameEnums.GamePhase.CHARGE
			battlefield.next_phase()  # Tell battlefield about phase change
		GameEnums.GamePhase.CHARGE:
			current_phase = GameEnums.GamePhase.FIGHT
			battlefield.next_phase()
		GameEnums.GamePhase.FIGHT:
			current_phase = GameEnums.GamePhase.MORALE
			battlefield.next_phase()
		GameEnums.GamePhase.MORALE:
			current_phase = GameEnums.GamePhase.MOVEMENT
			if current_player == GameEnums.PlayerTurn.PLAYER_2:
				remove_destroyed_units()  # Clean up at end of turn
			switch_player()
			battlefield.next_phase()  # Tell battlefield about phase change
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
	# Debug print each squad's first unit's owner
	for squad in player_squads:
		if not squad.is_empty():
			print("Squad owner:", squad[0].owner_player, " Expected owner:", current_player)
			# Verify squad ownership
			if squad[0].owner_player != current_player:
				push_error("Squad ownership mismatch!")
	print("Available squads:", player_squads.size())
	if player_squads.is_empty():
		return []
	
	# Return all squads
	return player_squads

func deploy_unit(unit: Unit, grid_pos: Vector2i) -> bool:
	# Verify unit ownership
	if unit.owner_player != current_player:
		print("ERROR: Attempting to deploy unit owned by player", unit.owner_player, 
			" during player", current_player, "'s turn")
		return false
		
	if not battlefield.is_in_deployment_zone(grid_pos, current_player):
		return false
		
	print("Attempting to deploy:", unit.get_unit_type(), "for player:", current_player)
	# Check if unit is already deployed and remove it from its current position
	var current_pos = battlefield.grid.get_unit_cell_pos(unit)
	if current_pos != Vector2i(-1, -1):
		battlefield.grid.remove_unit(current_pos)
	
	if battlefield.grid.place_unit(unit, grid_pos):
		var current_squad = battlefield.deployment_panel.get_selected_squad()
		# Track the deployed unit
		battlefield.deployment_panel.add_deployed_unit(unit, grid_pos)
		if not is_instance_valid(unit.get_parent()):
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

func get_next_squad_id() -> int:
	next_squad_id += 1
	return next_squad_id - 1

func add_squad_to_active(squad: Array, player: int):
	active_squads[player].append(squad)

func _on_squad_deployment_finished(squad_id: int):
	print("Game received squad_deployment_finished signal for squad_id:", squad_id)
	# Find and remove the squad from deployment_units_remaining
	for squad in deployment_units_remaining[current_player]:
		if squad[0].squad_id == squad_id:
			print("Found squad to remove from deployment_units_remaining")
			deployment_units_remaining[current_player].erase(squad)
			break
	
	# Create a new squad with all deployed units that share the squad_id
	var deployed_squad = []
	for pos in battlefield.grid.cells:
		var deployed_unit = battlefield.grid.cells[pos]
		if deployed_unit is Unit and deployed_unit.squad_id == squad_id:
			deployed_squad.append(deployed_unit)
	
	print("Created deployed squad with size:", deployed_squad.size())
	active_squads[current_player].append(deployed_squad)
	print("Added deployed squad of size:", deployed_squad.size())
	print("Squads remaining for player", current_player, ":", deployment_units_remaining[current_player].size())
	
	switch_player()
	battlefield.update_deployment_preview()
