class_name PartyBattlefield
extends RefCounted


var party: Party = null


func _init(p: Party) -> void:
    party = p


## Method used by the server and the client to determine the reach of a given unit.
static func get_tiles_at_reach(tile_id: int, from_player: bool, unit_type: Unit.EUnitType) -> Array[int]:
    var tiles: Array[int] = []
    # First retrieve the actual coordinates of the tile
    var tile_coords: Vector2 = PlayerTiles.tiles_coords[from_player][tile_id]
    # And the reach of the unit type
    var attack_ranges := GameManager.UNIT_RESOURCES[unit_type].attack_range as PackedVector2Array
    # For each reach coordinate, check the corresponding tiles on the opposite side of the battlefield.
    for attack_range: Vector2 in attack_ranges.duplicate(): # Duplicate to avoid modifying a reference
        if not from_player:
            # Invert the x coordinate when calculating the enemy's reach
            attack_range.x = -attack_range.x
        # Find the eventual corresponding tile in the coordinates.
        var target_tile: int = PlayerTiles.tiles_coords[not from_player].find(tile_coords + attack_range)
        if target_tile > -1:
            tiles.append(target_tile)
    return tiles
