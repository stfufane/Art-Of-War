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

enum States {
	WAITING_FOR_PLAYER,
	INIT_BATTLEFIELD,
	INIT_RESERVE,
	PLAYER_ACTION_CHOICE,
	PLAYER_RECRUIT,
	PLAYER_SUPPORT,
	PLAYER_ATTACK,
	PLAYER_ADD_TO_KINGDOM,
	ENEMY_TURN,
	ENEMY_SUPPORT,
	ENEMY_ATTACK,
}

var card_scene = preload("res://scenes/card.tscn")

var current_state = States.WAITING_FOR_PLAYER
var player_hand: Array[Card] = []
var card_in_hand: Card = null

var player_reserve: Array[Card] = []
var enemy_reserve:  Array[Card] = []

var player_deck: Array[CardType.UnitType] = []

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

func setup():
	current_state = States.INIT_BATTLEFIELD
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
