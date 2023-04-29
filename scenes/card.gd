class_name Card
extends Node2D

@export var type : CardType.UnitTypes

@onready var card_type: CardType = Model.CardTypes[type]

# TODO: add all the other information from the card type.
func _ready():
	$Container/CardName.text = card_type.name

