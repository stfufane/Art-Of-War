class_name Board
extends PanelContainer

enum ESide {PLAYER, ENEMY}
enum EUnitSource {HAND, RESERVE}

const FAR_BELOW: int = 800
const FAR_ABOVE: int = -400

@onready var deck_choice := $CanvasLayer/DeckChoice as DeckChoice
@onready var shuffle_hand := $CanvasLayer/ShuffleHand as ShuffleHand
@onready var board_parts := $BoardParts as Node2D
@onready var reserve := $BoardParts/Reserve as Reserve
@onready var enemy_reserve := $BoardParts/EnemyReserve as Reserve

@onready var turn_menu := $CanvasLayer/TurnMenu as TurnMenu
@onready var instructions := $CanvasLayer/Instruction as Instruction


func _ready() -> void:
    StateManager.get_state(StateManager.EState.DECK_CHOICE).started.connect(_on_deck_choice_started)
    StateManager.get_state(StateManager.EState.DECK_CHOICE).ended.connect(_on_deck_choice_ended)
    StateManager.get_state(StateManager.EState.RESHUFFLE).started.connect(_on_reshuffle_started)
    StateManager.get_state(StateManager.EState.RESHUFFLE).ended.connect(_on_reshuffle_ended)
    StateManager.get_state(StateManager.EState.RECRUIT).started.connect(_on_recruit_started)
    StateManager.get_state(StateManager.EState.FINISH_TURN).started.connect(_on_finish_turn_started)
    Events.reserve_updated.connect(_on_reserve_updated)

    # Trigger the first state from the server
    ActionsManager.do(Action.Code.BOARD_READY)

func display_elements() -> void:
    shuffle_hand.queue_free()
    board_parts.show()


func tween_modal_enter(modal: Panel) -> void:
    var initial_y := modal.position.y
    modal.position.y = FAR_ABOVE
    modal.show()
    var tween := create_tween()
    tween.tween_property(modal, "position", Vector2(modal.position.x, initial_y), 0.6).set_trans(Tween.TRANS_QUAD)


func tween_modal_exit(modal: Panel) -> Tween:
    var tween := create_tween()
    tween.tween_property(modal, "position", Vector2(modal.position.x, FAR_BELOW), 0.6).set_trans(Tween.TRANS_QUAD)
    return tween


func _on_reshuffle_started() -> void:
    shuffle_hand.init_hand()
    tween_modal_enter(shuffle_hand)


func _on_deck_choice_started() -> void:
    tween_modal_enter(deck_choice)


func _on_deck_choice_ended() -> void:
    var tween := tween_modal_exit(deck_choice)
    tween.tween_callback(deck_choice.queue_free)


func _on_reshuffle_ended() -> void:
    var tween := tween_modal_exit(shuffle_hand)
    tween.tween_callback(display_elements)


func _on_reserve_updated(side: ESide) -> void:
    if side == ESide.PLAYER:
        reserve.update()
    else:
        enemy_reserve.update()


func _on_recruit_started() -> void:
    if reserve.is_empty():
        instructions.text = "Choose a unit from your hand to recruit"
    else:
        instructions.text = "Choose a unit from your reserve to recruit"


func _on_finish_turn_started() -> void:
    instructions.text = "Add a unit from your hand to your kingdom or end your turn"
    turn_menu.finish_turn()
