class_name Kingdom
extends Control


@export var board_area: Card.BoardArea = Card.BoardArea.Kingdom


@onready var _card_container: HBoxContainer = $CardContainer


var _cards: Dictionary = {
	CardUnit.UnitType.Soldier: 0,
	CardUnit.UnitType.Archer: 0,
	CardUnit.UnitType.Guard: 0,
	CardUnit.UnitType.Wizard: 0,
	CardUnit.UnitType.Monk: 0
}

func _ready():
	Game.players_ready.connect(setup)


func setup():
	for unit_type: CardUnit.UnitType in _cards:
		var card_instance: Card = Game.create_card_instance(unit_type)
		card_instance.set_board_area(board_area)
		card_instance.set_nb_units(_cards[unit_type])
		_card_container.add_child(card_instance)


func increase_population(type: CardUnit.UnitType) -> void:
	_cards[type] += 1
	update_card_label(type)


func decrease_population(type: CardUnit.UnitType) -> void:
	_cards[type] -= 1
	update_card_label(type)


func get_unit_count(type: CardUnit.UnitType) -> int:
	return _cards[type]


func get_total_population() -> int:
	var total = 0
	for card: Card in _card_container.get_children():
		total += _cards[card.unit.type]
	return total


func is_empty() -> bool:
	for card: Card in _card_container.get_children():
		if _cards[card.unit.type] > 0:
			return false
	return true


func update_card_label(type: CardUnit.UnitType) -> void:
	for card: Card in _card_container.get_children():
		if card.unit.type == type:
			card.set_nb_units(_cards[type])
