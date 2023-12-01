class_name GoBackButton
extends Button


func _ready():
	pressed.connect(_on_pressed)

	# Define when this should show or hide
	Game.go_back_enabled.connect(show_hide)
	Game.States[State.Name.ACTION_CHOICE].started.connect(hide)
	Game.States[State.Name.ACTION_CHOICE].ended.connect(show)
	Game.States[State.Name.FINISH_TURN].ended.connect(hide)


func show_hide(shown: bool) -> void:
	show() if shown else hide()


func _on_pressed():
	Game.go_back_to_action_choice()
