class_name MainMenu
extends PanelContainer


@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var join_button: Button = $MarginContainer/VBoxContainer/JoinButton


func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)


func _on_start_button_pressed():
	Game.start_server()
	hide()


func _on_join_button_pressed():
	Game.join_server()
	hide()

