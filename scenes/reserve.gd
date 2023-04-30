class_name Reserve
extends Control

@onready var reserve = Model.player_reserve

func _ready():
	var card_scene = load("res://scenes/card.tscn")
	for card in reserve:
		var card_instance = card_scene.instantiate()
		$CardContainer.size.x += card_instance.size.x
		card_instance.type = card.type
		$CardContainer.add_child(card_instance)

