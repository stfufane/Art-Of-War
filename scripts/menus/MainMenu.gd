class_name MainMenu
extends PanelContainer


@onready var host_button: Button = $MarginContainer/VBoxContainer/HostButton
@onready var join_button: Button = $MarginContainer/VBoxContainer/JoinButton
@onready var connection_status: Label = $MarginContainer/VBoxContainer/ConnectionStatus
@onready var party_id_textbox: LineEdit = $MarginContainer/VBoxContainer/PartyId


func _ready() -> void:
    if DisplayServer.get_name() == "headless":
        return

    host_button.pressed.connect(_on_host_button_pressed)
    join_button.pressed.connect(_on_join_button_pressed)

    Network.connection_success.connect(_client_connected)
    Network.connection_failed.connect(_client_connection_failed)

    GameManager.no_party_found.connect(_on_party_not_found)
    GameManager.party_cancelled.connect(show)
    GameManager.party_created.connect(_on_party_created)

    # We come from an earlier game and the screen just reloaded,
    # so we don't want to show the server buttons
    # and we can still host or join a game
    if Network.connected:
        host_button.disabled = false
        join_button.disabled = false

    # An error has been set on the network before going back to the lobby.
    if not GameManager.lobby_error.is_empty():
        show_status(GameManager.lobby_error)
        GameManager.lobby_error = ""


func _client_connected() -> void:
    host_button.disabled = false
    join_button.disabled = false


func _client_connection_failed() -> void:
    show_status("Failed to connect to server")


func _on_party_created(_party_id: String) -> void:
    hide()


func _on_host_button_pressed() -> void:
    GameServer.create_party.rpc_id(1)


func _on_join_button_pressed() -> void:
    connection_status.hide()
    var party_id: String = party_id_textbox.text
    if party_id.is_empty():
        show_status("You must enter a party ID")
        return

    GameServer.join_party.rpc_id(1, party_id)


func _on_party_not_found() -> void:
    show_status("No party found with this ID")


func show_status(text: String) -> void:
    connection_status.text = text
    connection_status.show()
