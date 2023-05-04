class_name Reserve
extends Control

func _ready():
	var x = 0
	for card in Game.player_reserve:
		card.position = Vector2(x, 0)
		x += card.size.x
		add_child(card)

func add_card(card: Card):
	card.position.x = Game.player_reserve.size() * card.size.x
	add_child(card)
	Game.player_reserve.append(card)
