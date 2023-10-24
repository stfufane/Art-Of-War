class_name CardType
extends Object

enum UnitType {
	King,
	Soldier,
	Guard,
	Wizard,
	Archer,
	Monk
}

var type: UnitType
var name: String
var attack: int
var defense: int
var defense_engaged: int
var attack_range: PackedVector2Array

func _init(t: UnitType, n: String, a: int, d: int, d_e: int, a_r: PackedVector2Array):
	type = t
	name = n
	attack = a
	defense = d
	defense_engaged = d_e
	attack_range = a_r
