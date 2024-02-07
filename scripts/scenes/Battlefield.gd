class_name Battlefield extends Node2D

enum ESide { Player, Enemy }


@onready var units: Control = $Units
@onready var enemy_units: Control = $EnemyUnits


func _ready() -> void:
	Events.battle_tile_clicked.connect(_on_tile_clicked)
	Events.update_battlefield.connect(_on_battlefield_updated)
	Events.update_enemy_battlefield.connect(_on_enemy_battlefield_updated)


func _on_battlefield_updated(tile_id: int, unit: Unit.EUnitType):
	for tile: BattleTile in units.get_children():
		if tile.id == tile_id:
			tile.set_unit(unit)
			return


func _on_enemy_battlefield_updated(tile_id: int, unit: Unit.EUnitType):
	for tile: BattleTile in enemy_units.get_children():
		if tile.id == tile_id:
			tile.set_unit(unit)
			return


func _on_tile_clicked(tile: BattleTile) -> void:
	# TESTING
	if get_parent().name == "root":
		var tile_unit: Unit.EUnitType = GameManager.UNIT_RESOURCES.keys().pick_random()
		tile.set_unit(tile_unit)
	
	match StateManager.current_state:
		StateManager.EState.INIT_BATTLEFIELD:
			if tile.unit == null and tile.side == ESide.Player and GameManager.selected_hand_unit != null:
				GameServer.run_action.rpc_id(1, Action.Code.SET_BATTLEFIELD_UNIT, 
					{"tile_id":tile.id, "unit_type": GameManager.selected_hand_unit.unit.type})
