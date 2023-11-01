class_name Board
extends Node

@onready var support_menu: PanelContainer = $CanvasLayer/SupportMenu
@onready var end_turn_menu: PanelContainer = $CanvasLayer/EndTurnMenu

@onready var pass_button: Button = $CanvasLayer/EndTurnMenu/MarginContainer/VBoxContainer/PassButton
@onready var pass_support_button: Button = $CanvasLayer/SupportMenu/MarginContainer/VBoxContainer/PassButton

@onready var battlefield: Battlefield = $Battlefield
@onready var _reserve: CardsControl = $Reserve
@onready var enemy_reserve: CardsControl = $EnemyReserve
@onready var kingdom: Kingdom = $Kingdom
@onready var enemy_kingdom: Kingdom = $EnemyKingdom
@onready var _hand: PlayerHand = $PlayerHand


func _ready():
	Game.players_ready.connect(setup)
	Game.States[State.Name.INIT_BATTLEFIELD].started.connect(init_battlefield)
	Game.States[State.Name.INIT_RESERVE].started.connect(init_reserve)
	Game.States[State.Name.RECRUIT].started.connect(init_recruit_turn)
	Game.States[State.Name.SUPPORT].started.connect(init_support_turn)
	Game.States[State.Name.ATTACK_BLOCK].started.connect(init_attack_block)
	Game.States[State.Name.SUPPORT_BLOCK].started.connect(init_support_block)
	Game.States[State.Name.FINISH_TURN].started.connect(finish_turn)


func setup():
	setup_kingdom()
	if Game.first_player:
		Game.start_state(State.Name.INIT_BATTLEFIELD)
	else:
		Game.instruction_updated.emit("Waiting for the other player")


func setup_kingdom():
	# First card of the deck is put in the kingdom
	var unit_type = _hand._deck.pop_back()
	kingdom.increase_population(unit_type)
	add_card_to_enemy_kingdom.rpc(unit_type)
	kingdom.setup()
	enemy_kingdom.setup()


func init_battlefield():
	_hand.connect_click(_hand_card_selected)
	battlefield.card_added.connect(_card_added_on_battlefield)


func init_reserve():
	_hand.connect_click(_add_card_to_reserve)


func init_recruit_turn():
	# Recruitment is made by default from the reserve
	# If the reserve is empty, the player can recruit from the hand
	if !_reserve.is_empty():
		Game.instruction_updated.emit("Pick a card from your reserve")
		_reserve.connect_click(_reserve_card_selected)
	else:
		Game.instruction_updated.emit("Pick a card from your hand")
		_hand.connect_click(_hand_card_selected)

	# In both cases, the card is put on the battlefield
	battlefield.card_added.connect(_card_added_on_battlefield)


func init_support_turn():
	support_menu.show()
	pass


func init_attack_block():
	# The player can block the enemy attack if he has a guard or a king in hand.
	_hand.flash_attack_block_cards()
	pass


func init_support_block():
	# The player can block the enemy support if he has a wizard or a king in hand.
	pass


func finish_turn():
	# Add a card in the kingdom or pass.
	# If you have 6 cards in your hand, you MUST put a card in the kingdom
	pass_button.disabled = _hand.size() > 5
	end_turn_menu.show()

###########
# Signals #
###########
func _on_pass_support_button_pressed():
	pass


func _on_pass_button_pressed():
	if Game.get_state() != State.Name.FINISH_TURN:
		return
	Game.end_state()
	end_turn_menu.hide()


func _hand_card_selected(card_id: int):
	_card_selected(card_id, _hand)


func _reserve_card_selected(card_id: int):
	_card_selected(card_id, _reserve)


func _card_selected(card_id: int, from: CardsControl) -> void:
	var card: Card = instance_from_id(card_id)
	from.switch_card(card, Game.picked_card)
	
	Game.picked_card = card
	add_child(Game.picked_card)
	Game.picked_card.set_board_area(Card.BoardArea.Picked)


func _card_added_on_battlefield():
	# Disconnect the click on hand and reserve cards
	_hand.disconnect_click(_hand_card_selected)
	_reserve.disconnect_click(_reserve_card_selected)
	
	battlefield.card_added.disconnect(_card_added_on_battlefield)
	if Game.get_state() == State.Name.INIT_BATTLEFIELD:
		Game.end_state()
	else:
		Game.start_state(State.Name.FINISH_TURN)


func _add_card_to_reserve(card_id: int):
	var card: Card = instance_from_id(card_id)
	_hand.disconnect_click(_add_card_to_reserve)
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
