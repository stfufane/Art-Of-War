extends Control
class_name Card

@export var unit_type : CardType.UnitType
@onready var card_type: CardType = Game.CardTypes[unit_type]
@onready var card_label: Label = $Container/CardName
@onready var card_image: Sprite2D = $CardImage
@onready var flash_shader: Shader = preload("res://scenes/flash.gdshader")

# Tells where the card lies, to adapt its behaviour
enum Location {
	Nowhere,
	Hand,
	Picked,
	Reserve,
	Kingdom,
	Battlefield,
}

# The id where the card sits on the battlefield
var placeholder_id: int = 0

var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA

# The global location of the card on the board
var location: Location = Location.Nowhere 

var engaged: bool = false
var has_shader: bool = false

# To be listened by other scenes
signal card_clicked(int)

func _ready():
	base_color = $ColorRect.color
	card_type = Game.CardTypes[unit_type]
	card_label.text = card_type.name
	var image = load("res://images/cards/" + card_type.name + ".jpg")
	card_image.texture = image


func _process(_delta):
	if location == Location.Picked:
		var mouse_pos = get_viewport().get_mouse_position()
		set_global_position(mouse_pos + Vector2(50, 50))


func set_location(new_loc: Location):
	location = new_loc

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
	if not event.is_action_pressed("left_click"):
		return

	card_clicked.emit(get_instance_id())	
	match location:
		Location.Nowhere:
			pass
		Location.Battlefield:
			if Game.current_state != State.Name.ATTACK:
				return
			card_image.material = ShaderMaterial.new()
			if !has_shader:
				card_image.material.shader = flash_shader
			else:
				card_image.material = null
			has_shader = !has_shader

