class_name CardPlaceholder
extends Control

signal card_placeholder_clicked(int)


@export var board_area: Card.BoardArea = Card.BoardArea.Battlefield
@export var coords: Vector2
@export var label_text: String

@onready var label = $Label

var _current_card: Card = null
var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA
var is_highlighting: bool = false


func _ready():
	base_color = $ColorRect.color
	label.text = label_text


func set_text(new_text: String):
	label.text = new_text


func has_card() -> bool:
	return _current_card != null

func get_current_card() -> Card:
	return _current_card


func set_card(new_card: Card):
	if new_card.get_parent() != null:
		new_card.reparent(self)
	else:
		add_child(new_card)

	_current_card = new_card
	_current_card.placeholder_id = get_instance_id()
	_current_card.position = Vector2(0, 0)
	_current_card.set_board_area(board_area)


func remove_card():
	_current_card.queue_free()
	_current_card = null


func disengage_card():
	if _current_card != null:
		_current_card.disengage()


func connect_click(callback: Callable):
	_current_card.card_clicked.connect(callback)


func toggle_highlight():
	is_highlighting = !is_highlighting
	$ColorRect.color = highlight_color if is_highlighting else base_color


func highlight_off():
	is_highlighting = false
	$ColorRect.color = base_color


func _on_gui_input(event:InputEvent):
	if event.is_action_pressed(Game.LEFT_CLICK):
		card_placeholder_clicked.emit(get_instance_id())
