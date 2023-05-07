extends Node

var CardTypes = {
	CardType.UnitType.King: CardType.new(CardType.UnitType.King, "King", 1, 5, 4, [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]),
	CardType.UnitType.Soldier: CardType.new(CardType.UnitType.Soldier, "Soldier", INF, 2, 1, [Vector2(0, 1)]),
	CardType.UnitType.Archer: CardType.new(CardType.UnitType.Archer, "Archer", 1, 2, 1, [Vector2(-2, 1), Vector2(2, 1), Vector2(-1, 2), Vector2(1, 2)]),
	CardType.UnitType.Guard: CardType.new(CardType.UnitType.Guard, "Guard", 1, 3, 2, [Vector2(0, 1)]),
	CardType.UnitType.Wizard: CardType.new(CardType.UnitType.Wizard, "Wizard", 1, 2, 1, [Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)]),
	CardType.UnitType.Monk: CardType.new(CardType.UnitType.Monk, "Monk", 1, 2, 2, [Vector2(-1, 1), Vector2(1, 1), Vector2(-2, 2), Vector2(2, 2)])
}

# Initialize the player and enemy kingdoms
var player_kingdom: Dictionary = {
	CardType.UnitType.Soldier: 0,
	CardType.UnitType.Archer: 0,
	CardType.UnitType.Guard: 0,
	CardType.UnitType.Wizard: 0,
	CardType.UnitType.Monk: 0
}

var enemy_kingdom: Dictionary = {
	CardType.UnitType.Soldier: 0,
	CardType.UnitType.Archer: 0,
	CardType.UnitType.Guard: 0,
	CardType.UnitType.Wizard: 0,
	CardType.UnitType.Monk: 0
}

enum State {
	WAITING_FOR_PLAYER,
	INIT_BATTLEFIELD,
	INIT_RESERVE,
	ACTION_CHOICE,
	RECRUIT,
	SUPPORT,
	ATTACK,
	FINISH_TURN,
}

const INSTRUCTIONS: Dictionary = {
	State.WAITING_FOR_PLAYER: "Enemy is playing.",
	State.INIT_BATTLEFIELD: "Place a unit on the battlefield.",
	State.INIT_RESERVE: "Place a unit in your reserve.",
	State.ACTION_CHOICE: "Choose an action.",
	State.RECRUIT: "Recruit a unit.",
	State.SUPPORT: "Use a unit as support.",
	State.ATTACK: "Attack an enemy unit.",
	State.FINISH_TURN: "Add a unit to your kingdom.",
}

var state_init_methods: Dictionary = {}

var card_scene = preload("res://scenes/card.tscn")

var current_state = State.WAITING_FOR_PLAYER
var player_hand: Array[Card] = []
var picked_card: Card = null

var player_reserve: Array[Card] = []
var enemy_reserve:  Array[Card] = []

var player_deck: Array[CardType.UnitType] = []

# A reference to the board scene to be able to call some of the methods on it.
var board: Board = null

# The local multiplayer server port
const PORT = 1234
var enet_peer = ENetMultiplayerPeer.new()

var peer_id: int = 0
var first_player: bool = false

func start_server():
	enet_peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	first_player = true
	print("Started server with peer id: " + str(peer_id))

func join_server():
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	peer_id = multiplayer.get_unique_id()
	print("Joined server with peer id: " + str(peer_id))

func setup(scene_board: Board):
	current_state = State.WAITING_FOR_PLAYER
	board = scene_board
	state_init_methods = {
		State.WAITING_FOR_PLAYER: null,
		State.INIT_BATTLEFIELD: board.init_battlefield,
		State.INIT_RESERVE: board.init_reserve,
		State.ACTION_CHOICE: null,
		State.RECRUIT: null,
		State.SUPPORT: null,
		State.ATTACK: null,
		State.FINISH_TURN: null,
	}

	# First build the deck with 4 of each card.
	for _i in range(4):
		player_deck.append(CardType.UnitType.Soldier)
		player_deck.append(CardType.UnitType.Archer)
		player_deck.append(CardType.UnitType.Guard)
		player_deck.append(CardType.UnitType.Wizard)
		player_deck.append(CardType.UnitType.Monk)
	player_deck.shuffle()

	# Then draw the hand. It has the king by default + 3 cards.
	player_hand.append(get_card_instance(CardType.UnitType.King))
	for _i in range(3):
		player_hand.append(get_card_instance(player_deck.pop_back()))

func draw_card():
	if player_deck.size() > 0:
		player_hand.append(get_card_instance(player_deck.pop_back()))

func get_card_instance(card_type: CardType.UnitType) -> Card:
	var card_instance = card_scene.instantiate()
	card_instance.set_unit_type(card_type)
	return card_instance

func get_next_state() -> State:
	match current_state:
		State.INIT_BATTLEFIELD:
			return State.INIT_RESERVE
		State.INIT_RESERVE:
			return State.ACTION_CHOICE
		# TODO Manage the multiple possible states during a player's turn.
		State.FINISH_TURN:
			return State.ACTION_CHOICE
		_:
			return State.WAITING_FOR_PLAYER

func start_state(state: State, is_rpc: bool = false):
	current_state = state
	board.instruction.text = INSTRUCTIONS[state]

	# Avoid sending RPCs to the server when the server is the one calling this function.
	if not is_rpc:
		set_enemy_state.rpc(State.WAITING_FOR_PLAYER)

	var callback = state_init_methods[state]
	if callback != null:
		callback.call()

# When a state is finished by the first player, the second player enters the same state.
# When the second player finishes the state, the first player enters the next state.
# In both cases the current player waits.
func end_state():
	if first_player:
		set_enemy_state.rpc(current_state)
	else:
		set_enemy_state.rpc(get_next_state())
	current_state = State.WAITING_FOR_PLAYER
	board.instruction.text = INSTRUCTIONS[current_state]

@rpc("any_peer")
func set_enemy_state(state: State):
	start_state(state, true)
