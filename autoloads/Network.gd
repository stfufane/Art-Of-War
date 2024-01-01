extends Node

signal connection_success
signal connection_failed

signal party_created(id: String)
signal no_party_found
signal party_cancelled

const BOARD_SCENE: PackedScene = preload("res://screens/board.tscn")

@onready var config: Dictionary = ResourceLoader.load("res://config.tres", "JSON").get_data()
@onready var dev = config.get("dev", true)
@onready var server: String = config.get("server", "localhost")

# The local multiplayer server port
const PORT = 3134
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

# Stored by the server
var clients: Array[int] = []
var parties: Array[Party] = []

# Stored by the client
var party_id: String = ""

func _ready():
	if DisplayServer.get_name() == "headless":
		start_server()

	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.connection_failed.connect(_on_connection_failed)


func start_server() -> void:
	print("Starting the server")
	var server_error = enet_peer.create_server(PORT, 16)
	if server_error:
		print("Failed to create server", server_error);
		return

	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_on_peer_connected)


func _on_peer_connected(peer_id: int) -> void:
	print(str(peer_id) + " joined the server")
	if peer_id > 1:
		add_player(peer_id)


func join_server() -> void:
	print("Trying to connect to server")
	var client_error = enet_peer.create_client(server, PORT)
	# Small trick to detect that we actually connected to the server and catch the error otherwise.
	enet_peer.get_peer(1).set_timeout(0, 0, 5000)
	if client_error:
		print("Connection to the server failed : ", client_error)
		connection_failed.emit()
		enet_peer.close();
		return
	multiplayer.multiplayer_peer = enet_peer


func _on_connection_success() -> void:
	print("Connected to server")
	connection_success.emit()
	Game.peer_id = multiplayer.get_unique_id()


func _on_connection_failed() -> void:
	print("Connection failed")
	connection_failed.emit()
	enet_peer.close();


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
	party.add_player(player)
	parties.push_back(party)
	print("Created party: ", party.id)
	notify_party_created.rpc_id(player, party.id)


@rpc
func notify_party_created(id: String) -> void:
	party_id = id
	party_created.emit(party_id)


@rpc("any_peer")
func join_party(id: String) -> void:
	# Only the server can handle parties
	if not multiplayer.is_server():
		return

	var player = multiplayer.get_remote_sender_id()
	print(str(player) + " wants to join party " + id)

	# Find the index of the first available party to join
	var party_to_join: Party = null
	for party: Party in parties:
		if party.status == Party.Status.CREATED and party.id == id:
			party_to_join = party
			break

	if party_to_join == null:
		party_not_found.rpc_id(player)
		return

	print(str(player) + " is joining party " + id)
	party_to_join.add_player(player)

	# Start the game for the two players and declare their respective enemy ids.
	var first_player = party_to_join.players.front()
	print("Starting party for player " + str(first_player))
	start_party.rpc_id(first_player, true, player)
	print("Starting party for player " + str(player))
	start_party.rpc_id(player, false, first_player)


@rpc
func party_not_found():
	no_party_found.emit()


func cancel_party() -> void:
	print("cancel party", party_id)
	remove_party.rpc_id(1, party_id)
	party_id = ""
	party_cancelled.emit()


@rpc("any_peer")
func remove_party(id: String) -> void:
	print("remove_party")
	print(parties)
	var party_to_remove: Party = null
	for party: Party in parties:
		if party.id == id:
			party_to_remove = party
			break

	if party_to_remove != null:
		parties.erase(party_to_remove)

	print("party removed")
	print(parties)


@rpc
func start_party(first: bool, enemy_id: int) -> void:
	# The scene ready method will trigger game setup
	get_tree().change_scene_to_packed(BOARD_SCENE)
	Game.first_player = first
	Game.enemy_id = enemy_id
