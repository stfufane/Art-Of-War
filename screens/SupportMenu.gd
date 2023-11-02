extends PanelContainer


@onready var pass_support_button: Button = $MarginContainer/VBoxContainer/PassButton


func _ready():
	# Display the menu when the support state is started
	Game.States[State.Name.SUPPORT].started.connect(show)


func _on_pass_support_button_pressed():
	pass