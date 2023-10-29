class_name Kingdom
extends Control

@onready var _card_container: HBoxContainer = $CardContainer

var _cards: Dictionary = {
	CardType.UnitType.Soldier: 0,
	CardType.UnitType.Archer: 0,
	CardType.UnitType.Guard: 0,
	CardType.UnitType.Wizard: 0,
	CardType.UnitType.Monk: 0
}


func setup():
	for unit_type in _cards:
		var card_instance = Game.create_card_instance(unit_type)
		card_instance.set_nb_units(_cards[unit_type])
		_card_container.add_child(card_instance)


func increase_population(type: CardType.UnitType):
	_cards[type] += 1
	for card in _card_container.get_children():
		if card._unit_type == type:
			card.set_nb_units(_cards[type])
