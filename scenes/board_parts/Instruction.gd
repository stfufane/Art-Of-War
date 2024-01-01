class_name Instruction extends Label


func _ready():
	# Global signal that can be called from anywhere to update that text.
	Game.instruction_updated.connect(_on_instruction_updated)


func _on_instruction_updated(instruction: String):
	text = instruction
