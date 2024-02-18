class_name ReserveUnit extends ClickableUnit

func _on_gui_input(event: InputEvent) -> void:
	if !event.is_action_pressed(GameManager.LEFT_CLICK):
		return
	Events.reserve_unit_clicked.emit(self)
