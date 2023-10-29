class_name Card
extends Control

signal card_clicked(int)

@export  var _unit_type : CardType.UnitType

@onready var _type: CardType = Game.CardTypes[_unit_type]
@onready var _label: Label = $Container/CardName
@onready var _image: Sprite2D = $CardImage
@onready var _rect = $ColorRect
@onready var _flash_shader: Shader = preload("res://scenes/flash.gdshader")

# Tells where the card lies, to adapt its behaviour
enum BoardArea {
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
var _board_area: BoardArea = BoardArea.Nowhere 

var _engaged: bool = false
var _has_flash: bool = false


func _ready():
	base_color = _rect.color
	_type = Game.CardTypes[_unit_type]
	_label.text = _type.name
	var image = load("res://images/cards/" + _type.name + ".jpg")
	_image.texture = image


func _process(_delta):
	if _board_area == BoardArea.Picked:
		var mouse_pos = get_viewport().get_mouse_position()
		set_global_position(mouse_pos + Vector2(10, 10))


func set_board_area(new_area: BoardArea):
	_board_area = new_area


func set_unit_type(type: CardType.UnitType):
	_unit_type = type


func set_nb_units(nb_units: int):
	$Container/NbUnits.text = str(nb_units)


func disengage():
	_engaged = false
	_image.rotation_degrees = 0


func get_attack_range() -> PackedVector2Array:
	return _type.attack_range


func attack():
	_engaged = true
	_image.rotation_degrees = -90
	stop_flash()


func toggle_flash():
	if _has_flash:
		stop_flash()
	else:
		start_flash()


func start_flash():
	if _has_flash:
		return
	_image.material = ShaderMaterial.new()
	_image.material.shader = _flash_shader
	_has_flash = true

func stop_flash():
	if not _has_flash:
		return
	_image.material = null
	_has_flash = false


## Signals
############

func _on_gui_input(event:InputEvent):
	if not event.is_action_pressed(Game.LEFT_CLICK):
		return

	card_clicked.emit(get_instance_id())	
	match _board_area:
		BoardArea.Nowhere:
			pass
		BoardArea.Battlefield:
			if Game.get_state() != State.Name.ATTACK:
				return
			toggle_flash()


