class_name PartyBattlefield extends RefCounted

var party: Party = null

var player_tiles: Dictionary = {}

func _init(p: Party) -> void:
	party = p

## TODO methods that check whether a player can attack some part of the battlefield or not.