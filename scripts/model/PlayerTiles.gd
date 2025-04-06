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


func damage_unit(tile_id: int, damage: int) -> EUnitState:
    return tiles[tile_id].take_damage(damage)


func archer_damage_unit(tile_id: int) -> EUnitState:
    return tiles[tile_id].take_archer_damage()


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


func can_set_unit(tile_id: int) -> bool:
    assert(tiles.has(tile_id), "Invalid tile id %d" % tile_id)
    if has_unit(tile_id):
        return false
    # You can't put a tile on the back row if the front row is empty
    if tile_id > 2:
        if not has_unit(tile_id - 3):
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
    var hp: int = 0
    var unit: Unit = null:
        set(u):
            unit = u
            if u != null:
                hp = u.defense
    var engaged: bool = false:
        set(e):
            engaged = e
            if e and unit != null:
                hp = unit.defense_engaged

    func _init(tile_id: int) -> void:
        id = tile_id

    func take_damage(damage: int) -> EUnitState:
        print("Unit %s is taking %d damage" % [unit.resource_name, damage])
        var state := EUnitState.ALIVE
        # When a unit has all its hp and takes exactly the same amount of damage,
        # it's captured instead of being killed
        if engaged:
            if hp == unit.defense_engaged and damage == hp:
                state = EUnitState.CAPTURED
        else:
            if hp == unit.defense and damage == hp:
                state = EUnitState.CAPTURED

        hp -= damage
        if hp <= 0:
            state = EUnitState.DEAD

        if state != EUnitState.ALIVE:
            print("Unit %s died" % unit.resource_name)
            unit = null # Remove the unit from the battlefield.
        else:
            print("Unit still has %d HP after the attack" % hp)

        return state


    # Archer inflicts exactly one damage and cannot capture a unit.
    func take_archer_damage() -> EUnitState:
        hp -= 1
        if hp <= 0:
            return EUnitState.DEAD

        return EUnitState.ALIVE

    func reset_hp() -> void:
        if unit != null:
            hp = unit.defense
