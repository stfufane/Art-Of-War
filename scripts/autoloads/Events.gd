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
signal unit_captured_or_killed(side: Board.ESide, unit_tile_id: int)
signal unit_took_damage(side: Board.ESide, unit_tile_id: int, damage: int)

signal start_turn

signal recruit_done
signal attack_done(attacking_unit: int)
signal reset_priest_support
signal support_done
signal attack_to_block(attacking_unit: int, target: int)
signal support_to_block(unit: Unit.EUnitType)

signal state_changed(state: StateManager.EState)

signal update_instructions(instructions: String)
signal display_action_error(error: String)
