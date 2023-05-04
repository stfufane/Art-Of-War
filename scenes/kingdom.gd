class_name Kingdom
extends Control

func _ready():
	var x = 0
	for unit_type in Game.player_kingdom:
		var card_instance = Game.get_card_instance(unit_type)
		card_instance.position = Vector2(x, 0)
		x += card_instance.size.x
		card_instance.set_nb_units(Game.player_kingdom[unit_type])
		add_child(card_instance)

func increase_population(type: CardType.UnitType):
	Game.player_kingdom[type] += 1
	pass