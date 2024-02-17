class_name Board extends Node2D

@onready var camera := $Camera2D as Camera2D
@onready var shuffle_hand := $CanvasLayer/ShuffleHand as ShuffleHand
@onready var kingdom := $Kingdom as Kingdom
@onready var battlefield := $Battlefield as Battlefield
@onready var hand := $Hand as Hand
@onready var reserve := $Reserve as Reserve
@onready var enemy_reserve := $EnemyReserve as Reserve

# Sprites over the units that represent each zone.
@onready var banner := $Background/Banner as Sprite2D
@onready var castle := $Background/Castle as Sprite2D
@onready var tent := $Background/Tent as Sprite2D


func _ready() -> void:
	print("Loaded the board, ready to play")
	StateManager.States[StateManager.EState.RESHUFFLE].ended.connect(_on_reshuffle_ended)
	kingdom.hide()
	battlefield.hide()
	hand.hide()
	reserve.hide()
	enemy_reserve.hide()
	shuffle_hand.show()
	shuffle_hand.update_hand(3)


func display_elements() -> void:
	shuffle_hand.hide()
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


# TODO: Generic method to flash any sprite
func _toggle_flash_battlefield(state: bool) -> void:
	if state:
		if banner.material != null:
			return
		banner.material = ShaderMaterial.new()
		banner.material.shader = GameManager.FLASH_SHADER
	else:
		banner.material = null
