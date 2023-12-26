class_name MainMenu
extends PanelContainer


@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var join_button: Button = $MarginContainer/VBoxContainer/JoinButton
@onready var start_server_button: Button = $MarginContainer/VBoxContainer/StartServerButton
@onready var join_server_button: Button = $MarginContainer/VBoxContainer/JoinServerButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	start_server_button.pressed.connect(_on_start_server_button_pressed)
	join_server_button.pressed.connect(_on_join_server_button_pressed)

	multiplayer.connected_to_server.connect(_client_connected)
	multiplayer.server_disconnected.connect(_server_disconnected)

	# For remote server, hide the server buttons.
	if Network.server != "localhost":
		start_server_button.hide()
		join_server_button.hide()

		# Automatically connect to server
		if DisplayServer.get_name() != "headless":
			Network.join_server()


func _client_connected():
	start_button.disabled = false
	join_button.disabled = false
	start_server_button.hide()
	join_server_button.hide()


func _server_disconnected():
	start_button.disabled = true
	join_button.disabled = true


func _on_start_button_pressed():
	Network.create_party.rpc_id(1)
	start_button.disabled = true
	join_button.disabled = true


func _on_join_button_pressed():
	Network.join_party.rpc_id(1)


func _on_start_server_button_pressed():
	Network.start_server()


func _on_join_server_button_pressed():
	Network.join_server()
