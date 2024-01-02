class_name Lobby extends Control

@onready var main_menu = $MainMenu
@onready var waiting_menu = $WaitingMenu

func _ready() -> void:
	main_menu.show()
	waiting_menu.hide()
