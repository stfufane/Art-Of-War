class_name Battlefield
extends Control

signal card_added

func _ready():
	# Connect all the card nodes to react to click and hover
	for placeholder in get_tree().get_nodes_in_group("cards"):
		placeholder.connect("card_placeholder_clicked", _placeholder_clicked)
		placeholder.get_node("Container").connect("mouse_entered", _mouse_entered.bind(placeholder))
		placeholder.get_node("Container").connect("mouse_exited", _mouse_exited.bind(placeholder))


func _mouse_entered(placeholder_hovered: CardPlaceholder):
	if placeholder_available(placeholder_hovered):
		placeholder_hovered.set_text("Place card here")

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
		Game.States.INIT_BATTLEFIELD:
			# We can't put a card if there's no card in hand
			if Game.card_in_hand == null:
				return
			# Take the card that was picked in the hand
			clicked_placeholder.set_card(Game.card_in_hand)
			clicked_placeholder.current_card.connect("card_clicked", _card_clicked)
			card_added.emit()
		_:
			pass

# Click on a card to attack with it
func _card_clicked(id: int):
	var clicked_card: Card = instance_from_id(id)
	var placeholder: CardPlaceholder = instance_from_id(clicked_card.placeholder_id)
	# Highlight the enemy cards that are within reach of the selected card
	var attack_range = clicked_card.card_type.attack_range
	var card_coords = placeholder.location
	for enemy in get_tree().get_nodes_in_group("enemy_cards"):
		for coords in attack_range:
			if card_coords + coords == enemy.location:
				enemy.toggle_highlight()

# Check if a placeholder is available for a card to be placed on it
func placeholder_available(placeholder: CardPlaceholder) -> bool:
	if placeholder.current_card != null:
		return false
	# First line is always available
	if placeholder.location.y == -1:
		return true
	else:
		# Need to check the other placeholders to see if there's one in front of the hovered one
		for p in get_tree().get_nodes_in_group("cards"):
			# No need to check placeholders on the second line or on a different column
			if p.location.x != placeholder.location.x or p.location.y == -2:
				continue
			if p.current_card != null:
				return true
	return false
