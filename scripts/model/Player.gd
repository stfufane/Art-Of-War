class_name Player extends Object

var id: int
var first: bool = false
var opponent: Player = null
var label: String = "P1":
	get:
		return "P1" if first else "P2"

var deck: Array[Unit.EUnitType] = []
var reshuffle_attempts: int = 3

var reserve: Array[Unit.EUnitType] = []
var hand: Array[Unit.EUnitType] = []
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
		hand.append(deck.pop_back())
	hand.append(Unit.EUnitType.King)


func reshuffle_deck() -> void:
	reshuffle_attempts -= 1
	deck.clear()
	hand.clear()
	init_party()
	GameManager.update_hand_shuffle.rpc_id(id, hand, reshuffle_attempts)


func validate_hand() -> void:
	GameManager.update_hand.rpc_id(id, hand)
	state.hand_ready = true


func init_battlefield(data: Dictionary) -> void:
	var tile_id: int = data["tile_id"]
	var unit_type: Unit.EUnitType = data["unit_type"]
	party.battlefield.set_unit(id, tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())

	# Remove the selected unit from the hand and send an update the UI
	hand.erase(unit_type)
	GameManager.update_battlefield.rpc_id(id, Board.ESide.PLAYER, tile_id, unit_type)
	# Update the UI on the opponent's side too
	GameManager.update_battlefield.rpc_id(opponent.id, Board.ESide.ENEMY, tile_id, unit_type)

	# Trigger the state change
	state.battlefield_ready = true


func init_reserve(data: Dictionary) -> void:
	var unit_type: Unit.EUnitType = data["unit_type"]

	reserve.append(unit_type)
	hand.erase(unit_type)

	# Update the UI on both sides.
	GameManager.update_hand.rpc_id(id, hand)
	GameManager.update_reserve.rpc_id(id, Board.ESide.PLAYER, reserve)
	GameManager.update_reserve.rpc_id(opponent.id, Board.ESide.ENEMY, reserve)

	# Trigger the state change
	state.reserve_ready = true


func init_kingdom() -> void:
	var unit_type: Unit.EUnitType = deck.pop_back()
	kingdom.add_unit(unit_type)


func start_turn() -> void:
	party.current_player = id
	party.battlefield.reset_units(id)
	hand.append(deck.pop_back())
	GameManager.update_hand.rpc_id(id, hand)
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
	party.battlefield.set_unit(id, tile_id, GameManager.UNIT_RESOURCES[unit_type].duplicate())


#region Check actions called from [PlayerActions]

func can_start_recruit(_data: Variant) -> bool:
	return true


func can_start_attack(_data: Variant) -> bool:
	return true


func can_start_support(_data: Variant) -> bool:
	return true


func can_recruit(_data: Variant) -> bool:
	return true

#endregion