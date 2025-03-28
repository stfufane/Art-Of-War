## The two sides of the battlefield are mirrored horizontally so they can be represented by the same class
##  --- --- | --- ---
## | 3 | 0 ||| 0 | 3 |
##  --- --- | --- --- 
## | 4 | 1 ||| 1 | 4 |
##  --- --- | --- --- 
## | 5 | 2 ||| 2 | 5 |
##  --- --- | --- --- 
class_name PlayerTiles extends RefCounted

## Weird but convenient way to make the coordinates map with the tile ids.
## The (0, 0) tile is at the top left (tile id 3 of first player)
static var tiles_coords: Dictionary[bool, PackedVector2Array] = {
    true: PackedVector2Array([Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)]),
    false: PackedVector2Array([Vector2(2, 0), Vector2(2, 1), Vector2(2, 2), Vector2(3, 0), Vector2(3, 1), Vector2(3, 2)])
}

var player: Player = null
var tiles: Dictionary[int, UnitTile] = {}


func _init(p: Player) -> void:
    player = p
    for id in range(6):
        tiles[id] = UnitTile.new(id, player.first)


func reset_units_hp() -> void:
    for tile in tiles.values() as Array[UnitTile]:
        tile.reset_hp()


func disengage_units() -> void:
    for tile in tiles.values() as Array[UnitTile]:
        tile.engaged = false


func engage_unit(tile_id: int) -> void:
    tiles[tile_id].engaged = true


func is_engaged(tile_id: int) -> bool:
    return tiles[tile_id].engaged


func can_set_unit(tile_id: int) -> bool:
    assert(tiles.has(tile_id), "Invalid tile id %d" % tile_id)
    if tiles[tile_id].unit != null:
        return false
    # You can't put a tile on the back row if the front row is empty
    if tile_id > 2:
        if tiles[tile_id - 3].unit == null:
            return false
    return true


func set_unit(tile_id: int, unit: Unit) -> void:
    tiles[tile_id].unit = unit
    update_battlefield_ui(tile_id, unit.type)


func update_battlefield_ui(tile_id: int, unit_type: Unit.EUnitType) -> void:
    GameManager.update_battlefield.rpc_id(player.id, Board.ESide.PLAYER, tile_id, unit_type)
    GameManager.update_battlefield.rpc_id(player.opponent.id, Board.ESide.ENEMY, tile_id, unit_type)


class UnitTile:
    var id: int
    var position: Vector2
    var hp: int = 0
    var unit: Unit = null:
        set(u):
            unit = u
            if u != null:
                hp = u.defense
    var engaged: bool = false:
        set(e):
            engaged = e
            if e:
                hp = unit.defense_engaged

    func _init(tile_id: int, first: bool) -> void:
        id = tile_id
        position = PlayerTiles.tiles_coords[first][id]

    func reset_hp() -> void:
        if unit != null:
            hp = unit.defense
