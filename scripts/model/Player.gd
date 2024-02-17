class_name Player extends Object

var id: int
var first: bool = false

var battlefield_initialized: bool = false
var reserve_initialized: bool = false
var has_won: bool = false

var deck: Array[Unit.EUnitType] = []
var reshuffle_attempts: int = 3

var reserve: Array[Unit.EUnitType] = []
var hand: Array[Unit.EUnitType] = []

## Store the kingdom in raw number of units
var kingdom: Dictionary = {
	Unit.EUnitType.Soldier: 0,
	Unit.EUnitType.Guard: 0,
	Unit.EUnitType.Wizard: 0,
	Unit.EUnitType.Monk: 0,
	Unit.EUnitType.Archer: 0
}

## And also relative to the other player
var kingdom_status: Dictionary = {
	Unit.EUnitType.Soldier: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Guard: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Wizard: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Monk: KingdomUnit.EStatus.Equal,
	Unit.EUnitType.Archer: KingdomUnit.EStatus.Equal
}

var battlefield: Dictionary = {}

var dead_units: int = 0
var party: Party = null

## Every time the state is updated by the server, the client is notified via an RPC call
var current_state: StateManager.EState = StateManager.EState.WAITING_FOR_PLAYER :
	set(state):
		current_state = state
		print("Player %d state is now %s" % [id, StateManager.EState.keys()[current_state]])
		StateManager.set_state.rpc_id(id, state)


func _init(player_id: int) -> void:
	id = player_id


static func register_actions() -> void:
	var reshuffle_action := Action.new()\
		.with_check(func(player: Player) -> bool:
			return player.current_state == StateManager.EState.RESHUFFLE)\
		.with_action(func(player: Player, _data: Variant) -> void:
			player.reshuffle_deck())
	
	var validate_hand_action := Action.new()\
		.with_check(func(player: Player) -> bool:
			return player.current_state == StateManager.EState.RESHUFFLE)\
		.with_action(func(player: Player, _data: Variant) -> void:
			player.validate_hand())
	
	var set_battlefield_unit_action := Action.new()\
		.with_check(func(player: Player) -> bool:
			return player.current_state == StateManager.EState.INIT_BATTLEFIELD)\
		.with_action(func(player: Player, data: Variant) -> void:
			player.init_battlefield(data))
	
	GameServer.register_action(Action.Code.RESHUFFLE_HAND, reshuffle_action)
	GameServer.register_action(Action.Code.VALIDATE_HAND, validate_hand_action)
	GameServer.register_action(Action.Code.SET_BATTLEFIELD_UNIT, set_battlefield_unit_action)


func init_party() -> void:
	for _i in range(4):
		deck.append(Unit.EUnitType.Soldier)
		deck.append(Unit.EUnitType.Archer)
		deck.append(Unit.EUnitType.Guard)
		deck.append(Unit.EUnitType.Wizard)
		deck.append(Unit.EUnitType.Monk)
	deck.shuffle()
	
	for _i in range(3):
		hand.append(deck.pop_back())
	hand.append(Unit.EUnitType.King)


func reshuffle_deck() -> void:
	if reshuffle_attempts == 0:
		return
	
	print("Reshuffle hand for player ", id)
	reshuffle_attempts -= 1
	deck.clear()
	hand.clear()
	init_party()
	GameManager.update_hand_shuffle.rpc_id(id, hand, reshuffle_attempts)


func validate_hand() -> void:
	GameManager.update_hand.rpc_id(id, hand)
	
	# The player has validated his hand, we can init the kingdom
	# TODO move after init reserve
	init_kingdom()
	
	print("Validate hand for player ", id)
	if first:
		current_state = StateManager.EState.INIT_BATTLEFIELD
	else:
		if party.first_player.current_state == StateManager.EState.INIT_BATTLEFIELD:
			current_state = StateManager.EState.WAITING_FOR_PLAYER
		else:
			current_state = StateManager.EState.INIT_BATTLEFIELD


func init_kingdom() -> void:
	var unit_type: Unit.EUnitType = deck.pop_back()
	kingdom[unit_type] = 1
	party.update_kingdom_status()


func init_battlefield(data: Dictionary) -> void:
	if battlefield_initialized:
		return
	var tile_id: int = data["tile_id"]
	var unit_type: Unit.EUnitType = data["unit_type"]
	battlefield[tile_id] = GameManager.UNIT_RESOURCES[unit_type].duplicate()
	battlefield_initialized = true
	
	# Remove the selected unit from the hand
	hand.erase(unit_type)
	
	GameManager.update_battlefield.rpc_id(id, tile_id, unit_type)
	if first:
		GameManager.update_enemy_battlefield.rpc_id(party.second_player.id, tile_id, unit_type)
		current_state = StateManager.EState.INIT_RESERVE
		if party.second_player.current_state == StateManager.EState.WAITING_FOR_PLAYER:
			party.second_player.current_state = StateManager.EState.INIT_BATTLEFIELD
	else:
		GameManager.update_enemy_battlefield.rpc_id(party.first_player.id, tile_id, unit_type)
		current_state = StateManager.EState.WAITING_FOR_PLAYER


func init_reserve(unit_type: Unit.EUnitType) -> void:
	if reserve_initialized:
		return
	
	reserve.append(unit_type)
	reserve_initialized = true
	hand.erase(unit_type)
