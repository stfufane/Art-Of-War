extends Node


signal players_ready
signal instruction_updated(instruction: String)


var States: Dictionary = {
	State.Name.WAITING_FOR_PLAYER: State.new(State.Name.WAITING_FOR_PLAYER, "Waiting for opponent", false),
	State.Name.INIT_BATTLEFIELD: State.new(State.Name.INIT_BATTLEFIELD, "Init battlefield", true),
	State.Name.INIT_RESERVE: State.new(State.Name.INIT_RESERVE, "Init reserve", true),
	State.Name.START_TURN: State.new(State.Name.START_TURN, "Start turn", false),
	State.Name.ACTION_CHOICE: State.new(State.Name.ACTION_CHOICE, "Action choice", false),
	State.Name.RECRUIT: State.new(State.Name.RECRUIT, "Recruit", false),
	State.Name.SUPPORT: State.new(State.Name.SUPPORT, "Support", false),
	State.Name.SUPPORT_BLOCK: State.new(State.Name.SUPPORT_BLOCK, "You can block the enemy support by using a wizard or a king", false),
	State.Name.ATTACK: State.new(State.Name.ATTACK, "Attack", false),
	State.Name.ATTACK_BLOCK: State.new(State.Name.ATTACK_BLOCK, "You can block the enemy attack by using a guard or a king", false),
	State.Name.FINISH_TURN: State.new(State.Name.FINISH_TURN, "Finish turn", false),
}


const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")

# Input map constant
const LEFT_CLICK: String = "left_click"

var _current_state: State.Name = State.Name.WAITING_FOR_PLAYER
var previous_state: State.Name = State.Name.WAITING_FOR_PLAYER
var picked_card: Card = null

var _attack_in_progress: bool = false
var _attack_info: Dictionary = {}

var _current_supports: Array[CardType.UnitType] = []
var _pending_support: Card = null

# The local multiplayer server port
const PORT = 1234
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var peer_id: int = 0
var first_player: bool = false


func _ready():
	players_ready.connect(setup)
	States[State.Name.START_TURN].started.connect(func(): start_state(State.Name.ACTION_CHOICE))


func start_server():
	enet_peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	first_player = true
	multiplayer.peer_connected.connect(func(_id: int): players_ready.emit())
	print("Started server with peer id: " + str(peer_id))


func join_server():
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	multiplayer.peer_connected.connect(func(_id: int): players_ready.emit())
	print("Joined server with peer id: " + str(peer_id))


func setup():
	_current_state = State.Name.WAITING_FOR_PLAYER


func create_card_instance(unit_type: CardType.UnitType) -> Card:
	var card_instance = CARD_SCENE.instantiate()
	card_instance.set_unit_type(unit_type)
	return card_instance


func get_state() -> State.Name :
	return _current_state


func start_state(state: State.Name, is_rpc: bool = false):
	previous_state = _current_state
	_current_state = state
	instruction_updated.emit(States[state].instruction)

	# Avoid sending RPCs to the server when the server is the one calling this function.
	if !is_rpc and state != State.Name.WAITING_FOR_PLAYER:
		set_enemy_state.rpc(State.Name.WAITING_FOR_PLAYER)

	States[state].started.emit()


# After attacking, the enemy can play a support card to block the attack.
func enemy_attack_block(attacking_card: Card, enemy_placeholder: CardPlaceholder):
	# First store the info about the attack currently in progress.
	_attack_in_progress = true
	_attack_info = {
		"attacking_card": attacking_card,
		"enemy_placeholder": enemy_placeholder
	}
	start_state(State.Name.WAITING_FOR_PLAYER)
	set_enemy_state.rpc(State.Name.ATTACK_BLOCK)


func enemy_support_block(support_card: Card):
	_pending_support = support_card
	start_state(State.Name.WAITING_FOR_PLAYER)
	set_enemy_state.rpc(State.Name.SUPPORT_BLOCK)


# When a state is finished by the first player, the second player enters the same state.
# When the second player finishes the state, the first player enters the next state.
# In both cases the current player waits.
func end_state():
	if first_player and States[_current_state].happens_once:
		set_enemy_state.rpc(_current_state)
	else:
		set_enemy_state.rpc(States[_current_state].get_next_state())
	start_state(State.Name.WAITING_FOR_PLAYER)

@rpc("any_peer")
func set_enemy_state(state: State.Name):
	start_state(state, true)
