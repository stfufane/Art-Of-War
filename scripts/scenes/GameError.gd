class_name GameError
extends Label


func _ready() -> void:
    Events.display_action_error.connect(_on_error_updated)


func _on_error_updated(error: String) -> void:
    text = error
    await get_tree().create_timer(5.0).timeout
    text = ""