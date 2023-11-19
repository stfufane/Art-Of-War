class_name ActionMenu
extends PanelContainer

@onready var recruit_button: Button = $MarginContainer/VBoxContainer/RecruitButton
@onready var attack_button:  Button = $MarginContainer/VBoxContainer/AttackButton
@onready var support_button: Button = $MarginContainer/VBoxContainer/SupportButton

var _has_recruited: bool = false


func _ready():
	Game.States[State.Name.FINISH_TURN].started.connect(reset_recruit)
	Game.States[State.Name.ACTION_CHOICE].started.connect(show)
	Game.is_attack_available.connect(set_attack_button_enabled)
	Game.is_support_available.connect(set_support_button_enabled)


func reset_recruit():
	_has_recruited = false
	recruit_button.disabled = false


func set_attack_button_enabled(enabled: bool):
	attack_button.disabled = !enabled or _has_recruited


func set_support_button_enabled(enabled: bool):
	support_button.disabled = !enabled


func _on_attack_button_pressed():
	recruit_button.disabled = true # Can't recruit after attacking
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
	_has_recruited = true
	recruit_button.disabled = true # Can't recruit twice
	attack_button.disabled = true # Can't attack after recruiting
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.RECRUIT)
	hide()


func _on_end_turn_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.FINISH_TURN)
	hide()
