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
const LEFT_CLICK: String = "left_click" ## Input map constant

const UNIT_RESOURCES: Dictionary = {
	Unit.EUnitType.King: preload("res://resources/units/king.tres"),
	Unit.EUnitType.Soldier: preload("res://resources/units/soldier.tres"),
	Unit.EUnitType.Guard: preload("res://resources/units/guard.tres"),
	Unit.EUnitType.Wizard: preload("res://resources/units/wizard.tres"),
	Unit.EUnitType.Monk: preload("res://resources/units/monk.tres"),
	Unit.EUnitType.Archer: preload("res://resources/units/archer.tres")
}

## Used to display a message in the lobby
var error_message: String = ""

## Keep track of the current hand unit that is selected
var selected_hand_unit: HandUnit = null
var selected_reserve_unit: ReserveUnit = null

## init with dummy values for local testing
var units: Array[Unit.EUnitType] = [Unit.EUnitType.Soldier, Unit.EUnitType.Wizard, Unit.EUnitType.Archer]


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
func party_not_found():
	no_party_found.emit()


@rpc
func notify_party_stopped() -> void:
	error_message = "The other player left the game."
	get_tree().change_scene_to_packed(LOBBY_SCREEN)

#endregion

#region RPC Game actions called by the server

@rpc
func start_game(initial_units: Array):
	units.assign(initial_units)
	# The scene ready method of the board will trigger game setup
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
func update_battlefield(id: int, unit: Unit.EUnitType) -> void:
	Events.update_battlefield.emit(id, unit)


@rpc 
func update_enemy_battlefield(id: int, unit: Unit.EUnitType) -> void:
	Events.update_enemy_battlefield.emit(id, unit)

#endregion
