class_name State extends RefCounted

signal started
signal ended


var instruction: String


func _init(i: String) -> void:
	instruction = i
	