class_name Card
extends Control

@export var type : CardType.UnitType
@onready var card_type: CardType = Model.CardTypes[type]

# The id where the card sits
var placeholder_id: int
var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA

signal card_clicked(int)

# TODO: add all the other information from the card type.
func _ready():
	base_color = $ColorRect.color
	$Container/CardName.text = card_type.name

func set_nb_units(nb_units: int):
	$Container/NbUnits.text = str(nb_units)

func _on_gui_input(event:InputEvent):
	# Depending on the listener, the click on a card can trigger different actions.
	if event.is_action_pressed("left_click"):
		card_clicked.emit(get_instance_id())
