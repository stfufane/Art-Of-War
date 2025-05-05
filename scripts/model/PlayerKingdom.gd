class_name PlayerKingdom extends RefCounted

var player: Player = null

## Store the kingdom in raw number of units
var units: Dictionary[Unit.EUnitType, int] = {
	Unit.EUnitType.Soldier: 0,
	Unit.EUnitType.Guard: 0,
	Unit.EUnitType.Wizard: 0,
	Unit.EUnitType.Priest: 0,
	Unit.EUnitType.Archer: 0
}

## And also relative to the other player
var status: Dictionary[Unit.EUnitType, KingdomUnit.EStatus] = {
	Unit.EUnitType.Soldier: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Guard: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Wizard: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Priest: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Archer: KingdomUnit.EStatus.Equal
}

func _init(p: Player) -> void:
	player = p


func add_unit(type: Unit.EUnitType) -> void:
	if type == Unit.EUnitType.King:
		return
	units[type] += 1
	player.party.update_kingdom_status()


func units_total() -> int:
	var total := 0
	for unit_nb in units.values() as Array[int]:
		total += unit_nb
	return total