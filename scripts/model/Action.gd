class_name Action extends Object
## Defines a server action that can be called via RPC by a player
##
## Each action is defined by its unique code and a callback that will
## be executed on the server if the caller is valid


## The code used client side to call the action
enum Code {
	RESHUFFLE_HAND,
	VALIDATE_HAND,
	SET_BATTLEFIELD_UNIT
}


var code: Code
var check: Callable = func(_player: Player) -> bool: return true
var action: Callable = func(_player: Player, _data: Variant) -> void: pass


func with_code(in_code: Code) -> Action:
	self.code = in_code
	return self


func with_check(in_check: Callable) -> Action:
	self.check = in_check
	return self


func with_action(in_action: Callable) -> Action:
	self.action = in_action
	return self


func run(data: Variant) -> void:
	var player: Player = GameServer.get_current_player()
	if player == null or player.party == null:
		return
	
	if check.call(player):
		print("Player %d running action %s" % [player.id, Code.keys()[code]])
		action.call(player, data)
	else:
		push_warning("Player %d could not run action %s" % [player.id, Code.keys()[code]])
