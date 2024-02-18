extends Node
## Handles the actions that can be run by the players from the game
## All code running here is run on the server.
##
## All the possible actions must be registered here

## A collection of [Action] objects associated to their [enum Action.Code]
var actions: Dictionary = {}


func register_action(code: Action.Code, action: Action) -> void:
	actions[code] = action.with_code(code)


@rpc("any_peer")
func run(code: Action.Code, data: Variant = null) -> void:
	assert(actions.has(code), "Could not find the action with code " + Action.Code.keys()[code] + ", did you register it?")
	var action := actions.get(code) as Action
	action.run(data)


func register_actions() -> void:
	register_action(Action.Code.RESHUFFLE_HAND, Action.new()\
		.with_check(PlayerActions.check_reshuffle)\
		.with_action(PlayerActions.do_reshuffle))

	register_action(Action.Code.VALIDATE_HAND, Action.new()\
		.with_check(PlayerActions.check_validate_hand)\
		.with_action(PlayerActions.do_validate_hand))

	register_action(Action.Code.INIT_BATTLEFIELD, Action.new()\
		.with_check(PlayerActions.check_init_battlefield)\
		.with_action(PlayerActions.do_init_battlefield))

	register_action(Action.Code.INIT_RESERVE, Action.new()\
		.with_check(PlayerActions.check_init_reserve)\
		.with_action(PlayerActions.do_init_reserve))
