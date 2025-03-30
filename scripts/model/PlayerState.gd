class_name PlayerState extends RefCounted

var player: Player = null ## Reference to the player holding the state

## Every time the state is updated by the server, the client is notified via an RPC call
var current: StateManager.EState = StateManager.EState.WAITING_FOR_PLAYER:
	set(state):
		current = state
		print("%s (%d) state is now %s" % [player.label, player.id, StateManager.EState.keys()[current]])
		StateManager.set_state.rpc_id(player.id, state)


var hand_ready: bool = false:
	set(ready):
		hand_ready = ready
		if ready:
			current = StateManager.EState.INIT_BATTLEFIELD


var battlefield_ready: bool = false:
	set(ready):
		battlefield_ready = ready
		if ready:
			current = StateManager.EState.INIT_RESERVE


var reserve_ready: bool = false:
	set(ready):
		reserve_ready = ready
		if ready:
			if player.first:
				# If the first player is the first to finish, wait for the second player to finish
				# Otherwise, start the turn
				if player.opponent.state.reserve_ready:
					player.party.init_kingdoms()
					player.start_turn()
				else:
					current = StateManager.EState.WAITING_FOR_PLAYER
			else:
				# Second player always waits, and if he finished second, first player can start his turn.
				current = StateManager.EState.WAITING_FOR_PLAYER
				if player.opponent.state.reserve_ready:
					player.party.init_kingdoms()
					player.opponent.start_turn()


var is_attacking: bool = false:
	set(attacking):
		is_attacking = attacking
		if not is_attacking:
			attacking_tile = -1
			target_tile = -1

var is_supporting: bool = false

var attacking_tile: int = -1
var target_tile: int = -1

var has_attacked: bool = false
var has_recruited: bool = false
var attack_bonus: int = 0

var has_won: bool = false

func _init(p: Player) -> void:
	player = p


func new_turn() -> void:
	has_attacked = false
	has_recruited = false
	attack_bonus = 0
	current = StateManager.EState.ACTION_CHOICE


## After recruiting, we come back to action choice
func recruit_done() -> void:
	has_recruited = true
	GameManager.recruit_done.rpc_id(player.id)
	current = StateManager.EState.ACTION_CHOICE


func attack(attacking: int, target: int) -> void:
	is_attacking = true
	attacking_tile = attacking
	target_tile = target


func attack_done() -> void:
	# Mark the card that just attacked as engaged so it can't attack twice
	player.tiles.engage_unit(attacking_tile)
	var attacked_with := attacking_tile # Save a copy because it will be reset next line.
	is_attacking = false
	has_attacked = true

	current = StateManager.EState.ACTION_CHOICE
	player.opponent.state.current = StateManager.EState.WAITING_FOR_PLAYER
	# Notify both players that the attack is done.
	GameManager.attack_done.rpc_id(player.id, attacked_with)
	GameManager.attack_done.rpc_id(player.opponent.id, attacked_with)


func support_done() -> void:
	is_supporting = false
	current = StateManager.EState.ACTION_CHOICE
	player.opponent.state.current = StateManager.EState.WAITING_FOR_PLAYER
	# Notify both players that the support is done.
	GameManager.support_done.rpc_id(player.id)
	GameManager.support_done.rpc_id(player.opponent.id)


func end_turn() -> void:
	current = StateManager.EState.WAITING_FOR_PLAYER
	GameManager.end_turn.rpc_id(player.id)