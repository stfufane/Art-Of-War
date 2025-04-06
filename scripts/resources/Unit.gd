class_name Unit extends Resource
## The characteristics of a unit

## The type of unit
enum EUnitType {
	King,
	Soldier,
	Guard,
	Wizard,
	Archer,
	Monk,
	None # To allow returning invalid unit type
}

@export var type: EUnitType
@export var attack: int
@export var defense: int
@export var defense_engaged: int
@export var attack_range: PackedVector2Array
@export var support_text: String
@export var long_support_text: String