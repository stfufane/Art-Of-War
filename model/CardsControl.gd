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


func switch_card(drawn_card: Card, picked_up_card: Card) -> void:
	# If a card had already been picked up, put it back
	if picked_up_card != null:
		add_card(picked_up_card)

	remove_card(drawn_card)


func connect_click(callback: Callable) -> void:
	for card in _cards:
		card.card_clicked.connect(callback)


func disconnect_click(callback: Callable) -> void:
	for card in _cards:
		if card.card_clicked.is_connected(callback):
			card.card_clicked.disconnect(callback)


func is_empty() -> bool:
	return _cards.is_empty()


func get_cards() -> Array[Card]:
	return _cards
