class_name CardPlaceholder
extends Control

@export var location: Vector2
@export var label_text: String

var current_card: Card = null
var base_color: Color
var highlight_color: Color = Color.DARK_MAGENTA
var is_highlighting: bool = false

signal card_placeholder_clicked(int)

func _ready():
	base_color = $ColorRect.color
	$Container/Label.text = label_text

func set_text(new_text: String):
	$Container/Label.text = new_text

func _on_container_gui_input(event):
	if event.is_action_pressed("left_click"):
		card_placeholder_clicked.emit(get_instance_id())

func set_card(new_card: Card):
	current_card = new_card
	current_card.placeholder_id = get_instance_id()
	current_card.position.x = 0
	add_child(current_card)
	
func toggle_highlight():
	is_highlighting = not is_highlighting
	$ColorRect.color = highlight_color if is_highlighting else base_color

func remove_card():
	current_card.queue_free()
	current_card = null
