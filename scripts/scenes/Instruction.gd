class_name Instruction extends Label


func _ready() -> void:
	Events.update_instructions.connect(_on_instruction_updated)


func _on_instruction_updated(instruction: String) -> void:
	text = instruction