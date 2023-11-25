class_name Board
extends Node


@onready var _reserve: CardsControl = $Reserve
@onready var enemy_reserve: CardsControl = $EnemyReserve
@onready var kingdom: Kingdom = $Kingdom
@onready var enemy_kingdom: Kingdom = $EnemyKingdom
@onready var _hand: Hand = $Hand


func _ready():
	Game.hand_card_clicked.connect(_hand_card_clicked)
	Game.reserve_card_clicked.connect(_reserve_card_clicked)
	Game.no_support_played.connect(_no_support_played)
	Game.attack_validated.connect(_validate_attack)
	Game.archer_attacked.connect(_archer_attacked)
	Game.battlefield_card_switched.connect(_card_back_from_battlefield)
	Game.first_reserve_card_removed.connect(_card_removed_from_reserve)

	Game.States[State.Name.ACTION_CHOICE].started.connect(start_action)
	Game.States[State.Name.INIT_BATTLEFIELD].started.connect(setup)
	Game.States[State.Name.RECRUIT].started.connect(init_recruit_turn)


func setup() -> void:
	# First card of the deck is put in the kingdom
	increase_kingdom_population(_hand._deck.pop_back())
	

func start_action() -> void:
	Game.is_support_available = _hand.has_support_cards() and _reserve.size() < 5
	_reserve.stop_all_flashes()


func init_recruit_turn() -> void:
	# Recruitment is made by default from the reserve
	# If the reserve is empty, the player can recruit from the hand
	if _reserve.is_empty():
		Game.instruction_updated.emit("Pick a card from your hand")
		return
	
	# Automatically pick the first card from the reserve
	Game.instruction_updated.emit("You can pick the card most left of the reserve")
	_reserve.get_first_card().start_flash()


func card_selected(card: Card, from: CardsControl) -> void:
	Game.set_can_go_back(false)
	from.switch_card(card, Game.picked_card)
	
	Game.picked_card = card
	add_child(Game.picked_card)
	Game.picked_card.set_board_area(Card.BoardArea.Picked)


func add_card_to_reserve(card: Card, from: CardsControl = null) -> void:
	if from != null:
		from.remove_card(card)
	Game.add_event.emit("have", "added a " + str(card._type) + " to the reserve")
	_reserve.add_card(card)
	add_card_to_enemy_reserve.rpc(card._unit_type)


func recruit_from_hand(card: Card) -> void:
	# We can recruit from the hand only if the reserve is empty
	# and if we didn't pick up a card from the reserve already
	if _reserve.is_empty() and (Game.picked_card == null or Game.picked_card._picked_from != Card.BoardArea.Reserve):
		card_selected(card, _hand)


func play_support(card: Card) -> void:
	# Wizards and guards can only be played to counter the enemy's support
	if card._unit_type == CardType.UnitType.Wizard or card._unit_type == CardType.UnitType.Guard:
		return
	
	# Play a support from the hand
	_hand.stop_all_flashes()
	add_card_to_reserve(card, _hand)
	
	if card._unit_type == CardType.UnitType.King:
		# If the king is played as a support, it's a special case
		# The player can choose as which type of card he wants to play it
		Game.start_state(State.Name.KING_SUPPORT)
		return

	Game.enemy_support_block(Game.CardTypes[card._unit_type])


func play_attack_block(card: Card) -> void:
	# The player can block the enemy attack if he has a guard or a king in hand.
	if card._unit_type != CardType.UnitType.Guard and card._unit_type != CardType.UnitType.King:
		return
	
	_hand.stop_all_flashes()
	add_card_to_reserve(card, _hand)
	Game.add_event.emit("are", "blocking the attack with a " + str(card._type))
	attack_was_blocked.rpc(true)


func play_support_block(card: Card) -> void:
	# The player can block the enemy support if he has a wizard or a king in hand.
	if card._unit_type != CardType.UnitType.Wizard and card._unit_type != CardType.UnitType.King:
		return

	_hand.stop_all_flashes()
	add_card_to_reserve(card, _hand)
	Game.add_event.emit("are", "blocking the support with a " + str(card._type))
	support_was_blocked.rpc(true)


func increase_kingdom_population(unit_type: CardType.UnitType) -> bool:
	# Can't add the king to the kingdom
	if unit_type == CardType.UnitType.King:
		return false
	kingdom.increase_population(unit_type)
	add_card_to_enemy_kingdom.rpc(unit_type)
	return true


func handle_card_damage(target: Card, damage: int) -> void:
	target.take_damage(damage)

	# if the target still has hp, it's just hurt, the game continues
	if target._hp > 0:
		Game.add_event.emit("have", "hurt the " + str(target._type) + 
			", it now has " + str(target._hp) + " hp.")
		return

	# if the target has exactly 0 hp and was not hurt, it's captured and added to my kingdom
	# When used as a support, the archer cannot capture a card, it just kills it
	if target._hp == 0 and !target._hurt and Game.get_state() != State.Name.ARCHER_ATTACK:
		Game.add_event.emit("have", "captured the " + str(target._type))
		increase_kingdom_population(target._unit_type)
	else:
		Game.add_dead_enemy()
		Game.add_event.emit("have", "killed the " + str(target._type))

	# If it did not survive, the card is removed from the battlefield anyway
	Game.card_killed.emit(target)
	
	# If the target was a king, the game is over
	if target._unit_type == CardType.UnitType.King:
		# TODO: handle game over
		return


func finish_turn(card: Card) -> void:
	if increase_kingdom_population(card._unit_type):
		Game.add_event.emit("have", "added a " + str(card._type) + " to the kingdom")
		_hand.remove_card(card)
		Game.end_state()

###########
# Signals #
###########
func _hand_card_clicked(card: Card) -> void:
	match Game.get_state():
		State.Name.INIT_BATTLEFIELD:
			card_selected(card, _hand)
		State.Name.INIT_RESERVE:
			add_card_to_reserve(card, _hand)
			Game.end_state()
		State.Name.RECRUIT:
			recruit_from_hand(card)
		State.Name.SUPPORT:
			play_support(card)
		State.Name.ATTACK_BLOCK:
			play_attack_block(card)
		State.Name.SUPPORT_BLOCK:
			play_support_block(card)
		State.Name.FINISH_TURN:
			finish_turn(card)


func _reserve_card_clicked(_card: Card) -> void:
	if Game.get_state() == State.Name.RECRUIT:
		var first_reserve_card: Card = _reserve.get_first_card()
		first_reserve_card.stop_flash()
		card_selected(first_reserve_card, _reserve)


func _no_support_played() -> void:
	_hand.stop_all_flashes()
	# Send a signal to the enemy to tell him that we didn't play any support card to block his attack or support.
	# If we are passing, no need to tell the enemy, we just cancel the action we were doing.
	match Game.get_state():
		State.Name.ATTACK_BLOCK:
			if Game._my_turn:
				Game.process_attack_block(false, false)
			else:
				attack_was_blocked.rpc(false)
		State.Name.SUPPORT_BLOCK:
			if Game._my_turn:
				Game.process_support_block(false, false)
			else:
				support_was_blocked.rpc(false)


func _validate_attack() -> void:
	var attack_info: Dictionary = Game.get_attack_info()
	attack_info.attacking_card.stop_flash()
	var attacking_card: CardType = attack_info.attacking_card._type
	var attack_damage = attacking_card.attack
	
	# Soldier has a special attack that depends on the number of cards in hand
	if attack_info.attacking_card._unit_type == CardType.UnitType.Soldier:
		attack_damage = _hand.size()
	# Apply the potential attack bonus from the soldier support
	attack_damage += Game._attack_bonus

	var target: Card = attack_info.enemy_placeholder.get_current_card()
	handle_card_damage(target, attack_damage)


func _archer_attacked(target: Card) -> void:
	handle_card_damage(target, 1)
	# Go back to the action choice menu.
	Game.start_state(State.Name.ACTION_CHOICE)


func _card_back_from_battlefield(card: Card, to: Card.BoardArea) -> void:
	match to:
		Card.BoardArea.Reserve:
			add_card_to_reserve(card)
		Card.BoardArea.Hand:
			_hand.add_card(card)


func _card_removed_from_reserve() -> void:
	remove_first_card_from_enemy_reserve.rpc()

#################################################################################
# Network actions that are called to reflect local actions on the enemy board  ##
#################################################################################
@rpc("any_peer")
func add_card_to_enemy_reserve(unit_type: CardType.UnitType):
	enemy_reserve.add_card(Game.create_card_instance(unit_type))

@rpc("any_peer")
func remove_first_card_from_enemy_reserve():
	enemy_reserve.remove_first_card()

@rpc("any_peer")
func add_card_to_enemy_kingdom(unit_type: CardType.UnitType):
	enemy_kingdom.increase_population(unit_type)

@rpc("any_peer")
func attack_was_blocked(blocked: bool):
	Game.process_attack_block(blocked)

@rpc("any_peer")
func support_was_blocked(blocked: bool):
	Game.process_support_block(blocked)
