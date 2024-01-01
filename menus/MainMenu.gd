class_name MainMenu extends PanelContainer


@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var join_button: Button = $MarginContainer/VBoxContainer/JoinButton
@onready var start_server_button: Button = $MarginContainer/VBoxContainer/StartServerButton
@onready var join_server_button: Button = $MarginContainer/VBoxContainer/JoinServerButton
@onready var connection_status: Label = $MarginContainer/VBoxContainer/ConnectionStatus
@onready var party_id_textbox: TextEdit = $MarginContainer/VBoxContainer/PartyId

func _ready():
	if DisplayServer.get_name() == "headless":
		return

	start_button.pressed.connect(_on_start_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	start_server_button.pressed.connect(_on_start_server_button_pressed)
	join_server_button.pressed.connect(_on_join_server_button_pressed)

	Network.connection_success.connect(_client_connected)
	Network.connection_failed.connect(_client_connection_failed)
	Network.party_created.connect(_on_party_created)
	Network.no_party_found.connect(_on_party_not_found)
	Network.party_cancelled.connect(show)

	# For remote server, hide the server buttons.
	if Network.server != "localhost":
		start_server_button.hide()
		join_server_button.hide()
		# Automatically connect to server
		Network.join_server()


func _client_connected():
	start_button.disabled = false
	join_button.disabled = false
	start_server_button.hide()
	join_server_button.hide()
	show_status("Connected to server")
	await get_tree().create_timer(2.0).timeout
	connection_status.hide()


func _client_connection_failed():
	show_status("Failed to connect to server")


func _on_party_created(_party_id: String):
	hide()


func _server_disconnected():
	start_button.disabled = true
	join_button.disabled = true


func _on_start_button_pressed():
	Network.create_party.rpc_id(1)


func _on_join_button_pressed():
	connection_status.hide()
	var party_id: String = party_id_textbox.text
	if party_id == "":
		show_status("You must enter a party ID")

		return

	Network.join_party.rpc_id(1, party_id)


func _on_party_not_found():
	show_status("No party found with this ID")



func _on_start_server_button_pressed():
	Network.start_server()


func _on_join_server_button_pressed():
	connection_status.hide()
	Network.join_server()


func show_status(text: String) -> void:
	connection_status.text = text
	connection_status.show()
