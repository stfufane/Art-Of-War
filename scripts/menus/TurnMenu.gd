class_name TurnMenu extends PanelContainer

@onready var recruit_button: Button = $MarginContainer/HBoxContainer/RecruitButton
@onready var attack_button: Button = $MarginContainer/HBoxContainer/AttackButton
@onready var support_button: Button = $MarginContainer/HBoxContainer/SupportButton
@onready var end_turn_button: Button = $MarginContainer/HBoxContainer/EndTurnButton

const HIDING_STATES: Array[StateManager.EState] = [
	StateManager.EState.RECRUIT,
	StateManager.EState.ATTACK,
	StateManager.EState.SUPPORT,
	StateManager.EState.WAITING_FOR_PLAYER,
	StateManager.EState.GAME_OVER_LOSS,
	StateManager.EState.GAME_OVER_WIN
]

# Store the state to handle the case of the cancel button.
var attack_done: bool = false
var recruit_done: bool = false

func _ready() -> void:
	recruit_button.pressed.connect(_on_recruit_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	support_button.pressed.connect(_on_support_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	StateManager.get_state(StateManager.EState.ACTION_CHOICE).started.connect(_on_action_choice)
	Events.state_changed.connect(_on_state_changed)
	Events.start_turn.connect(_on_turn_started)
	Events.recruit_done.connect(_on_recruit_done)
	Events.attack_done.connect(_on_attack_done)


func _on_state_changed(state: StateManager.EState) -> void:
	if HIDING_STATES.has(state):
		hide()


func _on_action_choice() -> void:
	if recruit_done or attack_done:
		recruit_button.hide()
	else:
		recruit_button.show()
	
	if recruit_done:
		attack_button.hide()
	else:
		attack_button.show()
	
	support_button.show()
	end_turn_button.show()
	show()


func finish_turn() -> void:
	recruit_button.hide()
	attack_button.hide()
	support_button.hide()
	end_turn_button.show()


## After recruit, you can't recruit anymore nor attack
func _on_recruit_done() -> void:
	recruit_done = true
	recruit_button.hide()
	attack_button.hide()


## After attacking, you cannot recruit but you can still attack
func _on_attack_done(_attacking_unit: int) -> void:
	if not GameManager.my_turn:
		return
	attack_done = true
	recruit_button.hide()


## Reset all buttons
func _on_turn_started() -> void:
	attack_done = false
	recruit_done = false
	_on_action_choice()


func _on_attack_button_pressed() -> void:
	ActionsManager.do(Action.Code.START_ATTACK)


func _on_support_button_pressed() -> void:
	ActionsManager.do(Action.Code.START_SUPPORT)


func _on_recruit_button_pressed() -> void:
	ActionsManager.do(Action.Code.START_RECRUIT)


func _on_end_turn_button_pressed() -> void:
	match StateManager.current_state:
		StateManager.EState.ACTION_CHOICE:
			ActionsManager.do(Action.Code.PROMPT_END_TURN)
		StateManager.EState.FINISH_TURN:
			ActionsManager.do(Action.Code.END_TURN)
		_:
			return
