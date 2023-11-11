class_name State
extends Object

signal started
signal ended

enum Name {
	WAITING_FOR_PLAYER,
	INIT_BATTLEFIELD,
	INIT_RESERVE,
	START_TURN,
	ACTION_CHOICE,
	RECRUIT,
	SUPPORT,
	SUPPORT_BLOCK,
	ATTACK,
	ATTACK_BLOCK,
	FINISH_TURN,
}


var name: Name
var instruction: String
var happens_once: bool


func _init(n: Name, i: String, h_o: bool):
	name = n
	instruction = i
	happens_once = h_o


# For debug purposes
func _to_string() -> String:
	match name:
		State.Name.WAITING_FOR_PLAYER:
			return "Waiting for player"
		State.Name.INIT_BATTLEFIELD:
			return "Initializing battlefield"
		State.Name.INIT_RESERVE:
			return "Initializing reserve"
		State.Name.START_TURN:
			return "Starting turn"
		State.Name.ACTION_CHOICE:
			return "Choosing action"
		State.Name.RECRUIT:
			return "Recruiting"
		State.Name.SUPPORT:
			return "Supporting"
		State.Name.SUPPORT_BLOCK:
			return "Support blocking"
		State.Name.ATTACK:
			return "Attacking"
		State.Name.ATTACK_BLOCK:
			return "Attack blocking"
		State.Name.FINISH_TURN:
			return "Finishing turn"
		_:
			return "Unknown state"

# These are the automatic states that are started when calling end_state
# However, it's possible that a state is started manually in a middle of an other state,
# so the transition is not always the one defined here
func get_next_state() -> State.Name:
	match name:
		State.Name.INIT_BATTLEFIELD:
			return State.Name.INIT_RESERVE
		State.Name.INIT_RESERVE:
			return State.Name.START_TURN
		State.Name.RECRUIT:
			return State.Name.FINISH_TURN
		State.Name.SUPPORT:
			return State.Name.ACTION_CHOICE
		State.Name.ATTACK:
			return State.Name.ACTION_CHOICE
		State.Name.FINISH_TURN:
			return State.Name.START_TURN
		_:
			return State.Name.WAITING_FOR_PLAYER
