class_name Kingdom extends Node2D

@export var sprite_size: float = 16.0

@onready var units: Dictionary[Unit.EUnitType, KingdomUnit] = {
    Unit.EUnitType.Soldier: $Soldier as KingdomUnit,
    Unit.EUnitType.Guard: $Guard as KingdomUnit,
    Unit.EUnitType.Priest: $Priest as KingdomUnit,
    Unit.EUnitType.Archer: $Archer as KingdomUnit,
    Unit.EUnitType.Wizard: $Wizard as KingdomUnit
}

@onready var test_button := $Test as Button


func _ready() -> void:
    Events.update_kingdom.connect(_on_kingdom_updated)


func _on_kingdom_updated(units_status: Dictionary[Unit.EUnitType, KingdomUnit.EStatus]) -> void:
    for unit in units_status.keys() as Array[Unit.EUnitType]:
        units[unit].status = units_status[unit]
