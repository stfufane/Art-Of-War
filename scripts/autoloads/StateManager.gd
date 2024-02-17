extends Node

enum EState {
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
	CONSCRIPTION,
	FINISH_TURN,
	GAME_OVER
}

## The list of all available states with their associated texts
var States: Dictionary = {
	EState.WAITING_FOR_PLAYER: State.new("Waiting for opponent", false),
	EState.RESHUFFLE: State.new("Need to reshuffle your hand ?", true),
	EState.INIT_BATTLEFIELD: State.new("Init battlefield", true),
	EState.INIT_RESERVE: State.new("Init reserve", true),
	EState.START_TURN: State.new("Start turn", false),
	EState.ACTION_CHOICE: State.new("Action choice", false),
	EState.RECRUIT: State.new("Recruit a unit", false),
	EState.SUPPORT: State.new("Play a support by adding it to your reserve", false),
	EState.KING_SUPPORT: State.new("Choose what unit your king is playing as", false),
	EState.MOVE_UNIT: State.new("Move a unit on the battlefield", false),
	EState.ARCHER_ATTACK: State.new("Choose a target to hit with your archer", false),
	EState.SUPPORT_BLOCK: State.new("You can block the enemy support by using a wizard or a king", false),
	EState.ATTACK: State.new("Attack a unit on the enemy battlefield", false),
	EState.ATTACK_BLOCK: State.new("You can block the enemy attack by using a guard or a king", false),
	EState.CONSCRIPTION: State.new("You must recruit 2 units to repopulate the battlefield", false),
	EState.FINISH_TURN: State.new("Finish turn", false),
	EState.GAME_OVER: State.new("Game Over :)", true)
}

var current_state: EState = EState.WAITING_FOR_PLAYER


func get_state(state: EState) -> State:
	assert(States.has(state), EState.keys()[state] + " is not registered in the list of states.")
	return States.get(state) as State


## Triggered by the server at the start of an action
@rpc
func set_state(state: EState) -> void:
	get_state(current_state).ended.emit()
	current_state = state
	get_state(current_state).started.emit()
