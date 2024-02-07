extends Node

signal hand_reshuffled(reshuffle_attempts: int)
signal hand_updated
signal hand_unit_clicked(hand_unit: HandUnit)
signal reserve_unit_clicked(reserve_unit: ReserveUnit)
signal battle_tile_clicked(tile: BattleTile)
signal update_kingdom(status: Dictionary)
signal update_battlefield(tile_id: int, unit: Unit.EUnitType)
signal update_enemy_battlefield(tile_id: int, unit: Unit.EUnitType)
