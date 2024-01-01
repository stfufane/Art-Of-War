class_name SupportMenu extends PanelContainer


@onready var pass_support_button: Button = $MarginContainer/VBoxContainer/PassButton


func _ready():
	pass_support_button.pressed.connect(_on_pass_support_button_pressed)

	# Display the menu when the support state is started
	Game.States[State.Name.SUPPORT_BLOCK].started.connect(show)
	Game.States[State.Name.ATTACK_BLOCK].started.connect(show)
	Game.States[State.Name.SUPPORT_BLOCK].ended.connect(hide)
	Game.States[State.Name.ATTACK_BLOCK].ended.connect(hide)


func _on_pass_support_button_pressed():
	Game.no_support_played.emit()
