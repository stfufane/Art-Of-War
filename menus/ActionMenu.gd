class_name ActionMenu
extends PanelContainer

@onready var recruit_button: Button = $MarginContainer/VBoxContainer/RecruitButton
@onready var attack_button:  Button = $MarginContainer/VBoxContainer/AttackButton
@onready var support_button: Button = $MarginContainer/VBoxContainer/SupportButton


func _ready():
	Game.States[State.Name.ACTION_CHOICE].started.connect(show)
	Game.update_action_menu.connect(update_menu)


func update_menu() -> void:
	# Can't recruit twice or after having attacked
	recruit_button.disabled = Game.has_recruited or Game.has_attacked
	# Can't attack after recruiting
	attack_button.disabled = Game.has_recruited or !Game.is_attack_available
	support_button.disabled = !Game.is_support_available


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
