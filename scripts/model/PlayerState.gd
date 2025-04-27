class_name PlayerState extends RefCounted

var player: Player = null ## Reference to the player holding the state

## Every time the state is updated by the server, the client is notified via an RPC call
var current: StateManager.EState = StateManager.EState.WAITING_FOR_PLAYER:
    set(state):
        # The state can't change anymore when the party is over.
        if player.party.status == Party.EStatus.GAME_WON:
            return
        current = state
        print("%s (%d) state is now %s" % [player.label, player.id, StateManager.EState.keys()[current]])
        StateManager.set_state.rpc_id(player.id, state)


var hand_ready: bool = false:
    set(ready):
        hand_ready = ready
        if ready:
            current = StateManager.EState.INIT_BATTLEFIELD


var battlefield_ready: bool = false:
    set(ready):
        battlefield_ready = ready
        if ready:
            current = StateManager.EState.INIT_RESERVE


var reserve_ready: bool = false:
    set(ready):
        reserve_ready = ready
        if ready:
            if player.first:
                # If the first player is the first to finish, wait for the second player to finish
                # Otherwise, start the turn
                if player.opponent.state.reserve_ready:
                    player.party.init_kingdoms()
                    player.start_turn()
                else:
                    current = StateManager.EState.WAITING_FOR_PLAYER
            else:
                # Second player always waits, and if he finished second, first player can start his turn.
                current = StateManager.EState.WAITING_FOR_PLAYER
                if player.opponent.state.reserve_ready:
                    player.party.init_kingdoms()
                    player.opponent.start_turn()


var is_attacking: bool = false:
    set(attacking):
        is_attacking = attacking
        if not is_attacking:
            attacking_tile = -1
            target_tile = -1


# TODO: group inside a SupportData utilitary class
var support_unit: Unit.EUnitType = Unit.EUnitType.None
var king_support: bool = false
var priest_action: PriestAction = null
var archer_target_tile: int = -1
var attack_bonus: int = 0 # Increases when a soldier is used as support

var attacking_tile: int = -1
var target_tile: int = -1

var has_attacked: bool = false
var has_recruited: bool = false

var dead_units: int = 0


func _init(p: Player) -> void:
    player = p


func new_turn() -> void:
    has_attacked = false
    has_recruited = false
    attack_bonus = 0
    current = StateManager.EState.ACTION_CHOICE


## After recruiting, we come back to action choice
func recruit_done() -> void:
    has_recruited = true
    GameManager.recruit_done.rpc_id(player.id)
    current = StateManager.EState.ACTION_CHOICE


func attack(attacking: int, target: int) -> void:
    is_attacking = true
    attacking_tile = attacking
    target_tile = target


func attack_done() -> void:
    # Mark the card that just attacked as engaged so it can't attack twice
    player.tiles.engage_unit(attacking_tile)
    var attacked_with := attacking_tile # Save a copy because it will be reset next line.
    is_attacking = false
    has_attacked = true

    # Notify both players that the attack is done.
    GameManager.attack_done.rpc_id(player.id, attacked_with)
    GameManager.attack_done.rpc_id(player.opponent.id, attacked_with)

    # Check that the opponent still has units on his battlefield.
    # If he does not he's force to recruit 2 units. If he can't, he loses.
    if player.opponent.tiles.is_empty():
        player.opponent.state.current = StateManager.EState.CONSCRIPTION # TODO
        current = StateManager.EState.WAITING_FOR_PLAYER
        return

    # If the opponent has units, we can go back to action choice.
    current = StateManager.EState.ACTION_CHOICE
    player.opponent.state.current = StateManager.EState.WAITING_FOR_PLAYER


func is_supporting() -> bool:
    return support_unit != Unit.EUnitType.None


func start_support(unit_type: Unit.EUnitType) -> void:
    support_unit = unit_type
    # Remove the used support from the hand and add it to the reserve
    if king_support: # Handle the case of king support
        player.hand.remove_unit(Unit.EUnitType.King)
        player.reserve.add_unit(Unit.EUnitType.King)
    else:
        player.hand.remove_unit(unit_type)
        player.reserve.add_unit(unit_type)


func support_done() -> void:
    # Reset all support data
    support_unit = Unit.EUnitType.None
    king_support = false
    priest_action = null
    archer_target_tile = -1

    current = StateManager.EState.ACTION_CHOICE
    player.opponent.state.current = StateManager.EState.WAITING_FOR_PLAYER
    # Notify both players that the support is done.
    GameManager.support_done.rpc_id(player.id)
    GameManager.support_done.rpc_id(player.opponent.id)


func end_turn() -> void:
    current = StateManager.EState.WAITING_FOR_PLAYER
    GameManager.end_turn.rpc_id(player.id)


class PriestAction extends Object:
    var src_unit: Unit.EUnitType
    var src_tile: int
    var dest_tile: int
    func _init(s_u: Unit.EUnitType, s_t: int, d_t: int) -> void:
        src_unit = s_u
        src_tile = s_t
        dest_tile = d_t