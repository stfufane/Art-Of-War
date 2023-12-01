class_name Hand
extends CardsControl

var _deck: Array[CardUnit.UnitType] = []

func _ready() -> void:
	# Setup the game when players are ready.
	Game.players_ready.connect(setup)
	Game.reshuffle_deck.connect(reshuffle_deck)

	# Automatically draw a card at the start of a turn.
	Game.States[State.Name.START_TURN].started.connect(start_turn)
	Game.States[State.Name.ACTION_CHOICE].started.connect(start_action)
	Game.States[State.Name.SUPPORT].started.connect(flash_support_cards)
	Game.States[State.Name.ATTACK_BLOCK].started.connect(flash_attack_block_cards)
	Game.States[State.Name.SUPPORT_BLOCK].started.connect(flash_support_block_cards)

func setup() -> void:
	# Build the deck with 4 of each card.
	for _i in range(4):
		_deck.append(CardUnit.UnitType.Soldier)
		_deck.append(CardUnit.UnitType.Archer)
		_deck.append(CardUnit.UnitType.Guard)
		_deck.append(CardUnit.UnitType.Wizard)
		_deck.append(CardUnit.UnitType.Monk)
	_deck.shuffle()

	# Then draw the hand. It has the king by default + 3 cards.
	add_card(Game.create_card_instance(CardUnit.UnitType.King))
	for _i in range(3):
		add_card(Game.create_card_instance(_deck.pop_back()))


func reshuffle_deck() -> void:
	# Reset all the deck and cards in hand and draw a new hand.
	clear()
	_deck.clear()
	setup()


func start_turn() -> void:
	# Draw a card at the start of the turn and go directly to the next state.
	draw_card()
	Game.start_state(State.Name.ACTION_CHOICE)


func start_action() -> void:
	stop_all_flashes()


func draw_card() -> void:
	if !_deck.is_empty():
		add_card(Game.create_card_instance(_deck.pop_back()))


func is_deck_empty() -> bool:
	return _deck.is_empty()


func has_support_cards() -> bool:
	for card: Card in _cards:
		if card.unit.type != CardUnit.UnitType.Wizard and card.unit.type != CardUnit.UnitType.Guard:
			return true
	return false


func flash_support_cards() -> void:
	for card: Card in _cards:
		# Guards and wizards can only be played to block the other player
		if card.unit.type != CardUnit.UnitType.Wizard and card.unit.type != CardUnit.UnitType.Guard:
			card.start_flash()


func flash_attack_block_cards() -> void:
	for card: Card in _cards:
		if card.unit.type == CardUnit.UnitType.Guard or card.unit.type == CardUnit.UnitType.King:
			card.start_flash()


func flash_support_block_cards() -> void:
	for card: Card in _cards:
		if card.unit.type == CardUnit.UnitType.Wizard or card.unit.type == CardUnit.UnitType.King:
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
