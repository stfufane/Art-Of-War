extends Node

var CardTypes = {
	CardType.UnitType.King: CardType.new(CardType.UnitType.King, "King", 1, 5, 4, [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]),
	CardType.UnitType.Soldier: CardType.new(CardType.UnitType.Soldier, "Soldier", INF, 2, 1, [Vector2(0, 1)]),
	CardType.UnitType.Archer: CardType.new(CardType.UnitType.Archer, "Archer", 1, 2, 1, [Vector2(-2, 1), Vector2(2, 1), Vector2(-1, 2), Vector2(1, 2)]),
	CardType.UnitType.Guard: CardType.new(CardType.UnitType.Guard, "Guard", 1, 3, 2, [Vector2(0, 1)]),
	CardType.UnitType.Wizard: CardType.new(CardType.UnitType.Wizard, "Wizard", 1, 2, 1, [Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)]),
	CardType.UnitType.Monk: CardType.new(CardType.UnitType.Monk, "Monk", 1, 2, 2, [Vector2(-1, 1), Vector2(1, 1), Vector2(-2, 2), Vector2(2, 2)])
}

# Initialize the player's kingdom
var player_kingdom = {
	CardType.UnitType.Soldier: 0,
	CardType.UnitType.Archer: 0,
	CardType.UnitType.Guard: 0,
	CardType.UnitType.Wizard: 0,
	CardType.UnitType.Monk: 0
}

var player_hand: Array = []
var player_reserve: Array = []
var player_deck: Array = []

func _init():
	# First build the deck with 4 of each card.
	for _i in range(4):
		player_deck.append(CardTypes[CardType.UnitType.Soldier])
		player_deck.append(CardTypes[CardType.UnitType.Archer])
		player_deck.append(CardTypes[CardType.UnitType.Guard])
		player_deck.append(CardTypes[CardType.UnitType.Wizard])
		player_deck.append(CardTypes[CardType.UnitType.Monk])
	player_deck.shuffle()

	# Then draw the hand. It has the king by default + 3 cards.
	player_hand.append(CardTypes[CardType.UnitType.King])
	for _i in range(3):
		player_hand.append(player_deck.pop_back())
		player_reserve.append(player_deck.pop_back())
	
