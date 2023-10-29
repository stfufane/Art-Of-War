class_name Board
extends Node

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var action_menu: PanelContainer = $CanvasLayer/ActionMenu
@onready var support_menu: PanelContainer = $CanvasLayer/SupportMenu
@onready var end_turn_menu: PanelContainer = $CanvasLayer/EndTurnMenu

@onready var recruit_button: Button = $CanvasLayer/ActionMenu/MarginContainer/VBoxContainer/RecruitButton
@onready var pass_button: Button = $CanvasLayer/EndTurnMenu/MarginContainer/VBoxContainer/PassButton
@onready var pass_support_button: Button = $CanvasLayer/SupportMenu/MarginContainer/VBoxContainer/PassButton

@onready var battlefield: Battlefield = $Battlefield
@onready var _reserve: CardsControl = $Reserve
@onready var enemy_reserve: CardsControl = $EnemyReserve
@onready var kingdom: Kingdom = $Kingdom
@onready var enemy_kingdom: Kingdom = $EnemyKingdom
@onready var _hand: PlayerHand = $PlayerHand
@onready var _instruction: Label = $Instruction


func setup():
	Game.setup(self)
	_hand.setup()
	battlefield.setup()
	setup_kingdom()
	if Game.first_player:
		Game.start_state(State.Name.INIT_BATTLEFIELD)
	else:
		_instruction.text = "Waiting for the other player"


func setup_kingdom():
	# First card of the deck is put in the kingdom
	var unit_type = _hand._deck.pop_back()
	kingdom.increase_population(unit_type)
	add_card_to_enemy_kingdom.rpc(unit_type)
	kingdom.setup()
	enemy_kingdom.setup()


func init_battlefield():
	for card in _hand.get_cards():
		card.card_clicked.connect(_hand_card_selected)
	battlefield.card_added.connect(_card_added_on_battlefield)


func init_reserve():
	for card in _hand.get_cards():
		card.card_clicked.connect(_add_card_to_reserve)


func init_turn():
	# Reset the cards on the battlefield
	battlefield.disengage_cards()
	# Draw a card
	_hand.draw_card()
	# Start the turn
	Game.start_state(State.Name.ACTION_CHOICE)


# Show the action menu
func init_choice_action():
	# Hide the recruit action if the player attacked already or used a support card.
	if Game.previous_state == State.Name.ATTACK or Game.previous_state == State.Name.SUPPORT:
		recruit_button.hide()
	else:
		recruit_button.show()
	action_menu.show()


func init_recruit_turn():
	# Recruitment is made by default from the reserve
	# If the reserve is empty, the player can recruit from the hand
	if !_reserve.is_empty():
		_instruction.text = "Pick a card from your reserve"
		for card in _reserve.get_cards():
			card.card_clicked.connect(_reserve_card_selected)
	else:
		_instruction.text = "Pick a card from your hand"
		for card in _hand.get_cards():
			card.card_clicked.connect(_hand_card_selected)

	# In both cases, the card is put on the battlefield
	battlefield.card_added.connect(_card_added_on_battlefield)


func init_attack_turn():
	pass


func init_support_turn():
	support_menu.show()
	pass


func finish_turn():
	# Add a card in the kingdom or pass.
	# If you have 6 cards in your hand, you MUST put a card in the kingdom
	pass_button.disabled = _hand.get_cards().size() > 5
	end_turn_menu.show()

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
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.ATTACK)
	action_menu.hide()
	

func _on_support_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.SUPPORT)
	action_menu.hide()


func _on_pass_support_button_pressed():
	pass


func _on_recruit_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.RECRUIT)
	action_menu.hide()


func _on_end_turn_button_pressed():
	if Game.get_state() != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.FINISH_TURN)
	action_menu.hide()


func _on_pass_button_pressed():
	if Game.get_state() != State.Name.FINISH_TURN:
		return
	Game.end_state()
	end_turn_menu.hide()


func _hand_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	_hand.switch_card(card, Game.picked_card)

	Game.picked_card = card
	add_child(Game.picked_card)
	Game.picked_card.set_board_area(Card.BoardArea.Picked)


func _reserve_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	_reserve.switch_card(card, Game.picked_card)
	
	Game.picked_card = card
	add_child(Game.picked_card)
	Game.picked_card.set_board_area(Card.BoardArea.Picked)


func _card_added_on_battlefield():
	if Game.picked_card.card_clicked.is_connected(_hand_card_selected):
		Game.picked_card.card_clicked.disconnect(_hand_card_selected)
	if Game.picked_card.card_clicked.is_connected(_reserve_card_selected):
		Game.picked_card.card_clicked.disconnect(_reserve_card_selected)
	
	Game.picked_card = null
	# Disconnect the click on hand cards
	for card in _hand.get_cards():
		if card.card_clicked.is_connected(_hand_card_selected):
			card.card_clicked.disconnect(_hand_card_selected)
	# Disconnect the click on reserve cards
	for card in _reserve.get_cards():
		if card.card_clicked.is_connected(_reserve_card_selected):
			card.card_clicked.disconnect(_reserve_card_selected)
	
	battlefield.card_added.disconnect(_card_added_on_battlefield)
	if Game.get_state() == State.Name.INIT_BATTLEFIELD:
		Game.end_state()
	else:
		Game.start_state(State.Name.FINISH_TURN)


func _add_card_to_reserve(card_id: int):
	var card: Card = instance_from_id(card_id)
	for hand_card in _hand.get_cards():
		hand_card.card_clicked.disconnect(_add_card_to_reserve)
	_hand.remove_card(card)
	_reserve.add_card(card)
	add_card_to_enemy_reserve.rpc(card._unit_type)
	Game.end_state()


#################################################################################
# Network actions that are called to reflect local actions on the enemy board  ##
#################################################################################
@rpc("any_peer")
func add_card_to_enemy_reserve(unit_type: CardType.UnitType):
	enemy_reserve.add_card(Game.create_card_instance(unit_type))


@rpc("any_peer")
func add_card_to_enemy_kingdom(unit_type: CardType.UnitType):
	enemy_kingdom.increase_population(unit_type)
