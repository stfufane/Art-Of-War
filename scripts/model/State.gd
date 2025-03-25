class_name State extends RefCounted

signal started ## Emitted when the state is started
signal ended ## Emitted when the state is ended

## The instruction to display when this is the current state
var instruction: String


func _init(i: String) -> void:
	instruction = i
