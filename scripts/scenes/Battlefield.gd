class_name Battlefield
extends Node2D

@onready var units := $Units as Control
@onready var enemy_units := $EnemyUnits as Control

## The id of the tile the player is attacking from
var attacking_from: int = -1


func _ready() -> void:
    Events.battle_tile_clicked.connect(_on_tile_clicked)
    Events.enemy_battle_tile_clicked.connect(_on_enemy_tile_clicked)
    Events.battle_tile_hovered.connect(_on_tile_hovered)
    Events.update_battlefield.connect(_on_battlefield_updated)
    Events.attack_to_block.connect(_on_attack_to_block)
    Events.attack_done.connect(flash_all_tiles_off)
    Events.start_turn.connect(disengage_units)
    StateManager.get_state(StateManager.EState.ACTION_CHOICE).started.connect(flash_all_tiles_off)
    

func disengage_units() -> void:
    for tile in units.get_children() as Array[BattleTile]:
        tile.unit_engaged = false


func get_tile(tile_id: int) -> BattleTile:
    for tile in units.get_children() as Array[BattleTile]:
        if tile.id == tile_id:
            return tile
    
    return null


func get_enemy_tile(tile_id: int) -> BattleTile:
    for tile in enemy_units.get_children() as Array[BattleTile]:
        if tile.id == tile_id:
            return tile
    
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


func _on_tile_clicked(tile: BattleTile) -> void:
    # TESTING
    if get_parent().name == "root":
        var tile_unit: Unit.EUnitType = GameManager.UNIT_RESOURCES.keys().pick_random()
        tile.set_unit(tile_unit)

    match StateManager.current_state:
        StateManager.EState.INIT_BATTLEFIELD:
            if tile.unit == null and GameManager.selected_hand_unit != null:
                ActionsManager.run.rpc_id(1, Action.Code.INIT_BATTLEFIELD,
                    [tile.id, GameManager.selected_hand_unit.unit.type])

        StateManager.EState.RECRUIT:
            if tile.unit == null:
                if GameManager.selected_hand_unit == null and GameManager.selected_reserve_unit == null:
                    return
                var unit_type: Unit.EUnitType
                var source: Board.EUnitSource
                if GameManager.selected_hand_unit != null:
                    unit_type = GameManager.selected_hand_unit.unit.type
                    source = Board.EUnitSource.HAND
                else:
                    unit_type = GameManager.selected_reserve_unit.unit.type
                    source = Board.EUnitSource.RESERVE

                ActionsManager.run.rpc_id(1, Action.Code.RECRUIT, [tile.id, unit_type, source])

        StateManager.EState.ATTACK:
            if tile.unit != null:
                attacking_from = tile.id
                tile.toggle_flash(true)
                Events.update_instructions.emit("Select the enemy unit to attack")
            else:
                var attacking_tile := get_tile(attacking_from)
                if attacking_tile != null:
                    attacking_tile.toggle_flash(false)
                attacking_from = -1
                Events.update_instructions.emit("Select the unit to attack from")

        _:
            pass


func _on_enemy_tile_clicked(tile: BattleTile) -> void:
    match StateManager.current_state:
        StateManager.EState.ATTACK:
            if attacking_from == -1 or tile.unit == null:
                return

            tile.toggle_flash(true)
            Events.toggle_cancel_button.emit(false) # Cannot cancel anymore
            ActionsManager.run.rpc_id(1, Action.Code.ATTACK, [attacking_from, tile.id])

        _:
            pass


# Display an overlay of the hovered unit attack range
func _on_tile_hovered(tile: BattleTile, state: bool) -> void:
    if tile.unit == null:
        return

    # Do not display the reach when selecting a target
    if tile.side == Board.ESide.ENEMY and \
        StateManager.current_state == StateManager.EState.ATTACK and attacking_from != -1:
        return

    # Turn off all the hints
    if not state:
        for p_tile in units.get_children() as Array[BattleTile]:
            p_tile.toggle_range_hint(false)
        for e_tile in enemy_units.get_children() as Array[BattleTile]:
            e_tile.toggle_range_hint(false)
        return

    # Calculate which tiles should be hinted
    var tiles_in_reach := PartyBattlefield.get_tiles_at_reach(tile.id, tile.side == Board.ESide.PLAYER, tile.unit.type)
    var units_to_highlight: Control = enemy_units if tile.side == Board.ESide.PLAYER else units
    for highlight_tile in units_to_highlight.get_children() as Array[BattleTile]:
        highlight_tile.toggle_range_hint(tiles_in_reach.has(highlight_tile.id))


func _on_attack_to_block(attacking_tile: int, target_tile: int) -> void:
    get_enemy_tile(attacking_tile).toggle_flash(true)
    get_tile(target_tile).toggle_flash(true)