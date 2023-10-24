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
		card.connect("card_clicked", _reserve_card_chosen)


func init_turn():
	# Reset the cards on the battlefield
	battlefield.disengage_cards()
	# Draw a card
	Game.draw_card()
	hand.add_card(Game.player_hand.back())
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
	if !Game.player_reserve.is_empty():
		for card in Game.player_reserve:
			card.connect("card_clicked", _reserve_card_selected)
	else:
		for card in Game.player_hand:
			card.connect("card_clicked", _hand_card_selected)

	# In both cases, the card is put on the battlefield
	battlefield.connect("card_added", _card_added_on_battlefield)


func init_attack_turn():
	pass


func init_support_turn():
	support_menu.show()
	pass


func finish_turn():
	# Add a card in the kingdom or pass.
	# If you have 6 cards in your hand, you MUST put a card in the kingdom
	pass_button.disabled = Game.player_hand.size() > 5
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
	if Game.current_state != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.ATTACK)
	action_menu.hide()
	

func _on_support_button_pressed():
	if Game.current_state != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.SUPPORT)
	action_menu.hide()


func _on_pass_support_button_pressed():
	pass


func _on_recruit_button_pressed():
	if Game.current_state != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.RECRUIT)
	action_menu.hide()


func _on_end_turn_button_pressed():
	if Game.current_state != State.Name.ACTION_CHOICE:
		return
	Game.start_state(State.Name.FINISH_TURN)
	action_menu.hide()


func _on_pass_button_pressed():
	if Game.current_state != State.Name.FINISH_TURN:
		return
	Game.end_state()
	end_turn_menu.hide()


func _hand_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	# If a card had already been selected, put it back in the hand
	if Game.picked_card != null:
		remove_child(Game.picked_card)
		hand.add_card(Game.picked_card)
	
	Game.picked_card = card
	hand.remove_card(Game.picked_card)
	add_child(Game.picked_card)
	Game.picked_card.set_location(Card.Location.Picked)


func _reserve_card_selected(card_id: int):
	var card: Card = instance_from_id(card_id)
	if Game.picked_card != null:
		reserve.add_card(Game.picked_card)
	Game.picked_card = card
	reserve.remove_card(Game.picked_card)
	Game.picked_card.set_location(Card.Location.Picked)


func _card_added_on_battlefield():
	if Game.picked_card.is_connected("card_clicked", _hand_card_selected):
		Game.picked_card.disconnect("card_clicked", _hand_card_selected)
	if Game.picked_card.is_connected("card_clicked", _reserve_card_selected):
		Game.picked_card.disconnect("card_clicked", _reserve_card_selected)
	
	# remove_child(Game.picked_card)
	Game.picked_card = null
	# Disconnect the click on hand cards
	for card in Game.player_hand:
		if card.is_connected("card_clicked", _hand_card_selected):
			card.disconnect("card_clicked", _hand_card_selected)
	# Disconnect the click on reserve cards
	for card in Game.player_reserve:
		if card.is_connected("card_clicked", _reserve_card_selected):
			card.disconnect("card_clicked", _reserve_card_selected)
	
	battlefield.disconnect("card_added", _card_added_on_battlefield)
	if Game.current_state == State.Name.INIT_BATTLEFIELD:
		Game.end_state()
	else:
		Game.start_state(State.Name.FINISH_TURN)


func _reserve_card_chosen(card_id: int):
	var card: Card = instance_from_id(card_id)
	for hand_card in Game.player_hand:
		hand_card.disconnect("card_clicked", _reserve_card_chosen)
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
