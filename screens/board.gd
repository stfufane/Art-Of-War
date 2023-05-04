class_name Board
extends Control

@onready var battlefield: Battlefield = $Battlefield
@onready var reserve: Reserve = $Reserve
@onready var kingdom: Kingdom = $Kingdom
@onready var hand: PlayerHand = $PlayerHand
@onready var instruction: Label = $Instruction
@onready var deck: CardPlaceholder = $Deck

func _ready():
	instruction.text = "Place a card on the battlefield"
	for card in Game.player_hand:
		card.connect("card_clicked", _hand_card_selected)
	battlefield.connect("card_added", _card_added_on_battlefield)
	deck.connect("card_placeholder_clicked", _deck_clicked)

func _hand_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	# If a card had already been selected, put it back in the hand
	if Game.card_in_hand != null:
		hand.add_card(Game.card_in_hand)
	Game.card_in_hand = card
	hand.remove_card(Game.card_in_hand)

func _card_added_on_battlefield():
	Game.card_in_hand.disconnect("card_clicked", _hand_card_selected)
	Game.card_in_hand = null
	# Disconnect the click on hand cards
	for card in Game.player_hand:
		card.disconnect("card_clicked", _hand_card_selected)
	battlefield.disconnect("card_added", _card_added_on_battlefield)
	
	Game.current_state = Game.States.INIT_RESERVE
	instruction.text = "Place a card in your reserve"
	for card in Game.player_hand:
		card.connect("card_clicked", _reserve_card_selected)

func _reserve_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	for hand_card in Game.player_hand:
		hand_card.disconnect("card_clicked", _reserve_card_selected)
	hand.remove_card(card)
	reserve.add_card(card)

	Game.current_state = Game.States.PLAYER_TURN
	instruction.text = "Ready to start your turn"

func _deck_clicked(_placeholder_id: int):
	if Game.current_state != Game.States.PLAYER_TURN:
		return
	if Game.player_deck.is_empty():
		return
	
	Game.draw_card()
	hand.add_card(Game.player_hand.back())
	Game.current_state = Game.States.ENEMY_TURN
	instruction.text = "Enemy turn"
