class_name Card
extends Control

@export var unit_type : CardType.UnitType
@onready var card_type: CardType = Game.CardTypes[unit_type]
@onready var card_label: Label = $Container/CardName
@onready var card_image: Sprite2D = $CardImage
@onready var flash_shader: Shader = preload("res://scenes/flash.gdshader")

# The id where the card sits
var placeholder_id: int = 0
var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA

var engaged: bool = false
# var has_shader: bool = false

# To be listened by other scenes
signal card_clicked(int)

func _ready():
	base_color = $ColorRect.color
	card_type = Game.CardTypes[unit_type]
	card_label.text = card_type.name
	var image = load("res://images/cards/" + card_type.name + ".jpg")
	card_image.texture = image

func set_unit_type(type: CardType.UnitType):
	unit_type = type

func set_nb_units(nb_units: int):
	$Container/NbUnits.text = str(nb_units)

func disengage():
	engaged = false
	card_image.rotation_degrees = 0

func attack():
	engaged = true
	card_image.rotation_degrees = -90

func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_click"):
		# card_image.material.set_shader_parameter("intensity", 0.5);
		# card_image.material = ShaderMaterial.new()
		# if !has_shader:
		# 	card_image.material.shader = flash_shader
		# else:
		# 	card_image.material = null
		# has_shader = !has_shader
		card_clicked.emit(get_instance_id())

