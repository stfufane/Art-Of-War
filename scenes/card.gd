class_name Card
extends Control


@export  var unit : CardUnit

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
	EnemyKingdom,
	Battlefield,
	EnemyBattlefield
}

var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA

# The global location of the card on the board
var _board_area: BoardArea = BoardArea.Nowhere
var _picked_from: BoardArea = BoardArea.Nowhere

var _engaged: bool = false
var _has_flash: bool = false

var _hp: int = 0
var _hurt: bool = false


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	base_color = _rect.color
	_label.text = unit.name
	_hp = unit.defense
	var image = load("res://images/cards/" + unit.name + ".jpg")
	_image.texture = image


func _process(_delta: float):
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


func set_nb_units(nb_units: int) -> void:
	$Container/NbUnits.text = str(nb_units)


func disengage() -> void:
	_engaged = false
	_hp = unit.defense
	_hurt = false
	rotation_degrees = 0 if _board_area == BoardArea.Battlefield else 180


func engage() -> void:
	_engaged = true
	_hp = unit.defense_engaged
	rotation_degrees = -90 if _board_area == BoardArea.Battlefield else 90


func get_attack_range() -> PackedVector2Array:
	return unit.attack_range


func attack() -> void:
	engage()
	stop_flash()


func take_damage(damage: int) -> void:
	_hp -= damage
	if _hp > 0:
		_hurt = true


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
func _on_gui_input(event: InputEvent) -> void:
	if !event.is_action_pressed(Game.LEFT_CLICK):
		return

	match _board_area:
		BoardArea.Hand:
			Game.hand_card_clicked.emit(self)
		BoardArea.Reserve:
			Game.reserve_card_clicked.emit(self)
		BoardArea.Kingdom:
			Game.kingdom_card_clicked.emit(self)
		BoardArea.Battlefield:
			Game.battlefield_card_clicked.emit(self)
		BoardArea.EnemyBattlefield:
			Game.enemy_battlefield_card_clicked.emit(self)
