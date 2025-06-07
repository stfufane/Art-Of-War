extends Node

## Defines actions and RPC calls happening client side
##
## All the RPC methods in this class will be called from the server
## to reflect actions on the client

signal party_created(id: String)
signal no_party_found
signal party_cancelled


const BOARD_SCREEN: PackedScene = preload("res://screens/Board.tscn")
const LOBBY_SCREEN: PackedScene = preload("res://screens/Lobby.tscn")

## Input map constant
const LEFT_CLICK: StringName = &"left_click"

const FLASH_SHADER: Shader = preload("res://resources/shaders/flash.gdshader")

const UNIT_RESOURCES: Dictionary[Unit.EUnitType, Unit] = {
    Unit.EUnitType.King: preload("res://resources/units/king.tres") as Unit,
    Unit.EUnitType.Soldier: preload("res://resources/units/soldier.tres") as Unit,
    Unit.EUnitType.Guard: preload("res://resources/units/guard.tres") as Unit,
    Unit.EUnitType.Wizard: preload("res://resources/units/wizard.tres") as Unit,
    Unit.EUnitType.Priest: preload("res://resources/units/priest.tres") as Unit,
    Unit.EUnitType.Archer: preload("res://resources/units/archer.tres") as Unit
}

## Used to display a message in the lobby
var lobby_error: String = ""

var my_turn: bool = false

## Keep track of the current hand unit that is selected
var selected_hand_unit: HandUnit = null
var selected_reserve_unit: ReserveUnit = null
var selected_tile_id: int = -1
var selected_enemy_tile_id: int = -1
var switching_tiles: Array[int] = []

## Units available in hand (init with dummy values for local testing)
var units: Array[Unit.EUnitType] = [Unit.EUnitType.Soldier, Unit.EUnitType.Wizard, Unit.EUnitType.Archer]

## Units available in the reserve
var reserve: Array[Unit.EUnitType] = []
## Same for the enemy reserve
var enemy_reserve: Array[Unit.EUnitType] = []


#region Local game events to trigger server events

func is_reserve_full() -> bool:
    return reserve.size() >= 5


func init_battlefield(tile_id: int) -> void:
    if selected_hand_unit != null:
        ActionsManager.do(Action.Code.INIT_BATTLEFIELD, [tile_id, selected_hand_unit.unit.type])


func recruit(tile_id: int) -> void:
    var unit_type: Unit.EUnitType
    var source: Board.EUnitSource
    if selected_hand_unit != null:
        unit_type = selected_hand_unit.unit.type
        source = Board.EUnitSource.HAND
    else:
        unit_type = selected_reserve_unit.unit.type
        source = Board.EUnitSource.RESERVE

    ActionsManager.do(Action.Code.RECRUIT, [tile_id, unit_type, source])


func add_switching_tile(tile_id: int) -> void:
    if switching_tiles.has(tile_id):
        switching_tiles.erase(tile_id)
        return
    else:
        switching_tiles.append(tile_id)

    if switching_tiles.size() > 1 and selected_reserve_unit != null:
        selected_reserve_unit = null

    # If we have more than 2 units, remove the first one
    if switching_tiles.size() > 2:
        switching_tiles.pop_front()


func priest_support() -> void:
    if switching_tiles.is_empty():
        return
    if switching_tiles.size() == 1 and selected_reserve_unit == null:
        return

    var src_unit_type := selected_reserve_unit.unit.type if selected_reserve_unit != null else Unit.EUnitType.None
    var dest_tile: int = switching_tiles.front()
    var src_tile: int = switching_tiles.back() if switching_tiles.size() > 1 else -1
    ActionsManager.do(Action.Code.PRIEST_SUPPORT, [src_unit_type, src_tile, dest_tile])

#endregion


#region RPC Party events called by the server

@rpc
func notify_party_cancelled() -> void:
    print("Party cancelled")
    party_cancelled.emit()


@rpc
func notify_party_created(id: String) -> void:
    prints("Party created", id)
    party_created.emit(id)


@rpc
func party_not_found() -> void:
    no_party_found.emit()


@rpc
func notify_party_stopped() -> void:
    lobby_error = "The other player left the game."
    get_tree().change_scene_to_packed(LOBBY_SCREEN)


@rpc
func set_action_error(error: String) -> void:
    Events.display_action_error.emit(error)


#endregion

#region RPC Game actions called by the server

@rpc
func start_game() -> void:
    # The _ready method of the board will trigger game setup
    get_tree().change_scene_to_packed(BOARD_SCREEN)


@rpc
func init_hand_shuffle(initial_units: Array) -> void:
    units.assign(initial_units)


@rpc
func update_hand_shuffle(new_units: Array, reshuffle_attempts: int) -> void:
    units.assign(new_units)
    Events.hand_reshuffled.emit(reshuffle_attempts)


@rpc
func update_hand(new_units: Array) -> void:
    units.assign(new_units)
    Events.hand_updated.emit()


@rpc
func update_kingdom(units_status: Dictionary) -> void:
    Events.update_kingdom.emit(units_status)


@rpc
func update_battlefield(side: Board.ESide, id: int, unit: Unit.EUnitType) -> void:
    Events.update_battlefield.emit(side, id, unit)


@rpc
func unit_killed_or_captured(side: Board.ESide, id: int) -> void:
    Events.unit_captured_or_killed.emit(side, id)


@rpc
func unit_took_damage(side: Board.ESide, id: int, damage: int) -> void:
    Events.unit_took_damage.emit(side, id, damage)


@rpc
func update_reserve(side: Board.ESide, new_units: Array) -> void:
    var reserve_to_update: Array[Unit.EUnitType] = reserve if side == Board.ESide.PLAYER else enemy_reserve
    reserve_to_update.assign(new_units)
    Events.reserve_updated.emit(side)


@rpc
func start_turn() -> void:
    my_turn = true
    Events.start_turn.emit()


@rpc
func end_turn() -> void:
    my_turn = false


@rpc
func recruit_done() -> void:
    Events.recruit_done.emit()


@rpc
func attack_done(attacking_unit: int) -> void:
    Events.attack_done.emit(attacking_unit)


@rpc
func reset_priest_support() -> void:
    Events.reset_priest_support.emit()

@rpc
func support_done() -> void:
    Events.support_done.emit()


@rpc
func attack_to_block(attacking_tile: int, target_tile: int) -> void:
    Events.attack_to_block.emit(attacking_tile, target_tile)


@rpc
func support_to_block(unit_type: Unit.EUnitType) -> void:
    Events.support_to_block.emit(unit_type)

#endregion
