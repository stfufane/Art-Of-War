class_name Battlefield extends Node2D

@onready var units := $Units as Control
@onready var enemy_units := $EnemyUnits as Control


func _ready() -> void:
	Events.battle_tile_clicked.connect(_on_tile_clicked)
	Events.update_battlefield.connect(_on_battlefield_updated)
	Events.start_turn.connect(disengage_units)


func disengage_units() -> void:
	for tile in units.get_children() as Array[BattleTile]:
		tile.unit_engaged = false


func _on_battlefield_updated(side: Board.ESide, tile_id: int, unit: Unit.EUnitType) -> void:
	Events.toggle_battlefield_flash.emit(false)
	var units_to_process: Control = units if side == Board.ESide.PLAYER else enemy_units
	for tile in units_to_process.get_children() as Array[BattleTile]:
		if tile.id == tile_id:
			tile.set_unit(unit)
			return


func _on_enemy_battlefield_updated(tile_id: int, unit: Unit.EUnitType) -> void:
	for tile in enemy_units.get_children() as Array[BattleTile]:
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
			if (
				tile.unit == null
				and tile.side == Board.ESide.PLAYER
				and GameManager.selected_hand_unit != null
			):
				ActionsManager.run.rpc_id(
					1,
					Action.Code.INIT_BATTLEFIELD,
					{"tile_id": tile.id, "unit_type": GameManager.selected_hand_unit.unit.type}
				)

		StateManager.EState.RECRUIT:
			if tile.unit == null and tile.side == Board.ESide.PLAYER:
				if (
					GameManager.selected_hand_unit == null
					and GameManager.selected_reserve_unit == null
				):
					return
				var unit_type: Unit.EUnitType = (
					GameManager.selected_hand_unit.unit.type
					if GameManager.selected_hand_unit != null
					else GameManager.selected_reserve_unit.unit.type
				)
				var source: Board.EUnitSource = (
					Board.EUnitSource.HAND
					if GameManager.selected_hand_unit != null
					else Board.EUnitSource.RESERVE
				)
				ActionsManager.run.rpc_id(
					1,
					Action.Code.RECRUIT,
					{"tile_id": tile.id, "unit_type": unit_type, "source": source}
				)
