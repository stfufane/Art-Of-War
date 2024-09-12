class_name Board
extends PanelContainer

enum ESide {PLAYER, ENEMY}
enum EUnitSource {HAND, RESERVE}

@onready var camera := $Camera2D as Camera2D
@onready var shuffle_hand := $CanvasLayer/ShuffleHand as ShuffleHand
@onready var kingdom := $Kingdom as Kingdom
@onready var battlefield := $Battlefield as Battlefield
@onready var hand := $Hand as Hand
@onready var reserve := $Reserve as Reserve
@onready var enemy_reserve := $EnemyReserve as Reserve

@onready var turn_menu := $CanvasLayer/TurnMenu as TurnMenu
@onready var instructions := $CanvasLayer/Instruction as Instruction

# All the baclground elements
@onready var background_elements := $Background/BackgroundElements as Node2D

# Sprites over the units that represent each zone.
@onready var banner := $Background/BackgroundElements/Banner as Sprite2D
@onready var castle := $Background/BackgroundElements/Castle as Sprite2D
@onready var tent := $Background/BackgroundElements/Tent as Sprite2D


func _ready() -> void:
    print("Loaded the board, ready to play")
    StateManager.get_state(StateManager.EState.RESHUFFLE).ended.connect(_on_reshuffle_ended)
    StateManager.get_state(StateManager.EState.RECRUIT).started.connect(_on_recruit_started)
    Events.toggle_battlefield_flash.connect(_toggle_flash_battlefield)
    Events.reserve_updated.connect(_on_reserve_updated)

    background_elements.hide()
    kingdom.hide()
    battlefield.hide()
    hand.hide()
    reserve.hide()
    enemy_reserve.hide()
    turn_menu.hide()
    shuffle_hand.show()
    shuffle_hand.update_hand(3)


func display_elements() -> void:
    shuffle_hand.hide()
    background_elements.show()
    kingdom.show()
    battlefield.show()
    hand.show()
    reserve.show()
    enemy_reserve.show()


func _on_reshuffle_ended() -> void:
    var tween := create_tween()
    tween.tween_property(shuffle_hand, "position", Vector2(shuffle_hand.position.x, 800), 0.6).set_trans(Tween.TRANS_QUAD)
    tween.tween_callback(display_elements)
    _toggle_flash_battlefield(true)


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


# TODO: Generic method to flash any sprite
func _toggle_flash_battlefield(state: bool) -> void:
    if state:
        if banner.material != null:
            return
        var s_material := ShaderMaterial.new()
        s_material.set_shader(GameManager.FLASH_SHADER)
        banner.material = s_material
    else:
        banner.material = null
