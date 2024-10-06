class_name BlockMenu extends PanelContainer

# This button will display guard or wizard depending on whether we're blocking an attack or a support.
@onready var guard_wizard_button: Button = $MarginContainer/HBoxContainer/GuardWizardButton
@onready var king_button: Button = $MarginContainer/HBoxContainer/KingButton
@onready var pass_button: Button = $MarginContainer/HBoxContainer/PassButton


func _ready() -> void:
    guard_wizard_button.pressed.connect(_on_guard_wizard_button_pressed)
    king_button.pressed.connect(_on_king_button_pressed)
    pass_button.pressed.connect(_on_pass_button_pressed)

    StateManager.get_state(StateManager.EState.ACTION_CHOICE).started.connect(hide)
    StateManager.get_state(StateManager.EState.ATTACK_BLOCK).started.connect(show)


func _on_king_button_pressed() -> void:
    pass


func _on_guard_wizard_button_pressed() -> void:
    pass


func _on_pass_button_pressed() -> void:
    pass