class_name PlayerHand
extends Control

var _deck: Array[CardType.UnitType] = []
var _cards: Array[Card] = []

func setup():
	# Build the deck with 4 of each card.
	for _i in range(4):
		_deck.append(CardType.UnitType.Soldier)
		_deck.append(CardType.UnitType.Archer)
		_deck.append(CardType.UnitType.Guard)
		_deck.append(CardType.UnitType.Wizard)
		_deck.append(CardType.UnitType.Monk)
	_deck.shuffle()

	# Then draw the hand. It has the king by default + 3 cards.
	_cards.append(Game.create_card_instance(CardType.UnitType.King))
	for _i in range(3):
		_cards.append(Game.create_card_instance(_deck.pop_back()))

	var x = 0
	for card in _cards:
		x += card.size.x
		put_card(card, x)

func draw_card():
	if _deck.size() > 0:
		_cards.append(Game.create_card_instance(_deck.pop_back()))
		add_card(_cards.back())
		

func add_card(card: Card):
	var x = (_cards.size() - 1) * card.size.x
	put_card(card, x)
	

func put_card(card: Card, x: int):
	add_child(card)
	card.position = Vector2(x, 0)
	card.set_board_area(Card.BoardArea.Hand)


func remove_card(card: Card):
	remove_child(card)
	_cards.erase(card)
	reorder_cards()


func reorder_cards():
	var x = 0
	for card in _cards:
		card.position = Vector2(x, 0)
		x += card.size.x
