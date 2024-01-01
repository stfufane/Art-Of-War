class_name CardUnit extends Resource

enum UnitType {
	King,
	Soldier,
	Guard,
	Wizard,
	Archer,
	Monk
}

@export var type: UnitType
@export var name: String
@export var attack: int
@export var defense: int
@export var defense_engaged: int
@export var attack_range: PackedVector2Array
