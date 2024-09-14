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


func check_reshuffle() -> bool:
    return state.current == StateManager.EState.RESHUFFLE and reshuffle_attempts > 0


func reshuffle_deck() -> void:
    reshuffle_attempts -= 1
    deck.clear()
    hand.clear()
    init_party()
    GameManager.update_hand_shuffle.rpc_id(id, hand.units, reshuffle_attempts)


func check_validate_hand() -> bool:
    return state.current == StateManager.EState.RESHUFFLE and not state.hand_ready


func validate_hand() -> void:
    state.hand_ready = true
    hand.update_hand_ui()


func check_init_battlefield(tile_id: int, _unit_type: Unit.EUnitType) -> bool:
    return state.current == StateManager.EState.INIT_BATTLEFIELD \
    and not state.battlefield_ready \
    and tiles.can_set_unit(tile_id)


func init_battlefield(tile_id: int, unit_type: Unit.EUnitType) -> void:
    tiles.set_unit(tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())

    # Remove the selected unit from the hand
    hand.remove_unit(unit_type)

    # Trigger the state change
    state.battlefield_ready = true


func check_init_reserve(unit_type: Unit.EUnitType) -> bool:
    return state.current == StateManager.EState.INIT_RESERVE \
    and not state.reserve_ready \
    and hand.units.has(unit_type)


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


func check_start_recruit() -> bool:
    return party.current_player == id and \
        state.current == StateManager.EState.ACTION_CHOICE and \
        not state.has_recruited and \
        not state.has_attacked


func start_recruit() -> void:
    state.current = StateManager.EState.RECRUIT


func check_start_attack() -> bool:
    return party.current_player == id and \
        state.current == StateManager.EState.ACTION_CHOICE and \
        not state.has_recruited


func start_attack() -> void:
    state.current = StateManager.EState.ATTACK


func check_start_support() -> bool:
    return party.current_player == id and \
        state.current == StateManager.EState.ACTION_CHOICE and \
        not state.has_recruited


func start_support() -> void:
    state.current = StateManager.EState.SUPPORT


func check_recruit(tile_id: int, unit_type: Unit.EUnitType, source: Board.EUnitSource) -> bool:
    return party.current_player == id and \
        state.current == StateManager.EState.RECRUIT and \
        ((source == Board.EUnitSource.RESERVE and reserve.has(unit_type)) \
        or (source == Board.EUnitSource.HAND and hand.has(unit_type))) and \
        tiles.can_set_unit(tile_id) and \
        (source == Board.EUnitSource.RESERVE or \
        (source == Board.EUnitSource.HAND and reserve.is_empty()))


func recruit(tile_id: int, unit_type: Unit.EUnitType, source: Board.EUnitSource) -> void:
    tiles.set_unit(tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())
    if source == Board.EUnitSource.RESERVE:
        reserve.remove_unit(unit_type)
    elif source == Board.EUnitSource.HAND:
        hand.remove_unit(unit_type)

    # Flag that we have recruited a unit (possible only once per turn)
    state.recruit_done()


func check_add_to_kingdom(unit: Unit.EUnitType) -> bool:
    return party.current_player == id and \
        state.current == StateManager.EState.FINISH_TURN and \
        hand.has(unit) and unit != Unit.EUnitType.King


func add_to_kingdom(unit: Unit.EUnitType) -> void:
    kingdom.add_unit(unit)
    hand.remove_unit(unit)
    end_turn()


func prompt_end_turn() -> void:
    state.current = StateManager.EState.FINISH_TURN


func end_turn() -> void:
    state.end_turn()
    opponent.start_turn()