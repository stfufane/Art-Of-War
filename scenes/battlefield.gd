class_name Battlefield
extends Node2D

@onready var player_hand = Model.PlayerHand

func _ready():
	# Connect all the card nodes to react to click and hover
	for placeholder in get_tree().get_nodes_in_group("cards"):
		placeholder.connect("battlefield_card_clicked", _placeholder_clicked)
		placeholder.get_node("Container").connect("mouse_entered", _mouse_entered.bind(placeholder))
		placeholder.get_node("Container").connect("mouse_exited", _mouse_exited.bind(placeholder))
	pass # Replace with function body.

func _mouse_entered(placeholder_clicked: CardPlaceholder):
	if placeholder_available(placeholder_clicked):
		placeholder_clicked.set_text("Place card here")

func _mouse_exited(placeholder_clicked: CardPlaceholder):
	if placeholder_clicked.current_card == null:
		placeholder_clicked.set_text("Empty")

func _placeholder_clicked(id: int):
	var clicked_placeholder: CardPlaceholder = instance_from_id(id)
	# We can't put a card if there's already one there.
	if not placeholder_available(clicked_placeholder):
		return
	# Take the card on top of the player's hand
	var first_card = player_hand.pop_back()
	clicked_placeholder.set_card(first_card)

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
