class_name PlayerReserve extends RefCounted

const MAX_UNITS: int = 5

var player: Player = null
var units: Array[Unit.EUnitType] = []

func _init(p: Player) -> void:
	player = p

func add_unit(type: Unit.EUnitType) -> void:
	units.append(type)
	update_reserve_ui()

func remove_unit(type: Unit.EUnitType) -> void:
	units.erase(type)
	update_reserve_ui()

func has(unit_type: Unit.EUnitType) -> bool:
	return units.has(unit_type)

func is_empty() -> bool:
	return units.is_empty()

func is_full() -> bool:
	return units.size() == MAX_UNITS

func update_reserve_ui() -> void:
	GameManager.update_reserve.rpc_id(player.id, Board.ESide.PLAYER, units)
	GameManager.update_reserve.rpc_id(player.opponent.id, Board.ESide.ENEMY, units)
