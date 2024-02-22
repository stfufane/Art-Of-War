class_name PlayerKingdom extends RefCounted

var player: Player = null

## Store the kingdom in raw number of units
var units: Dictionary = {
	Unit.EUnitType.Soldier: 0,
	Unit.EUnitType.Guard: 0,
	Unit.EUnitType.Wizard: 0,
	Unit.EUnitType.Monk: 0,
	Unit.EUnitType.Archer: 0
}

## And also relative to the other player
var status: Dictionary = {
	Unit.EUnitType.Soldier: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Guard: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Wizard: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Monk: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Archer: KingdomUnit.EStatus.Equal
}

func _init(p: Player) -> void:
    player = p


func add_unit(type: Unit.EUnitType) -> void:
    units[type] += 1
    player.party.update_kingdom_status()