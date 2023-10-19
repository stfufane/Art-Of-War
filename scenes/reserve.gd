class_name Reserve
extends Control

@export var is_enemy: bool
@onready var reserve = Game.enemy_reserve if is_enemy else Game.player_reserve

func setup():
	var x = 0
	for card in reserve:
		card.position = Vector2(x, 0)
		x += card.size.x
		add_child(card)

func add_card(card: Card):
	card.position.x = reserve.size() * card.size.x
	add_child(card)
	reserve.append(card)

func remove_card(card: Card):
	remove_child(card)
	Game.player_reserve.erase(card)
	reorder_cards()

func reorder_cards():
	var x = 0
	for card in Game.player_reserve:
		card.position = Vector2(x, 0)
		x += card.size.x
