class_name ActionMenu
extends PanelContainer

@onready var recruit_button = $MarginContainer/VBoxContainer/RecruitButton
@onready var attack_button = $MarginContainer/VBoxContainer/AttackButton


func _ready():
	Game.States[State.Name.ACTION_CHOICE].started.connect(_action_choice_started)
	Game.is_attack_available.connect(set_attack_button_enabled)


func set_attack_button_enabled(enabled: bool):
	attack_button.disabled = !enabled

func _action_choice_started():
	# Hide the recruit action if the player attacked already or used a support card.
	if Game.previous_state == State.Name.ATTACK or Game.previous_state == State.Name.SUPPORT:
		recruit_button.hide()
	else:
		recruit_button.show()
	show()


func _on_attack_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.ATTACK)
	hide()


func _on_support_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.SUPPORT)
	hide()


func _on_recruit_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.RECRUIT)
	hide()


func _on_end_turn_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.FINISH_TURN)
	hide()
