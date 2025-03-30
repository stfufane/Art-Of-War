class_name PartyBattlefield
extends RefCounted

## The two sides of the battlefield are mirrored horizontally so they can be represented by the same class
##  --- --- | --- ---
## | 3 | 0 ||| 0 | 3 |
##  --- --- | --- --- 
## | 4 | 1 ||| 1 | 4 |
##  --- --- | --- --- 
## | 5 | 2 ||| 2 | 5 |
##  --- --- | --- --- 

var party: Party = null

const PlayerSide := &"player"
const OpponentSide := &"opponent"


func _init(p: Party) -> void:
    party = p


## Weird but convenient way to make the coordinates map with the tile ids.
## Each player has the same set of ids, so we just need to retrieve ids from the other side based on their position.
## It's symmetrical so we don't care which player needs the information, we just need the ids.
## The (0, 0) tile is at the top left (tile id 3 of first player)
static var tiles_coords: Dictionary[StringName, PackedVector2Array] = {
    PlayerSide: PackedVector2Array([Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)]),
    OpponentSide: PackedVector2Array([Vector2(2, 0), Vector2(2, 1), Vector2(2, 2), Vector2(3, 0), Vector2(3, 1), Vector2(3, 2)])
}


## Method used by the server and the client to determine the reach of a given unit.
static func get_tiles_at_reach(tile_id: int, unit_type: Unit.EUnitType) -> Array[int]:
    var tiles: Array[int] = []
    # First retrieve the actual coordinates of the tile
    var tile_coords: Vector2 = tiles_coords[PlayerSide][tile_id]
    # And the reach of the unit type
    var attack_ranges := GameManager.UNIT_RESOURCES[unit_type].attack_range as PackedVector2Array
    # For each reach coordinate, check the corresponding tiles on the opposite side of the battlefield.
    for attack_range: Vector2 in attack_ranges:
        # Find the eventual corresponding tile in the coordinates.
        var target_tile: int = tiles_coords[OpponentSide].find(tile_coords + attack_range)
        if target_tile > -1:
            tiles.append(target_tile)
    return tiles
