class_name PlayerHand
extends Control

func setup():
	var x = 0
	for card in Game.player_hand:
		x += card.size.x
		put_card(card, x)

func add_card(card: Card):
	var x = (Game.player_hand.size() - 1) * card.size.x
	put_card(card, x)
	
func put_card(card: Card, x: int):
	print("Add card to hand")
	add_child(card)
	card.position = Vector2(x, 0)
	card.set_location(Card.Location.Hand)

func remove_card(card: Card):
	remove_child(card)
	Game.player_hand.erase(card)
	reorder_cards()

func reorder_cards():
	var x = 0
	for card in Game.player_hand:
		card.position = Vector2(x, 0)
		x += card.size.x
