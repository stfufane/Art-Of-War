class_name Kingdom
extends Control

@onready var kingdom = Model.player_kingdom

func _ready():
	var card_scene = load("res://scenes/card.tscn")
	for card_type in kingdom:
		var card_instance = card_scene.instantiate()
		$CardContainer.size.x += card_instance.size.x
		card_instance.type = card_type
		card_instance.set_nb_units(kingdom[card_type])
		$CardContainer.add_child(card_instance)