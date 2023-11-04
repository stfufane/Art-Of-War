# Represents a scene capable of holding a list of cards and display them in a horizontal box.
class_name CardsControl
extends Control

@export var board_area: Card.BoardArea

@onready var _card_container: HBoxContainer = $CardContainer

var _cards: Array[Card] = []


func add_card(card: Card) -> void:
	card.set_board_area(board_area)
	_cards.append(card)
	if card.get_parent() != null:
		card.reparent(_card_container)
	else:
		_card_container.add_child(card)


func remove_card(card: Card) -> void:
	_card_container.remove_child(card)
	_cards.erase(card)


func remove_card_type(type: CardType.UnitType) -> void:
	for card in _cards:
		if card._unit_type == type:
			remove_card(card)
			return


func switch_card(drawn_card: Card, picked_up_card: Card) -> void:
	# If a card had already been picked up, put it back
	if picked_up_card != null:
		add_card(picked_up_card)

	remove_card(drawn_card)


func is_empty() -> bool:
	return _cards.is_empty()


func size() -> int:
	return _cards.size()


func get_cards() -> Array[Card]:
	return _cards
