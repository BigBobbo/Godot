extends Node2D

enum GamePhase {DEPLOYMENT, MOVEMENT, SHOOTING, MELEE}
enum PlayerTurn {PLAYER_1, PLAYER_2}

var current_phase: GamePhase = GamePhase.DEPLOYMENT
var current_player: PlayerTurn = PlayerTurn.PLAYER_1
var deployment_units_remaining = []

func _ready():
    setup_game()

func setup_game():
    # Initialize armies for both players
    var player1_army = create_ork_army()
    var player2_army = create_ork_army()
    deployment_units_remaining = player1_army + player2_army

func create_ork_army() -> Array:
    var army = []
    # Create Warboss
    var warboss = load("res://scenes/units/Warboss.tscn").instantiate()
    army.append(warboss)
    
    # Create two squads of Ork Boyz
    for i in range(2):
        var boy_squad = []
        for j in range(10):
            var boy = load("res://scenes/units/OrkBoy.tscn").instantiate()
            boy_squad.append(boy)
        army.append(boy_squad)
    
    return army

func next_phase():
    match current_phase:
        GamePhase.DEPLOYMENT:
            if deployment_units_remaining.is_empty():
                current_phase = GamePhase.MOVEMENT
        GamePhase.MOVEMENT:
            current_phase = GamePhase.SHOOTING
        GamePhase.SHOOTING:
            current_phase = GamePhase.MELEE
        GamePhase.MELEE:
            current_phase = GamePhase.MOVEMENT
            switch_player()

func switch_player():
    current_player = PlayerTurn.PLAYER_2 if current_player == PlayerTurn.PLAYER_1 else PlayerTurn.PLAYER_1 