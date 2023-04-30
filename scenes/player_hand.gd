class_name PlayerHand
extends Control

@onready var player_hand = Model.player_hand

func _ready():
	var card_scene = load("res://scenes/card.tscn")
	for card in player_hand:
		var card_instance = card_scene.instantiate()
		$CardContainer.size.x += card_instance.size.x
		card_instance.type = card.type
		$CardContainer.add_child(card_instance)
