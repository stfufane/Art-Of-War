class_name EndTurnMenu
extends PanelContainer

@onready var pass_button: Button = $MarginContainer/VBoxContainer/PassButton


func _ready():
	Game.States[State.Name.FINISH_TURN].started.connect(show)
	Game.States[State.Name.FINISH_TURN].ended.connect(hide)
	Game.hand_size_updated.connect(set_pass_enabled)


# It's not possible to pass at the end of the turn if we have more than 5 cards in hand
func set_pass_enabled(hand_size: int):
	pass_button.disabled = hand_size > 5


func _on_pass_button_pressed():
	if Game.get_state() != State.Name.FINISH_TURN:
		return
	Game.end_state()

