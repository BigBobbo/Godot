# Warhammer 40K Tactical Game

Warhammer 40K Tactical Game Analysis
This is a turn-based tactical game based on Warhammer 40K rules, implemented in Godot 4. The game simulates the tabletop experience with grid-based movement, unit stats, and dice-based combat resolution. Let me break down how it works in detail.
Core Game Structure
The game is organized around a phase-based turn system that alternates between two players. Each player controls an army composed of units organized into squads. The main components are:
Game Controller (Game.gd): Manages game state, player turns, and phase transitions
Battlefield (Battlefield.gd): Handles the grid, unit placement, movement, and combat
Grid System (Grid.gd): Manages the underlying grid cells and unit positions
Units (Unit.gd and subclasses): Represent individual models with stats and abilities
UI Components: Various panels for deployment, unit stats, combat log, etc.
Save/Load System: Allows saving and loading game state
Game Phases
The game follows a structured sequence of phases that mirror the Warhammer 40K tabletop game:
1. Deployment Phase
What happens:
Players take turns placing their units on the battlefield in their designated deployment zones
Each player has a deployment zone (red for Player 1, blue for Player 2)
Units are organized into squads that must be deployed together
User actions:
Select a squad from the deployment panel
Click in their deployment zone to place units
Click "Finish Squad Deployment" when all units in a squad are placed
The game automatically switches to the other player after a squad is deployed
Expected output:
Units appear on the battlefield in the clicked positions
The deployment panel updates to show remaining units
When all units are deployed, the game advances to the Movement phase
2. Movement Phase
What happens:
The active player can move their units within movement range
Units in a squad must maintain coherency (stay within 2 cells of another squad member)
Each unit can only move once per turn
User actions:
Select a squad from the squad panel
Click on a unit to select it
Click on a highlighted cell to move the unit there
Click "Finish Moving Squad" when done moving the squad
If units are out of coherency, the movement is reverted and the player must try again
Expected output:
Valid movement cells are highlighted in green
Units move to the selected positions
Units out of coherency are highlighted in orange
The combat log provides feedback on movement actions
3. Shooting Phase
What happens:
The active player can select units to shoot at enemy units
Each unit can only shoot once per turn
Range and line of sight are checked
Dice are rolled to determine hits, wounds, and saves
User actions:
Click on a friendly unit to select it as the shooter
Valid targets are highlighted in red
Click on an enemy unit to shoot at it
Expected output:
A range indicator shows the shooting range
The combat log displays dice roll results
Hit rolls (based on Ballistic Skill)
Wound rolls (based on Strength vs. Toughness)
Save rolls (based on Armor Save)
Damage is applied to the target
Units are marked as destroyed if they lose all wounds
4. Charge Phase
What happens:
The active player can attempt to charge enemy units with their squads
A charge roll (2D6) determines how far units can move
Units must end their charge move within engagement range of the target
User actions:
Select a squad from the squad panel
Click on an enemy unit to attempt a charge
If successful, select and move individual units in the charging squad
Click "Finish Squad" when done positioning the charging units
Units must maintain coherency and at least one model must reach the target
Expected output:
The combat log shows the charge roll
Valid charge moves are highlighted
Units that successfully charge are marked as being in melee
Units that fail a charge cannot charge again this turn
5. Fight Phase
What happens:
Units in melee combat can attack enemy units
Attacks are resolved with dice rolls for hits, wounds, and saves
Each unit can only fight once per turn
User actions:
Click on a friendly unit in melee to select it
Click on an enemy unit in engagement range to attack it
Expected output:
The combat log shows attack results
Hit rolls (based on Weapon Skill)
Wound rolls (based on Strength vs. Toughness)
Save rolls (based on Armor Save)
Damage is applied to the target
6. Morale Phase
What happens:
Units that have taken casualties must take morale tests
Currently this phase is mostly a placeholder in the implementation
User actions:
Currently automatic (no user interaction required)
Expected output:
The game advances to the next player's turn
Key Game Mechanics
Unit Stats and Combat
Units have several key statistics:
Movement: How far a unit can move (in cells)
Weapon Skill (WS): Melee attack accuracy (roll needed to hit)
Ballistic Skill (BS): Ranged attack accuracy (roll needed to hit)
Strength: Determines ability to wound in combat
Toughness: Resistance to wounds
Wounds: How much damage a unit can take before being destroyed
Armor Save: Roll needed to ignore wounds
Attacks: Number of attack dice rolled in combat
Combat is resolved through dice rolls:
1. Hit Roll: Roll ≥ BS/WS to hit
Wound Roll: Roll based on Strength vs. Toughness comparison
Save Roll: Defender rolls ≥ Armor Save to prevent damage
Squad Coherency
Units in a squad must stay within 2 cells of at least one other unit in the same squad. This is checked:
After movement
After charge moves
If coherency is broken, the player must reposition their units
Charging and Melee
Charging works as follows:
Select a squad and target an enemy unit
Roll 2D6 to determine charge distance
If the roll is sufficient, units can move up to that distance
At least one unit must end within engagement range (1 cell) of the target
Units that successfully charge are marked as being in melee
Save/Load System
The game includes a save/load system that stores:
Current phase and player
Unit positions and states
Squad information
Allows resuming games later
Technical Implementation
Grid System
The battlefield uses a 24x24 grid of 32-pixel cells
Units occupy one or more cells based on their size
The grid tracks unit positions and handles movement validation
Line of sight and range calculations are performed on the grid
Unit Management
Units are organized into squads with a shared squad ID
Each unit tracks its own state (moved, shot, charged, fought)
Units have visual indicators for selection, health, and destroyed status
Combat Resolution
Combat uses random dice rolls (1-6)
Results are displayed in the combat log
Damage is applied to units, reducing their wounds
Units are marked as destroyed when wounds reach zero
UI Components
Deployment Panel: Shows units available for deployment
Squad Panel: Lists available squads for the current phase
Unit Stats: Shows detailed stats for hovered units
Combat Log: Displays combat results and game messages
Save/Load Panel: Interface for saving and loading games
Conclusion
This implementation provides a simplified but faithful adaptation of the Warhammer 40K tabletop game. It captures the core mechanics of movement, shooting, and melee combat while automating the dice rolling and rule enforcement. The phase-based turn structure and squad management reflect the strategic depth of the original game.
The code is well-organized with clear separation between game logic, UI, and unit behavior. The save/load functionality adds convenience for longer games. While some advanced features from the tabletop game are not yet implemented (as noted in the TODO list), the current implementation provides a solid foundation for a tactical wargame experience.

## Current Features
- Grid-based movement system
- Deployment phase
- Movement phase
- Basic shooting phase
- Combat log with dice roll results
- Unit stats and characteristics
- Player turns

## TODO List

### High Priority
1. Implement unit removal when destroyed
2. Add melee phase
3. Add unit coherency for squads
4. Show range indicators when selecting units to shoot
5. Add line of sight checks for shooting

### Medium Priority
1. Add different weapon profiles
2. Add terrain and cover saves
3. Add unit special rules
4. Add morale phase
5. Add objective markers
6. Add victory conditions

### Low Priority
1. Add unit animations
2. Add sound effects
3. Add particle effects for shooting/damage
4. Add army list builder
5. Add save/load game state
6. Add UI for unit stats and abilities

### Bug Fixes Needed
1. Improve combat log visibility and formatting
2. Fix deployment zone visualization
3. Add visual feedback for phase changes
4. Add confirmation for ending phases/turns
5. Fix unit stats visibility
6. Fix unit stats position
7. Range circle for shooting does not align with actual range
8. Add way to add differnt cell sizes for different model types easily
9. Be able to rotate models
10. Ensure measurements are taken from outter edge of models
11. During deployment phase, show the models that are about to be deployed and be able to select specific ones
12. add terrain to the battlefield
13. Add alternate controls i.e phone or steam deck
14. Try actual cell sizes, so much bigger board and models
15. Add army list builder
16. Add save/load game state
17. add option to advance a squad
18. Add way to add different weapon profiles
19. Add terrain and cover saves
20. Add unit special rules
21. Add morale phase
22. Add objective markers
23. Add victory conditions
24. Add way to select which model is charging from a squad

### Polish
1. Add better unit visuals
2. Improve UI aesthetics
3. Add turn/phase indicators
4. Add hover tooltips for units
5. Add battle statistics tracking


## Current Phase Implementation Status
- [x] Deployment Phase
- [x] Movement Phase
- [x] Shooting Phase
- [ ] Melee Phase
- [ ] Morale Phase 