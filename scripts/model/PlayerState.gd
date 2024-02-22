class_name PlayerState extends RefCounted

var player: Player = null ## Reference to the player holding the state

## Every time the state is updated by the server, the client is notified via an RPC call
var current: StateManager.EState = StateManager.EState.WAITING_FOR_PLAYER :
	set(state):
		current = state
		print("%s (%d) state is now %s" % [player.label, player.id, StateManager.EState.keys()[current]])
		StateManager.set_state.rpc_id(player.id, state)


var hand_ready: bool = false :
	set(ready):
		hand_ready = ready
		if ready:
			current = StateManager.EState.INIT_BATTLEFIELD


var battlefield_ready: bool = false :
	set(ready):
		battlefield_ready = ready
		if ready:
			current = StateManager.EState.INIT_RESERVE


var reserve_ready: bool = false :
	set(ready):
		reserve_ready = ready
		if ready:
			if player.first:
				# If the first player is the first to finish, wait for the second player to finish
				# Otherwise, start the turn
				if player.opponent.state.reserve_ready:
					player.start_turn()
					player.party.init_kingdoms()
				else:
					current = StateManager.EState.WAITING_FOR_PLAYER
			else:
				# Second player always waits, and if he finished second, first player can start his turn.
				current = StateManager.EState.WAITING_FOR_PLAYER
				if player.opponent.state.reserve_ready:
					player.opponent.start_turn()
					player.party.init_kingdoms()


var has_won: bool = false

func _init(p: Player) -> void:
	player = p
