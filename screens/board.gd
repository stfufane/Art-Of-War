class_name Board
extends Node


@onready var battlefield: Battlefield = $Battlefield
@onready var _reserve: CardsControl = $Reserve
@onready var enemy_reserve: CardsControl = $EnemyReserve
@onready var kingdom: Kingdom = $Kingdom
@onready var enemy_kingdom: Kingdom = $EnemyKingdom
@onready var _hand: Hand = $Hand


func _ready():
	Game.players_ready.connect(setup)
	Game.hand_card_clicked.connect(_hand_card_clicked)
	Game.reserve_card_clicked.connect(_reserve_card_clicked)

	Game.States[State.Name.RECRUIT].started.connect(init_recruit_turn)
	Game.States[State.Name.ATTACK_BLOCK].started.connect(init_attack_block)
	Game.States[State.Name.SUPPORT_BLOCK].started.connect(init_support_block)


func setup():
	# First card of the deck is put in the kingdom
	_increase_kingdom_population(_hand._deck.pop_back())
	kingdom.setup()
	enemy_kingdom.setup()


func init_recruit_turn():
	# Recruitment is made by default from the reserve
	# If the reserve is empty, the player can recruit from the hand
	if !_reserve.is_empty():
		Game.instruction_updated.emit("Pick a card from your reserve")
	else:
		Game.instruction_updated.emit("Pick a card from your hand")


func init_attack_block():
	# The player can block the enemy attack if he has a guard or a king in hand.
	pass


func init_support_block():
	# The player can block the enemy support if he has a wizard or a king in hand.
	pass


###########
# Signals #
###########
func _hand_card_clicked(card: Card) -> void:
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD:
			_card_selected(card, _hand)
		State.Name.INIT_RESERVE:
			_add_card_to_reserve(card)
		State.Name.RECRUIT:
			# We can recruit from the hand only if the reserve is empty
			if _reserve.is_empty():
				_card_selected(card, _hand)
		State.Name.ATTACK_BLOCK:
			pass # TODO
		State.Name.SUPPORT_BLOCK:
			pass # TODO
		State.Name.FINISH_TURN:
			if _increase_kingdom_population(card._unit_type):
				_hand.remove_card(card)
				Game.end_state()


func _increase_kingdom_population(unit_type: CardType.UnitType) -> bool:
	# Can't add the king to the kingdom
	if unit_type == CardType.UnitType.King:
		return false
	kingdom.increase_population(unit_type)
	add_card_to_enemy_kingdom.rpc(unit_type)
	return true

func _reserve_card_clicked(card: Card) -> void:
	match Game.get_state():
		State.Name.INIT_RESERVE, State.Name.RECRUIT:
			_card_selected(card, _reserve)
			remove_card_from_enemy_reserve.rpc(card._unit_type)


func _card_selected(card: Card, from: CardsControl) -> void:
	from.switch_card(card, Game.picked_card)
	
	Game.picked_card = card
	add_child(Game.picked_card)
	Game.picked_card.set_board_area(Card.BoardArea.Picked)


func _add_card_to_reserve(card: Card):
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
func remove_card_from_enemy_reserve(unit_type: CardType.UnitType):
	enemy_reserve.remove_card_type(unit_type)

@rpc("any_peer")
func add_card_to_enemy_kingdom(unit_type: CardType.UnitType):
	enemy_kingdom.increase_population(unit_type)
