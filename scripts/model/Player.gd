class_name Player extends Object

var id: int
var first: bool = false

var hand_ready: bool = false :
	set(ready):
		hand_ready = ready
		if ready:
			current_state = StateManager.EState.INIT_BATTLEFIELD


var battlefield_ready: bool = false :
	set(ready):
		battlefield_ready = ready
		if ready:
			current_state = StateManager.EState.INIT_RESERVE


var reserve_ready: bool = false :
	set(ready):
		reserve_ready = ready
		if ready:
			if first:
				# If the first player is the first to finish, wait for the second player to finish
				# Otherwise, start the turn
				if party.second_player.reserve_ready:
					current_state = StateManager.EState.START_TURN
					party.init_kingdoms()
				else:
					current_state = StateManager.EState.WAITING_FOR_PLAYER
			else:
				# Second player always waits, and he finished second, first player can start his turn.
				current_state = StateManager.EState.WAITING_FOR_PLAYER
				if party.first_player.reserve_ready:
					party.first_player.current_state = StateManager.EState.START_TURN
					party.init_kingdoms()


## Every time the state is updated by the server, the client is notified via an RPC call
var current_state: StateManager.EState = StateManager.EState.WAITING_FOR_PLAYER :
	set(state):
		current_state = state
		print("Player %d (%s) state is now %s" % [id, "first" if first else "second", StateManager.EState.keys()[current_state]])
		StateManager.set_state.rpc_id(id, state)


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
	
	var init_reserve_action := Action.new()\
		.with_check(func(player: Player) -> bool:
			return player.current_state == StateManager.EState.INIT_RESERVE)\
		.with_action(func(player: Player, data: Variant) -> void:
			player.init_reserve(data))
	
	GameServer.register_action(Action.Code.RESHUFFLE_HAND, reshuffle_action)
	GameServer.register_action(Action.Code.VALIDATE_HAND, validate_hand_action)
	GameServer.register_action(Action.Code.SET_BATTLEFIELD_UNIT, set_battlefield_unit_action)
	GameServer.register_action(Action.Code.ADD_RESERVE_UNIT, init_reserve_action)


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
	print("Validate hand for player ", id)
	hand_ready = true


func init_battlefield(data: Dictionary) -> void:
	if battlefield_ready:
		return
	
	var tile_id: int = data["tile_id"]
	var unit_type: Unit.EUnitType = data["unit_type"]
	battlefield[tile_id] = GameManager.UNIT_RESOURCES[unit_type].duplicate()

	# Remove the selected unit from the hand and send an update the UI
	hand.erase(unit_type)	
	GameManager.update_battlefield.rpc_id(id, tile_id, unit_type)
	
	# Notify the opponent's UI as well
	if first:
		GameManager.update_enemy_battlefield.rpc_id(party.second_player.id, tile_id, unit_type)
	else:
		GameManager.update_enemy_battlefield.rpc_id(party.first_player.id, tile_id, unit_type)
	
	# Trigger the state change
	battlefield_ready = true


func init_reserve(data: Dictionary) -> void:
	if reserve_ready:
		return
	
	var unit_type: Unit.EUnitType = data["unit_type"]
	
	reserve.append(unit_type)
	hand.erase(unit_type)

	GameManager.update_hand.rpc_id(id, hand)
	GameManager.update_reserve.rpc_id(id, reserve)

	if first:
		GameManager.update_enemy_reserve.rpc_id(party.second_player.id, reserve)
	else:
		GameManager.update_enemy_reserve.rpc_id(party.first_player.id, reserve)

	reserve_ready = true


func init_kingdom() -> void:
	var unit_type: Unit.EUnitType = deck.pop_back()
	kingdom[unit_type] = 1
	party.update_kingdom_status()
