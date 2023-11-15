class_name ActionMenu
extends PanelContainer

@onready var recruit_button = $MarginContainer/VBoxContainer/RecruitButton
@onready var attack_button = $MarginContainer/VBoxContainer/AttackButton
@onready var support_button = $MarginContainer/VBoxContainer/SupportButton


func _ready():
	Game.States[State.Name.START_TURN].started.connect(func(): recruit_button.disabled = false)
	Game.States[State.Name.ACTION_CHOICE].started.connect(show)
	Game.is_attack_available.connect(set_attack_button_enabled)
	Game.hand_size_updated.connect(set_support_button_enabled)


func set_attack_button_enabled(enabled: bool):
	attack_button.disabled = !enabled


func set_support_button_enabled(hand_size: int) -> void:
	# TODO Check that reserve is not full
	support_button.disabled = hand_size == 0


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
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.RECRUIT)
	hide()


func _on_end_turn_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.FINISH_TURN)
	hide()
