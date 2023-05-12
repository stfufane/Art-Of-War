class_name Board
extends Control

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var action_menu: PanelContainer = $CanvasLayer/ActionMenu
@onready var recruit_button: Button = $CanvasLayer/ActionMenu/MarginContainer/VBoxContainer/RecruitButton

@onready var battlefield: Battlefield = $Battlefield
@onready var reserve: Reserve = $Reserve
@onready var enemy_reserve: Reserve = $EnemyReserve
@onready var kingdom: Kingdom = $Kingdom
@onready var enemy_kingdom: Kingdom = $EnemyKingdom
@onready var hand: PlayerHand = $PlayerHand
@onready var instruction: Label = $Instruction

func setup():
	Game.setup(self)
	hand.setup()
	battlefield.setup()
	reserve.setup()
	setup_kingdom()
	if Game.first_player:
		Game.start_state(State.Name.INIT_BATTLEFIELD)
	else:
		instruction.text = "Waiting for the other player"

func setup_kingdom():
	# First card of the deck is put in the kingdom
	var unit_type = Game.player_deck.pop_back()
	kingdom.increase_population(unit_type)
	add_card_to_enemy_kingdom.rpc(unit_type)
	kingdom.setup()
	enemy_kingdom.setup()

func init_battlefield():
	for card in Game.player_hand:
		card.connect("card_clicked", _hand_card_selected)
	battlefield.connect("card_added", _card_added_on_battlefield)

func init_reserve():
	for card in Game.player_hand:
		card.connect("card_clicked", _reserve_card_selected)

func init_choice_action():
	# Show the action menu
	# Hide the recruit action if the player attacked already or used a support card.
	if Game.previous_state == State.Name.ATTACK or Game.previous_state == State.Name.SUPPORT:
		recruit_button.hide()
	else:
		recruit_button.show()
	action_menu.show()

func finish_turn():
	# Add a card in the kingdom or pass.
	# If you have 6 cards in your hand, you MUST put a card in the kingdom
	pass

###########
# Signals #
###########

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

func _on_attack_button_pressed():
	if Game.current_state != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.ATTACK)
	action_menu.hide()
	
func _on_support_button_pressed():
	if Game.current_state != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.SUPPORT)
	action_menu.hide()

func _on_recruit_button_pressed():
	if Game.current_state != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.RECRUIT)
	action_menu.hide()

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
	if Game.current_state == State.Name.INIT_BATTLEFIELD:
		Game.end_state()
	else:
		Game.start_state(State.Name.FINISH_TURN)

func _reserve_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	for hand_card in Game.player_hand:
		hand_card.disconnect("card_clicked", _reserve_card_selected)
	hand.remove_card(card)
	reserve.add_card(card)
	add_card_to_enemy_reserve.rpc(card.unit_type)
	Game.end_state()

#################################################################################
# Network actions that are called to reflect local actions on the enemy board  ##
#################################################################################
@rpc("any_peer")
func add_card_to_enemy_reserve(unit_type: CardType.UnitType):
	enemy_reserve.add_card(Game.get_card_instance(unit_type))

@rpc("any_peer")
func add_card_to_enemy_kingdom(unit_type: CardType.UnitType):
	enemy_kingdom.increase_population(unit_type)
