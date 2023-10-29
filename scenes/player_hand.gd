class_name PlayerHand
extends CardsControl

var _deck: Array[CardType.UnitType] = []

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
	add_card(Game.create_card_instance(CardType.UnitType.King))
	for _i in range(3):
		add_card(Game.create_card_instance(_deck.pop_back()))


func draw_card():
	if !_deck.is_empty():
		add_card(Game.create_card_instance(_deck.pop_back()))
		

func is_deck_empty() -> bool:
	return _deck.is_empty()

