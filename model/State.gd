class_name State
extends Object

signal started
signal ended

enum Name {
	WAITING_FOR_PLAYER,
	RESHUFFLE,
	INIT_BATTLEFIELD,
	INIT_RESERVE,
	START_TURN,
	ACTION_CHOICE,
	RECRUIT,
	SUPPORT,
	KING_SUPPORT,
	MOVE_UNIT,
	ARCHER_ATTACK,
	SUPPORT_BLOCK,
	ATTACK,
	ATTACK_BLOCK,
	FINISH_TURN,
}

var instruction: String
var happens_once: bool


func _init(i: String, h_o: bool):
	instruction = i
	happens_once = h_o


# These are the automatic states that are started when calling end_state
# However, it's possible that a state is started manually in a middle of an other state,
# so the transition is not always the one defined here
static func get_next_state(name: State.Name) -> State.Name:
	match name:
		State.Name.RESHUFFLE:
			return State.Name.INIT_BATTLEFIELD
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
