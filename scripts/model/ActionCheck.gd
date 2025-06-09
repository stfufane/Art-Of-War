class_name ActionCheck extends RefCounted

var player: Player = null

var error_message: String = ""

const NOT_YOUR_TURN: String = "It's not your turn"
const NOT_AUTHORIZED: String = "You're not authorized to perform this action now"
const RECRUIT_DONE: String = "You've already recruited, you can't recruit or attack this turn"

## Determines from which states we can go back to the action choice.
static var CANCELLABLE_STATES: Array[StateManager.EState] = [
    StateManager.EState.ATTACK,
    StateManager.EState.SUPPORT,
    StateManager.EState.KING_SUPPORT,
    StateManager.EState.ARCHER_SUPPORT,
    StateManager.EState.PRIEST_SUPPORT,
    StateManager.EState.RECRUIT,
    StateManager.EState.FINISH_TURN,
]

## List of possible supports when it's the player's turn
const AUTHORIZED_SUPPORTS: Array[Unit.EUnitType] = [
    Unit.EUnitType.Archer, Unit.EUnitType.King, Unit.EUnitType.Priest, Unit.EUnitType.Soldier
]

func _init(p: Player) -> void:
    player = p


func check_deck_choice(nb_units: Array[int]) -> bool:
    if nb_units.size() != 6:
        error_message = "You passed the wrong number of units"
        return false
    var total_units: int = nb_units.reduce(func(accum: int, number: int) -> int: return accum + number, 0)
    if total_units != 20:
        error_message = "You must have exactly 20 units"
        return false
    return true


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
    if player.reserve.is_full():
        error_message = "Your reserve is full, you cannot add an other support"
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


func check_attack(attacking_tile: int, _target_tile: int) -> bool:
    if player.tiles.is_engaged(attacking_tile):
        error_message = "You can't attack with an already engaged unit"
        player.state.current = StateManager.EState.ACTION_CHOICE
        return false
    return true


func check_recruit(tile_id: int, unit_type: Unit.EUnitType, source: Board.EUnitSource) -> bool:
    if player.state.current != StateManager.EState.CONSCRIPTION:
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
    if source == Board.EUnitSource.RESERVE and player.reserve.front() != unit_type:
        error_message = "You have to take the first unit of your reserve"
        return false

    return true


func check_support_choice(support_type: Unit.EUnitType) -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.SUPPORT and player.state.current != StateManager.EState.KING_SUPPORT:
        error_message = NOT_AUTHORIZED
        return false
    if not AUTHORIZED_SUPPORTS.has(support_type):
        error_message = "You can only play archer, soldier, priest or king as a support"
        return false
    if player.state.current != StateManager.EState.KING_SUPPORT and not player.hand.has(support_type):
        error_message = "You don't have this unit in your hand"
        return false
    return true


func check_king_support(support_type: Unit.EUnitType) -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.KING_SUPPORT:
        error_message = NOT_AUTHORIZED
        return false
    if not AUTHORIZED_SUPPORTS.has(support_type):
        error_message = "You can only play archer, soldier or priest as a king support"
        return false
    return true


func check_priest_support(src_unit: Unit.EUnitType, src_tile: int, dest_tile: int) -> bool:
    var internal_check := func() -> bool:
        if player.party.current_player != player.id:
            error_message = NOT_YOUR_TURN
            return false
        elif player.state.current != StateManager.EState.PRIEST_SUPPORT and player.state.current != StateManager.EState.KING_SUPPORT:
            error_message = NOT_AUTHORIZED
            return false

        if src_tile < 0:
            if not player.reserve.has(src_unit):
                error_message = "You do not have this unit in your reserve"
                return false
            
            if not player.tiles.has_unit(dest_tile) and not player.tiles.can_set_unit(dest_tile):
                error_message = "You can't put a unit here"
                return false
        else:
            if not player.tiles.can_swap_tiles(src_tile, dest_tile):
                error_message = "You cannot swap these units"
                return false
        
        return true
    
    if not internal_check.call():
        GameManager.reset_priest_support.rpc_id(player.id)
        return false

    return true


func check_archer_support(target_tile: int) -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.ARCHER_SUPPORT and player.state.current != StateManager.EState.KING_SUPPORT:
        error_message = NOT_AUTHORIZED
        return false
    if not player.opponent.tiles.has_unit(target_tile):
        error_message = "There's no unit to attack on this tile"
        return false
    return true


func check_soldier_support() -> bool:
    if player.party.current_player != player.id:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.SUPPORT and player.state.current != StateManager.EState.KING_SUPPORT:
        error_message = NOT_AUTHORIZED
        return false
    if not player.state.king_support and not player.hand.has(Unit.EUnitType.Soldier):
        error_message = "You don't have a soldier unit in your hand"
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


func check_block_attack(unit: Unit.EUnitType) -> bool:
    # Tricky one, you can block only if it's NOT your turn.
    if player.party.current_player == player.id and not player.opponent.state.is_attacking:
        error_message = NOT_YOUR_TURN
        return false
    if player.state.current != StateManager.EState.ATTACK_BLOCK:
        error_message = NOT_AUTHORIZED
        return false
    if player.reserve.is_full():
        error_message = "Your reserve is already full, you cannot block"
        return false
    if not player.hand.has(unit) or (unit != Unit.EUnitType.King and unit != Unit.EUnitType.Guard):
        error_message = "You can't block with this unit"
        return false
    return true


func check_block_support(unit: Unit.EUnitType) -> bool:
    if player.state.current != StateManager.EState.SUPPORT_BLOCK:
        error_message = NOT_AUTHORIZED
        return false
    if player.reserve.is_full():
        error_message = "Your reserve is already full, you cannot block"
        return false
    if not player.hand.has(unit) or (unit != Unit.EUnitType.King and unit != Unit.EUnitType.Wizard):
        error_message = "You can't block with this unit"
        return false
    return true


func check_no_attack_block() -> bool:
    if player.state.current != StateManager.EState.ATTACK_BLOCK:
        error_message = NOT_AUTHORIZED
        return false
    return true


func check_no_support_block() -> bool:
    if player.state.current != StateManager.EState.SUPPORT_BLOCK:
        error_message = NOT_AUTHORIZED
        return false
    return true


func check_cancel() -> bool:
    if not CANCELLABLE_STATES.has(player.state.current):
        error_message = NOT_AUTHORIZED
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
