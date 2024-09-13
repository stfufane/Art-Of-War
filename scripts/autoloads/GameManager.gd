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
    Unit.EUnitType.Monk: preload("res://resources/units/monk.tres") as Unit,
    Unit.EUnitType.Archer: preload("res://resources/units/archer.tres") as Unit
}

## Used to display a message in the lobby
var lobby_error: String = ""

## Keep track of the current hand unit that is selected
var selected_hand_unit: HandUnit = null
var selected_reserve_unit: ReserveUnit = null

## Units available in hand (init with dummy values for local testing)
var units: Array[Unit.EUnitType] = [Unit.EUnitType.Soldier, Unit.EUnitType.Wizard, Unit.EUnitType.Archer]

## Units available in the reserve
var reserve: Array[Unit.EUnitType] = []
## Same for the enemy reserve
var enemy_reserve: Array[Unit.EUnitType] = []


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
func start_game(initial_units: Array) -> void:
    units.assign(initial_units)
    # The _ready method of the board will trigger game setup
    get_tree().change_scene_to_packed(BOARD_SCREEN)


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
func update_reserve(side: Board.ESide, new_units: Array) -> void:
    var reserve_to_update: Array[Unit.EUnitType] = reserve if side == Board.ESide.PLAYER else enemy_reserve
    reserve_to_update.assign(new_units)
    Events.reserve_updated.emit(side)


@rpc
func start_turn() -> void:
    Events.start_turn.emit()


@rpc
func recruit_done() -> void:
    Events.recruit_done.emit()


@rpc
func attack_done() -> void:
    Events.attack_done.emit()


@rpc
func attack_to_block(attacking_tile: int, target_tile: int) -> void:
    Events.attack_to_block.emit(attacking_tile, target_tile)

#endregion
