class_name CardPlaceholder
extends Node2D

@export var location: Vector2

var current_card: CardType = null
signal battlefield_card_clicked(int)

func set_text(new_text: String):
	$Container/Label.text = new_text

func _on_container_gui_input(event):
	if event.is_action_pressed("left_click"):
		battlefield_card_clicked.emit(get_instance_id())

func set_card(new_card: CardType):
	current_card = new_card
	$Container/Label.text = current_card.name
