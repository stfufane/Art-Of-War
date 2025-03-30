extends Node


signal hand_reshuffled(reshuffle_attempts: int)
signal hand_updated
signal hand_unit_clicked(hand_unit: HandUnit)

signal reserve_unit_clicked(reserve_unit: ReserveUnit)
signal reserve_updated(side: Board.ESide)

signal battle_tile_clicked(tile: BattleTile)
signal enemy_battle_tile_clicked(tile: BattleTile)
signal battle_tile_hovered(tile: BattleTile, state: bool)

signal update_kingdom(status: Dictionary)
signal update_battlefield(side: Board.ESide, tile_id: int, unit: Unit.EUnitType)

signal start_turn

signal recruit_done
signal attack_done(attacking_unit: int)
signal support_done
signal attack_to_block(attacking_unit: int, target: int)
signal unit_captured_or_killed(unit_tile_id: int)

signal update_instructions(instructions: String)
signal display_action_error(error: String)
signal toggle_cancel_button(shown: bool)