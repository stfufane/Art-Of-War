class_name Card
extends Control

@export var unit_type : CardType.UnitType
@onready var card_type: CardType = Game.CardTypes[unit_type]
@onready var card_label: Label = $Container/CardName

# The id where the card sits
var placeholder_id: int = 0
var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA

# To be listened by other scenes
signal card_clicked(int)

func _ready():
	base_color = $ColorRect.color
	card_type = Game.CardTypes[unit_type]
	card_label.text = card_type.name
	card_label.text = card_type.name

func set_unit_type(type: CardType.UnitType):
	unit_type = type

func set_nb_units(nb_units: int):
	$Container/NbUnits.text = str(nb_units)

func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_click"):
		card_clicked.emit(get_instance_id())
