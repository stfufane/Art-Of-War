extends Node

enum EState {
	WAITING_FOR_PLAYER,
	RESHUFFLE,
	INIT_BATTLEFIELD,
	INIT_RESERVE,
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
var States: Dictionary[EState, State] = {
	EState.WAITING_FOR_PLAYER: State.new("Waiting for opponent"),
	EState.RESHUFFLE: State.new("Need to reshuffle your hand ?"),
	EState.INIT_BATTLEFIELD: State.new("Add a unit on your battlefield"),
	EState.INIT_RESERVE: State.new("Add a unit to your reserve"),
	EState.ACTION_CHOICE: State.new("Choose your next action"),
	EState.RECRUIT: State.new("Recruit a unit"),
	EState.SUPPORT: State.new("Play a support by adding it to your reserve"),
	EState.KING_SUPPORT: State.new("Choose what unit your king is playing as"),
	EState.MOVE_UNIT: State.new("Move a unit on the battlefield"),
	EState.ARCHER_ATTACK: State.new("Choose a target to hit with your archer"),
	EState.SUPPORT_BLOCK: State.new("You can block the enemy support by using a wizard or a king"),
	EState.ATTACK: State.new("Attack a unit on the enemy battlefield"),
	EState.ATTACK_BLOCK: State.new("You can block the enemy attack by using a guard or a king"),
	EState.CONSCRIPTION: State.new("You must recruit 2 units to repopulate the battlefield"),
	EState.FINISH_TURN: State.new("Finish turn"),
	EState.GAME_OVER: State.new("Game Over :)")
}

var current_state: EState = EState.WAITING_FOR_PLAYER


func get_state(state: EState) -> State:
	assert(States.has(state), EState.keys()[state] + " is not registered in the list of states.")
	return States.get(state)


## Triggered by the server at the start of an action
@rpc
func set_state(state: EState) -> void:
	get_state(current_state).ended.emit()
	current_state = state
	var new_state := get_state(current_state)
	Events.update_instructions.emit(new_state.instruction)
	new_state.started.emit()
