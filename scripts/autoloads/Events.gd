extends Node

## Graphical events
signal toggle_castle_flash
signal toggle_reserve_flash
signal toggle_battlefield_flash(state: bool)

signal hand_reshuffled(reshuffle_attempts: int)
signal hand_updated
signal hand_unit_clicked(hand_unit: HandUnit)

signal reserve_unit_clicked(reserve_unit: ReserveUnit)
signal reserve_updated(side: Board.ESide)

signal battle_tile_clicked(tile: BattleTile)
signal update_kingdom(status: Dictionary)
signal update_battlefield(side: Board.ESide, tile_id: int, unit: Unit.EUnitType)

signal start_turn

signal update_instructions(instructions: String)
signal update_turn_menu # A condition has changed and may have enabled/disabled an action from the menu