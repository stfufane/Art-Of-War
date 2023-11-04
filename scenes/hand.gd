class_name Hand
extends CardsControl

var _deck: Array[CardType.UnitType] = []

func _ready() -> void:
	# Setup the game when players are ready.
	Game.players_ready.connect(setup)

	# Automatically draw a card at the start of a turn.
	Game.States[State.Name.START_TURN].started.connect(start_turn)
	Game.States[State.Name.ATTACK_BLOCK].started.connect(flash_attack_block_cards)
	Game.States[State.Name.SUPPORT_BLOCK].started.connect(flash_support_block_cards)

func setup() -> void:
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


func start_turn() -> void:
	# Draw a card at the start of the turn and go directly to the next state.
	draw_card()
	Game.start_state(State.Name.ACTION_CHOICE)


func draw_card() -> void:
	if !_deck.is_empty():
		add_card(Game.create_card_instance(_deck.pop_back()))
		

func is_deck_empty() -> bool:
	return _deck.is_empty()


func flash_attack_block_cards() -> void:
	for card in _cards:
		if card._unit_type == CardType.UnitType.Guard or card._unit_type == CardType.UnitType.King:
			card.start_flash()


func flash_support_block_cards() -> void:
	for card in _cards:
		if card._unit_type == CardType.UnitType.Wizard or card._unit_type == CardType.UnitType.King:
			card.start_flash()

#
# Overrides from CardsControl
###############################
func add_card(card: Card) -> void:
	super.add_card(card)
	Game.hand_size_updated.emit(_cards.size())


func remove_card(card: Card) -> void:
	super.remove_card(card)
	Game.hand_size_updated.emit(_cards.size())