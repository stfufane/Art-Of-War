class_name Board
extends Control

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu

@onready var battlefield: Battlefield = $Battlefield
@onready var reserve: Reserve = $Reserve
@onready var enemy_reserve: Reserve = $EnemyReserve
@onready var kingdom: Kingdom = $Kingdom
@onready var enemy_kingdom: Kingdom = $EnemyKingdom
@onready var hand: PlayerHand = $PlayerHand
@onready var instruction: Label = $Instruction
@onready var deck: CardPlaceholder = $Deck

func _on_start_button_pressed():
	Game.start_server()
	main_menu.hide()
	# The game will start when the second player connects
	multiplayer.peer_connected.connect(_player_joined)

func _on_join_button_pressed():
	Game.join_server()
	main_menu.hide()
	multiplayer.peer_connected.connect(_player_joined)

func _player_joined(_p_id: int):
	setup()

func setup():
	Game.setup()
	hand.setup()
	battlefield.setup()
	reserve.setup()
	setup_kingdom()
	start_game()

func setup_kingdom():
	# First card of the deck is put in the kingdom
	var unit_type = Game.player_deck.pop_back()
	kingdom.increase_population(unit_type)
	add_card_to_enemy_kingdom.rpc(unit_type)
	kingdom.setup()
	enemy_kingdom.setup()

func start_game():
	instruction.text = "Place a card on the battlefield"
	for card in Game.player_hand:
		card.connect("card_clicked", _hand_card_selected)
	battlefield.connect("card_added", _card_added_on_battlefield)
	deck.connect("card_placeholder_clicked", _deck_clicked)

func _hand_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	# If a card had already been selected, put it back in the hand
	if Game.picked_card != null:
		hand.add_card(Game.picked_card)
	Game.picked_card = card
	hand.remove_card(Game.picked_card)

func _card_added_on_battlefield():
	Game.picked_card.disconnect("card_clicked", _hand_card_selected)
	Game.picked_card = null
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
	add_card_to_enemy_reserve.rpc(card.unit_type)

	Game.current_state = Game.States.PLAYER_ACTION_CHOICE
	instruction.text = "Ready to start your turn"

func _deck_clicked(_placeholder_id: int):
	if Game.current_state != Game.States.PLAYER_ACTION_CHOICE:
		return
	if Game.player_deck.is_empty():
		return
	
	Game.draw_card()
	hand.add_card(Game.player_hand.back())
	Game.current_state = Game.States.ENEMY_TURN
	instruction.text = "Enemy turn"

###
# Network actions that are called to reflect local actions on the enemy board
###

@rpc("any_peer")
func add_card_to_enemy_reserve(unit_type: CardType.UnitType):
	enemy_reserve.add_card(Game.get_card_instance(unit_type))

@rpc("any_peer")
func add_card_to_enemy_kingdom(unit_type: CardType.UnitType):
	enemy_kingdom.increase_population(unit_type)