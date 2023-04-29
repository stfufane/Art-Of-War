extends Node2D

@export var type : CardType.UnitTypes

@onready var card_type: CardType = Model.CardTypes[type]

# Called when the node enters the scene tree for the first time.
func _ready():
	$Container/CardName.text = card_type.name
	pass # Replace with function body.

func _process(_delta):
	pass
