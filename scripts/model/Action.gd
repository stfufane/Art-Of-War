class_name Action extends RefCounted
## Defines a server action that can be called via RPC by a player
##
## Each action is defined by its unique code and a callback that will
## be executed on the server if the caller is valid


## The code used client side to call the action
enum Code {
	RESHUFFLE_HAND,
	VALIDATE_HAND,
	INIT_BATTLEFIELD,
	INIT_RESERVE,
	START_RECRUIT,
	START_ATTACK,
	START_SUPPORT,
	RECRUIT,
	ATTACK,
	SUPPORT,
	END_TURN,
}


var code: Code
var check: StringName
var action: StringName

func _init(in_code: Code, in_check: StringName, in_action: StringName) -> void:
	code = in_code
	check = in_check
	action = in_action


func run(args: Array = []) -> void:
	var player: Player = GameServer.get_current_player()
	if player == null or player.party == null:
		push_error("No player or party found to run action %s" % Code.keys()[code])
		return

	if not check.is_empty():
		var check_callable := Callable(player, check)
		assert(check_callable.is_valid(), "Could not find the check function %s" % check)
		if not check_callable.callv(args):
			push_warning("%s (%d) could not run action %s" % [player.label, player.id, Code.keys()[code]])
			GameManager.set_action_error.rpc_id(player.id, "You cannot perform this action")
			return

	var action_callable := Callable(player, action)
	assert(action_callable.is_valid(), "Could not find the action function %s" % action)
	print("%s (%d) running action %s" % [player.label, player.id, Code.keys()[code]])
	action_callable.callv(args)
