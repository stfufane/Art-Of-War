class_name MainMenu
extends PanelContainer

func _on_start_button_pressed():
	Game.start_server()
	hide()


func _on_join_button_pressed():
	Game.join_server()
	hide()

