class_name Player extends Object

var id: int
var first: bool = false
var label: String = "P1" :
	get: 
		return "P1" if first else "P2"

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
	if reshuffle_attempts == 0:
		return
	
	reshuffle_attempts -= 1
	deck.clear()
	hand.clear()
	init_party()
	GameManager.update_hand_shuffle.rpc_id(id, hand, reshuffle_attempts)


func validate_hand() -> void:
	GameManager.update_hand.rpc_id(id, hand)
	state.hand_ready = true


func init_battlefield(data: Dictionary) -> void:
	if state.battlefield_ready:
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
	state.battlefield_ready = true


func init_reserve(data: Dictionary) -> void:
	if state.reserve_ready:
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

	state.reserve_ready = true


func init_kingdom() -> void:
	var unit_type: Unit.EUnitType = deck.pop_back()
	kingdom[unit_type] = 1
	party.update_kingdom_status()
