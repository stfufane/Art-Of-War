class_name PlayerTiles extends RefCounted

enum EUnitState {
    ALIVE,
    CAPTURED,
    DEAD
}

var player: Player = null
var tiles: Dictionary[int, UnitTile] = {}


func _init(p: Player) -> void:
    player = p
    for id in range(6):
        tiles[id] = UnitTile.new(id)


func reset_units_hp() -> void:
    for tile in tiles.values() as Array[UnitTile]:
        tile.reset_hp()


func disengage_units() -> void:
    for tile in tiles.values() as Array[UnitTile]:
        tile.engaged = false


func engage_unit(tile_id: int) -> void:
    tiles[tile_id].engaged = true


func can_swap_tiles(tile_id_1: int, tile_id_2: int) -> bool:
    # Check if the tiles are not empty and not the same
    if tile_id_1 == tile_id_2:
        return false
    if not has_unit(tile_id_1) and not has_unit(tile_id_2):
        return false

    # If both have units, it's all good, they're already in valid positions.
    if has_unit(tile_id_1) and has_unit(tile_id_2):
        return true

    # The complicated case is when moving a unit to an empty tile.
    # We can't move a unit behind itself or it would create an empty front row.
    # First we check if the dest tile is valid. If it is, we check that moving the unit won't create an empty front row.
    var internal_check := func(src_tile: int, dest_tile: int) -> bool:
        if not has_unit(dest_tile):
            if not can_set_unit(dest_tile):
                return false
            if src_tile + 3 == dest_tile:
                return false
        return true

    if not internal_check.call(tile_id_1, tile_id_2) or not internal_check.call(tile_id_2, tile_id_1):
        return false

    return true


func swap_units(tile_id_1: int, tile_id_2: int) -> void:
    # First swap all the unit contents
    var tile_1: UnitTile = tiles[tile_id_1]
    print("Swapping tile 1 %s with tile 2 %s" % [tile_1.to_string(), tiles[tile_id_2].to_string()])
    tiles[tile_id_1] = tiles[tile_id_2]
    tiles[tile_id_2] = tile_1

    # Then reset the ids and update the UI accordingly
    tiles[tile_id_1].id = tile_id_1
    tiles[tile_id_2].id = tile_id_2
    update_battlefield_ui(tile_id_1, tiles[tile_id_1].unit.type if has_unit(tile_id_1) else Unit.EUnitType.None)
    update_battlefield_ui(tile_id_2, tiles[tile_id_2].unit.type if has_unit(tile_id_2) else Unit.EUnitType.None)

    # Check that we did not leave an empty tile in the front row
    check_back_row()


func check_back_row() -> void:
    for tile_id in PartyBattlefield.BackRow:
        # Check that the tile in front of it is not empty
        if has_unit(tile_id) and not has_unit(tile_id - 3):
            # The back row tile is empty, we need to move the unit to the front row
            swap_units(tile_id, tile_id - 3)


func damage_unit(tile_id: int, damage: int, is_archer: bool) -> EUnitState:
    return tiles[tile_id].take_damage(damage, is_archer)


func is_engaged(tile_id: int) -> bool:
    return tiles[tile_id].engaged


func has_unit(tile_id: int) -> bool:
    return tiles[tile_id].unit != null


func get_attack(tile_id: int) -> int:
    if has_unit(tile_id):
        return tiles[tile_id].unit.attack
    return 0


func get_unit_type(tile_id: int) -> Unit.EUnitType:
    if has_unit(tile_id):
        return tiles[tile_id].unit.type
    return Unit.EUnitType.None


func is_empty() -> bool:
    for tile in tiles.values() as Array[UnitTile]:
        if tile.unit != null:
            return false
    return true


func can_set_unit(tile_id: int) -> bool:
    assert(tiles.has(tile_id), "Invalid tile id %d" % tile_id)
    # You can't replace a unit during conscription
    if player.state.current == StateManager.EState.CONSCRIPTION and has_unit(tile_id):
        return false
    # You can't put a tile on the back row if the front row is empty
    if PartyBattlefield.BackRow.has(tile_id):
        if not has_unit(tile_id - 3):
            return false
    return true


func set_unit(tile_id: int, unit: Unit) -> void:
    tiles[tile_id].unit = unit
    update_battlefield_ui(tile_id, unit.type)


func update_battlefield_ui(tile_id: int, unit_type: Unit.EUnitType) -> void:
    GameManager.update_battlefield.rpc_id(player.id, Board.ESide.PLAYER, tile_id, unit_type)
    GameManager.update_battlefield.rpc_id(player.opponent.id, Board.ESide.ENEMY, tile_id, unit_type)


class UnitTile extends RefCounted:
    var id: int
    var hp: int = 0
    var unit: Unit = null:
        set(u):
            unit = u
            if u != null:
                hp = u.defense
                engaged = false
    var engaged: bool = false:
        set(e):
            engaged = e
            if e and unit != null:
                hp = unit.defense_engaged


    func _init(tile_id: int) -> void:
        id = tile_id


    func _to_string() -> String:
        var unit_string: String = "[UnitTile %d" % id
        if unit != null:
            unit_string += " with %s (%d hp)" % [unit.resource_name, hp]
        else:
            unit_string += " without unit"
        unit_string += "]"
        return unit_string

    func take_damage(damage: int, is_archer: bool) -> EUnitState:
        print("Unit %s is taking %d damage" % [unit.resource_name, damage])
        var state := EUnitState.ALIVE
        # When a unit has all its hp and takes exactly the same amount of damage,
        # it's captured instead of being killed, except when dealing damage with an archer.
        if not is_archer:
            if engaged:
                if hp == unit.defense_engaged and damage == hp:
                    state = EUnitState.CAPTURED
            else:
                if hp == unit.defense and damage == hp:
                    state = EUnitState.CAPTURED

        if state != EUnitState.CAPTURED:
            hp -= damage
            if hp <= 0:
                state = EUnitState.DEAD

        if state != EUnitState.ALIVE:
            print("Unit %s died" % unit.resource_name)
            unit = null # Remove the unit from the battlefield.
        else:
            print("Unit still has %d HP after the attack" % hp)

        return state


    func reset_hp() -> void:
        if unit != null:
            hp = unit.defense
