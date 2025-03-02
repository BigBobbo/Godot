extends RefCounted

var current_phase: int
var current_player: int
var units: Array
var active_squads: Dictionary

func serialize() -> Dictionary:
	return {
		"current_phase": current_phase,
		"current_player": current_player,
		"units": units,
		"active_squads": active_squads
	}

func deserialize(data: Dictionary):
	current_phase = data.current_phase
	current_player = data.current_player
	units = data.units
	
	# Fix for active_squads deserialization
	active_squads = {}
	for player_key in data.active_squads:
		# Convert string key back to integer
		var player_int = int(player_key)
		active_squads[player_int] = data.active_squads[player_key] 