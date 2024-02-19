class_name ClickableUnit extends Control

@export var unit: Unit

@onready var tiltable: TiltableUnit = $TiltableUnit

var side: Board.ESide = Board.ESide.PLAYER

func _ready() -> void:
	tiltable.unit = unit
	if side == Board.ESide.ENEMY:
		tiltable.h_flip()
	gui_input.connect(_on_gui_input)


func _on_gui_input(_event: InputEvent) -> void:
	pass
