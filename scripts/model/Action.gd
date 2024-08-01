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


func with_code(in_code: Code) -> Action:
	self.code = in_code
	return self


func with_check(in_check: StringName) -> Action:
	self.check = in_check
	return self


func with_action(in_action: StringName) -> Action:
	self.action = in_action
	return self


func run(args: Array = []) -> void:
	var player: Player = GameServer.get_current_player()
	if player == null or player.party == null:
		push_error("No player or party found to run action %s" % Code.keys()[code])
		return

	if check.is_empty() or Callable(player, check).callv(args):
		print("%s (%d) running action %s" % [player.label, player.id, Code.keys()[code]])
		Callable(player, action).callv(args)
	else:
		push_warning("%s (%d) could not run action %s" % [player.label, player.id, Code.keys()[code]])
