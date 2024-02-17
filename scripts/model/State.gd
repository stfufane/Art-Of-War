class_name State extends Object

signal started
signal ended


var instruction: String
var happens_once: bool


func _init(i: String, h_o: bool) -> void:
	instruction = i
	happens_once = h_o

# These are the automatic states that are started when calling end_state
# However, it's possible that a state is started manually in a middle of an other state,
# so the transition is not always the one defined here
static func get_next_state(name: StateManager.EState) -> StateManager.EState:
	match name:
		StateManager.EState.RESHUFFLE:
			return StateManager.EState.INIT_BATTLEFIELD
		StateManager.EState.INIT_BATTLEFIELD:
			return StateManager.EState.INIT_RESERVE
		StateManager.EState.INIT_RESERVE:
			return StateManager.EState.START_TURN
		StateManager.EState.RECRUIT:
			return StateManager.EState.FINISH_TURN
		StateManager.EState.SUPPORT:
			return StateManager.EState.ACTION_CHOICE
		StateManager.EState.ATTACK:
			return StateManager.EState.ACTION_CHOICE
		StateManager.EState.FINISH_TURN:
			return StateManager.EState.START_TURN
		_:
			return StateManager.EState.WAITING_FOR_PLAYER
