class_name Board extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var shuffle_hand: ShuffleHand = $CanvasLayer/ShuffleHand
@onready var kingdom: Kingdom = $Kingdom
@onready var battlefield: Battlefield = $Battlefield
@onready var hand: Hand = $Hand
@onready var reserve: Reserve = $Reserve
@onready var enemy_reserve: Reserve = $EnemyReserve


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


func _on_reshuffle_ended():
	var tween = create_tween()
	tween.tween_property(shuffle_hand, "position", Vector2(shuffle_hand.position.x, 800), 0.6).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(display_elements)


