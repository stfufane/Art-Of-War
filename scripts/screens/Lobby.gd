class_name Lobby extends Control

@onready var main_menu = $MainMenu
@onready var host_menu = $HostMenu

func _ready() -> void:
	main_menu.show()
	host_menu.hide()
