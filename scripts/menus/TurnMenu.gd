class_name TurnMenu extends Control

@onready var recruit_button: Button = $MarginContainer/HBoxContainer/RecruitButton
@onready var attack_button: Button = $MarginContainer/HBoxContainer/AttackButton
@onready var support_button: Button = $MarginContainer/HBoxContainer/SupportButton
@onready var end_turn_button: Button = $MarginContainer/HBoxContainer/EndTurnButton


func _ready() -> void:
	recruit_button.pressed.connect(_on_recruit_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	support_button.pressed.connect(_on_support_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	StateManager.get_state(StateManager.EState.ACTION_CHOICE).ended.connect(show)
	Events.update_turn_menu.connect(update_menu)


func update_menu() -> void:
	pass
	# # Can't recruit twice or after having attacked
	# recruit_button.disabled = Game.has_recruited or Game.has_attacked
	# # Can't attack after recruiting
	# attack_button.disabled = Game.has_recruited or !Game.is_attack_available
	# support_button.disabled = !Game.is_support_available


func _on_attack_button_pressed() -> void:
	if StateManager.current_state != StateManager.EState.ACTION_CHOICE:
		return
	# TODO: Request server to start attack state
	hide()


func _on_support_button_pressed() -> void:
	if StateManager.current_state != StateManager.EState.ACTION_CHOICE:
		return
	# TODO: Request server to start support state
	hide()


func _on_recruit_button_pressed() -> void:
	if StateManager.current_state != StateManager.EState.ACTION_CHOICE:
		return
	# TODO: Request server to start recruit state
	hide()


func _on_end_turn_button_pressed() -> void:
	if StateManager.current_state != StateManager.EState.ACTION_CHOICE:
		return
	# TODO: Request server to end turn
	hide()
