# Warhammer 40K Tactical Game

A simplified tactical game based on Warhammer 40K rules, implemented in Godot 4.

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

### Polish
1. Add better unit visuals
2. Improve UI aesthetics
3. Add turn/phase indicators
4. Add hover tooltips for units
5. Add battle statistics tracking

### To Be Triaged
1. Show unit that is about to be deployed
2. Introduce the concept of units as opposed to models
3. Destroyed units should be marked as such but remain on the battlefield until the end of the turn
4. There is no actual restiction to what squad is moving
5. Advance rules are not implemented


## Current Phase Implementation Status
- [x] Deployment Phase
- [x] Movement Phase
- [x] Shooting Phase
- [ ] Melee Phase
- [ ] Morale Phase 