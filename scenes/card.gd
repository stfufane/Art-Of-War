class_name Card
extends Control


var Types: Dictionary = {
	CardType.UnitType.King: CardType.new(CardType.UnitType.King, "King", 1, 5, 4, [Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]),
	CardType.UnitType.Soldier: CardType.new(CardType.UnitType.Soldier, "Soldier", INF, 2, 1, [Vector2(0, 1)]),
	CardType.UnitType.Archer: CardType.new(CardType.UnitType.Archer, "Archer", 1, 2, 1, [Vector2(-2, 1), Vector2(2, 1), Vector2(-1, 2), Vector2(1, 2)]),
	CardType.UnitType.Guard: CardType.new(CardType.UnitType.Guard, "Guard", 1, 3, 2, [Vector2(0, 1)]),
	CardType.UnitType.Wizard: CardType.new(CardType.UnitType.Wizard, "Wizard", 1, 2, 1, [Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)]),
	CardType.UnitType.Monk: CardType.new(CardType.UnitType.Monk, "Monk", 1, 2, 2, [Vector2(-1, 1), Vector2(1, 1), Vector2(-2, 2), Vector2(2, 2)])
}


@export  var _unit_type : CardType.UnitType

@onready var _type: CardType = Types[_unit_type]
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
	EnemyReserve,
	Kingdom,
	Battlefield,
	EnemyBattlefield
}

# The id where the card sits on the battlefield
var placeholder: CardPlaceholder = null

var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA

# The global location of the card on the board
var _board_area: BoardArea = BoardArea.Nowhere 
var _picked_from: BoardArea = BoardArea.Nowhere

var _engaged: bool = false
var _has_flash: bool = false


func _ready() -> void:
	base_color = _rect.color
	_type = Types[_unit_type]
	_label.text = _type.name
	var image = load("res://images/cards/" + _type.name + ".jpg")
	_image.texture = image


func _process(_delta):
	if _board_area == BoardArea.Picked:
		var mouse_pos = get_viewport().get_mouse_position()
		set_global_position(mouse_pos + Vector2(10, 10))


func set_board_area(new_area: BoardArea):
	# When picking a card, it's removed from its area so we want to know where it came from.
	if new_area == BoardArea.Picked:
		_picked_from = _board_area
	_board_area = new_area


func get_board_area() -> BoardArea:
	return _board_area


func set_unit_type(type: CardType.UnitType) -> void:
	_unit_type = type


func set_nb_units(nb_units: int) -> void:
	$Container/NbUnits.text = str(nb_units)


func disengage() -> void:
	_engaged = false
	_image.rotation_degrees = 0


func get_attack_range() -> PackedVector2Array:
	return _type.attack_range


func attack() -> void:
	_engaged = true
	_image.rotation_degrees = -90
	stop_flash()


func toggle_flash() -> void:
	if _has_flash:
		stop_flash()
	else:
		start_flash()


func start_flash() -> void:
	if _has_flash:
		return
	_image.material = ShaderMaterial.new()
	_image.material.shader = _flash_shader
	_has_flash = true


func stop_flash() -> void:
	if !_has_flash:
		return
	_image.material = null
	_has_flash = false


## Signals
############
func _on_gui_input(event:InputEvent) -> void:
	if !event.is_action_pressed(Game.LEFT_CLICK):
		return

	match _board_area:
		BoardArea.Hand:
			Game.hand_card_clicked.emit(self)
		BoardArea.Reserve:
			Game.reserve_card_clicked.emit(self)
		BoardArea.Battlefield:
			Game.battlefield_card_clicked.emit(self)
		BoardArea.EnemyBattlefield:
			Game.enemy_battlefield_card_clicked.emit(self)
		_:
			pass

