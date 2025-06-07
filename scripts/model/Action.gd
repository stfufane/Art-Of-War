class_name Action extends RefCounted
## Defines a server action that can be called via RPC by a player
##
## Each action is defined by its unique code and a callback that will
## be executed on the server if the caller is valid

const NO_CHECK: StringName = &""

## The code used client side to call the action
enum Code {
    BOARD_READY,
    CHOOSE_DECK,
    RESHUFFLE_HAND,
    VALIDATE_HAND,
    INIT_BATTLEFIELD,
    INIT_RESERVE,
    START_RECRUIT,
    START_ATTACK,
    START_SUPPORT,
    RECRUIT,
    ATTACK,
    BLOCK_ATTACK,
    SUPPORT_CHOICE,
    KING_SUPPORT,
    PRIEST_SUPPORT,
    ARCHER_SUPPORT,
    SOLDIER_SUPPORT,
    BLOCK_SUPPORT,
    NO_ATTACK_BLOCK,
    NO_SUPPORT_BLOCK,
    ADD_TO_KINGDOM,
    PROMPT_END_TURN,
    END_TURN,
    CANCEL_ACTION,
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
    if not is_instance_valid(player) or not is_instance_valid(player.party):
        push_error("No player or party found to run action %s" % Code.keys()[code])
        return

    if check != NO_CHECK:
        var check_callable := Callable(player.action_check, check)
        assert(check_callable.is_valid(), "Could not find the check function %s" % check)
        if not check_callable.callv(args):
            push_warning("%s (%d) could not run action %s" % [player.label, player.id, Code.keys()[code]])
            GameManager.set_action_error.rpc_id(player.id, player.action_check.error_message)
            return

    var action_callable := Callable(player, action)
    assert(action_callable.is_valid(), "Could not find the action function %s" % action)
    print("%s (%d) running action %s" % [player.label, player.id, Code.keys()[code]])
    action_callable.callv(args)
    GameManager.set_action_error.rpc_id(player.id, "")
