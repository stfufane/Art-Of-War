class_name ReshuffleMenu extends PanelContainer

@onready var reshuffle_button: Button = $MarginContainer/VBoxContainer/ReshuffleButton
@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton

const MAX_RESHUFFLE: int = 3

var nb_reshuffle: int = 1

func _ready():
	reshuffle_button.pressed.connect(_on_reshuffle_button_pressed)
	play_button.pressed.connect(_on_play_button_pressed)

	Game.States[State.Name.RESHUFFLE].started.connect(show)
	Game.States[State.Name.RESHUFFLE].ended.connect(hide)
	update_reshuffle_button()


func update_reshuffle_button():
	reshuffle_button.text = "Yes (" + str(nb_reshuffle) + "/" + str(MAX_RESHUFFLE) + ")"


func _on_play_button_pressed():
	Game.end_state()


func _on_reshuffle_button_pressed():
	Game.reshuffle_deck.emit()
	if nb_reshuffle == MAX_RESHUFFLE:
		reshuffle_button.hide()
		return

	nb_reshuffle += 1
	update_reshuffle_button()
