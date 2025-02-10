extends Control

@onready var phase_label = $PhaseLabel
@onready var turn_label = $TurnLabel
@onready var next_phase_button = $NextPhaseButton

var game: Node

func _ready():
	game = get_parent()
	update_labels()

func _on_next_phase_button_pressed():
	game.next_phase()
	update_labels()

func update_labels():
	var phase_text = "Phase: "
	match game.current_phase:
		GameEnums.GamePhase.DEPLOYMENT:
			phase_text += "Deployment"
		GameEnums.GamePhase.MOVEMENT:
			phase_text += "Movement"
		GameEnums.GamePhase.SHOOTING:
			phase_text += "Shooting"
		GameEnums.GamePhase.CHARGE:
			phase_text += "Charge"
		GameEnums.GamePhase.FIGHT:
			phase_text += "Fight"
		GameEnums.GamePhase.MORALE:
			phase_text += "Morale"
	
	var turn_text = "Turn: Player "
	turn_text += "1" if game.current_player == GameEnums.PlayerTurn.PLAYER_1 else "2"
	
	phase_label.text = phase_text
	turn_label.text = turn_text 
