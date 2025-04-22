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
        deck.append(Unit.EUnitType.Priest)
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
    tiles.set_unit(tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate() as Unit)

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
    # Nothing to do if a player won the game.
    if party.status == Party.EStatus.GAME_WON:
        return
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
    tiles.set_unit(tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate() as Unit)
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


func support_choice(unit_type: Unit.EUnitType) -> void:
    match unit_type:
        Unit.EUnitType.King:
            state.current = StateManager.EState.KING_SUPPORT
            state.king_support = true
        Unit.EUnitType.Archer:
            state.current = StateManager.EState.ARCHER_SUPPORT
        Unit.EUnitType.Priest:
            state.current = StateManager.EState.PRIEST_SUPPORT
        _:
            pass


func soldier_support() -> void:
    trigger_support_block(Unit.EUnitType.Soldier)


func archer_support(target_tile: int) -> void:
    state.archer_target_tile = target_tile
    trigger_support_block(Unit.EUnitType.Archer)


func priest_support(src_unit: Unit.EUnitType, src_tile: int, dest_tile: int) -> void:
    state.priest_action = PlayerState.PriestAction.new(src_unit, src_tile, dest_tile)
    trigger_support_block(Unit.EUnitType.Priest)


func trigger_support_block(support_unit: Unit.EUnitType) -> void:
    state.support_unit = support_unit
    state.current = StateManager.EState.WAITING_FOR_PLAYER
    opponent.state.current = StateManager.EState.SUPPORT_BLOCK
    GameManager.support_to_block.rpc_id(opponent.id, support_unit)


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


# We did not block the attack, the opponent can apply the effects.
func no_attack_block() -> void:
    opponent.apply_attack()


func apply_attack() -> void:
    var damage: int = 0
    var opponent_unit_type := opponent.tiles.get_unit_type(state.target_tile)
    var unit_type := tiles.get_unit_type(state.attacking_tile)
    if unit_type == Unit.EUnitType.Soldier:
        damage = hand.size()
    else:
        damage = tiles.get_attack(state.attacking_tile)
    damage += state.attack_bonus

    var target_state := opponent.tiles.damage_unit(state.target_tile, damage)
    match target_state:
        PlayerTiles.EUnitState.ALIVE:
            GameManager.unit_took_damage.rpc_id(id, Board.ESide.ENEMY, state.target_tile, damage)
            GameManager.unit_took_damage.rpc_id(opponent.id, Board.ESide.PLAYER, state.target_tile, damage)
        PlayerTiles.EUnitState.DEAD, PlayerTiles.EUnitState.CAPTURED:
            # Notify players that a unit died and increase the graveyard
            GameManager.unit_killed_or_captured.rpc_id(id, Board.ESide.ENEMY, state.target_tile)
            GameManager.unit_killed_or_captured.rpc_id(opponent.id, Board.ESide.PLAYER, state.target_tile)
            if target_state == PlayerTiles.EUnitState.CAPTURED:
                kingdom.add_unit(opponent_unit_type)

    state.attack_done()


func apply_support() -> void:
    match state.support_unit:
        Unit.EUnitType.Soldier:
            state.attack_bonus += 1
        Unit.EUnitType.Priest:
            if state.priest_action.src_tile > -1:
                tiles.swap_units(state.priest_action.src_tile, state.priest_action.dest_tile)
            else:
                var replaced_unit := tiles.get_unit_type(state.priest_action.dest_tile)
                # Exchange the units in the reserve
                reserve.remove_unit(state.priest_action.src_unit)
                reserve.add_unit(replaced_unit)
                tiles.set_unit(state.priest_action.dest_tile, GameManager.UNIT_RESOURCES[state.priest_action.src_unit].duplicate() as Unit)
        Unit.EUnitType.Archer:
            var target_state := opponent.tiles.archer_damage_unit(state.archer_target_tile)
            match target_state:
                PlayerTiles.EUnitState.ALIVE:
                    GameManager.unit_took_damage.rpc_id(id, Board.ESide.ENEMY, state.archer_target_tile, 1)
                    GameManager.unit_took_damage.rpc_id(opponent.id, Board.ESide.PLAYER, state.archer_target_tile, 1)
                PlayerTiles.EUnitState.DEAD:
                    # Notify players that a unit died and increase the graveyard
                    GameManager.unit_killed_or_captured.rpc_id(id, Board.ESide.ENEMY, state.archer_target_tile)
                    GameManager.unit_killed_or_captured.rpc_id(opponent.id, Board.ESide.PLAYER, state.archer_target_tile)
                _:
                    # You can't capture when using an archer to inflict damage to a unit
                    pass
        _:
            pass
    
    state.support_done()


# Several cases here :
# - The current player is using a support, the opponent blocked it, and we don't block the block -> cancel the support
# - The current player is using a support, the opponent did not block it -> apply the support or the attack
# - The opponent is using a support to block an attack, we don't block the block -> cancel the attack
func no_support_block() -> void:
    # The current player is not blocking the support block
    if party.current_player == id:
        if state.is_attacking:
            # The current player did not block the support, the attack is done without any effect.
            state.attack_done()
        else:
            # Cancel the support
            state.support_done()

    # The opponent is not blocking the support block
    else:
        if opponent.state.is_attacking:
            opponent.apply_attack() # Apply the opponent's attack
        else:
            opponent.apply_support() # Apply the opponent's support


func add_to_kingdom(unit: Unit.EUnitType) -> void:
    hand.remove_unit(unit)
    kingdom.add_unit(unit)
    end_turn()


func prompt_end_turn() -> void:
    state.current = StateManager.EState.FINISH_TURN


func end_turn() -> void:
    state.end_turn()
    opponent.start_turn()


func cancel_action() -> void:
    # Go back to the action choice depending on the current state.
    state.current = StateManager.EState.ACTION_CHOICE
