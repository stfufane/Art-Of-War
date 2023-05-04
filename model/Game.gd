extends Node

@onready var CardTypes = {
	CardType.UnitType.King: CardType.new(CardType.UnitType.King, "King", 1, 5, 4, [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]),
	CardType.UnitType.Soldier: CardType.new(CardType.UnitType.Soldier, "Soldier", INF, 2, 1, [Vector2(0, 1)]),
	CardType.UnitType.Archer: CardType.new(CardType.UnitType.Archer, "Archer", 1, 2, 1, [Vector2(-2, 1), Vector2(2, 1), Vector2(-1, 2), Vector2(1, 2)]),
	CardType.UnitType.Guard: CardType.new(CardType.UnitType.Guard, "Guard", 1, 3, 2, [Vector2(0, 1)]),
	CardType.UnitType.Wizard: CardType.new(CardType.UnitType.Wizard, "Wizard", 1, 2, 1, [Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)]),
	CardType.UnitType.Monk: CardType.new(CardType.UnitType.Monk, "Monk", 1, 2, 2, [Vector2(-1, 1), Vector2(1, 1), Vector2(-2, 2), Vector2(2, 2)])
}

# Initialize the player's kingdom
@onready var player_kingdom: Dictionary = {
	CardType.UnitType.Soldier: 0,
	CardType.UnitType.Archer: 0,
	CardType.UnitType.Guard: 0,
	CardType.UnitType.Wizard: 0,
	CardType.UnitType.Monk: 0
}

enum States {
	# WAITING_FOR_PLAYER,
	INIT_BATTLEFIELD,
	INIT_RESERVE,
	PLAYER_TURN,
	ENEMY_TURN,
}

enum PlayerStates {
	RECRUIT,
	SUPPORT,
	ATTACK,
	ADD_TO_KINGDOM,
}

@onready var card_scene = preload("res://scenes/card.tscn")

@onready var current_state = States.INIT_BATTLEFIELD
@onready var player_hand: Array[Card] = []
@onready var player_reserve: Array[Card] = []
@onready var player_deck: Array[CardType.UnitType] = []
@onready var card_in_hand: Card = null

func _ready():
	# First build the deck with 4 of each card.
	for _i in range(4):
		player_deck.append(CardType.UnitType.Soldier)
		player_deck.append(CardType.UnitType.Archer)
		player_deck.append(CardType.UnitType.Guard)
		player_deck.append(CardType.UnitType.Wizard)
		player_deck.append(CardType.UnitType.Monk)
	player_deck.shuffle()

	# Then draw the hand. It has the king by default + 3 cards.
	player_hand.append(get_card_instance(CardType.UnitType.King))
	for _i in range(3):
		player_hand.append(get_card_instance(player_deck.pop_back()))

func draw_card():
	if player_deck.size() > 0:
		player_hand.append(get_card_instance(player_deck.pop_back()))

func get_card_instance(card_type: CardType.UnitType) -> Card:
	var card_instance = card_scene.instantiate()
	card_instance.set_unit_type(card_type)
	return card_instance
