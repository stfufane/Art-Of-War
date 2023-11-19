class_name GameEvents
extends PanelContainer

@onready var content: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel


func _ready():
	Game.add_event.connect(update_text)


func update_text(text: String) -> void:
	content.newline()
	content.append_text(Game.get_player_name() + ": " + text)
	add_line.rpc(text)


@rpc("any_peer")
func add_line(text: String):
	content.newline()
	content.append_text(Game.get_other_player_name() + ": " + text)

