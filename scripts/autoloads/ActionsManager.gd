extends Node
## Handles the actions that can be run by the players from the game
## All code running here is run on the server.
##
## All the possible actions must be registered here

## A collection of [Action] objects associated to their [enum Action.Code]
var actions: Dictionary[Action.Code, Action] = {}


func register_action(code: Action.Code, in_check: StringName, in_action: StringName) -> void:
    assert(not actions.has(code), Action.Code.keys()[code] + "is already registered.")
    actions[code] = Action.new(code, in_check, in_action)


func do(code: Action.Code, args: Array = []) -> void:
    run.rpc_id(1, code, args)


@rpc("any_peer")
func run(code: Action.Code, args: Array = []) -> void:
    assert(actions.has(code), "Could not find the action with code " + Action.Code.keys()[code] + ", did you register it?")
    var action: Action = actions.get(code)
    action.run(args)


func register_actions() -> void:
    register_action(Action.Code.RESHUFFLE_HAND, &"check_reshuffle", &"reshuffle_deck")
    register_action(Action.Code.VALIDATE_HAND, &"check_validate_hand", &"validate_hand")
    register_action(Action.Code.INIT_BATTLEFIELD, &"check_init_battlefield", &"init_battlefield")
    register_action(Action.Code.INIT_RESERVE, &"check_init_reserve", &"init_reserve")
    register_action(Action.Code.START_RECRUIT, &"check_start_recruit", &"start_recruit")
    register_action(Action.Code.START_ATTACK, &"check_start_attack", &"start_attack")
    register_action(Action.Code.START_SUPPORT, &"check_start_support", &"start_support")
    register_action(Action.Code.RECRUIT, &"check_recruit", &"recruit")
    register_action(Action.Code.SUPPORT_CHOICE, &"check_support_choice", &"support_choice")
    register_action(Action.Code.KING_SUPPORT, &"check_king_support", &"support_choice") # King support is a special case of support choice
    register_action(Action.Code.PRIEST_SUPPORT, &"check_priest_support", &"priest_support")
    register_action(Action.Code.ARCHER_SUPPORT, &"check_archer_support", &"archer_support")
    register_action(Action.Code.SOLDIER_SUPPORT, &"check_soldier_support", &"soldier_support")
    register_action(Action.Code.ATTACK, &"check_attack", &"attack")
    register_action(Action.Code.BLOCK_ATTACK, &"check_block_attack", &"block_attack")
    register_action(Action.Code.BLOCK_SUPPORT, &"check_block_support", &"block_support")
    register_action(Action.Code.NO_ATTACK_BLOCK, &"check_no_attack_block", &"no_attack_block")
    register_action(Action.Code.NO_SUPPORT_BLOCK, &"check_no_support_block", &"no_support_block")
    register_action(Action.Code.PROMPT_END_TURN, Action.NO_CHECK, &"prompt_end_turn")
    register_action(Action.Code.ADD_TO_KINGDOM, &"check_add_to_kingdom", &"add_to_kingdom")
    register_action(Action.Code.END_TURN, &"check_end_turn", &"end_turn")
    register_action(Action.Code.CANCEL_ACTION, &"check_cancel", &"cancel_action")
