extends Node


signal players_ready
signal instruction_updated(instruction: String)
signal hand_size_updated(size: int)
signal is_attack_available(bool)
signal no_support_played
signal attack_validated
signal card_killed(card: Card)


# When a card is clicked, it will emit a signal depending on where it lies on the board.
signal hand_card_clicked(card: Card)
signal battlefield_card_clicked(card: Card)
signal enemy_battlefield_card_clicked(card: Card)
signal reserve_card_clicked(card: Card)


var States: Dictionary = {
	State.Name.WAITING_FOR_PLAYER: State.new(State.Name.WAITING_FOR_PLAYER, "Waiting for opponent", false),
	State.Name.INIT_BATTLEFIELD: State.new(State.Name.INIT_BATTLEFIELD, "Init battlefield", true),
	State.Name.INIT_RESERVE: State.new(State.Name.INIT_RESERVE, "Init reserve", true),
	State.Name.START_TURN: State.new(State.Name.START_TURN, "Start turn", false),
	State.Name.ACTION_CHOICE: State.new(State.Name.ACTION_CHOICE, "Action choice", false),
	State.Name.RECRUIT: State.new(State.Name.RECRUIT, "Recruit a unit", false),
	State.Name.SUPPORT: State.new(State.Name.SUPPORT, "Play a support by adding it to your reserve", false),
	State.Name.SUPPORT_BLOCK: State.new(State.Name.SUPPORT_BLOCK, "You can block the enemy support by using a wizard or a king", false),
	State.Name.ATTACK: State.new(State.Name.ATTACK, "Attack a unit on the enemy battlefield", false),
	State.Name.ATTACK_BLOCK: State.new(State.Name.ATTACK_BLOCK, "You can block the enemy attack by using a guard or a king", false),
	State.Name.FINISH_TURN: State.new(State.Name.FINISH_TURN, "Finish turn", false),
}


const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")

# Input map constant
const LEFT_CLICK: String = "left_click"

var _current_state: State.Name = State.Name.WAITING_FOR_PLAYER
var previous_state: State.Name = State.Name.WAITING_FOR_PLAYER
var picked_card: Card = null

var _attack_info: Dictionary = {}

var _current_supports: Array[CardType.UnitType] = []
var _pending_support: Card = null

# The local multiplayer server port
const PORT = 1234
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var peer_id: int = 0
var first_player: bool = false

# Useful when having having a support loop to know who is actually playing.
var _my_turn: bool = false


func start_server() -> void:
	enet_peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	first_player = true
	multiplayer.peer_connected.connect(setup)


func join_server() -> void:
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	multiplayer.peer_connected.connect(setup)


func setup(_player_id: int) -> void:
	players_ready.emit()
	if first_player:
		start_state(State.Name.INIT_BATTLEFIELD)
	else:
		instruction_updated.emit("Waiting for the other player")

	# When the turn starts, pass _my_turn to true and pass it to false for the enemy.
	States[State.Name.START_TURN].started.connect(start_turn)


func create_card_instance(unit_type: CardType.UnitType) -> Card:
	var card_instance = CARD_SCENE.instantiate()
	card_instance.set_unit_type(unit_type)
	return card_instance


func start_turn() -> void:
	_my_turn = true
	set_enemy_turn.rpc()


func start_state(state: State.Name) -> void:
	previous_state = _current_state
	_current_state = state
	instruction_updated.emit(States[state].instruction)

	States[previous_state].ended.emit()

	# Avoid sending RPCs to the server when the server is the one calling this function.
	if state != State.Name.WAITING_FOR_PLAYER:
		set_enemy_state.rpc(State.Name.WAITING_FOR_PLAYER)

	States[state].started.emit()


# When a state is finished by the first player, the second player enters the same state.
# When the second player finishes the state, the first player enters the next state.
# In both cases the current player waits.
func end_state() -> void:
	if first_player and States[_current_state].happens_once:
		set_enemy_state.rpc(_current_state)
	else:
		set_enemy_state.rpc(States[_current_state].get_next_state())


# After attacking, the enemy can play a support card to block the attack.
func enemy_attack_block(attacking_card: Card, enemy_placeholder: CardPlaceholder) -> void:
	# First store the info about the attack currently in progress.
	_attack_info = {
		"attacking_card": attacking_card,
		"enemy_placeholder": enemy_placeholder
	}
	set_enemy_state.rpc(State.Name.ATTACK_BLOCK)


func process_attack_block(attack_blocked: bool, is_rpc: bool = true) -> void:
	# If attack was blocked, we can block the support with an other support until it's not possible to block anymore
	if attack_blocked:
		start_state(State.Name.ATTACK_BLOCK)
		return

	# Otherwise we apply the attack that was in progress
	if _my_turn:
		if is_rpc:
			attack_validated.emit()
		else:
			print("Attack was cancelled")
	
	# We can then choose an other action.
	start_state(State.Name.ACTION_CHOICE)


func process_support_block(support_blocked: bool, is_rpc: bool = true) -> void:
	if support_blocked:
		# If support was blocked, we can block it with an other support until it's not possible to block anymore
		start_state(State.Name.SUPPORT_BLOCK)
		return
	
	# Otherwise we apply the support effect if the enemy passed (if the call is non-rpc, it means the player passed)
	if _my_turn:
		if is_rpc:
			_current_supports.append(_pending_support._unit_type)
			# TODO: process support effect
		else:
			print("Support was cancelled")
		# Whoever passed, we can choose an other action
		start_state(State.Name.ACTION_CHOICE)


func enemy_support_block(support_card: Card) -> void:
	_pending_support = support_card
	set_enemy_state.rpc(State.Name.SUPPORT_BLOCK)


#################################################################################
# Getters
#################################################################################

func get_state() -> State.Name :
	return _current_state


func get_attack_info() -> Dictionary:
	return _attack_info

#################################################################################
# Network actions that are called to reflect local actions on the enemy board  ##
#################################################################################

@rpc("any_peer")
func set_enemy_state(state: State.Name) -> void:
	start_state(state)


@rpc("any_peer")
func set_enemy_turn() -> void:
	_my_turn = false
