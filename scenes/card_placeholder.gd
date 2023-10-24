class_name CardPlaceholder
extends Control

@export var location: Vector2
@export var label_text: String

@onready var label = $Label

var current_card: Card = null
var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA
var is_highlighting: bool = false

signal card_placeholder_clicked(int)


func _ready():
	base_color = $ColorRect.color
	label.text = label_text


func set_text(new_text: String):
	label.text = new_text


func set_card(new_card: Card):
	if new_card.get_parent() != null:
		new_card.reparent(self)
	else:
		add_child(new_card)

	current_card = new_card
	current_card.placeholder_id = get_instance_id()
	current_card.position = Vector2(0, 0)
	# Mirror the card on the enemy battlefield
	if is_in_group("enemy_cards"):
		current_card.rotation_degrees = 180


func remove_card():
	current_card.queue_free()
	current_card = null	


func toggle_highlight():
	is_highlighting = not is_highlighting
	$ColorRect.color = highlight_color if is_highlighting else base_color


func highlight_off():
	is_highlighting = false
	$ColorRect.color = base_color


func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_click"):
		card_placeholder_clicked.emit(get_instance_id())
