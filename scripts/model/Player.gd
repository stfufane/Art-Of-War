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

func reshuffle_deck() -> void:
	reshuffle_attempts -= 1
	deck.clear()
	hand.clear()
	init_party()
	GameManager.update_hand_shuffle.rpc_id(id, hand, reshuffle_attempts)


func validate_hand() -> void:
	state.hand_ready = true
	hand.update_hand_ui()


func init_battlefield(data: Dictionary) -> void:
	var tile_id: int = data["tile_id"]
	var unit_type: Unit.EUnitType = data["unit_type"]
	party.battlefield.set_unit(self, tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())

	# Remove the selected unit from the hand
	hand.remove_unit(unit_type)

	# Trigger the state change
	state.battlefield_ready = true


func init_reserve(data: Dictionary) -> void:
	var unit_type: Unit.EUnitType = data["unit_type"]

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


func start_recruit() -> void:
	state.current = StateManager.EState.RECRUIT


func start_attack() -> void:
	state.current = StateManager.EState.ATTACK


func start_support() -> void:
	state.current = StateManager.EState.SUPPORT


func recruit(data: Dictionary) -> void:
	var tile_id: int = data["tile_id"]
	var unit_type: Unit.EUnitType = data["unit_type"]
	var source: Board.EUnitSource = data["source"]

	party.battlefield.set_unit(self, tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())
	if source == Board.EUnitSource.RESERVE:
		reserve.remove_unit(unit_type)
	elif source == Board.EUnitSource.HAND:
		hand.remove_unit(unit_type)
	
	# Flag that we have recruited a unit (possible only once per turn)
	state.recruit_done()


#region Check actions called from [PlayerActions]

func can_start_recruit(_data: Variant) -> bool:
	return state.current == StateManager.EState.ACTION_CHOICE and \
		not state.has_recruited and \
		not state.has_attacked


func can_start_attack(_data: Variant) -> bool:
	return state.current == StateManager.EState.ACTION_CHOICE and \
		not state.has_recruited


func can_start_support(_data: Variant) -> bool:
	return state.current == StateManager.EState.ACTION_CHOICE and \
		not state.has_recruited


## Check if the player can recruit a unit
func can_recruit(data: Variant) -> bool:
	return state.current == StateManager.EState.RECRUIT and \
	 	(data["source"] == Board.EUnitSource.RESERVE or \
		(data["source"] == Board.EUnitSource.HAND and reserve.is_empty()))

#endregion