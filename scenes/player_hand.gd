class_name PlayerHand
extends Control

func setup():
	var x = 0
	for card in Game.player_hand:
		add_child(card)
		card.position = Vector2(x, 0)
		x += card.size.x

func add_card(card: Card):
	add_child(card)
	var x = (Game.player_hand.size() - 1) * card.size.x
	card.position = Vector2(x, 0)

func remove_card(card: Card):
	remove_child(card)
	Game.player_hand.erase(card)
	reorder_cards()

func reorder_cards():
	var x = 0
	for card in Game.player_hand:
		card.position = Vector2(x, 0)
		x += card.size.x
