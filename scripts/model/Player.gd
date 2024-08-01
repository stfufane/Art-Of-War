class_name Player extends Object

var id: int
var first: bool = false
var opponent: Player = null
var label: String:
	get:
		return "P1" if first else "P2"

var deck: Array[Unit.EUnitType] = []
var reshuffle_attempts: int = 3

var reserve := PlayerReserve.new(self)
var hand := PlayerHand.new(self)
var kingdom := PlayerKingdom.new(self)

var dead_units: int = 0
var party: Party = null

var state: PlayerState = null


func _init(player_id: int) -> void:
	id = player_id
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
		hand.add_unit(deck.pop_back())
	hand.add_unit(Unit.EUnitType.King)


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
		and party.battlefield.can_set_unit(id, tile_id)


func init_battlefield(tile_id: int, unit_type: Unit.EUnitType) -> void:
	party.battlefield.set_unit(self, tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())

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
	var unit_type: Unit.EUnitType = deck.pop_back()
	kingdom.add_unit(unit_type)


func start_turn() -> void:
	party.current_player = id
	party.battlefield.reset_units(id)
	hand.add_unit(deck.pop_back())
	state.new_turn()


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


func check_recruit(tile_id: int, _unit_type: Unit.EUnitType, source: Board.EUnitSource) -> bool:
	return party.current_player == id and \
		state.current == StateManager.EState.RECRUIT and \
		party.battlefield.can_set_unit(id, tile_id) and \
	 	(source == Board.EUnitSource.RESERVE or \
		(source == Board.EUnitSource.HAND and reserve.is_empty()))


func recruit(tile_id: int, unit_type: Unit.EUnitType, source: Board.EUnitSource) -> void:
	party.battlefield.set_unit(self, tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())
	if source == Board.EUnitSource.RESERVE:
		reserve.remove_unit(unit_type)
	elif source == Board.EUnitSource.HAND:
		hand.remove_unit(unit_type)
	
	# Flag that we have recruited a unit (possible only once per turn)
	state.recruit_done()
