class_name Battlefield
extends Control


signal card_added

var attacking_card: Card = null

# Represents the two sides of the battlefield as flat arrays.
var _player_cards: Array[Card] = [null, null, null, null, null, null]
var _enemy_cards: Array[Card] = [null, null, null, null, null, null]


func setup():
	# Connect all the card nodes to react to click and hover
	for placeholder in get_tree().get_nodes_in_group("cards"):
		placeholder.connect("card_placeholder_clicked", _placeholder_clicked)
		placeholder.connect("mouse_entered", _mouse_entered.bind(placeholder))
		placeholder.connect("mouse_exited", _mouse_exited.bind(placeholder))


func disengage_cards():
	for placeholder in get_tree().get_nodes_in_group("cards"):
		if placeholder.current_card != null:
			placeholder.current_card.disengage()

func add_player_card(card: Card, coords: Vector2):
	card.set_board_area(Card.BoardArea.Battlefield)
	if coords.y == -1:
		_player_cards[coords.x] = card
	else:
		_player_cards[coords.x + abs(coords.y) + 1] = card


func _mouse_entered(placeholder_hovered: CardPlaceholder):
	match Game.current_state:
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT:
			if placeholder_available(placeholder_hovered):
				placeholder_hovered.set_text("Place card here")
			else:
				placeholder_hovered.set_text("Can't place card here")
		_:
			pass


func _mouse_exited(placeholder_hovered: CardPlaceholder):
	if placeholder_hovered.current_card == null:
		placeholder_hovered.set_text("")


# Click on a placeholder to put a card on it
func _placeholder_clicked(id: int):
	var clicked_placeholder: CardPlaceholder = instance_from_id(id)
	# We can't put a card if there's already one there.
	if not placeholder_available(clicked_placeholder):
		return
	
	match Game.current_state:
		State.Name.INIT_BATTLEFIELD, State.Name.RECRUIT:
			# We can't put a card if there's no card in hand
			if Game.picked_card == null:
				return
			# Take the card that was picked in the hand
			clicked_placeholder.set_card(Game.picked_card)
			add_player_card(Game.picked_card, clicked_placeholder.coords)
			# Notify the opponent so it adds the card to his battlefield
			add_enemy_card.rpc(clicked_placeholder.current_card._unit_type, clicked_placeholder.name)
			clicked_placeholder.current_card.connect("card_clicked", _card_clicked)
			card_added.emit()
		_:
			pass


func all_highlights_off():
	for enemy_placeholder in get_tree().get_nodes_in_group("enemy_cards"):
		enemy_placeholder.highlight_off()


# Click on a card to attack with it
func _card_clicked(id: int):
	all_highlights_off()
	var clicked_card: Card = instance_from_id(id)
	if Game.current_state != State.Name.ATTACK:
		return

	attacking_card = clicked_card

	var placeholder: CardPlaceholder = instance_from_id(clicked_card.placeholder_id)
	# Highlight the enemy cards that are within reach of the selected card
	var attack_range: PackedVector2Array = clicked_card._type.attack_range
	var card_coords: Vector2 = placeholder.coords
	for enemy in get_tree().get_nodes_in_group("enemy_cards"):
		for coords in attack_range:
			if card_coords + coords == enemy.coords:
				enemy.toggle_highlight()
			

func _enemy_card_clicked(id: int):
	if Game.current_state != State.Name.ATTACK || attacking_card == null:
		return
	
	# Check that the card is within reach of the attacking card
	var clicked_card: Card = instance_from_id(id)
	var attack_range = attacking_card._type.attack_range
	var enemy_coords: Vector2 = instance_from_id(clicked_card.placeholder_id).coords
	var attacking_card_coords: Vector2 = instance_from_id(attacking_card.placeholder_id).coords
	for coords in attack_range:
		if enemy_coords == attacking_card_coords + coords:
			attacking_card.attack()
			attacking_card = null
			all_highlights_off()
			# TODO: Store the ongoing attack to know if it can be applied or not
			# Check if the opponent blocks the attack
			Game.enemy_support()
			break


# Check if a placeholder is available for a card to be placed on it
func placeholder_available(placeholder: CardPlaceholder) -> bool:
	if placeholder.current_card != null:
		return false
	# First line is always available
	if placeholder.coords.y == -1:
		return true
	else:
		# Need to check the other placeholders to see if there's one in front of the hovered one
		for p in get_tree().get_nodes_in_group("cards"):
			# No need to check placeholders on the second line or on a different column
			if p.coords.x != placeholder.coords.x or p.coords.y == -2:
				continue
			if p.current_card == null:
				return false
	return false


### 
# Network functions that are called to reflect local actions on the opponent's battlefield
###

@rpc("any_peer")
func add_enemy_card(type: CardType.UnitType, placeholder_name: String):
	var enemy_card = Game.create_card_instance(type)
	var enemy_placehoder: CardPlaceholder = $EnemyContainer.get_node(placeholder_name)
	enemy_placehoder.set_card(enemy_card)
	var coords = enemy_placehoder.coords
	if enemy_placehoder.coords.y == 0:
		_enemy_cards[coords.y + abs(coords.x - 2)] = enemy_card
	else:
		_enemy_cards[coords.y + abs(coords.x - 4)] = enemy_card
	enemy_card.connect("card_clicked", _enemy_card_clicked)
