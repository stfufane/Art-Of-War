class_name Battlefield
extends Node2D

@onready var units := $Units as Control
@onready var enemy_units := $EnemyUnits as Control


func _ready() -> void:
    Events.battle_tile_clicked.connect(_on_tile_clicked)
    Events.enemy_battle_tile_clicked.connect(_on_enemy_tile_clicked)
    Events.battle_tile_hovered.connect(_on_tile_hovered)
    Events.update_battlefield.connect(_on_battlefield_updated)
    Events.attack_to_block.connect(_on_attack_to_block)
    Events.attack_done.connect(_on_attack_done)
    Events.support_done.connect(_on_support_done)
    Events.unit_took_damage.connect(_on_unit_took_damage)
    Events.unit_captured_or_killed.connect(_on_unit_captured_or_killed)
    Events.start_turn.connect(disengage_units)
    Events.reset_priest_support.connect(_on_reset_priest_support)
    StateManager.get_state(StateManager.EState.ACTION_CHOICE).started.connect(flash_all_tiles_off)
    StateManager.get_state(StateManager.EState.PRIEST_SUPPORT).started.connect(_on_reset_priest_support)


func disengage_units() -> void:
    for tile in units.get_children() as Array[BattleTile]:
        if tile.unit != null:
            tile.unit_engaged = false # Will also reset the HP of the unit.


func get_tile(tile_id: int) -> BattleTile:
    for tile in units.get_children() as Array[BattleTile]:
        if tile.id == tile_id:
            return tile

    assert(false, "[Battlefield.get_tile] Invalid tile id %d" % tile_id)
    return null


func get_enemy_tile(tile_id: int) -> BattleTile:
    for tile in enemy_units.get_children() as Array[BattleTile]:
        if tile.id == tile_id:
            return tile

    assert(false, "[Battlefield.get_enemy_tile] Invalid tile id %d" % tile_id)
    return null


func flash_all_tiles_off() -> void:
    for tile in units.get_children() as Array[BattleTile]:
        tile.toggle_flash(false)
    for tile in enemy_units.get_children() as Array[BattleTile]:
        tile.toggle_flash(false)


func _on_battlefield_updated(side: Board.ESide, tile_id: int, unit: Unit.EUnitType) -> void:
    var units_to_process: Control = units if side == Board.ESide.PLAYER else enemy_units
    for tile in units_to_process.get_children() as Array[BattleTile]:
        if tile.id == tile_id:
            tile.set_unit(unit)
            return


func _on_attack_done(attacking_tile: int) -> void:
    if GameManager.my_turn:
        get_tile(attacking_tile).unit_engaged = true
    flash_all_tiles_off()


func _on_unit_took_damage(side: Board.ESide, unit_tile_id: int, damage: int) -> void:
    var damaged_unit := get_tile(unit_tile_id) if side == Board.ESide.PLAYER else get_enemy_tile(unit_tile_id)
    damaged_unit.take_damage(damage) # TODO animate something showing damage.


func _on_unit_captured_or_killed(side: Board.ESide, unit_tile_id: int) -> void:
    var dead_unit := get_tile(unit_tile_id) if side == Board.ESide.PLAYER else get_enemy_tile(unit_tile_id)
    dead_unit.reset_unit() # TODO animate the tile disappearing.


func _on_tile_clicked(tile: BattleTile) -> void:
    # TESTING
    if get_parent().name == "root":
        var tile_unit: Unit.EUnitType = GameManager.UNIT_RESOURCES.keys().pick_random()
        tile.set_unit(tile_unit)

    match StateManager.current_state:
        StateManager.EState.INIT_BATTLEFIELD:
            if tile.unit == null:
                GameManager.init_battlefield(tile.id)

        StateManager.EState.RECRUIT, StateManager.EState.CONSCRIPTION:
            if GameManager.selected_hand_unit == null and GameManager.selected_reserve_unit == null:
                return
            GameManager.recruit(tile.id)

        StateManager.EState.ATTACK:
            if tile.unit_engaged:
                Events.update_instructions.emit("This unit has already attacked this turn. Choose an other one.")
                return
            elif tile.unit != null:
                GameManager.selected_tile_id = tile.id
                tile.toggle_flash(true)
                Events.update_instructions.emit("Select the enemy unit to attack")
            else:
                var attacking_tile := get_tile(GameManager.selected_tile_id)
                if attacking_tile != null:
                    attacking_tile.toggle_flash(false)
                GameManager.selected_tile_id = -1
                Events.update_instructions.emit("Select the unit to attack from")

        StateManager.EState.PRIEST_SUPPORT:
            GameManager.add_switching_tile(tile.id)
            tile.toggle_flash(GameManager.switching_tiles.has(tile.id))
            GameManager.priest_support()

        _:
            pass


func _on_reset_priest_support() -> void:
    # Make sure there are no leftovers of previous priest support
    GameManager.switching_tiles.clear()
    GameManager.selected_reserve_unit = null
    for tile in units.get_children() as Array[BattleTile]:
        tile.toggle_flash(false)
    

func _on_enemy_tile_clicked(tile: BattleTile) -> void:
    match StateManager.current_state:
        StateManager.EState.ATTACK:
            if GameManager.selected_tile_id == -1 or tile.unit == null:
                return

            tile.toggle_flash(true)
            ActionsManager.do(Action.Code.ATTACK, [GameManager.selected_tile_id, tile.id])
        StateManager.EState.ARCHER_SUPPORT:
            if tile.unit == null:
                return
            ActionsManager.do(Action.Code.ARCHER_SUPPORT, [tile.id])
            
        _:
            pass


# Display an overlay of the hovered unit attack range
func _on_tile_hovered(tile: BattleTile, state: bool) -> void:
    if tile.unit == null:
        return

    # Do not display the reach when selecting a target
    if tile.side == Board.ESide.ENEMY and \
        StateManager.current_state == StateManager.EState.ATTACK and GameManager.selected_tile_id != -1:
        return

    # Turn off all the hints
    if not state:
        for p_tile in units.get_children() as Array[BattleTile]:
            p_tile.toggle_range_hint(false)
        for e_tile in enemy_units.get_children() as Array[BattleTile]:
            e_tile.toggle_range_hint(false)
        return

    # Calculate which tiles should be hinted
    var tiles_in_reach := PartyBattlefield.get_tiles_at_reach(tile.id, tile.unit.type)
    var units_to_highlight: Control = enemy_units if tile.side == Board.ESide.PLAYER else units
    for highlight_tile in units_to_highlight.get_children() as Array[BattleTile]:
        highlight_tile.toggle_range_hint(tiles_in_reach.has(highlight_tile.id))


func _on_attack_to_block(attacking_tile: int, target_tile: int) -> void:
    get_enemy_tile(attacking_tile).toggle_flash(true)
    get_tile(target_tile).toggle_flash(true)


func _on_support_done() -> void:
    for tile in units.get_children() as Array[BattleTile]:
        tile.toggle_flash(false)
