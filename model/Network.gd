extends Node

const BOARD_SCENE: PackedScene = preload("res://screens/board.tscn")

@onready var config: Dictionary = ResourceLoader.load("res://config.tres", "JSON").get_data()
@onready var dev = config.get("dev", true)
@onready var server: String = config.get("server", "localhost")

# The local multiplayer server port
const PORT = 3134
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var clients: Array[int] = []
var parties: Array[Party] = []

func _ready():
	if DisplayServer.get_name() == "headless":
		start_server()


func start_server() -> void:
	print("Starting the server")
	enet_peer.create_server(PORT, 16)
	multiplayer.peer_connected.connect(_on_connection_ok)

	multiplayer.multiplayer_peer = enet_peer
	print("Server id = " + str(multiplayer.get_unique_id()))


@rpc("any_peer", "reliable")
func add_player(peer_id) -> void:
	print(peer_id, " added to the server")
	clients.push_back(peer_id)


@rpc("any_peer")
func create_party() -> void:
	# Only the server can initialize a party
	if not multiplayer.is_server():
		return

	var player = multiplayer.get_remote_sender_id()
	print(str(player) + " wants to create a party")
	var party: Party = Party.new();
	party.id = player
	party.add_player(player)
	parties.push_back(party)


@rpc("any_peer")
func join_party() -> void:
	# Only the server can handle parties
	if not multiplayer.is_server():
		return

	# Cannot join if there are no parties
	if parties.is_empty() or parties.all(func(p: Party): return p.status != Party.Status.CREATED):
		return

	# Find the index of the first available party to join
	var party_to_join: Party
	for party: Party in parties:
		if party.status == Party.Status.CREATED:
			party_to_join = party
			break

	var player = multiplayer.get_remote_sender_id()
	print(str(player) + " wants to join a party")
	party_to_join.add_player(player)

	# Start the game for the two players and declare their respective enemy ids.
	var first_player = party_to_join.players.front()
	print("Starting party for player " + str(first_player))
	start_party.rpc_id(first_player, true, player)
	print("Starting party for player " + str(player))
	start_party.rpc_id(player, false, first_player)


func join_server() -> void:
	print("Trying to connect to server")
	var client_error = enet_peer.create_client(server, PORT)
	multiplayer.peer_connected.connect(_on_connection_ok)
	if client_error:
		# TODO: connection_failed signal
		print("Connection to the server failed : ", client_error)
		return

	multiplayer.multiplayer_peer = enet_peer


func _on_connection_ok(peer_id: int) -> void:
	if multiplayer.is_server():
		# TODO: server_started signal
		print("The server started")
		return

	multiplayer.peer_connected.disconnect(_on_connection_ok)
	Game.peer_id = multiplayer.get_unique_id()
	print(str(Game.peer_id) + " joined the server")
	add_player.rpc_id(1, Game.peer_id) # Tell the server to register the player

@rpc
func start_party(first: bool, enemy_id: int) -> void:
	# The scene ready method will trigger game setup
	get_tree().change_scene_to_packed(BOARD_SCENE)
	Game.first_player = first
	Game.enemy_id = enemy_id
