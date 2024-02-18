class_name ClickableUnit extends Control

@export var unit: Unit

@onready var tiltable: TiltableUnit = $TiltableUnit

func _ready() -> void:
	tiltable.unit = unit
	gui_input.connect(_on_gui_input)


func _on_gui_input(_event: InputEvent) -> void:
	pass
