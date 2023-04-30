class_name CardType
extends Object

var type: UnitType
var name: String
var attack: int
var defense: int
var defense_engaged: int
var attack_range: PackedVector2Array

enum UnitType {
	King,
	Soldier,
	Guard,
	Wizard,
	Archer,
	Monk
}

func _init(t, n, a, d, d_e, a_r):
	type = t
	name = n
	attack = a
	defense = d
	defense_engaged = d_e
	attack_range = a_r
	

