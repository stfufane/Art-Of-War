class_name Player
extends Object

var id: int
var first: bool = false
var opponent: Player = null


var label: String:
    get:
        return "P1" if first else "P2"


var deck: Array[Unit.EUnitType] = []
var reshuffle_attempts: int = 3

var reserve: PlayerReserve = null
var hand: PlayerHand = null
var kingdom: PlayerKingdom = null
var tiles: PlayerTiles = null
var state: PlayerState = null
var action_check: ActionCheck = null

var dead_units: int = 0
var party: Party = null


func _init(player_id: int) -> void:
    id = player_id

func setup() -> void:
    reserve = PlayerReserve.new(self)
    hand = PlayerHand.new(self)
    kingdom = PlayerKingdom.new(self)
    tiles = PlayerTiles.new(self)
    state = PlayerState.new(self)
    action_check = ActionCheck.new(self)


func init_party() -> void:
    for _i in range(4):
        deck.append(Unit.EUnitType.Soldier)
        deck.append(Unit.EUnitType.Archer)
        deck.append(Unit.EUnitType.Guard)
        deck.append(Unit.EUnitType.Wizard)
        deck.append(Unit.EUnitType.Monk)
    deck.shuffle()

    for _i in range(3):
        hand.add_unit(draw_from_deck())
    hand.add_unit(Unit.EUnitType.King)


func draw_from_deck() -> Unit.EUnitType:
    var drawn_card: Unit.EUnitType = deck.pop_back()
    return drawn_card


func reshuffle_deck() -> void:
    reshuffle_attempts -= 1
    deck.clear()
    hand.clear()
    init_party()
    GameManager.update_hand_shuffle.rpc_id(id, hand.units, reshuffle_attempts)


func validate_hand() -> void:
    state.hand_ready = true
    hand.update_hand_ui()


func init_battlefield(tile_id: int, unit_type: Unit.EUnitType) -> void:
    tiles.set_unit(tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())

    # Remove the selected unit from the hand
    hand.remove_unit(unit_type)

    # Trigger the state change
    state.battlefield_ready = true


func init_reserve(unit_type: Unit.EUnitType) -> void:
    reserve.add_unit(unit_type)
    hand.remove_unit(unit_type)

    # Trigger the state change
    state.reserve_ready = true


func init_kingdom() -> void:
    kingdom.add_unit(draw_from_deck())


func start_turn() -> void:
    party.current_player = id
    tiles.reset_units_hp()
    hand.add_unit(draw_from_deck())
    state.new_turn()
    GameManager.start_turn.rpc_id(id)


func start_recruit() -> void:
    state.current = StateManager.EState.RECRUIT


func start_attack() -> void:
    state.current = StateManager.EState.ATTACK


func start_support() -> void:
    state.current = StateManager.EState.SUPPORT


func recruit(tile_id: int, unit_type: Unit.EUnitType, source: Board.EUnitSource) -> void:
    tiles.set_unit(tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())
    if source == Board.EUnitSource.RESERVE:
        reserve.remove_unit(unit_type)
    elif source == Board.EUnitSource.HAND:
        hand.remove_unit(unit_type)

    # Flag that we have recruited a unit (possible only once per turn)
    state.recruit_done()


# When attacking, we first notify the enemy so he can counter the attack
func attack(attacking_tile: int, target_tile: int) -> void:
    state.attack(attacking_tile, target_tile)
    state.current = StateManager.EState.WAITING_FOR_PLAYER
    opponent.state.current = StateManager.EState.ATTACK_BLOCK
    GameManager.attack_to_block.rpc_id(opponent.id, attacking_tile, target_tile)


func block_attack(unit: Unit.EUnitType) -> void:
    # The unit used to block is added to the reserve and removed from the hand
    reserve.add_unit(unit)
    hand.remove_unit(unit)
    state.current = StateManager.EState.WAITING_FOR_PLAYER
    # The opponent can now block the attack block if he wants
    opponent.state.current = StateManager.EState.SUPPORT_BLOCK


func block_support(unit: Unit.EUnitType) -> void:
    # The unit used to block is added to the reserve and removed from the hand
    reserve.add_unit(unit)
    hand.remove_unit(unit)
    state.current = StateManager.EState.WAITING_FOR_PLAYER
    # The opponent can now block the support block if he wants (the loop ends when someone does not block)
    opponent.state.current = StateManager.EState.SUPPORT_BLOCK


# The opponent did not block the attack, we can apply the effects.
func no_attack_block() -> void:
    # TODO: apply attack
    opponent.state.attack_done()
    state.current = StateManager.EState.WAITING_FOR_PLAYER
    opponent.state.current = StateManager.EState.ACTION_CHOICE
    pass


# Several cases here :
# - The current player is using a support, the opponent blocked it, and we don't block the block -> cancel the support
# - The current player is using a support, the opponent did not block it -> apply the support or the attack
# - The opponent is using a support to block an attack, we don't block the block -> cancel the attack
func no_support_block() -> void:
    pass


func add_to_kingdom(unit: Unit.EUnitType) -> void:
    kingdom.add_unit(unit)
    hand.remove_unit(unit)
    end_turn()


func prompt_end_turn() -> void:
    state.current = StateManager.EState.FINISH_TURN
    

func end_turn() -> void:
    state.end_turn()
    opponent.start_turn()


func cancel_action() -> void:
    # Go back to the action choice depending on the current state.
    # TODO: check the previous state
    state.current = StateManager.EState.ACTION_CHOICE