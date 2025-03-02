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
	active_squads = data.active_squads 