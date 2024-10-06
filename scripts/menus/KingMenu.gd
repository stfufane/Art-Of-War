class_name KingMenu extends PanelContainer

@onready var soldier_button: Button = $MarginContainer/HBoxContainer/SoldierButton
@onready var archer_button: Button = $MarginContainer/HBoxContainer/ArcherButton
@onready var priest_button: Button = $MarginContainer/HBoxContainer/PriestButton


func _ready() -> void:
    soldier_button.pressed.connect(_on_soldier_button_pressed)
    archer_button.pressed.connect(_on_archer_button_pressed)
    priest_button.pressed.connect(_on_priest_button_pressed)


func _on_soldier_button_pressed() -> void:
    pass


func _on_archer_button_pressed() -> void:
    pass


func _on_priest_button_pressed() -> void:
    pass