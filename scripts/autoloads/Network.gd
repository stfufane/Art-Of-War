extends Node

signal connection_success
signal connection_failed


@onready var config: Dictionary = ResourceLoader.load("res://config.tres", "JSON").get_data()
@onready var dev: bool = config.get("dev", true)
@onready var server: String = config.get("server", "localhost")

var connected: bool = false

# The local multiplayer server port
const PORT := 3134
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()


func _ready() -> void:
    if DisplayServer.get_name() == "headless":
        start_server()
    else:
        join_server()


######################
### SERVER METHODS ###

func start_server() -> void:
    print("Starting the server")
    var server_error := enet_peer.create_server(PORT, 16)
    if server_error:
        prints("Failed to create server", server_error);
        return

    connected = true
    ActionsManager.register_actions()
    multiplayer.multiplayer_peer = enet_peer
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func stop_server() -> void:
    print("Stopping the server")
    connected = false
    multiplayer.peer_connected.disconnect(_on_peer_connected)
    multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
    enet_peer.close()


func _on_peer_connected(peer_id: int) -> void:
    print(peer_id, " joined the server")
    if peer_id > 1:
        GameServer.add_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
    print(peer_id, " left the server")
    if peer_id > 1:
        GameServer.remove_player(peer_id)


######################
### CLIENT METHODS ###

func join_server() -> void:
    multiplayer.connected_to_server.connect(_on_connection_success)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    print("Trying to connect to server")
    var client_error := enet_peer.create_client(server, PORT)
    # Small trick to detect that we actually connected to the server and catch the error otherwise.
    enet_peer.get_peer(1).set_timeout(0, 0, 5000)
    if client_error:
        print("Connection to the server failed : ", client_error)
        connection_failed.emit()
        enet_peer.close();
        return
    multiplayer.multiplayer_peer = enet_peer


func _on_connection_success() -> void:
    connected = true
    connection_success.emit()


func _on_connection_failed() -> void:
    connection_failed.emit()
    enet_peer.close();


func _on_server_disconnected() -> void:
    connected = false
    # Clean the signals
    multiplayer.connected_to_server.disconnect(_on_connection_success)
    multiplayer.connection_failed.disconnect(_on_connection_failed)
    multiplayer.server_disconnected.disconnect(_on_server_disconnected)
