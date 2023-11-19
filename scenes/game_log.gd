class_name GameEvents
extends PanelContainer

@onready var content: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel


func _ready():
	Game.add_event.connect(update_text)


func update_text(aux: String, text: String) -> void:
	content.newline()
	content.append_text("You " + aux + " " + text)
	add_line.rpc(aux, text)


@rpc("any_peer")
func add_line(aux: String, text: String):
	content.newline()
	content.append_text("Enemy " + ("has " if aux == "have" else "is ") + text)

