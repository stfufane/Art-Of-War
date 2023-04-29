class_name CardType
extends Object

var name: String
var attack: int
var defense: int
var defense_engaged: int
var attack_range: PackedVector2Array

enum UnitTypes {
	King,
	Soldier,
	Guard,
	Wizard,
	Archer,
	Monk
}

func _init(n, a, d, d_e, a_r):
	name = n
	attack = a
	defense = d
	defense_engaged = d_e
	attack_range = a_r
	

