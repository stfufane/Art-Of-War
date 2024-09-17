class_name ActionCheck extends RefCounted

var player: Player = null

var error_message: String = ""

const NOT_YOUR_TURN: String = "It's not your turn"
const NOT_AUTHORIZED: String = "You're not authorized to perform this action now"
const RECRUIT_DONE: String = "You've already recruited, you can't recruit or attack this turn"

func _init(p: Player) -> void:
    player = p


func check_reshuffle() -> bool:
    if player.state.current != StateManager.EState.RESHUFFLE:
        error_message = NOT_AUTHORIZED
        return false
    if player.reshuffle_attempts == 0:
        error_message = "You cannot reshuffle anymore"
        return false
    
    return true


func check_validate_hand() -> bool:
    return player.state.current == StateManager.EState.RESHUFFLE and not player.state.hand_ready


func check_init_battlefield(tile_id: int, _unit_type: Unit.EUnitType) -> bool:
    if not player.state.current == StateManager.EState.INIT_BATTLEFIELD:
        error_message = NOT_AUTHORIZED
        return false
    if player.state.battlefield_ready:
        error_message = "You've already set your battlefield"
        return false
    if not player.tiles.can_set_unit(tile_id):
        error_message = "You can't set a unit here"
        return false
    
    return true

func check_init_reserve(unit_type: Unit.EUnitType) -> bool:
    if not player.state.current == StateManager.EState.INIT_RESERVE:
        error_message = NOT_AUTHORIZED
        return false
    if player.state.reserve_ready:
        error_message = "You've already set your reserve"
        return false
    if not player.hand.has(unit_type):
        error_message = "You don't have this type of unit in your hand"
        return false
    
    return true


func check_start_recruit() -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.ACTION_CHOICE:
        error_message = NOT_AUTHORIZED
        return false
    if player.state.has_recruited:
        error_message = RECRUIT_DONE
        return false
    if player.state.has_attacked:
        error_message = "You've already attacked, you can't recruit this turn"
        return false
    return true


func check_start_support() -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.ACTION_CHOICE:
        error_message = NOT_AUTHORIZED
        return false
    return true


func check_start_attack() -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.ACTION_CHOICE:
        error_message = NOT_AUTHORIZED
        return false
    if player.state.has_recruited:
        error_message = RECRUIT_DONE
        return false
    return true


func check_recruit(tile_id: int, unit_type: Unit.EUnitType, source: Board.EUnitSource) -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.RECRUIT:
        error_message = NOT_AUTHORIZED
        return false
    if player.state.has_recruited:
        error_message = RECRUIT_DONE
        return false
    if not player.tiles.can_set_unit(tile_id):
        error_message = "You can't put a unit here"
        return false
    if source == Board.EUnitSource.HAND and not player.reserve.is_empty():
        error_message = "You have to put a unit from your reserve first"
        return false
    if source == Board.EUnitSource.HAND and not player.hand.has(unit_type):
        error_message = "You don't have this unit in your hand"
        return false
    if source == Board.EUnitSource.RESERVE and not player.reserve.has(unit_type):
        error_message = "You don't have this unit in your reserve"
        return false

    return true


func check_add_to_kingdom(unit: Unit.EUnitType) -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.FINISH_TURN:
        error_message = NOT_AUTHORIZED
        return false
    if not player.hand.has(unit) or unit == Unit.EUnitType.King:
        error_message = "You can't put this unit in your kingdom"
        return false
    return true


func check_end_turn() -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.FINISH_TURN:
        error_message = NOT_AUTHORIZED
        return false
    if player.hand.is_full():
        error_message = "You have to put a unit from your hand in your kingdom"
        return false
    return true
