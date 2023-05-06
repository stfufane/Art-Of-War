class_name Kingdom
extends Control

@export var is_enemy: bool
@onready var kingdom = Game.enemy_kingdom if is_enemy else Game.player_kingdom

func setup():
	var x = 0
	for unit_type in kingdom:
		var card_instance = Game.get_card_instance(unit_type)
		card_instance.position = Vector2(x, 0)
		x += card_instance.size.x
		card_instance.set_nb_units(kingdom[unit_type])
		card_instance.add_to_group("kingdom_cards")
		add_child(card_instance)

func increase_population(type: CardType.UnitType):
	kingdom[type] += 1
	for card in get_tree().get_nodes_in_group("kingdom_cards"):
		if card.unit_type == type:
			card.set_nb_units(kingdom[type])
			break
