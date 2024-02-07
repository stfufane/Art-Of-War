class_name Unit extends Resource
## The characteristics of a unit

## The type of unit
enum EUnitType {
	King,
	Soldier,
	Guard,
	Wizard,
	Archer,
	Monk
}

@export var type: EUnitType
@export var name: String
@export var attack: int
@export var defense: int
@export var defense_engaged: int
@export var attack_range: PackedVector2Array
