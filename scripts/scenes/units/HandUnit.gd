class_name HandUnit extends ClickableUnit

func _on_gui_input(event: InputEvent) -> void:
	if !event.is_action_pressed(GameManager.LEFT_CLICK):
		return
	Events.hand_unit_clicked.emit(self)
